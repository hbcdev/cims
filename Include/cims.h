*-- Common include file
#INCLUDE "FOXPRO.H"
#INCLUDE "STRINGS.H"
#INCLUDE "ADO.H"
#INCLUDE "EXCEL9.H"

#DEFINE INIFILE	 "CIMS.INI"
#DEFINE LOGFILE_LOC	 "CIMS.LOG"
#DEFINE CFGFILE "HEALTHPAC.CFG"
#DEFINE TITLE_LOC  "HBC Claim Information Management System"
#DEFINE TIMS_LOC "Health Fund and Product Assignment System"
#DEFINE PIMS_LOC "Prefer Provider Organization System"
#DEFINE CIMS_LOC "Per-Certification & Claim assessment System"
#DEFINE FIMS_LOC "Claim Payment & Billing System"
#DEFINE SIMS_LOC "HBC Administration Setup System"
#DEFINE SQLERROR_LOC = "ไม่สามารถติดต่อ SQL Server กรุณาติดต่อ Support"
#DEFINE NOTFOUND_LOC = "ไม่พบข้อมูลที่ต้องการค้นหา"

#DEFINE PROGVER "AIMS20120401"
#DEFINE VERSIONS_LOC "3.1.410"

#DEFINE DEBUGMODE	.T.
#DEFINE CRLF		CHR(13) + CHR(10)
#DEFINE CR			CHR(13)
#DEFINE TAB		CHR(9)
#DEFINE LOCALSITE .F.
#DEFINE GENNOTIFY .F.

#DEFINE CURRENCY	"฿"
#DEFINE AERRORARRAY	7
*#DEFILE DAYMINTUE 86400
*
*-- These constants are used in vsbaseform to 
*-- indicate the status of the current alias
#DEFINE FILE_OK		0
#DEFINE FILE_BOF		1
#DEFINE FILE_EOF		2
#DEFINE FILE_CANCEL	3

*-- Constants to identify which trigger failed
*-- using element 5 of the array returned by 
*-- AERROR(), as well as to reference the appropriate
*-- array element in the error message array: aErrorMsg[]
#DEFINE INSERTTRIG  1
#DEFINE UPDATETRIG  2
#DEFINE DELETETRIG  3

*-- Constants used to read the system registry
#DEFINE HKEY_LOCAL_MACHINE				-2147483646  
#DEFINE KEY_SHARED_TOOLS_LOCATION	"Software\Microsoft\Shared Tools Location"
#DEFINE KEY_NTCURRENTVERSION			"Software\Microsoft\Windows NT\CurrentVersion"
#DEFINE KEY_WIN4CURRENTVERSION		"Software\Microsoft\Windows\CurrentVersion"
#DEFINE KEY_WIN4_MSINFO					"Software\Microsoft\Shared Tools\MSInfo"
#DEFINE KEY_QUERY_VALUE					1
#DEFINE ERROR_SUCCESS					0

#DEFINE ADMINBAR_LOC "Administration"
#DEFINE ALL_LOC "All"

#DEFINE USER_APPDEV_LOC "APPLICATIONS DEVELOPER"
#DEFINE USER_OPSMGR_LOC "OPERATIONS MANAGER"

#DEFINE DOLLAR_FORMAT1_LOC ": $"
#DEFINE DOLLAR_FORMAT2_LOC ""
#DEFINE DOLLAR_FORMAT3_LOC "$"
#DEFINE SEEKVALUE_LOC	"*Case Study"

#DEFINE SYS2011_EXCLUSIVE_LOC 	"EXCLUSIVE"
#DEFINE SYS2011_RECLOCK_LOC 	"RECORD LOCKED"
#DEFINE SYS2011_RECUNLOCK_LOC 	"RECORD UNLOCKED"

#DEFINE	I_SHPMIN	111			&& how far left can the Behind the Scenes splitter go?
#DEFINE I_SHPMAX	303			&& how far right can the Behind the Scenes splitter go?