PARAMETERS ttDate
CLOSE ALL 

SET MULTILOCKS ON 
SELECT 0 
USE ?  ALIAS void

OPEN DATABASE cims
USE member IN 0 ORDER policy
*=CURSORSETPROP("Buffering",5,"member")

IF EMPTY(ttDate)
	ttDate = DATETIME()
ENDIF 		


SELECT void
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999") NOWAIT 
	lcPol = "OLI"+policy_no+ALLTRIM(product)
	IF SEEK(lcPol, "member", "pol_plan")
		? policy_no+" "+product
		REPLACE member.status WITH void.Status, ;
			member.expiry WITH IIF(member.expiry > void.expirty, void.expirty, member.expiry), ;
			member.adj_plan_date WITH ttDate
		?? "     "+member.status	
	ENDIF 	
ENDSCAN 	

