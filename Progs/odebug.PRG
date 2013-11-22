LPARAMETER lcParameter, lcParameter2, lcParameter3

*** lcParameter = full OLE server string
*** "wwFoxIsapi.TRegister.ShowCustomer('User=Id1&Name=Rick','fox.ini',0)"

*** Make VFP Visible
_SCREEN.visible=.T.

*** Show what the server's path is
wait window nowait CURDIR()

set step on

SET PATH TO  c:\wwapps\foxisapi\data; c:\wwapps\foxisapi\classes; c:\wwapps\foxisapi\forms; c:\wwapps\common; c:\utilprg

set default to c:\wwapps\foxisapi

SET PROCEDURE TO FOXISAPI ADDITIVE
SET PROCEDURE TO TREGISTER ADDITIVE

lnDot2=AT(".",lcParameter,2)
lnBracket=AT("(",lcParameter)

lcParms=EXTRACT(lcParameter,"(",")")
lcClass=EXTRACT(lcParameter,".",".")
lcMethod=SUBSTR(lcParameter,lnDot2 +1, lnBracket - lnDot2 -1)

oServer=CREATE(lcClass)

*** Now eval the server string
RETURN EVAL("oServer."+lcMethod+"("+lcParms+")")

