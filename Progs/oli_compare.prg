CLOSE ALL 
SET EXCLUSIVE ON
SELECT 0
USE (GETFILE("DBF", "Last month File","Open")) ALIAS old
SELECT 0
USE (GETFILE("DBF", "This month File","Open")) ALIAS new
SELECT new
IF EMPTY(CDX(1))
	INDEX ON policy_no TAG policy_no
ENDIF 	
SET ORDER TO policy_no IN new
CLEAR
SELECT old
GO TOP 
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@z 999,999") NOWAIT 
	IF SEEK(policy_no, "new","policy_no")
		lcPol = policy_no
		SELECT new
		DO WHILE lcPol = policy_no AND !EOF()
			DELETE
			SKIP 
		ENDDO 
		SELECT old 	
	ELSE 
		DELETE
	ENDIF 
ENDSCAN 		
SET EXCLUSIVE OFF 