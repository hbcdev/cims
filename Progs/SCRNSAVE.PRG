DEFINE CLASS ScreenSaver AS CUSTOM
  #DEFINE SPI_GETSCREENSAVEACTIVE    16
  #DEFINE SPI_SETSCREENSAVEACTIVE    17

  ScreenSaverActive = .F.
  
  FUNCTION Init
  
    LOCAL llresult, lnactive
    DECLARE SHORT SystemParametersInfo IN Win32API;
      INTEGER uiAction, INTEGER uiParam,;
      INTEGER @pvParam, INTEGER fWinIni
    lnactive = 0
    llresult = (SystemParametersInfo(SPI_GETSCREENSAVEACTIVE,;
      0, @lnactive, 0) # 0)
    IF llresult
      This.ScreenSaverActive = (lnactive # 0)
    ENDIF
    RETURN llresult
  ENDFUNC
  
  PROCEDURE DisableScreenSaver
  
    IF This.ScreenSaverActive
      DECLARE SHORT SystemParametersInfo IN Win32API;
        INTEGER uiAction, INTEGER uiParam,;
        INTEGER pvParam, INTEGER fWinIni
      = SystemParametersInfo(SPI_SETSCREENSAVEACTIVE, 0, 0, 0)
    ENDIF
    RETURN
  ENDPROC

  PROCEDURE EnableScreenSaver
  
    IF This.ScreenSaverActive
      DECLARE SHORT SystemParametersInfo IN Win32API;
        INTEGER uiAction, INTEGER uiParam,;
        INTEGER pvParam, INTEGER fWinIni
      = SystemParametersInfo(SPI_SETSCREENSAVEACTIVE, 1, 0, 0)
    ENDIF
    RETURN
  ENDPROC
  
  PROCEDURE Destroy
  
    This.EnableScreenSaver
    CLEAR DLLS
    RETURN
  ENDPROC
ENDDEFINE