IF VARTYPE(_Screen.myBrowse) = "O"
	_screen.RemoveObject("myBrowse")
	WAIT WINDOW TIMEOUT 2 "Browser Has been unloaded"	
	RETURN
ENDIF
