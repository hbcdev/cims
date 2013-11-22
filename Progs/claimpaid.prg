LOCAL lcRetVal,;
	lcPrint

lcRetVal = oApp.DoFormretVal("getdate")

*set class to class\notify
*o = creat("getdate")
*o.show
*cRetVal = o.uretval
IF !EMPTY(lcRetVal)
	cFundCode = LEFT(lcretVal,3)
	nMonth = VAL(SUBSTR(lcRetVal,7,2))
	lcPrint = RIGHT(lcRetVal,1)
	USE cims!claim_paid IN 0
	DO CASE
	CASE lcPrint = "1"
		REPORT FORM report\claimpaid TO PRINTER NOCONSOLE
	CASE lcPrint = "2"
		REPORT FORM report\claimpaid PREVIEW NOCONSOLE
	ENDCASE
	USE IN claim_paid
ENDIF		
		