LOCAL oForm As TForm
oForm = CREATEOBJECT("TForm")
oForm.Show(1)
* end of main
 
#DEFINE NIM_ADD 0
#DEFINE NIM_MODIFY 1
#DEFINE NIM_DELETE 2
#DEFINE NIF_MESSAGE 1
#DEFINE NIF_ICON 2
#DEFINE NIF_TIP 4
#DEFINE NOTIFYICONDATA_SIZE 88
#DEFINE MAX_PATH 260
#DEFINE GWL_WNDPROC -4
#DEFINE IMAGE_ICON 1
#DEFINE LR_LOADFROMFILE 0x0010
#DEFINE LR_DEFAULTSIZE 0x0040
 
#DEFINE WM_MOUSEMOVE 0x0200
#DEFINE WM_LBUTTONDOWN 0x0201
#DEFINE WM_LBUTTONUP 0x0202
#DEFINE WM_RBUTTONDOWN 0x0204
#DEFINE WM_RBUTTONUP 0x0205
#DEFINE WM_MBUTTONDOWN 0x0207
#DEFINE WM_MBUTTONUP 0x0208
 
DEFINE CLASS TForm As Form
    Width=350
    Height=200
    BorderStyle=2
    MinButton=.F.
    MaxButton=.F.
    Caption="Systray Icon"
    Autocenter=.T.
 
    ADD OBJECT taskbaricon As TaskbarStatus
    ADD OBJECT sbar As Tbar WITH Top=398, Left=0, Height=21, Width=685
 
    ADD OBJECT chShowIcon As CheckBox WITH;
    Left=15, Top=15, Caption="Show Icon", Autosize=.T.
 
    ADD OBJECT cmdLoadIcon As CommandButton WITH;
    Left=120, Top=10, Width=140, Height=27,;
    Caption="Load Icon from file"
 
PROCEDURE chShowIcon.Click
    ThisForm.ShowIcon(THIS.Value)
 
PROCEDURE cmdLoadIcon.Click
    ThisForm.LoadIcon
 
PROCEDURE taskbaricon.OnUdfMessage
PARAMETERS wParam As Integer, lParam As Integer
    DODEFAULT()
 
    DO CASE
    CASE lParam=WM_MOUSEMOVE
        ThisForm.sbar.Panels(1).Text = "Mouse moves: " +;
            TRANS(THIS.LastMouseX) + ", " + TRANS(THIS.LastMouseY)
    CASE lParam=WM_LBUTTONDOWN
        ThisForm.sbar.Panels(2).Text = "Left Button Down"
    CASE lParam=WM_LBUTTONUP
        ThisForm.sbar.Panels(2).Text = "Left Button Up"
    CASE lParam=WM_RBUTTONDOWN
        ThisForm.sbar.Panels(2).Text = "Right Button Down"
    CASE lParam=WM_RBUTTONUP
        ThisForm.sbar.Panels(2).Text = "Right Button Up"
    CASE lParam=WM_MBUTTONDOWN
        ThisForm.sbar.Panels(2).Text = "Middle Button Down"
    CASE lParam=WM_MBUTTONUP
        ThisForm.sbar.Panels(2).Text = "Middle Button Up"
    ENDCASE
 
PROCEDURE ShowIcon(nMode)
* shows or hides icon in the systray
    WITH THIS.taskbaricon
        IF nMode = 0
            .DeleteIcon
        ELSE
            .baloon = VERSION()
            .InitIcon(.GetDefaultIcon())
        ENDIF
    ENDWITH
 
PROCEDURE LoadIcon
* loads icon from a file and displays in the systray
    LOCAL cPath, cIconFile
    cPath = SYS(5) + SYS(2003)
    cIconFile = GETFILE("ico", "Load icon file")
    SET DEFAULT TO (m.cPath)
 
    IF NOT EMPTY(m.cIconFile)
        THIS.taskbaricon.baloon = LOWER(m.cIconFile)
        THIS.taskbaricon.InitIcon(m.cIconFile)
        THIS.chShowIcon.Value=1
    ENDIF
 
ENDDEFINE
 
DEFINE CLASS Tbar As OleControl
    OleClass="MSComctlLib.SBarCtrl.2"
 
PROCEDURE Init
    THIS.Height=21
    THIS.Panels.Add
    THIS.Panels(1).Width = 160
    THIS.Panels(2).Width = 700
ENDDEFINE
 
DEFINE CLASS TaskbarStatus As Custom
    hWindow=0
    AppID=1
    MessageID=0x4001
    hOrigProc=0
    hIcon=0
    baloon=""
    LastMouseX=0
    LastMouseY=0
 
PROCEDURE Init
    THIS.declare
    THIS.hWindow = _screen.HWnd
    THIS.hOrigProc = GetWindowLong(THIS.hWindow, GWL_WNDPROC)
 
PROCEDURE Destroy
    THIS.DeleteIcon
 
PROCEDURE DeleteIcon
    IF THIS.hIcon <> 0
        THIS.SetIcon(NIM_DELETE)
        = DestroyIcon(THIS.hIcon)
        THIS.hIcon = 0
 
        IF VERSION(5) >= 900  && VFP9+
            = UNBINDEVENTS(THIS.hWindow, THIS.MessageID)
        ENDIF
    ENDIF
 
PROCEDURE InitIcon(hIcon)
    THIS.DeleteIcon
 
    DO CASE
    CASE VARTYPE(m.hIcon)="N"
        THIS.hIcon = m.hIcon
    CASE VARTYPE(m.hIcon)="C"
        THIS.hIcon = THIS.LoadIcon(m.hIcon)
    OTHERWISE
        RETURN
    ENDCASE
    THIS.SetIcon(NIM_ADD)
 
PROCEDURE SetIcon(cAction)
    LOCAL cBuffer
 
    cBuffer = num2dword(NOTIFYICONDATA_SIZE) +;
        num2dword(THIS.hWindow) +;
        num2dword(THIS.appid) +;
        num2dword(NIF_ICON + NIF_MESSAGE + NIF_TIP) +;
        num2dword(THIS.MessageID) +;
        num2dword(THIS.hIcon) +;
        PADR(THIS.baloon, 64, Chr(0))
 
    IF Shell_NotifyIcon(m.cAction, @cBuffer) <> 0
        IF VERSION(5) >= 900  && VFP9+
            = BINDEVENT(THIS.hWindow, THIS.MessageID,;
                THIS, "HookedWindowProc")
        ENDIF
    ENDIF
 
PROCEDURE GetMousePos(nX, nY)
* retrieves position of the cursor in screen coordinates
    LOCAL cBuffer
    cBuffer = REPLICATE(Chr(0), 8)
    = GetCursorPos(@cBuffer)
    nX = buf2dword(SUBSTR(cBuffer, 1,4))
    nY = buf2dword(SUBSTR(cBuffer, 5,4))
 
PROCEDURE LoadIcon(cIconFile)
* loads icon from a file
    LOCAL hIcon
    TRY
    hIcon = LoadImage(0, m.cIconFile, IMAGE_ICON,;
        0,0, LR_LOADFROMFILE+LR_DEFAULTSIZE)
    CATCH
        hIcon=0
    ENDTRY
RETURN m.hIcon
 
PROCEDURE GetDefaultIcon
* loads application icon
    LOCAL cBuffer, nBufsize, nIconIndex, hIcon
    cBuffer = REPLICATE(CHR(0), MAX_PATH)
    nBufsize = GetModuleFileName (0, @cBuffer, MAX_PATH)
    cBuffer = LEFT(cBuffer, nBufsize)
    nIconIndex = 0  && works as a reference only 
    hIcon = ExtractAssociatedIcon(0, cBuffer, @nIconIndex)
RETURN m.hIcon
 
PROCEDURE OnUdfMessage(wParam As Integer, lParam As Integer)
* you will probably want to subclass this
    LOCAL nX, nY
    STORE 0 TO nX, nY
    THIS.GetMousePos(@nX, @nY)
    THIS.LastMouseX=m.nX
    THIS.LastMouseY=m.nY
 
PROCEDURE HookedWindowProc(hWindow as Integer,;
    nMsgID as Integer, wParam as Integer, lParam as Integer)
* requires VFP9, otherwise ignored
* note that input parameters are predefined and should not be changed
* see WindowProc function for details
 
    LOCAL nReturn
    nReturn=0
 
    DO CASE
    CASE nMsgID=THIS.MessageID
        THIS.OnUdfMessage(wParam, lParam)
 
    OTHERWISE
    * pass control to the original window procedure
        nReturn = CallWindowProc(THIS.hOrigProc, THIS.hWindow,;
            m.nMsgID, m.wParam, m.lParam)
    ENDCASE
RETURN nReturn
 
PROTECTED PROCEDURE declare
    DECLARE INTEGER DestroyIcon IN user32 INTEGER hIcon
     DECLARE INTEGER SetForegroundWindow IN user32 INTEGER hWindow
    DECLARE INTEGER GetCursorPos IN user32 STRING @ lpPoint
    DECLARE INTEGER Shell_NotifyIcon IN shell32 INTEGER dwMsg, STRING @lpdata
    DECLARE INTEGER GetWindowLong IN user32 INTEGER hWindow, INTEGER nIndex
 
    DECLARE INTEGER ExtractAssociatedIcon IN shell32;
        INTEGER hInst, STRING lpIconPath, INTEGER @lpiIcon
 
    DECLARE INTEGER GetModuleFileName IN kernel32;
        INTEGER hModule, STRING @lpFilename, INTEGER nSize
 
    DECLARE INTEGER CallWindowProc IN user32;
        INTEGER lpPrevWndFunc, INTEGER hWindow, LONG Msg,;
        INTEGER wParam, INTEGER lParam
 
    DECLARE INTEGER LoadImage IN user32;
        INTEGER hinst, STRING lpszName, INTEGER uType,;
        INTEGER cxDesired, INTEGER cyDesired, INTEGER fuLoad
 
ENDDEFINE
 
FUNCTION buf2dword(cBuffer)
RETURN Asc(SUBSTR(cBuffer, 1,1)) + ;
    BitLShift(Asc(SUBSTR(cBuffer, 2,1)),  8) +;
    BitLShift(Asc(SUBSTR(cBuffer, 3,1)), 16) +;
    BitLShift(Asc(SUBSTR(cBuffer, 4,1)), 24)
 
FUNCTION num2dword(nValue)
#DEFINE m0  0x0100
#DEFINE m1  0x010000
#DEFINE m2  0x01000000
    IF nValue < 0
        nValue = 0x100000000 + nValue
    ENDIF
    LOCAL b0, b1, b2, b3
    b3 = Int(nValue/m2)
    b2 = Int((nValue - b3*m2)/m1)
    b1 = Int((nValue - b3*m2 - b2*m1)/m0)
    b0 = Mod(nValue, m0)
RETURN Chr(b0)+Chr(b1)+Chr(b2)+Chr(b3)
 
 
