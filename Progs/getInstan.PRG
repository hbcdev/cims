DEFINE CLASS AppInstances as Custom 

procedure init   this.VerifyInstance(.t.)endproc 
Procedure VerifyInstance(lMessageOnly As Boolean) As Integer
With This
   .DllInit()
   Local hWinActive, hWindow, lcWinText, hWinCount, lnWinIndex
   hWinActive = GetActiveWindow()
   hWindow = -1
   hWinCount = 0
   nCounter = 0
#Define GW_HWNDFIRST 0
#Define GW_HWNDLAST 1
#Define GW_HWNDNEXT 2
Do While hWindow <> GetWindow (hWinActive, GW_HWNDLAST)
   If hWindow = -1
      hWindow = GetWindow(hWinActive, GW_HWNDFIRST)
   Else
      hWindow = GetWindow(hWindow, GW_HWNDNEXT)
   Endif
   If IsWindow(hWindow) <> 0 And IsWindowVisible(hWindow) <> 0;
      And GetWindowTextLength(hWindow) > 0
      lcWinText = .GetWinText(hWindow)
      If hWindow <> hWinActive And Not "Program Manager" $ lcWinText
         hWinCount = hWinCount + 1
         Dimen arrWin[hWinCount, 2]
         arrWin[hWinCount, 1] = hWindow
         arrWin[hWinCount, 2] = lcWinText
      Endif
   Endif
Enddo
If hWinCount > 0
   nCounter = 0
   For lnWinIndex=1 To hWinCount
      aa = Upper(arrWin[lnWinIndex, 2])
      If Left(aa,15) = "INT-E-VIEW 2000"
         nCounter = nCounter + 1
      Endif
   Endfor
   If lMessageOnly And nCounter >= 1
      If nCounter = 1
         Messagebox(Transform(nCounter,"999 ")+ ;
          " Instance of Your Application is already opened. ",0,_Screen.Caption)
      Else
         Messagebox(Transform(nCounter,"999 ")+ ;
          " Instance of Your Application are already opened ",0,_Screen.Caption)
      Endif
   Else
   Endif
Endif
Endwith
Return nCounter
Endproc
Function CloseApp (hWindow)
   #Define WM_QUIT 18
   #Define WM_SYSCOMMAND 274
   #Define SC_CLOSE 61536 && 0xF060
   #Define PROCESS_TERMINATE 1
   Local hWinProcId, hWinThreadId, hProcess
Declare SHORT PostMessage In user32;
   INTEGER HWnd, Integer Msg, Integer wParam, Integer Lparam
   = PostMessage(hWindow, WM_SYSCOMMAND, SC_CLOSE, 0)
   = Inkey(0.1)
   If IsWindow(hWindow) = 0
      Return .T.
   Endif
   This.GetThreadProcessId (hWindow, @hWinProcId, @hWinThreadId)
   hProcess = OpenProcess(PROCESS_TERMINATE, 0, hWinProcId)
   If hProcess <> 0
      =TerminateProcess(hProcess, 0)
      =CloseHandle(hProcess)
   Endif
   Endfunc
Function GetWinText(hWindow)
   Local lnBufsize, lcBuffer
   lnBufsize = 1024
   lcBuffer = Repli(Chr(0), lnBufsize)
   lnBufsize = GetWindowText(hWindow, @lcBuffer, lnBufsize)
   Return Iif(lnBufsize=0, "", Left(lcBuffer,lnBufsize))
   Endfunc
Procedure GetThreadProcessId(hWindow, hProcId, hThreadId)
   Store 0 To hProcId, hThreadId
   hThreadId = GetWindowThreadProcessId(hWindow, @hProcId)
   Endproc
Procedure DllInit
   Declare Integer GetActiveWindow In user32
   Declare Integer GetWindow In user32 Integer HWnd, Integer wFlag
   Declare Integer IsWindow In user32 Integer HWnd
   Declare Integer IsWindowVisible In user32 Integer HWnd
   Declare Integer GetWindowTextLength In user32 Integer HWnd
   Declare Integer CloseHandle In kernel32 Integer hObject
Declare Integer GetWindowText In user32;
   INTEGER HWnd, String @lpString, Integer cch
Declare Integer GetWindowThreadProcessId In user32;
   INTEGER HWnd, Integer @lpdwProcId
Declare Integer OpenProcess In kernel32;
   INTEGER dwDesiredAccess, Integer bInheritHandle,;
   INTEGER dwProcId
Declare Integer TerminateProcess In kernel32;
   INTEGER hProcess, Integer uExitCode
   ENDPROC
   ENDDEFINE 