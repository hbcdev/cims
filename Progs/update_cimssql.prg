SET DELETED ON 
CLOSE ALL 
CLEAR 

USE cimssql!vw_member IN 0 ALIAS memberSQL NODATA 
USE cims!members IN 0



SELECT members
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 9,999,999") NOWAIT 
	SCATTER MEMO MEMVAR
	*********************
	SELECT memberSQL
	APPEND BLANK 
	GATHER MEMVAR MEMO 
	*********************
	SELECT members
ENDSCAN 	






PROCEDURE oldsql

SELECT members
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 9,999,999") NOWAIT 
	SCATTER MEMO MEMVAR
	***********************
	cTpacode = m.tpacode
	cPolicyNo = m.policy_no
	cPlan = m.product
	IF REQUERY("memberSql") = 1
		IF RECCOUNT("memberSql") = 0
			WAIT WINDOW m.policy_no AT 12, 25 NOWAIT			 
			INSERT INTO cimssql!vw_member FROM MEMVAR
		ENDIF 	
	ENDIF 
	******************
	SELECT members
ENDSCAN 	
	

