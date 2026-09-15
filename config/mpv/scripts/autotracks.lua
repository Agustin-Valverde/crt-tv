-- autotracks.lua : pick audio/subtitle tracks per crt-tv rules on every file load.
-- Category is derived from the file's top-level folder under ~/videos.
--   Anime, Cartoons-Series : audio latino -> else native + Spanish subs -> else English subs
--   Movies                 : native audio + Spanish subs -> else English subs
-- Per-show overrides come from ~/.config/mpv/overrides.json.

local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

local CATEGORY_PROFILES = {
  ["Anime"]           = "latino_first",
  ["Cartoons-Series"] = "latino_first",
  ["Movies"]          = "native_subs",
}
local DEFAULT_PROFILE = "latino_first"

-- ---------- helpers ----------
local function lower(s) return s and s:lower() or "" end

local function is_spanish(lang)
  local l = lower(lang)
  return l:find("^spa") ~= nil or l:find("^es") ~= nil or l:find("lat") ~= nil
end

local function is_english(lang)
  local l = lower(lang)
  return l:find("^eng") ~= nil or l:find("^en") ~= nil
end

local function title_latino(title)
  local t = lower(title)
  return t:find("latin") or t:find("latino") or t:find("america") or t:find("419") or t:find("lat")
end

local function title_castilian(title)
  local t = lower(title)
  return t:find("castellano") or t:find("castilian") or t:find("espa") or t:find("spain") or t:find("iberic")
end

local function detect_category(path)
  if not path then return nil end
  for cat, _ in pairs(CATEGORY_PROFILES) do
    if path:find("/" .. cat .. "/", 1, true) then return cat end
  end
  return nil
end

local function tracks_of(tl, typ)
  local r = {}
  for _, t in ipairs(tl) do if t.type == typ then r[#r + 1] = t end end
  return r
end

-- audio picks
local function pick_latino_audio(auds)
  for _, t in ipairs(auds) do  -- 1) spanish + latino title
    if is_spanish(t.lang) and title_latino(t.title) then return t end
  end
  for _, t in ipairs(auds) do  -- 2) spanish, not explicitly castilian
    if is_spanish(t.lang) and not title_castilian(t.title) then return t end
  end
  return nil
end

local function pick_native_audio(auds)
  for _, t in ipairs(auds) do if t.default and not is_spanish(t.lang) then return t end end
  for _, t in ipairs(auds) do if not is_spanish(t.lang) then return t end end
  for _, t in ipairs(auds) do if t.default then return t end end
  return auds[1]
end

-- subtitle picks
local function pick_spanish_sub(subs)
  for _, t in ipairs(subs) do if is_spanish(t.lang) and title_latino(t.title) then return t end end
  for _, t in ipairs(subs) do if is_spanish(t.lang) and not title_castilian(t.title) then return t end end
  for _, t in ipairs(subs) do if is_spanish(t.lang) then return t end end
  return nil
end

local function pick_english_sub(subs)
  for _, t in ipairs(subs) do
    if is_english(t.lang) and not lower(t.title):find("sdh") and not lower(t.title):find("forced") then return t end
  end
  for _, t in ipairs(subs) do if is_english(t.lang) then return t end end
  return nil
end

-- ---------- overrides ----------
local function load_overrides()
  local home = os.getenv("HOME") or ""
  local f = io.open(home .. "/.config/mpv/overrides.json", "r")
  if not f then return {} end
  local content = f:read("*a"); f:close()
  local data = utils.parse_json(content or "")
  return (type(data) == "table") and data or {}
end

local function matching_override(path)
  if not path then return nil end
  for key, val in pairs(load_overrides()) do
    if key:sub(1, 1) ~= "_" and type(val) == "table" and path:find(key, 1, true) then
      return val
    end
  end
  return nil
end

-- ---------- apply ----------
local function set_audio(t) if t then mp.set_property_number("aid", t.id) end end
local function set_sub_on(t)
  if t then
    mp.set_property_number("sid", t.id)
    mp.set_property_bool("sub-visibility", true)
  end
end
local function set_sub_off()
  mp.set_property("sid", "no")
  mp.set_property_bool("sub-visibility", false)
end

local function apply_profile(profile, auds, subs)
  if profile == "native_subs" then
    set_audio(pick_native_audio(auds))
    local s = pick_spanish_sub(subs) or pick_english_sub(subs)
    if s then set_sub_on(s) else set_sub_off() end
  else -- latino_first
    local la = pick_latino_audio(auds)
    if la then
      set_audio(la); set_sub_off()
    else
      set_audio(pick_native_audio(auds))
      local s = pick_spanish_sub(subs) or pick_english_sub(subs)
      if s then set_sub_on(s) else set_sub_off() end
    end
  end
end

local function select_tracks()
  local tl = mp.get_property_native("track-list")
  if not tl then return end
  local path = mp.get_property("path")
  local auds, subs = tracks_of(tl, "audio"), tracks_of(tl, "sub")

  local ov = matching_override(path)
  if ov then
    if ov.aid then mp.set_property_number("aid", ov.aid) end
    if ov.sid then mp.set_property_number("sid", ov.sid) end
    if ov.sub ~= nil then mp.set_property_bool("sub-visibility", ov.sub and true or false) end
    if not ov.profile then
      msg.info("autotracks: applied override for " .. tostring(path))
      return
    end
  end

  local profile = (ov and ov.profile) or CATEGORY_PROFILES[detect_category(path)] or DEFAULT_PROFILE
  apply_profile(profile, auds, subs)

  -- Auto zoom-to-fill for widescreen content (4:3 CRT). The app's `z` key still
  -- toggles this manually for the current file.
  local w = mp.get_property_number("width")
  local h = mp.get_property_number("height")
  if w and h and h > 0 then
    mp.set_property_number("panscan", (w / h >= 1.5) and 1.0 or 0.0)
  end

  msg.info(string.format("autotracks: profile=%s aids=%d subs=%d", profile, #auds, #subs))
end

mp.register_event("file-loaded", select_tracks)
