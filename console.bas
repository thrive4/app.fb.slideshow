' allows for hybrid usage console feedback when app is compiled in -gui mode
' courtesy https://stackoverflow.com/questions/510805/can-a-win32-console-application-detect-if-it-has-been-run-from-the-explorer-or-n
' comment bobsobol
function print2console(msg as string, forcewstr as boolean = false) as boolean

    if AttachConsole(ATTACH_PARENT_PROCESS) THEN ' gui mode
        Shell("Cls")
        ' sigh work around msg = wstr(msg) does not work ....
        if forcewstr then
            print wstr(msg)
        else
            print msg
        end if
        ' restore the normal prompt in cmd console
        freeconsole()
		PostMessage(GetForegroundWindow, WM_KEYDOWN, VK_RETURN, 0)
    else
        if forcewstr then
            print wstr(msg)
        else
            print msg
        end if
    END IF

    return true

end function
