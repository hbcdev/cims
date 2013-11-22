*-- (c) Comway Softtech Inc. 1998
#INCLUDE "INCLUDE\CIMS.H"
LOCAL llHadError
*-- DECLARE DLL statements for reading/writing to private INI files
DECLARE INTEGER GetPrivateProfileString IN Win32API  AS GetPrivStr ;
	String cSection, String cKey, String cDefault, String @cBuffer, ;
	Integer nBufferSize, String cINIFile
DECLARE INTEGER WritePrivateProfileString IN Win32API AS WritePrivStr ;
	String cSection, String cKey, String cValue, String cINIFile
*-- DECLARE DLL statements for reading/writing to system registry
DECLARE Integer RegOpenKeyEx IN Win32API ;
	Integer nKey, String @cSubKey, Integer nReserved,;
	Integer nAccessMask, Integer @nResult
DECLARE Integer RegQueryValueEx IN Win32API ;
	Integer nKey, String cValueName, Integer nReserved,;
	Integer @nType, String @cBuffer, Integer @nBufferSize
DECLARE Integer RegCloseKey IN Win32API ;
	Integer nKey
*-- DECLARE DLL statement for Windows 3.1 API function GetProfileString
DECLARE INTEGER GetProfileString IN Win32API AS GetProStr ;
	String cSection, String cKey, String cDefault, ;
	String @cBuffer, Integer nBufferSize
***************************************************
PUBLIC gcOldDir, gcOldPath, gcOldClassLib, gcOldEscape, gcFllName, goFaxServer, gcDocScanPath, ;
	 gTHealth, gtAims, gcUserName, DataPath, gcServerName, gcProgDir, gcTemp, gcSharePath, ;
	 glUseLibs,gcImgLoc,gcIview,gcReportPath, gcQueryPath, gcNews, gcProgPath, ;
	 gnType, gnAll, gnCover, gnData, gcCaption, gnTotalIncoming, gcServerUnc, gnConn
CLEAR
*-- Ensure the project manager is closed, or we may run into
*-- conflicts when trying to KEYBOARD a hot-key
DEACTIVATE WINDOW "Project Manager"
DEACTIVATE WINDOW "Properties"

*-- All public vars will be released as soon as the application
*-- object is created.
IF SET('TALK') = 'ON'
	SET TALK OFF
	PUBLIC gcOldTalk
	gcOldTalk = 'ON'
ELSE
	PUBLIC gcOldTalk
	gcOldTalk = 'OFF'
ENDIF
*SET COVERAGE TO cims.log
****************************************
IF SYS(5) = "Y:"
	=MESSAGEBOX([คุณไม่สามารถเรียกใช้งานโปรแกรมจากไดรฟ์ "Y:" กรุณาเปลี่ยนการเรียกใช้งานโปรแกรมที่ไดรฟ์ "D:\Hips\" เท่านั้น], 0, "Warning")
ELSE 
	*******************************************	
	SET PROC TO utility.prg
	*goFaxServer = CreateObject("FaxComEx.FaxServer")
	gcOldEscape  = SET('ESCAPE')
	gcOldDir        = FULLPATH(CURDIR())
	gcOldPath     = SET('PATH')
	gcOldClassLib = SET('CLASSLIB')
	gcCaption = "Enter data for query report"
	gTHealth = .T.
	gtAims = .T.
	llHadError = .F.
	gnTotalIncoming = 0
	******************************************
	IF "WACHARAKIAT" $ ID() OR "MOBILE" $ ID() OR "DRAGON" $ ID() or "HBC-DR" $ id()
		gcProgDir = GetPath()
		gcTemp = "D:\Report"
		gcMonthlyReportPath = "D:\report"
	endif
	if empty(gcProgDir)	
		IF FILE("DataPath.txt")
			gcProgDir = FILETOSTR("DataPath.txt")		
		ELSE 
			IF FILE("\\HBCSRV01\Cims$\DataPath.txt")
				gcProgDir = FILETOSTR("\\HBCSRV01\Cims$\DataPath.txt")
			else 
				gcProgDir = "\\DRAGON-DATA\HIPS\" &&GetPath()
			ENDIF
		ENDIF 	
	ENDIF
	*
	IF !DIRECTORY(gcProgDir)
		=MESSAGEBOX("ไม่พบโฟลเดอร์จัดเก็บฐานข้อมูล "+gcProgDir+" กรุณาติดต่อ IT support", 0, "Aims Error")
		return 
	ENDIF 	
	gcTemp = "V:\"
	gcMonthlyReportPath = "M:\"	
	gcServerUnc = LEFT(gcProgDir, LEN(gcProgDir)-5)
	DataPath = gcProgDir+"DATA\"
	ImagePath = gcProgDir+"IMAGE\"
	gcProgPath = gcProgDir+"Progs\"
	gcReportPath = gcProgDir+"Report\"
	gcQueryPath = gcProgDir+"Query\"
	gcNews = gcProgDir+"News\"
	gcDocScanPath = 	gcProgDir+"Scan_Documents\"
	***********************************************
	*-- Set up the path so we can instantiate the application object
	*-- GET User name
	gcUserName = GetUserName()
	*-- GET Default Path
	*SET DEFA TO (gcProgDir)
	glUseLibs = .F.
	************************************************************************
	*-- Connect to SQL Server
	if !file("nosql.txt")
		gnConn = -1
		gnConn = getSQLConnection()
		IF gnConn < 0
			=MESSAGEBOX("ไม่สามารถติดต่อ SQL Server กรุณาแจ้ง Support เพื่อทำการแก้ไข", 0, "Error")
			RETURN 
		ENDIF 	
	endif 	
	************************************************************************
	*-- Set up the path so we can instantiate the application object
	IF SetPath(gcProgDir)
	  PUBLIC oApp
	  oApp = CREATEOBJECT("Aims")
	  IF TYPE('oApp') = "O"
	    *-- Release all public vars, since their values were
	    *-- picked up by the Environment class
	    RELEASE gcOldDir, gcOldPath, gcOldClassLib, gcOldEscape
	    oApp.Do()
	  ENDIF
	ENDIF
ENDIF 
IF gnConn > 0
	=SQLDISCONNECT(gnConn)
ENDIF 
CLOSE ALL 	
CLEAR DLLS
RELEASE ALL EXTENDED
CLEAR ALL
******************************
FUNCTION SetPath(tcProgDir)
	LOCAL lcSys16, ;
		lcProgram
	lcSys16 = SYS(16)
	lcProgram = SUBSTR(lcSys16, AT(":", lcSys16) - 1)
	CD LEFT(lcProgram, RAT("\", lcProgram))
	*-- If we are running MAIN.PRG directly, then
	*-- CD up to the parent directory
	IF RIGHT(lcProgram, 3) = "FXP"
		CD ..
	endif
	lcPath = addbs(tcProgDir)+"Data;"+addbs(tcProgDir)+"Class;"+addbs(tcProgDir)+"Form;"+;
		addbs(tcProgDir)+"Progs;"+addbs(tcProgDir)+"Include;"+addbs(tcProgDir)+"Menus;"+addbs(tcProgDir)+"Image"
	set path to (lcPath)
		
	*SET PATH TO (DATAPATH), CLASS, FORM,  PROGS, INCLUDE, MENUS, IMAGE
	SET CLASSLIB TO AIMSMAIN, HCGEN, HCBASE, LOGIN, NOTIFY 		
ENDFUNC
***********************************************
FUNCTION getSqlConnection

LOCAL lnConn AS Integer

lcFile = addbs(DataPath)+"cimsdb.txt"	
if 'WACHARAKIAT-NB' $ id()
	lcDSNLess="driver={SQL Server Native Client 11.0};server=dragon-data;Trusted_Connection=Yes;Database=CimsDB"
else
	lcDSNLess="driver={SQL Server Native Client 10.0};server=dragon-data;Trusted_Connection=Yes;Database=CimsDB"	
	if file(lcFile)
		lcDSNLess = filetostr(lcFile)
	else
		=strtofile(lcDsnLess, lcFile)	
	endif 	
endif	
lnConn = Sqlstringconnect(lcDSNLess)

IF lnConn < 1
	RETURN -1
ENDIF 

RETURN lnConn
***********************************************