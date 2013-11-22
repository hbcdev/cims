PARAMETERS ttDate

CLOSE ALL 
SET MULTILOCKS ON 
SET DELETED ON 
USE ? IN 0 ALIAS adj
USE cims!member IN 0 ORDER policy
=CURSORSETPROP("Buffering", 5, "member")

SELECT adj
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 99,999") NOWAIT 
	IF SEEK(policy_no, "member")
		SELECT member	
		IF cause11 = "P"
			SCATTER MEMO MEMVAR 
			m.cause11 = ""
			m.cause12 = ""
			m.l_update = ttDate
			REPLACE status WITH "C", adj_plan_date WITH ttDate, customer_id WITH adj.customer_i
			INSERT INTO cims!member FROM MEMVAR 
		ELSE
			REPLACE member.effective WITH adj.effective, member.expiry WITH adj.expirty, ;
				member.customer_id WITH adj.customer_i
		ENDIF 
	ENDIF 
	SELECT adj 
ENDSCAN 				


