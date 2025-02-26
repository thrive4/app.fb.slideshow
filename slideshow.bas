' based on TwinklebearDev SDL 2.0 Tutorial Lesson 6: True Type Fonts with SDL_ttf
' Translated to FreeBASIC by Michael "h4tt3n" Schmidt Nissen, march 2017
' http://www.willusher.io/sdl2%20tutorials/2013/12/18/lesson-6-true-type-fonts-with-sdl_ttf
' tweaked for fb and sdl2 june 2023 by thrive4
' supported formats .bmp, .gif, .gls, .jpg, .jpeg, .mp3, .png, .pcx

#include once "SDL2/SDL.bi"
#include once "SDL2/SDL_ttf.bi"
#include once "SDL2/SDL_image.bi"
#include once "utilfile.bas"
#include once "shuffleplay.bas"
#cmdline "app.rc"

' setup screen and sdl
dim event        as SDL_Event
dim running      as boolean = true
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
' surfaces needed for adding alpha
' sdl allocates memory per step SDL_SetSurfaceAlphaMod, SDL_ConvertSurfaceFormat
' using the same surface leads to a memeory leak.... 
Dim As SDL_Surface Ptr dsurf
Dim As SDL_Surface Ptr esurf
Dim As Integer imagew, imageh, iW, iH

' scale image
dim as integer imagex, imagey
dim as single  scaledw, scaledh 
dim scale as single

' define area for rendering image
dim slideshow  as SDL_Rect
' setup glass aka window
Dim As SDL_Window Ptr glass
dim desktopplate as SDL_Rect
dim pip          as sdl_rect

' get slideshow handle when launched
dim slideshowapp as hwnd = GetForegroundWindow

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
dim menurefresh as integer = 25000

' effects
dim fade        as integer = 1
dim fadetime    as single  = 1 - fps / interval '((interval / 1000) * 1.465f) / (interval / 1000)
dim effectpan   as string  = "left2right"
dim effectzoom  as string  = "zoomin"
dim effectfade  as string  = "fadein"
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
dim ttfmessage       as string = "ttfmessage"
Dim datetime         As Double
dim dateformat       as string = "dd/mm/yyyy"
dim timeformat       as string = "hh:mm:ss"
' clockposistion options bottomleft, bottomright, topleft, topright 
dim clockposistion   as string = "bottomleft"
dim locale           as string = "en"
' options default, en, en-abrivated
dim datedisplay      as string = "default"
dim shared clockposx as integer
dim shared clockposy as integer

' force date to other langauage
dim ddatetime as string
dim langenday(0 to 6) as string
dim langenmonth(1 to 12) as string
dim fd as SYSTEMTIME
GetLocalTime(@fd)

' setup display filename
dim imagename as string
' imagenametype options file, fullpath, folder
dim imagenametype as string = "folder"

' setup list of images for background
dim filename    as string
dim fileext     as string = ""
dim imagefolder as string
dim imagetypes  as string = ".bmp, .gif, .gls, .jpg, .jpeg, .mp3, .png, .pcx" 
dim playtype    as string = "shuffle"

' init app by overwrite by commandline or config file
'ini overwrite
dim inifile as string = exepath + "\conf\" + "conf.ini"
dim f       as long
dim as string itm, inikey, inival

' setup the text aka texture and image with sdl
Dim As SDL_Texture Ptr background_surface
Dim As SDL_Texture Ptr temp_surface
Dim As SDL_Texture Ptr texture
SDL_SetTextureBlendMode(temp_surface, SDL_BLENDMODE_BLEND)
Dim As SDL_Color ttfcolor = (255, 255, 255, 0)
Dim As SDL_Color backgrondcolor = (1, 1, 1, 0)
Dim As SDL_Color ttffontgrey    = (185, 195, 205, 0)

Dim shared As TTF_Font Ptr ttffontdef
dim ttffontsize     as integer
Dim shared As TTF_Font Ptr ttffontclock
Dim shared As TTF_Font Ptr ttffontdate

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
                case "usecons"
                    usecons = inival
            end select
            'print inikey + " - " + inival
        end if    
    loop    
end if    

' verify locale otherwise set default
select case locale
    case "en", "de", "fr", "nl"
        ' nop
    case else
        logentry("error", "unsupported locale " + locale + " applying default setting")
        locale = "en"
end select

' get date info
inifile = exepath + "\conf\" + locale + "\date.ini"
if FileExists(inifile) = false then
    logentry("error", inifile + " file does not excist")
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

                case "d0"
                    langenday(0) = inival
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
            end select
        end if    
    loop
    close(f)    
end if    

' parse commandline
select case command(1)
    case "/?", "-h", "-help", "-man"
        displayhelp(locale)
        goto cleanup
    case "-v", "-ver"
        consoleprint appname + " version " & exeversion 
        goto cleanup
end select

dummy = resolvepath(command(1))
if instr(dummy, ".") <> 0 and instr(dummy, "..") = 0 and instr(dummy, ".m3u") = 0 then
    fileext = lcase(mid(dummy, instrrev(dummy, ".")))
    if instr(1, imagetypes, fileext) = 0 then
        logentry("fatal", dummy + " file type not supported")
    end if
    imagefolder = left(dummy, instrrev(dummy, "\") - 1)
    chk = createlist(imagefolder, imagetypes, "slideshow")
    currentimage = setcurrentlistitem("slideshow", dummy)
    'currentimage -= 1
else
    ' specific path
    if instr(dummy, "\") <> 0 and instr(dummy, ".m3u") = 0  then
        imagefolder = dummy
        if checkpath(imagefolder) = false then
            logentry("fatal",  "error: path not found " + imagefolder)
        else
            chk = createlist(imagefolder, imagetypes, "slideshow")
            if chk = false then
                logentry("fatal", "error: no displayable files found")
            end if
            filename = listplay(playtype, "slideshow")
        end if
    ELSE
        ' fall back to path imagefolder specified in conf.ini
        if checkpath(imagefolder) = false then
            logentry("warning", "error: path not found " + imagefolder)
            ' try scanning exe path
            imagefolder = exepath
        end if
        chk = createlist(imagefolder, imagetypes, "slideshow")
        if chk = false then
            logentry("fatal", "error: no displayable files found")
        end if
        filename = listplay(playtype, "slideshow")
    end if
end if
if command(2) = "fullscreen" or command(4) = "fullscreen" then
    screenwidth  = desktopw
    screenheight = desktoph
    fullscreen = true
end if 

' setup parsing pls and m3u
dim maxitems        as integer

' use .m3u as slideshow coverart mp3s
if instr(dummy, ".m3u") <> 0 then
    if FileExists(dummy) then
        'nop
    else
        logentry("fatal", dummy + " file does not excist or possibly use full path to file")
    end if
    maxitems = getmp3playlist(dummy, "slideshow")
    filename = listplay(playtype, "slideshow")
    logentry("notice", "parsing and playing playlist " + filename)
end if

' search with query and export .m3u 
if instr(dummy, ":") <> 0 and len(command(2)) <> 0 and command(2) <> "fullscreen" then
    select case command(2)
        case "artist"
        case "title"
        case "album"
        case "year"
        case "genre"
        case else
            delfile(exepath + "\" + "slideshow" + ".tmp")
            delfile(exepath + "\" + "slideshow" + ".lst")
            delfile(exepath + "\" + "slideshow" + ".swp")
            logentry("fatal", "unknown tag '" & command(2) & "' valid tags artist, title, album, genre and year")
    end select
    ' scan and search nr results overwritten by getmp3playlist
    maxitems = exportm3u(dummy, "*.mp3", "m3u", "exif", command(2), command(3))
    maxitems = getmp3playlist(exepath + "\" + command(3) + ".m3u", "slideshow")
    filename = listplay(playtype, "slideshow")
    currentsong = setcurrentlistitem("slideshow", filename)
    if currentsong = 1 then
        logentry("fatal", "no matches found for " + command(3) + " in " + command(2))
    end if
end if
dummy = ""

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
    filename = listplay(playtype, "slideshow")
    checkmp3cover(filename)
    ' validate if false get next image
    if filename = "" or FileExists(filename) = false then
        filename = listplay(playtype, "slideshow")
        checkmp3cover(filename)
    end if
end sub

' via https://www.freebasic.net/forum/viewtopic.php?t=32323 by fxm
Function syncfps(ByVal MyFps As Ulong, ByVal SkipImage As Boolean = True, ByVal Restart As Boolean = False, ByRef ImageSkipped As Boolean = False) As Ulong
    '' 'MyFps' : requested FPS value, in frames per second
    '' 'SkipImage' : optional parameter to activate the image skipping (True by default)
    '' 'Restart' : optional parameter to force the resolution acquisition, to reset to False on the next call (False by default)
    '' 'ImageSkipped' : optional parameter to inform the user that the image has been skipped (if image skipping is activated)
    '' function return : applied FPS value (true or apparent), in frames per second
    Static As Single tos
    Static As Single bias
    Static As Long count
    Static As Single sum
    ' initialization calibration
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
        bias = 0
        count = 0
        sum = 0
    End If
    Static As Double t1
    Static As Long N = 1
    Static As Ulong fps
    Static As Single tf
    ' delay generation
    Dim As Double t2 = Timer
    #if Not defined(__FB_WIN32__) And Not defined(__FB_LINUX__)
    If t2 < t1 Then t1 -= 24 * 60 * 60
    #endif
    Dim As Double t3 = t2
    Dim As Single dt = (N * tf - (t2 - t1)) * 1000 - bias
    If (dt >= 3 * tos / 2) Or (SkipImage = False) Or (N >= 20) Or (fps / N <= 10) Then
        If dt <= tos Then dt = tos / 2
        Sleep dt, 1
        t2 = Timer
        #if Not defined(__FB_WIN32__) And Not defined(__FB_LINUX__)
        If t2 < t1 Then t1 -= 24 * 60 * 60 : t3 -= 24 * 60 * 60
        #endif
        fps = N / (t2 - t1)
        tf = 1 / MyFps
        t1 = t2
        ' automatic test and regulation
        Dim As Single delta = (t2 - t3) * 1000 - (dt + bias)
        If Abs(delta) > 3 * tos Then
            tos = 0
        Else
            bias += 0.1 * Sgn(delta)
        End If
        ' automatic calibation
        If dt < tos Then
            If count = 100 Then
                tos = sum / 100 * 1000
                bias = 0
                sum = 0
                count = 0
            Else
                sum += (t2 - t3)
                count += 1
            End If
        End If
        ImageSkipped = False
        N = 1
    Else
        ImageSkipped = True
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
            SDL_FreeSurface(surf)
            Return NULL
        End If
        Dim As SDL_Texture Ptr texture = SDL_CreateTextureFromSurface(renderer, surf)
        if (texture = NULL) Then
            SDL_FreeSurface(surf)
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

' toggle main loop to opengl shader if .gls file
#include once "shadertoy.bas"
dim glrunning as boolean = false
if instr(1, filename, ".gls") > 0 then
    running      = false
    glrunning    = true
    glfullscreen = true
    shader.CompileFile(filename)
else
    SDL_GL_DeleteContext(glContext)
    SDL_DestroyWindow(glglass)
end if

' init window and render
SDL_SetHint(SDL_HINT_VIDEO_ALLOW_SCREENSAVER, "1")
' respond to power plan settings blank display on windows set hint before sdl init video
If (SDL_Init(SDL_INIT_VIDEO) = not NULL) Then
    SDL_Quit()
    logentry("fatal", "sdl2 video could not be initlized error: " + *SDL_GetError())
else
    ' disable specific subsytems sdl
    SDL_QuitSubSystem(SDL_INIT_AUDIO)
    SDL_QuitSubSystem(SDL_INIT_HAPTIC)
    ' filter non used events
    SDL_EventState(SDL_FINGERMOTION,    SDL_IGNORE)
    SDL_EventState(SDL_FINGERDOWN,      SDL_IGNORE)
    SDL_EventState(SDL_FINGERUP,        SDL_IGNORE)
    SDL_EventState(SDL_MULTIGESTURE,    SDL_IGNORE)
    SDL_EventState(SDL_DOLLARGESTURE,   SDL_IGNORE)
    SDL_EventState(SDL_JOYBALLMOTION,   SDL_IGNORE)
    SDL_EventState(SDL_DROPFILE,        SDL_IGNORE)
    ' render scale quality: 0 point, 1 linear, 2 anisotropic
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1") 
End If
' init SDL_ttf
if (TTF_Init() = Not 0) Then 
    SDL_Quit()
    end 
EndIf

initsdl:
desktopplate.x = 0
desktopplate.y = 0
desktopplate.w = screenwidth
desktopplate.h = screenheight

' rescale fonts to screensize
ttffontsize = fix(screenheight / 100 * 3) 
dim offsetfonty     as integer = fix(ttffontsize / (screenheight / 500))
dim fontsizeclock   as integer = 10 + ttffontsize
dim fontsizedate    as integer = fix(0.9 * ttffontsize)
ttffontdef   = TTF_OpenFont(ttffont, ttffontsize)
ttffontclock = TTF_OpenFont(ttffont, fontsizeclock)
ttffontdate  = TTF_OpenFont(ttffont, fontsizedate)

if fullscreen then
    SDL_ShowCursor(SDL_DISABLE)
    glass = SDL_CreateWindow( "imageviewer", null, null, screenwidth, screenheight, SDL_WINDOW_BORDERLESS)
else
    SDL_ShowCursor(SDL_ENABLE)
    glass = SDL_CreateWindow( "imageviewer", 100, 100, screenwidth, screenheight, SDL_WINDOW_RESIZABLE)
end if
if (glass = NULL) Then
	SDL_Quit()
    logentry("fatal", "abnormal termination sdl2 could not create window")
EndIf
Dim As SDL_Renderer Ptr renderer = SDL_CreateRenderer(glass, -1, SDL_RENDERER_ACCELERATED Or SDL_RENDERER_PRESENTVSYNC)
'SDL_SetWindowOpacity(glass, 0.5)
if (renderer = NULL) Then	
	SDL_Quit()
    logentry("fatal", "abnormal termination sdl2 could not create renderer")
EndIf

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

' main shadertoy sdl
While glrunning

    ' make sure gl window is on top
    SDL_RaiseWindow(glglass)

    While SDL_PollEvent(@event)
        select case event.type
            case SDL_KEYDOWN and event.key.keysym.sym = SDLK_ESCAPE
                SDL_GL_DeleteContext(glContext)
                SDL_DestroyWindow(glglass)
                glrunning = False
                running = false
            case SDL_WINDOWEVENT and event.window.event = SDL_WINDOWEVENT_CLOSE
                SDL_GL_DeleteContext(glContext)
                SDL_DestroyWindow(glglass)
                glrunning = False
                running   = false
            case SDL_WINDOWEVENT and event.window.event = SDL_WINDOWEVENT_MINIMIZED
                SDL_HideWindow(glglass)
            case SDL_WINDOWEVENT and event.window.event = SDL_WINDOWEVENT_RESTORED
                SDL_ShowWindow(glglass)
            ' keep gl window in place relative to regular sdl window
            case SDL_WINDOWEVENT and event.window.event = SDL_WINDOWEVENT_MOVED
                SDL_GetWindowPosition(glass, @w2, @h2)
                sdl_setwindowposition(glglass, w2, h2)
            case SDL_WINDOWEVENT and event.window.event = SDL_WINDOWEVENT_RESIZED
                SDL_GetWindowPosition(glass, @w2, @h2)
                sdl_setwindowposition(glglass, w2, h2)
            case SDL_KEYDOWN and event.key.keysym.sym = SDLK_F11
                SDL_GL_DeleteContext(glContext)
                SDL_DestroyRenderer(renderer)
                SDL_DestroyWindow(glass)
                SDL_DestroyWindow(glglass)
                select case fullscreen
                    case true
                        ' enable or disable mouse cursor in window
                        screenwidth  = 1280
                        screenheight = 720
                        fullscreen = false
                        goto initgl
                    case false
                        screenwidth  = desktopw
                        screenheight = desktoph
                        fullscreen = true
                        sdl_setwindowposition(glglass, 0, 0)
                        goto initgl
                end select
        end select
    Wend

    ' timer
    currenttime = SDL_GetTicks()
    if (currenttime > inittime + interval * 3) then
        filename = listplay(playtype, "slideshow")
        ' todo needs better handeling funky behaivour
        if shader.CompileFile(filename) = false then
            print "error compiling " & filename
        end if
        inittime = currenttime
    end if

    ' enable shader
    glUseProgram(Shader.ProgramObject)
    tNow = Timer()

    ' get uniforms locations in shader program
    var iGlobalTime = glGetUniformLocation(Shader.ProgramObject,"iGlobalTime")
    var iTime       = glGetUniformLocation(Shader.ProgramObject,"iTime")
    var iResolution = glGetUniformLocation(Shader.ProgramObject,"iResolution")
    var iMouse      = glGetUniformLocation(Shader.ProgramObject,"iMouse")
    var iDate       = glGetUniformLocation(Shader.ProgramObject,"iDate")
    glUniform3f(iResolution, v3.x, v3.y, v3.z)
    glUniform4f(idate, year(now), month(now), day(now), (hour(now) * 60 * 60) + (minute(now) * 60) + second(now) + (epoch - fix(epoch)))
    glUniform1f(iGlobalTime, tNow - tStart)
    glUniform1f(iTime, tNow - tStart)
    glClear (GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
    glRectf (-1.0, -1.0, 1.0, 1.0)

    ' Update the screen
    SDL_GL_SwapWindow(glglass)

    SDL_SetWindowTitle(glass, "shadertoy sdl2 file: " & filename)
    ' reduce cpu usage affects shader animation
    ' use sdl_delay to keep cpu usage low around 80 for ~10%
    fpscurrent = syncfps(fps)
    ' todo phase out funky trick to achieve desired animation duration
    sleep fpscurrent * 0.35f
Wend

' work around to init first image regular sdl
if glrunning = false then
    getimage(filename, mp3file, mp3chk, playtype)
    SDL_DestroyTexture(background_surface)
    background_surface = IMG_LoadTexture(renderer, filename)

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
end if ' end glrunning false

' main regular sdl
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
        background_surface = IMG_LoadTexture(renderer, filename)
        ' if image can not be loaded skip to next file
        if background_surface = null then
            getimage(filename, mp3file, mp3chk, playtype)
            background_surface = IMG_LoadTexture(renderer, filename)
            dummy = filename
        end if

        ' add alpha for crossfade
        dsurf = IMG_Load(dummy)
        SDL_SetSurfaceAlphaMod(dsurf, 0)
        esurf = SDL_ConvertSurfaceFormat(dsurf, SDL_PIXELFORMAT_RGBA32, 0)
        temp_surface = SDL_CreateTextureFromSurface(renderer, esurf)
        SDL_FreeSurface(dsurf)
        SDL_FreeSurface(esurf)

        ' init effects
        fade = 1
        fxinittime = currenttime

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
                ddatetime = langenday(fd.wDayOfWeek) & ", " & day(now) & " " + langenmonth(month(datetime)) & " " & year(datetime)
            case "short"
                ddatetime = left(langenday(fd.wDayOfWeek), 3) + ", " & day(now) & " " + left(langenmonth(month(datetime)), 3) & " " & year(datetime)
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

    ' use sdl_delay to keep cpu usage low around 80 for ~10%
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
    

wend

'cleanup sdl
SDL_DestroyTexture(texture)
SDL_DestroyTexture(background_surface)
SDL_DestroyRenderer(renderer)
SDL_DestroyWindow(glass)
TTF_Quit()
SDL_Quit()
IMG_Quit()
close

cleanup:
' cleanup listplay files
delfile(exepath + "\" + "slideshow" + ".tmp")
delfile(exepath + "\" + "slideshow" + ".lst")
delfile(exepath + "\" + "slideshow" + ".swp")
delfile(exepath + "\thumb.jpg")
delfile(exepath + "\thumb.png")

logentry("terminate", "normal termination " + appname)
