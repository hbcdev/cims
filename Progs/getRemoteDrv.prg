*LPARAMETER tcServer, tcShareDrive, tcLocalDrive, tcPassword

*IF PARAMETER() < 4
*	RETURN
*ENDIF	

DECLARE INTEGER WNetAddConnection IN Win32API AS WNetAdd ;
     STRING @ RemoteDrive,;
     STRING @ Password,;
     STRING @ LocalDrive

DECLARE INTEGER WNetCancelConnection IN Win32API AS WNetCancel ;
     STRING @ LocalDrive,;
     INTEGER True

LOCAL lcRemote,;
	 lcPassword,;
	 lcLocal,;
	 lcPrvDrive
lcRemote = "\\HBCNT\HBCAPP"
lcPassword = ""
lcLocal = "F:"

susp
IF !EMPTY(WNetAdd(@lcRemote, @lcPassword, @lcLocal))
     Wait Window "Mapping Failed"
ELSE
     Wait Window "Mapped " + lcLocal + " to " + lcRemote
     lcPrvDrive = SYS(5)
     cd (lcLocal)
     getfile(lcLocal)
     cd (lcPrvDrive)
     If !Empty(WNetCancel(lcLocal, 1))
          Wait Window "Cancel mapping failed"
     Else
          Wait Window "Unmapped " + lcLocal
     Endif
Endif
Clear Dlls
