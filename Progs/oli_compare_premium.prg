CLEAR ALL 
CLOSE ALL 
SELECT 0
USE (GETFILE("DBF", "Last month File","Open")) ALIAS old
SELECT 0
USE (GETFILE("DBF", "This month File","Open")) ALIAS new
SELECT new
IF EMPTY(CDX(1))
	INDEX ON policy_no+plan TAG policy
ENDIF 	
SET ORDER TO policy IN new
CLEAR
SELECT old
GO TOP 
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@z 9,999,999") NOWAIT 
	IF SEEK(policy_no+plan, "new","policy")
		IF old.premium # new.premium
			?policy_no+" "+plan+" "+TRANSFORM(old.premium,"@Z 99,999.99")+" "+TRANSFORM(new.premium,"@Z 99,999.99")
		ENDIF 	
	ENDIF 
ENDSCAN 		
