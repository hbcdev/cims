*-- (c) Comway Softtech Inc. 1998
#INCLUDE "INCLUDE\MISC.H"

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
*--
Clear
*-- Ensure the project manager is closed, or we may run into
*-- conflicts when trying to KEYBOARD a hot-key
Deactivate WINDOW "Project Manager"

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
PUBLIC gcOldDir, gcOldPath, gcOldClassLib, gcOldEscape, gTHealth,gcUserName,DataPath
gcOldEscape   = SET('ESCAPE')
gcOldDir      = FULLPATH(CURDIR())
gcOldPath     = SET('PATH')
gcOldClassLib = SET('CLASSLIB')
gTHealth = .T.
*-- Set up the path so we can instantiate the application object
SET PATH TO PROGS ,FORM ,CLASS ,MENUS ,DATA ,INCLUDE
SET CLASSLIB TO MISC,WIZBASE,WIZBTNS,WIZEMBSS
SET PROC TO utility.prg
*--
gcUserName = GetUserName()
DataPath = GetPath()
SET DEFA TO (DataPath)
DataPath = DataPath+"DATA\"

DO path WITH DataPath
WAIT WINDOW "Database On " + DataPath NOWAIT

IF EMPTY(DataPath)
	QUIT	
ENDIF	