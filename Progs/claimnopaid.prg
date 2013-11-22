LOCAL lcRetVal,;
	lcPrint

lcRetVal = oApp.DoFormretVal("getdate")
lcRetVal = oApp.DoFormRetVal("dateentry")
IF EMPTY(lcRetVal)
	RETURN
ENDIF
cFundCode = LEFT(lcRetVal,3)
lcPrint = RIGHT(lcRetVal,1)
dDate = CTOD(SUBSTR(lcRetVal,4,10))
lcEnd = CTOD(SUBSTR(lcRetVal,14,10))
USE cims!claim_nopaid IN 0
DO CASE
CASE lcPrint = "1"
	REPORT FORM report\claimnopaid TO PRINTER NOCONSOLE
CASE lcPrint = "2"
	REPORT FORM report\claimnopaid PREVIEW NOCONSOLE
CASE lcPrint = "3"
	lcFileName = "Outstanding_"+STRTRAN(SUBSTR(lcRetVal,4,10)+"_"+SUBSTR(lcRetVal,14,10), "/", "")
	EXPORT TO PUTFILE("Save To File Name:", lcFileName, "XLS") TYPE XL5
ENDCASE
USE IN claim_nopaid
		