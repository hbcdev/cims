PARAMETERS tcUrl

IF EMPTY(tcUrl)
	tcUrl = "http://dragon\company"
ENDIF 	
* This code adds a browser to the vfp desktop
IF VARTYPE(_Screen.myBrowse) = "O"
	WAIT WINDOW TIMEOUT 3 "Browser already loaded!"
	RETURN
ENDIF
_Screen.AddObject("myBrowse", "iNet")
_Screen.myBrowse.Visible = .T.
WAIT WINDOW TIMEOUT 2 "Browser Loaded"

Define Class iNet As Container
	Width = _screen.Width
	Height = _screen.Height
	Name = "MyBrowser"

	Add Object olecontrol1 As OleControl With ;
		Name = "Olecontrol1",;
		OLEClass = "shell.explorer.2"
	Top=0
	Left=0
	Height=_screen.Height
	Width=_screen.Width

	Procedure Load
	On Error Retry
Endproc
* to remove it use
* _screen.RemoveObject("myBrowse")
	Procedure Init
	With This
		.olecontrol1.Top = 0
		.olecontrol1.Width = .Width
		.olecontrol1.Left = 0
		.olecontrol1.Height = .Height
		.olecontrol1.navigate(tcUrl)
		.Visible = .T.
	Endwith
Endproc
Enddefine

