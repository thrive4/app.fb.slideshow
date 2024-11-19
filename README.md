## slideshow
basic slideshow written in freebasic and sdl2\
supported file types or extensions:\
.bmp, .gif, .gls, .jpg, .jpeg, .mp3, .png, .pcx\
\
Effects include a pan scan zoom aka the\
'ken burns' effect plus fade in and crossfade.\
Special support for .mp3 this will extract the\
cover art from a mp3 and display it if present\
and .gls aka shadertoy webgl shaders.

See https://www.shadertoy.com/ for more info.

## usage
slideshow.exe "path to file or folder"\
slideshow.exe "path to file or folder" fullscreen\
if no file or path is specified the current dir will be scanned for an image\
if the folder has subfolder(s) these will be scanned for images as well\
or specify a path via \conf\conf.ini\

generate .m3u: slideshow "path to file or folder" "tag" "tagquery"\
example: slideshow.exe g:\data\mp3\classic artist beethoven\
generates the m3u file beethoven.m3u\
which then can be played by slideshow.exe beethoven.m3u
* simple search so 195 is equivelant of ?195? or \*195*
* runtime in seconds is not calculated default is #EXTINF:134
* no explicit wildcard support, only searchs on one tag
* supported tags artist, title, album, genre and year
## navigation
f11                                 : toggle fullscreen\
esc                                 : close application
## configuration
' options de, en, fr and nl\
locale          = en\
[clock and date display]\
ttffont       = gisha.ttf\
' options dddd, dd mmm yyyy or dd/mm/yyyy\
dateformat    = dddd, dd mmm yyyy\
' options hh:mm, hh:mm:ss AM/PM, hh:mm AM/PM\
timeformat    = hh:mm\
' clockposistion options bottomleft, bottomright, topleft, topright\
clockposistion = bottomleft\
' language date options os, full, abbreviated\
' full and abbreviated use date.ini allowing\
' to override the os language\
datedisplay = abbreviated\
[images]\
' location images\
imagefolder = g:\data\images\flickr\alpha clock
## requirements
sdl2 (32bit) v2.26.5.0 or up\
https://github.com/libsdl-org/SDL/releases
\
sdl image (32bit) v2.8.1 or up\
https://github.com/libsdl-org/SDL_image/releases
\
sdl ttf (32bit) v2.20.2.0 or up\
https://github.com/libsdl-org/SDL_ttf/releases
## performance
windows 7 / windows 10(1903)\
ram usage ~20MB / 20MB (pending image size)\
handles   ~160 / ~200\
threads   11 / 16\
cpu       ~1 (low) / ~2\
tested on intel i5-6600T
## special thanks
TwinklebearDev SDL 2.0 Tutorial Lesson 3\
Tutorial translating to FreeBASIC by Michael "h4tt3n" Schmidt Nissen

gisha.ttf courtesy of microsoft corporation (non-commerical use)

djpeters for freebasic shadertoy webgl intergration\
https://www.freebasic.net/forum/viewtopic.php?t=24462&hilit=shadertoy

app.ico courtesy of Sebastian Rubio\
https://www.iconarchive.com/show/plateau-icons-by-sbstnblnd/Apps-video-player-icon.html
