' based on TwinklebearDev SDL 2.0 Tutorial Lesson 6: True Type Fonts with SDL_ttf
' Translated to FreeBASIC by Michael "h4tt3n" Schmidt Nissen, march 2017
' http://www.willusher.io/sdl2%20tutorials/2013/12/18/lesson-6-true-type-fonts-with-sdl_ttf
' tweaked for fb and sdl2 june 2023 by thrive4
' supported image format bmp, gif, jpeg, jpg, lbm, pcx, png, pnm, svg, tga, tiff, tff, webp, xcf, xpm, xv

#include once "SDL2/SDL.bi"
#include once "SDL2/SDL_ttf.bi"
#include once "SDL2/SDL_image.bi"
#include once "utilfile.bas"
#include once "shuffleplay.bas"
#cmdline "app.rc"

' setup screen and sdl
dim event        as SDL_Event
dim running      as boolean = True
dim screenwidth  As integer = 1280
dim screenheight As integer = 720
dim fullscreen   as boolean = false
dim fps          as ulong   = 30
dim fpscurrent   as ulong
dim desktopw     as integer
dim desktoph     as integer
dim desktopr     as integer
dim rotateimage  as SDL_RendererFlip = SDL_FLIP_NONE
dim rotateangle  as double = 0

'zoomtype options stretch, scaled, zoomsmallimage
dim zoomtype        as string = "zoomsmallimage"
dim dummy           as string = ""
dim shared mp3file  as string
dim shared mp3chk   as boolean
mp3chk = false

' get desktop info
ScreenInfo desktopw, desktoph,,,desktopr
SDL_ShowCursor(SDL_DISABLE)

' setup timer used as interval between showing next image in microseconds
dim inittime    as integer = 0
dim interval    as integer = fps * 100 '3000
dim currenttime as integer
' setup timer used by effects
dim fxinittime  as integer = 0

' effects
dim fade        as integer = 1
dim fadetime    as single = 1 - fps / interval '((interval / 1000) * 1.465f) / (interval / 1000)
dim effectpan   as string = "left2right"
dim effectzoom  as string = "zoomin"
dim effectfade  as string = "fadein"
dim fxpanrnd(1 to 5) as string
fxpanrnd(1) = "left2right"
fxpanrnd(2) = "right2left"
fxpanrnd(3) = "top2bottom"
fxpanrnd(4) = "bottom2top"
fxpanrnd(5) = "none"
dim fxzoomrnd(1 to 3) as string
fxzoomrnd(1) = "zoomin"
fxzoomrnd(2) = "zoomout"
fxzoomrnd(3) = "none"
dim fxfadernd(1 to 3) as string
fxfadernd(1) = "fadein"
fxfadernd(2) = "crossfade"
fxfadernd(3) = "none"

' setup clock and date display
Dim ttffont          as string = exepath + "\" + "gisha.ttf"
dim shared clockposx as integer
dim shared clockposy as integer
dim ttfmessage       as string = "ttfmessage"
Dim datetime         As Double
dim dateformat       as string = "dd/mm/yyyy"
dim timeformat       as string = "hh:mm:ss"
' clockposistion options bottomleft, bottomright, topleft, topright 
dim clockposistion   as string = "bottomleft"
' options default, en, en-abrivated
'dim locale         as string = "default"
dim datedisplay      as string = "default"

' force date to other langauage
dim ddatetime as string
dim langenday(1 to 7) as string
dim langenmonth(1 to 12) as string

' setup display filename
dim imagename as string
' imagenametype options file, fullpath, folder
dim imagenametype as string = "folder"

' setup list of images for background
dim filename    as string
dim fileext     as string = ""
dim imagefolder as string
dim imagetypes  as string = ".bmp, .gif, .jpg, .mp3, .png, .pcx, .jpeg, .tff" 
dim playtype    as string = "shuffle"

' init app by overwrite by commandline or config file
'ini overwrite
dim itm     as string
dim inikey  as string
dim inival  as string
dim inifile as string = exepath + "\conf\" + "conf.ini"
dim f       as integer
if FileExists(inifile) = false then
    logentry("error", inifile + "file does not excist")
else 
    f = readfromfile(inifile)
    Do Until EOF(f)
        Line Input #f, itm
        if instr(1, itm, "=") > 1 then
            inikey = trim(mid(itm, 1, instr(1, itm, "=") - 2))
            inival = trim(mid(itm, instr(1, itm, "=") + 2, len(itm)))
            select case inikey
                case "screenwidth"
                    screenwidth = val(inival)
                case "screenheight"
                    screenheight = val(inival)
                case "fullscreen"
                    fullscreen = cbool(inival)
                case "zoomtype"
                    zoomtype = inival
                case "interval"
                    interval = val(inival)
                case "ttffont"
                    ttffont = exepath + "\" + inival
                case "dateformat"
                    dateformat = inival
                case "datedisplay"
                    datedisplay = inival
                case "timeformat"
                    timeformat = inival
                case "clockposistion"
                    clockposistion = inival
                case "locale"
                    locale = inival
                case "imagenametype"
                    imagenametype = inival
                case "imagefolder"
                    imagefolder = inival
                case "playtype"
                    playtype = inival
                case "logtype"
                    logtype = inival
            end select
            'print inikey + " - " + inival
        end if    
    loop    
end if    

select case command(2)
    case "/?", "-man", ""
        displayhelp(locale)
    case "fullscreen"
        screenwidth  = desktopw
        screenheight = desktoph
        fullscreen = true
    case ""
        ' no switch    
        'displayhelp
end select

select case "locale"
    case "en", "de", "fr"
        dim itm     as string
        dim inikey  as string
        dim inival  as string
        dim inifile as string = exepath + "\conf\" + locale + "\date.ini"
        dim f       as integer
        if FileExists(inifile) = false then
            logentry("error", inifile + "file does not excist")
        else 
            f = readfromfile(inifile)
            Do Until EOF(f)
                Line Input #f, itm
                if instr(1, itm, "=") > 1 then
                    inikey = trim(mid(itm, 1, instr(1, itm, "=") - 2))
                    inival = trim(mid(itm, instr(1, itm, "=") + 2, len(itm)))
                    select case inikey
                        case "m1"
                            langenmonth(1) = inival
                        case "m2"
                            langenmonth(2) = inival
                        case "m3"
                            langenmonth(3) = inival
                        case "m4"
                            langenmonth(4) = inival
                        case "m5"
                            langenmonth(5) = inival
                        case "m6"
                            langenmonth(6) = inival
                        case "m7"
                            langenmonth(7) = inival
                        case "m8"
                            langenmonth(8) = inival
                        case "m9"
                            langenmonth(9) = inival
                        case "m10"
                            langenmonth(10) = inival
                        case "m11"
                            langenmonth(11) = inival
                        case "m12"
                            langenmonth(12) = inival

                        case "d1"
                            langenday(1) = inival
                        case "d2"
                            langenday(2) = inival
                        case "d3"
                            langenday(3) = inival
                        case "d4"
                            langenday(4) = inival
                        case "d5"
                            langenday(5) = inival
                        case "d6"
                            langenday(6) = inival
                        case "d7"
                            langenday(7) = inival
                    end select
                end if    
            loop    
        end if    

    case else
        langenday(1) = "sunday"
        langenday(2) = "monday"
        langenday(3) = "tuesday"
        langenday(4) = "wensday"
        langenday(5) = "thurseday"
        langenday(6) = "friday"
        langenday(7) = "saturday"

        langenmonth(1)  = "january"
        langenmonth(2)  = "february"
        langenmonth(3)  = "march"
        langenmonth(4)  = "april"
        langenmonth(5)  = "may"
        langenmonth(6)  = "june"
        langenmonth(7)  = "july"
        langenmonth(8)  = "august"
        langenmonth(9)  = "september"
        langenmonth(10) = "oktober"
        langenmonth(11) = "november"
        langenmonth(12) = "december"
end select

' get images if applicable override first image with preferd a specific image
'imagefolder = command(1)
if instr(command(1), ".") <> 0 then
    fileext = lcase(mid(command(1), instrrev(command(1), ".")))
    if instr(1, imagetypes, fileext) = 0 then
        dummy = command(1) + " file type not supported"
        logentry("terminate", "abnormal termination " + dummy)
    end if
    if FileExists(exepath + "\" + command(1)) = false then
        if FileExists(imagefolder) then
            'nop
        else
            dummy = imagefolder + " does not excist or is incorrect"
            logentry("terminate", "abnormal termination " + dummy)
        end if
    else
        imagefolder = exepath + "\" + command(1)
    end if
    filename = command(1)
    imagefolder = left(command(1), instrrev(command(1), "\") - 1)
    chk = createlist(imagefolder, imagetypes, "image")
else
    if instr(command(1), ":") <> 0 then
        imagefolder = command(1)
        if checkpath(imagefolder) = false then
            dummy =  "error: path not found " + imagefolder
            logentry("terminate", "abnormal termination " + dummy)
        else
            chk = createlist(imagefolder, imagetypes, "image")
            filename = listplay(playtype, "image")
        end if
    ELSE
        if checkpath(imagefolder) = false then
            dummy =  "error: path not found " + imagefolder
            logentry("warning", dummy)
            ' try scanning exe path
            imagefolder = exepath
        end if
        chk = createlist(imagefolder, imagetypes, "image")
        filename = listplay(playtype, "image")
        if chk = false then
            dummy = "no displayable files found"
            print dummy    
            logentry("warning", dummy)
            running = false
        end if
    end if
end if

'Locate csrlin, pos   
'print "scanning folder for audiofiles and creating playlist..."

' check and get mp3 cover art
sub checkmp3cover(byref filename as string)
    if getmp3cover(filename) and instr(filename, ".mp3") > 0 then
        mp3file = filename
        mp3chk  = true
        if FileExists(exepath + "\thumb.jpg") then
            filename = exepath + "\thumb.jpg"
        else
            filename = exepath + "\thumb.png"
        end if
    else
        mp3file = ""
        mp3chk  = false
    end if
end sub

' get next or previous image
sub getimage(byref filename as string, byref dummy as string, byref mp3chk as boolean, byval playtype as string)
    filename = listplay(playtype, "image")
    checkmp3cover(filename)
    ' validate if false get next image
    if filename = "" or FileExists(filename) = false then
        filename = listplay(playtype, "image")
        checkmp3cover(filename)
    end if
end sub

' via https://www.freebasic.net/forum/viewtopic.php?p=299305&sid=71b9b1edd5e91553b901d064a45ad12c#p299305 by fxm
Function syncfps(ByVal MyFps As Ulong, ByVal SkipImage As Boolean = True, ByVal Restart As Boolean = False) As Ulong
    '' 'MyFps' : requested FPS value, in frames per second
    '' 'SkipImage' : optional parameter to activate the image skipping (True by default)
    '' 'Restart' : optional parameter to force the resolution acquisition, to reset to False on the ext call (False by default)
    '' function return : applied FFS value, in frames per second
    Static As Single tos
    Static As Single bias
    If tos = 0 Or Restart = True Then
        Dim As Double t = Timer
        For I As Integer = 1 To 10
            Sleep 1, 1
        Next I
        Dim As Double tt = Timer
        #if Not defined(__FB_WIN32__) And Not defined(__FB_LINUX__)
        If tt < t Then t -= 24 * 60 * 60
        #endif
        tos = (tt - t) / 10 * 1000
        bias = 0.55 * tos - 0.78
    End If
    Static As Double t1
    Static As Double t3
    Static As Long N = 1
    Static As Long k = 1
    Static As Ulong fps
    Static As Single tf
    If N >= k Then
        Dim As Double t2 = Timer
        #if Not defined(__FB_WIN32__) And Not defined(__FB_LINUX__)
        If t2 < t1 Then t1 -= 24 * 60 * 60
        #endif
        t3 = t2
        Dim As Single dt = (k * tf - (t2 - t1)) * 1000 - bias
        If dt < 1 Then dt = 1
        Sleep dt, 1
        t2 = Timer
        #if Not defined(__FB_WIN32__) And Not defined(__FB_LINUX__)
        If t2 < t1 Then t1 -= 24 * 60 * 60 : t3 -= 24 * 60 * 60
        #endif
        fps = k / (t2 - t1)
        t1 = t2
        Dim As Single delta = (t2 - t3) * 1000 - (dt + bias)
        bias += 0.1 * Sgn(delta)
        tf = 1 / MyFps
        Dim As Single tos0 = tos
        If tos0 > 24 Then tos0 = 24
        If tos0 < 4.8 Then tos0 = 4.8
        k = Int(MyFps / 240 * tos0)
        If k = 0 Or SkipImage = False Then k = 1
        If Abs(delta) > 3 * tos Then
            tos = 0
        End If
        N = 1
    Else
        N += 1
    End If
    Return fps
End Function

' scale and posisition image scale needs to be a float 
function resizebyaspectratio(screenw as integer, screenh as integer, imagew as integer, imageh as integer) as single
    dim screenar as single = screenw / screenh
    dim imagear  as single = imagew / imageh

    dim scale as single = 0
    if (screenar > imagear) then
        scale = screenh / imageh
    else
        scale = screenw / imagew
    end if
    return scale
end function

function scaledfit(screenw as integer, screenh as integer,_
    imagew as integer, imageh as integer,_
    ByRef scaledw As single, ByRef scaledh As single,_
    byref posx as integer, byref posy as integer) as boolean
    
    ' pending on size of scaled image and window size recalculate posx, posy 
    dim scale as single = 1
    if imagew > screenw or imageh > screenh then
        posx = 0
        posy = 0
        scale = resizebyaspectratio(screenw, screenh, imagew, imageh)
    end if    
    ' round scale rendertexture works with integers
    scaledw = abs(scale * imagew)
    scaledh = abs(scale * imageh)
    if scaledw < screenw then
        posx = screenw  / 2
        posx = posx - (scaledw / 2)
    end if
    if scaledh < screenh then
        posy = screenh / 2
        posy = posy - (scaledh / 2)
    end if
    
    return true
end function

' setup the text aka texture and image with sdl
Dim As SDL_Texture Ptr background_surface
Dim As SDL_Texture Ptr temp_surface
Dim As SDL_Texture Ptr texture
SDL_SetTextureBlendMode(temp_surface, SDL_BLENDMODE_BLEND)
' font type and Color in RGBA format
Dim As SDL_Color ttfcolor = (255, 255, 255, 0)
#define sdl_rgba(r, g, b, a) type<sdl_color>(r, g, b, a)
Dim As SDL_Color tempc          = (45, 125, 195, 0)
Dim As SDL_Color backgrondcolor = (1, 1, 1, 0)
Dim As SDL_Color ttffontgrey    = (185, 195, 205, 0)

dim tempa as integer

' scale image
dim imagex  as integer
dim imagey  as integer
dim scaledw as single
dim scaledh as single
dim scale   as single
Dim         As Integer iW, iH

' define area for rendering image
dim slideshow  as SDL_Rect

initsdl:
dim desktopplate as SDL_Rect
desktopplate.x = 0
desktopplate.y = 0
desktopplate.w = screenwidth
desktopplate.h = screenheight

dim pip as sdl_rect
pip.x = 100
pip.y = 100
pip.w = 100
pip.h = 100

' init window and render
SDL_SetHint(SDL_HINT_VIDEO_ALLOW_SCREENSAVER, "1")
' respond to power plan settings blank display on windows set hint before sdl init video
If (SDL_Init(SDL_INIT_VIDEO) = not NULL) Then
    logentry("terminate", "sdl2 video could not be initlized error: " + *SDL_GetError())
    SDL_Quit()
else
    ' no audio needed
    SDL_QuitSubSystem(SDL_INIT_AUDIO)
    ' render scale quality: 0 point, 1 linear, 2 anisotropic
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1") 
   ' filter non used events
    SDL_EventState(SDL_FINGERMOTION,    SDL_IGNORE)
    SDL_EventState(SDL_MULTIGESTURE,    SDL_IGNORE)
    SDL_EventState(SDL_DOLLARGESTURE,   SDL_IGNORE)
End If
' setup glass aka window
Dim As SDL_Window Ptr glass
if fullscreen then
    SDL_ShowCursor(SDL_DISABLE)
    glass = SDL_CreateWindow( "imageviewer", null, null, screenwidth, screenheight, SDL_WINDOW_BORDERLESS)
else
    SDL_ShowCursor(SDL_ENABLE)
    glass = SDL_CreateWindow( "imageviewer", 100, 100, screenwidth, screenheight, SDL_WINDOW_RESIZABLE)
end if
if (glass = NULL) Then
    logentry("terminate", "abnormal termination sdl2 could not create window")
	SDL_Quit()
EndIf
Dim As SDL_Renderer Ptr renderer = SDL_CreateRenderer(glass, -1, SDL_RENDERER_ACCELERATED Or SDL_RENDERER_PRESENTVSYNC)
'SDL_SetWindowOpacity(glass, 0.5)
if (renderer = NULL) Then	
    logentry("terminate", "abnormal termination sdl2 could not create renderer")
	SDL_Quit()
EndIf

' init SDL_ttf
if (TTF_Init() = Not 0) Then 
    SDL_Quit()
    end 
EndIf

dim ttffontsize     as integer
ttffontsize = fix(screenheight / 100 * 3) 
dim offsetfonty     as integer = fix(ttffontsize / (screenheight / 500))
dim fontsizeclock   as integer = 10 + ttffontsize
dim fontsizedate    as integer = fix(0.9 * ttffontsize)

Dim shared As TTF_Font Ptr ttffontdef
ttffontdef = TTF_OpenFont(ttffont, ttffontsize)

Dim shared As TTF_Font Ptr ttffontclock
ttffontclock = TTF_OpenFont(ttffont, fontsizeclock)

Dim shared As TTF_Font Ptr ttffontdate
ttffontdate = TTF_OpenFont(ttffont, fontsizedate)

Sub renderTexture(  ByVal tex As SDL_Texture Ptr, _
	                ByVal ren As SDL_Renderer Ptr, _ 
	                Byval x   As Integer, _
	                Byval y   As Integer, _
	                Byval r   As Integer, _ ' rotate in degrees
	                Byval c   As Integer, _ ' the point around which dstrect will be rotated
	                Byval f   As Integer)   ' flip SDL_FLIP_NONE, SDL_FLIP_HORIZONTAL, SDL_FLIP_VERTICAL
	
    if tex <> null then	
        Dim As Integer w, h
        Dim As SDL_Rect dst
        SDL_QueryTexture(tex, NULL, NULL, @w, @h)
        dst.x = x
        dst.y = y
        dst.w = w
        dst.h = h
        SDL_RenderCopyEx(ren, tex, NULL, @dst, r, c, f)
        SDL_DestroyTexture(tex)' todo check this	
    end if
End Sub

Function renderText( ByRef message  As Const String, _
                     Byval ttffont  As TTF_Font ptr, _
                     ByVal col      As SDL_Color, _
                     ByVal renderer As SDL_Renderer Ptr ) As SDL_Texture Ptr

    if message <> "" then
        if (ttffontdef = NULL) Then
            Return NULL
        End If
        ' load surface into a texture
        Dim As SDL_Surface Ptr surf
        surf = TTF_RenderText_Blended(ttffont, message, col)
        if (surf = NULL) Then 
            TTF_CloseFont(ttffontdef)
            Return NULL
        End If
        Dim As SDL_Texture Ptr texture = SDL_CreateTextureFromSurface(renderer, surf)
        if (texture = NULL) Then
            Return NULL
        EndIf
        ' clean up
        SDL_FreeSurface(surf)
        return texture
    else
        return null
    end if

End Function

function closesdlfonts() as boolean
    TTF_CloseFont(ttffontdef)
    TTF_CloseFont(ttffontclock)
    TTF_CloseFont(ttffontdate)
    return true
end function

' Get the texture w/h so we can center it in the screen
Dim As Integer imagew, imageh
SDL_QueryTexture(texture, NULL, NULL, @imagew, @imageh )
Dim As integer posx = (screenwidth / 2 - imagew / 2)
Dim As integer posy = (screenheight / 2 - imageh / 2)

' work aorund to init first image
getimage(filename, mp3file, mp3chk, playtype)
slideshow.x = 0
slideshow.y = 0
slideshow.w = 1.2 * screenwidth
slideshow.h = 1.2 * screenheight
pip.x = slideshow.x
pip.y = slideshow.y
pip.w = slideshow.w
pip.h = slideshow.h

' tricky todo check this used to show first image without delay in slideshow
inittime = SDL_GetTicks() - interval
' todo check placement screen
select case clockposistion
    case "bottomleft" 
        ' display clock in bottom corner left
        clockposx = 30
        clockposy = screenheight - fontsizeclock * 3.5f
    case "bottomright" 
        ' display clock in bottom corner right
        clockposx = screenwidth  - fontsizeclock * 6.0f
        clockposy = screenheight - fontsizeclock * 3.5f
    case "topleft" 
        ' display clock in top corner left
        clockposx = fontsizeclock
        clockposy = fontsizeclock
    case "topright" 
        ' display clock in top corner right
        clockposx = screenwidth  - fontsizeclock * 6.0f
        clockposy = fontsizeclock
end select

' background on launch
SDL_RenderClear(renderer)
    SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_NONE)
    SDL_SetRenderDrawColor(renderer, backgrondcolor.r, backgrondcolor.g, backgrondcolor.b, backgrondcolor.a)
    SDL_RenderFillRect(renderer, @desktopplate)
    texture = renderText("SLIDESHOW", ttffontclock, ttffontgrey, renderer)
    SDL_QueryTexture(texture, NULL, NULL, @iW, @iH)
    renderTexture(texture, renderer, screenwidth * 0.5f - iW * 0.5f, screenheight * 0.5f, 0, null, SDL_FLIP_NONE)
    SDL_DestroyTexture(texture)
SDL_RenderPresent(renderer)
sdl_delay(400)


while running
    datetime = Now()

    while SDL_PollEvent(@event) <> 0
        ' basic interaction 
        select case event.type
            case SDL_KEYDOWN and event.key.keysym.sym = SDLK_ESCAPE
                running = False
            case SDL_WINDOWEVENT and event.window.event = SDL_WINDOWEVENT_CLOSE
                running = False
            case SDL_KEYDOWN and event.key.keysym.sym = SDLK_F11
                SDL_DestroyTexture(background_surface)
                SDL_DestroyRenderer(renderer)
                SDL_DestroyWindow(glass)
                closesdlfonts()
                select case fullscreen
                    case true
                        ' enable or disable mouse cursor in window
                        screenwidth  = 1280
                        screenheight = 720
                        fullscreen = false
                        zoomtype = "zoomsmallimage"
                        goto initsdl
                    case false
                        screenwidth  = desktopw
                        screenheight = desktoph
                        fullscreen = true
                        zoomtype = "zoomsmallimage"
                        goto initsdl
                end select
                close
        end select
    wend

    ' if image can not be loaded skip to next file
    if background_surface = null then
        getimage(filename, mp3file, mp3chk, playtype)
        dummy = filename
    end if

    ' timer
    currenttime = SDL_GetTicks()
    if (currenttime > inittime + interval) then
        ' bookmark previous image for crossfade
        dummy = filename

        pip.x = slideshow.x
        pip.y = slideshow.y
        pip.w = slideshow.w
        pip.h = slideshow.h
        SDL_DestroyTexture(temp_surface)
        SDL_DestroyTexture(background_surface)

        getimage(filename, mp3file, mp3chk, playtype)
        SDL_DestroyTexture(background_surface)
        background_surface = IMG_LoadTexture(renderer, filename)

        temp_surface       = IMG_Load(dummy)
        IMG_SavePNG(temp_surface, exepath + "\dummy.png")
        SDL_FreeSurface(temp_surface)
        SDL_DestroyTexture(temp_surface)
        temp_surface       = IMG_LoadTexture(renderer, exepath + "\dummy.png")

        ' scaling image
        SDL_QueryTexture(background_surface, NULL, NULL, @iW, @iH)
        select case zoomtype
            case "scaled"
                chk = scaledfit(screenwidth, screenheight, iW, iH, scaledw, scaledh, imagex, imagey)
                slideshow.x = imagex
                slideshow.y = imagey
                slideshow.w = scaledw
                slideshow.h = scaledh
            ' setup ken burns fx
            case "zoomsmallimage"
                scale = resizebyaspectratio(screenwidth, screenheight, iW, iH)
                ' init effects
                fade = 1
                randomize
                effectzoom = fxzoomrnd(int(rnd * 3) + 1)
                effectfade = fxfadernd(int(rnd * 3) + 1)
                if scale < 0.5 then
                    scale = 0.45f + scale
                else
                    scale = 0.35f + scale
                end if
                select case effectzoom
                    case "none"
                        'nop
                    case "zoomout"
                        scale = scale * 1.75f
                    case "zoomin"
                        'nop
                end select
                if iW < 0.8f * screenwidth then
                    slideshow.w = 1.25f * scale * iW
                    slideshow.h = 1.25f * scale * iH
                    effectzoom = "none"
                    effectpan = fxpanrnd(int(rnd * (5 - 3) + 3))
                else
                    slideshow.w = scale * iW
                    slideshow.h = scale * iH
                    effectpan = fxpanrnd(int(rnd * (3 - 1) + 1))
                end if
                ' init position
                select case effectpan
                case "left2right"
                    slideshow.x = (screenwidth * 0.35f) - slideshow.w * 0.5
                    slideshow.y = (screenheight * 0.5f) - slideshow.h * 0.5
                case "right2left"
                    slideshow.x = (screenwidth * 0.65f) - slideshow.w * 0.5
                    slideshow.y = (screenheight * 0.5f) - slideshow.h * 0.5
                case "bottom2top"
                    slideshow.x = (screenwidth * 0.50f) - slideshow.w * 0.5
                    slideshow.y = (screenheight * 0.65f) - slideshow.h * 0.5
                case "top2bottom"
                    slideshow.x = (screenwidth * 0.50f) - slideshow.w * 0.5
                    slideshow.y = (screenheight * 0.35f) - slideshow.h * 0.5
                end select
            case "stretch"
                slideshow.x = 0
                slideshow.y = 0
                slideshow.w = screenwidth
                slideshow.h = screenheight
        end select
        inittime = currenttime
    end if

    ' timer effects
    if (currenttime < fxinittime + interval) then
        select case effectzoom
            case "zoomout"
                slideshow.w = slideshow.w - fadetime * (iW / iH)
                slideshow.h = slideshow.h - fadetime
                slideshow.x = slideshow.x + fadetime * (iW / iH)
                slideshow.y = slideshow.y + fadetime
            case "zoomin"
                slideshow.w = slideshow.w + fadetime * (iW / iH)
                slideshow.h = slideshow.h + fadetime
                slideshow.x = slideshow.x - fadetime * (iW / iH)
                slideshow.y = slideshow.y - fadetime
            case "none"
                'nop    
        end select
        select case effectpan
            case "left2right"
                slideshow.x = slideshow.x + fadetime
            case "right2left"
                slideshow.x = slideshow.x - fadetime
            case "top2bottom"
                slideshow.y = slideshow.y + fadetime
            case "bottom2top"
                slideshow.y = slideshow.y - fadetime
            case "none"
                ' nop
        end select
        ' todo find out why this is needed
        if fade < 1 then fade = 1 end if
        if fade < 256 then
            ' special case mp3 file
            if mp3file <> "" then
                effectfade = "fadein"
            end if
            select case effectfade
            case "fadein"
                SDL_SetTextureColorMod(background_surface, fade, fade, fade)
            case "crossfade"
                SDL_SetTextureAlphaMod(temp_surface, 256 - fade)
            case "none"
                SDL_SetTextureColorMod(background_surface, 255, 255, 255)
            End select
            fade += 2.0f * fadetime
        end if    
        fxinittime = currenttime
    end if

    ' note the ttf texture create a small memory leak mitigated by destroying the background surface
    SDL_RenderClear(renderer)
        ' image
        SDL_RenderCopyEx(renderer, background_surface, null, @slideshow, rotateangle, null, rotateimage)
        select case effectfade
            case "crossfade"
                SDL_RenderCopyEx(renderer, temp_surface, null, @pip, rotateangle, null, rotateimage)
        end select

        ' clock
        SDL_DestroyTexture(texture)
        texture = renderText(format(datetime, timeformat), ttffontclock, ttfcolor, renderer)
        renderTexture(texture, renderer, clockposx, clockposy, 0, null, SDL_FLIP_NONE)

        ' date
        select case datedisplay
            case "full" 
                ddatetime = langenday(weekday(datetime)) & ", " & day(now) & " " + langenmonth(month(datetime)) & " " & year(datetime)
            case "abbreviated"
                ddatetime = left(langenday(weekday(datetime)), 3) + ", " & day(now) & " " + left(langenmonth(month(datetime)), 3) & " " & year(datetime)
            case "os"    
                ddatetime = format(datetime, dateformat)
        end select
        SDL_DestroyTexture(texture)
        texture = renderText(ddatetime, ttffontdate, ttfcolor, renderer)
        renderTexture(texture, renderer, clockposx, clockposy + fontsizeclock, 0, null, SDL_FLIP_NONE)

        ' display image name
        select case imagenametype
            case "folder"
                dummy = left(filename, instrrev(filename, "\") -1)
                imagename = mid(dummy, instrrev(dummy, "\") + 1)
            case "file"
                imagename = mid(left(filename, len(filename) - instr(filename, "\") -1), InStrRev(filename, "\") + 1, len(filename))
            case "fullpath"
                imagename = filename
        end select
        ' special case mp3 file
        if mp3file <> "" then
            imagename = mid(left(mp3file, len(mp3file) - instr(mp3file, "\") -1), InStrRev(mp3file, "\") + 1, len(mp3file))
        end if

        SDL_DestroyTexture(texture)
        texture = renderText(lcase(imagename), ttffontdate, ttfcolor, renderer)
        renderTexture(texture, renderer, clockposx, clockposy + fontsizeclock + fontsizedate, 0, null, SDL_FLIP_NONE)
    SDL_RenderPresent(renderer)

    fpscurrent = syncfps(fps)
    ' todo phase out funky trick to achieve desired animation duration
    sleep fpscurrent * 0.35f

    if fullscreen then
        ' nop
    else
        if mp3chk then
            SDL_SetWindowTitle(glass, "slideshow - " + mp3file    + " - " & fpscurrent & " fps")' / refresh monitor = " & desktopr)
        else
            SDL_SetWindowTitle(glass, "slideshow - " + filename + " - " & fpscurrent & " fps")' / refresh monitor = " & desktopr)
        end if
    end if
    
    ' use sdl_delay to keep cpu usage low around 80 for ~10%
    'SDL_Delay(25)
    'regulateLite(30)

wend

cleanup:
' cleanup listplay files
delfile(exepath + "\" + "image" + ".tmp")
delfile(exepath + "\" + "image" + ".lst")
delfile(exepath + "\thumb.jpg")
delfile(exepath + "\thumb.png")
delfile(exepath + "\dummy.png")

' cleanup and terminate
SDL_DestroyTexture(texture)
SDL_DestroyTexture(background_surface)
SDL_DestroyRenderer(renderer)
SDL_DestroyWindow(glass)
TTF_Quit()
SDL_Quit()
IMG_Quit()
close

logentry("terminate", "normal termination " + appname)
