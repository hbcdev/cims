PARAMETERS tdDate, tdPaidDate
*tdDate = adjust date
*tdPaidDate = Last paid date

IF EMPTY(tdPaidDate)
	RETURN 
ENDIF 	

IF EMPTY(tdDate)
	tdDate = DATE()
ENDIF 
	
CLOSE ALL 
USE (GETFILE("DBF", "Enter Paid File")) ALIAS paid
USE cims!member ORDER policy_no IN 0
*
CLEAR 
IF !USED("paid")
	RETURN 
ENDIF 	
*
lnRecNo = 0
SELECT paid
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	IF SEEK("OLI"+policy_no, "member", "policy_no")
		lcPolicyNo = policy_no
		lnRecNo = lnrecNo + 1
		SELECT member
		DO WHILE policy_no = lcPolicyNo AND !EOF()
			IF TTOD(adj_plan_date) # tdDate		
				REPLACE member.cause11 WITH "P", ;
					member.cause12 WITH STRTRAN(DTOC(tdPaidDate), "/", "")
			ENDIF 		
			SKIP 
		ENDDO 
		SELECT paid
	ELSE 
		=STRTOFILE(policy_no+CHR(13), "markpaid.txt", .T.)	
	ENDIF 
ENDSCAN
=MESSAGEBOX("Total Mark "+TRANSFORM(lnRecno,"@Z 9,999,999"))
 	