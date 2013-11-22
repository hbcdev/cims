DEFINE CLASS HipsTools AS Custom OLEPUBLIC

cAppStartPath = ""
lError = .F.
cErrorMsg = ""
*******************************
* Init
*******************************
FUNCTION Init

SET RESOURCE OFF
SET EXCLUSIVE OFF
SET CPDIALOG OFF
SET DELETED ON
SET EXACT OFF
SET SAFETY OFF
SET DATE TO DMY
SET HOUR TO 24
SET REPROCESS TO 2 SECONDS
*
*** Force server into unattended mode - any dialog will cause an error with error message
=SYS(2335,0)

*** Utility routines like Get AppstartPath etc.
SET PROCEDURE TO wwUtils ADDITIVE

This.cAppStartPath TO ADDBS(JustPath(Application.ServerName))

**** Important : We need to get at our data
SET PATH TO (This.cAppStartPath)
DO PATH WITH "DATA"

ENDFUNC
*******************************
* GetClientInfo
*******************************
