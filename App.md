https://github.com/MaironW/entertainment-wave-2021

C++ I suppose, never used that but doesnt seems like a complex app, claude can recreate it. We need to go simple as we are in the rpi

mpv for video playing

On startup of the pi it always open on randomized TV
ssh to it and you can navigate the app
app shows TV - RADIO - EXIT in retro style, you can move within the app with command or using the keyboard (like when you press keys when an mpv video is playing) to explore similar to a file explorer
EXIT justs quit the app.

Audio & subtitles: 
- Most torrents come with subtitles and different audio tracks
- Ideally, it should be easy to change between them (mpv got commands), but ideally it should automatically follow an predetermined order when playing a videos:
	- Anime and Simpsons: audito latino, if not, native with spanish subtitles (then english subtitles)
	- Movies: native language with spanish subtitles (then english)
	- Subtitles size and position is also VERY important
Sizing: 
- Right now we have some sizing errors, black band on the side of some videos, panscan kinda works, but on some cases it zooms too much and we loose some video, in others it just doesnt fix. We need to get an universal solution if possible

Torrent: 
- When adding a new program via torrent, the program should automatically now it was added

TV:
- First option is always Shuffle (Randomized between all the folders content)
- Else you can check for specific shows:
	- We will separate it show in a folder
	- it selecting a show, it will follow just the native sorting
	- Its simple, dont need any indicator of a seen show or something like that

Radio:
- Open the spotify tui, we need to setup my personal account.

WE always keep the retro look, like the github repo