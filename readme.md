## slideshow
basic slideshow written in freebasic and sdl2\
supported image types or extensions:\
.bmp, .gif, .jpg, .png, .pcx, .jpeg, .tff\
\
Effects include a pan scan zoom aka the\
'ken burns' effect plus fade in and crossfade.\
Special support for .mp3 this will extract the\
cover art from a mp3 and display it if present.
## usage
slideshow.exe "path to file or folder"\
slideshow.exe "path to file or folder" fullscreen\
if no file or path is specified the current dir will be scanned for an image\
if the folder has subfolder(s) these will be scanned for images as well\
or specify a path via \conf\conf.ini\
## configuration
' options de, en, fr and nl\
locale          = en\
[clock and date display]\
ttffont       = gisha.ttf\
fontsizeclock = 58\
fontsizedate  = 30\
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
sdl2 (32bit) v2.24.2.0\
https://github.com/libsdl-org/SDL/releases
\
sdl image (32bit) v2.6.2.0\
https://github.com/libsdl-org/SDL_image/releases
## performance
windows 7 / windows 10(1903)\
ram usage ~20MB / 20MB (pending image size)\
handles   ~160 / ~200\
threads   11 / 16\
cpu       ~1 (low) / ~2\
tested on intel i5-6600T
## navigation
f11                                 : toggle fullscreen\
esc                                 : close application
## special thanks
TwinklebearDev SDL 2.0 Tutorial Lesson 3\
Tutorial translating to FreeBASIC by Michael "h4tt3n" Schmidt Nissen\
gisha.ttf courtesy of microsoft corporation (non-commerical use)\
app.ico courtesy of Sebastian Rubio\
https://www.iconarchive.com/show/plateau-icons-by-sbstnblnd/Apps-video-player-icon.html

