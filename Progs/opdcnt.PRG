IF !USED("notify")
	USE cims!notify ORDER customer_i IN 0
ENDIF
SELECT notify
SET ORDER TO policy
GO TOP
DO WHILE !EOF()
	lnOpdCnt = 0
	IF EMPTY(policy_no) 
		SKIP
	ELSE	
		lcCustID = LEFT(customer_id,3)+ALLTRIM(policy_no)
		DO WHILE LEFT(customer_id,3)+ALLTRIM(policy_no) = lcCustID AND !EOF()
			IF notify_type = 1 AND treatment_type = 1
				lnOpdCnt = lnOpdCnt+1
				WAIT WINDOW LEFT(customer_id,3)+ALLTRIM(policy_no)+" OPD No. "+STR(lnOpdcnt,2) NOWAIT
				REPLACE opdcnt WITH lnOpdCnt
			ENDIF	
			SKIP
		ENDDO
	ENDIF	
ENDDO