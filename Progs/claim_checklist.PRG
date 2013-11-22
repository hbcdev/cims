PARAMETERS tcFundCode, tdReturnDate

IF EMPTY(tcFundCode) AND EMPTY(tdReturnDate)
	RETURN 
ENDIF 

SELECT * FROM cims!claim WHERE fundcode = tcFundCode AND return_date = tdReturnDate INTO CURSOR curClaimCheck

IF _TALLY = 0
	RETURN 
ENDIF 	

lcFileError = ADDBS(gcProgDir)+"ErrorLog\"+tcFundCode + "_"+ STRTRAN(DTOC(tdReturnDate), "/", "-")+".txt"

SELECT curClaimCheck
SCAN 
	lcCheckError = ClaimCheckList()
	IF !EMPTY(lcCheckError)
		lcHead = notify_no+"   "+assessor_by+"     "+audit_by+CHR(13)+CHR(10)
		=STRTOFILE(lcHead+lcCheckError, lcFileError, 1)
	ENDIF 	
ENDSCAN 	
*
IF FILE(lcFileError)
	MODIFY FILE (lcFileError) NOEDIT 
ENDIF 	
*