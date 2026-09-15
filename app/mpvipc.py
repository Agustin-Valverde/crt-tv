"""Minimal JSON-IPC client for a running mpv (--input-ipc-server).

All methods fail soft: if mpv isn't running (socket missing) they return None /
False instead of raising, so the UI stays usable while the TV is stopped.
"""
import json
import socket


class MPV:
    def __init__(self, path):
        self.path = path

    def _request(self, payload):
        """Send one command, return mpv's reply dict (or None on failure)."""
        payload = dict(payload)
        payload["request_id"] = 1
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.settimeout(1.0)
            s.connect(self.path)
            s.sendall((json.dumps(payload) + "\n").encode("utf-8"))
            buf = b""
            while True:
                chunk = s.recv(4096)
                if not chunk:
                    break
                buf += chunk
                done = False
                for line in buf.split(b"\n"):
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        msg = json.loads(line)
                    except ValueError:
                        continue
                    if msg.get("request_id") == 1 and "error" in msg:
                        s.close()
                        return msg
                if done:
                    break
            s.close()
        except (OSError, socket.timeout):
            return None
        return None

    # ---- reads ----
    def is_running(self):
        return self._request({"command": ["get_property", "idle-active"]}) is not None

    def get(self, prop):
        r = self._request({"command": ["get_property", prop]})
        if r and r.get("error") == "success":
            return r.get("data")
        return None

    # ---- writes ----
    def command(self, *args):
        return self._request({"command": list(args)})

    def cycle(self, prop):
        return self.command("cycle", prop)

    def add(self, prop, value):
        return self.command("add", prop, value)

    def set(self, prop, value):
        return self.command("set", prop, value)
