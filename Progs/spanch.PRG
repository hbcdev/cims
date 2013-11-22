#DEFINE MOUSE_HOURGLASS    11       && 11 = Hourglass, from FoxPro.h
      LOCAL loSplash, loMain
      loSplash = NEWOBJECT("splashform")   && Create splash form
      loSplash.SHOW()                      && Show splash form
      loMain = NEWOBJECT('mainform')       && Create main form
      loMain.SHOW()                        && Show main form
      RELEASE loSplash                     && Release splash form
      READ EVENTS

      DEFINE CLASS splashform AS FORM
         ALWAYSONTOP = .T.   && Make splash form remain on top
         AUTOCENTER = .T.
         WIDTH = 263
         NAME = "Form1"
         * Next 3 properties required for splash form to not show in
         * TaskBar
         SHOWWINDOW = 2
         DESKTOP = .T.
         TITLEBAR = 0

         BORDERSTYLE = 2
         MOUSEPOINTER = MOUSE_HOURGLASS

         ADD OBJECT lbl1 AS LABEL WITH ;
            TOP = 225, ;
            LEFT = 10, ;
            CAPTION = 'My Splash Screen Caption', ;
            FONTSIZE = 14, ;
            FONTBOLD = .T., ;
            FONTNAME = 'Arial', ;
            AUTOSIZE = .T.

         ADD OBJECT img1 AS IMAGE WITH ;
            PICTURE = HOME(2)+'Servers\Gopher\WTHOT.BMP', ;
            TOP = 0, ;
            LEFT = 0

         PROCEDURE INIT
         * Set mouse cursor to hourglass.
         THIS.SETALL('MOUSEPOINTER', THIS.MOUSEPOINTER)
         ENDPROC
         ENDDEFINE

      DEFINE CLASS mainform AS FORM
         CAPTION = "Application Main Form - Click CloseBox to Quit"
         SHOWWINDOW = 2
         AUTOCENTER = .T.
         WIDTH = 500
         HEIGHT = 400
         PROCEDURE INIT
            DECLARE integer Sleep IN WIN32API integer
            Sleep(2000) && This adjusts load time, time is in milliseconds.
            CLEAR DLLS Sleep
         ENDPROC

         PROCEDURE QUERYUNLOAD()
            CLEAR EVENTS
         ENDPROC
      ENDDEFINE
