CLOSE ALL 
SELECT 0 
USE ?  ALIAS cust
OPEN DATABASE \\hbcnt\hips\data\cims.DBC
USE member IN 0 ORDER policy

SELECT cust
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999") NOWAIT 
	IF SEEK(policy_no, "member")
		? policy_no
		REPLACE member.customer_id WITH customer_i
	ENDIF 	
ENDSCAN 
USE IN cust	