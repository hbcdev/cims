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
	SCATTER MEMVAR 
	UPDATE cims!member SET name = m.name, surname = m.surname, customer_id = m.customer_i ;
	WHERE tpacode = "OLI" AND policy_no = m.policy_no AND product = m.product
ENDSCAN 				


