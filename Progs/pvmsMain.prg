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
CLEAR
*-- Ensure the project manager is closed, or we may run into
*-- conflicts when trying to KEYBOARD a hot-key
DEACTIVATE WINDOW "Project Manager"
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
********************
PUBLIC gcOldDir, gcOldPath, gcOldClassLib, gcOldEscape, gTHealth, gcUserName, DataPath, gcServerName
gcOldEscape  = SET('ESCAPE')
gcOldDir        = FULLPATH(CURDIR())
gcOldPath     = SET('PATH')
gcOldClassLib = SET('CLASSLIB')
gTHealth = .T.
llHadError = .F.
*-- Set up the path so we can instantiate the application object
SET PATH TO PROGS ,FORM ,CLASS ,MENUS ,INCLUDE
SET CLASSLIB TO HCBASE,NOTIFY
SET PROC TO utility.prg

*-- GET User name
gcUserName = GetUserName()
*-- GET Default Path
DataPath = GetPath()
DataPath = DataPath+"DATA\"

IF EMPTY(DataPath)
	=MESSAGEBOX("Cannot find Database directory. Please contact your administrator for this probelm.",MB_ICONINFORMATION+MB_OK,TITLE_LOC)
	Quit	
ENDIF
*
SET PATH TO (DataPath)
WAIT WINDOW "Database On " + DataPath NOWAIT