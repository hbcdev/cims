CLOSE ALL 
SET MULTILOCKS ON 

USE (GETFILE("DBF", "Enter File")) ALIAS paid
USE cims!member ORDER policy_no IN 0

=CURSORSETPROP("Buffering", 5, "member")
*
IF !USED("paid")
	RETURN 
ENDIF 	
*
SELECT paid
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	IF SEEK("OLI"+policy_no, "member", "policy_no")
		lcPolicyNo = policy_no
		SELECT member
		DO WHILE policy_no = lcPolicyNo AND !EOF()
			REPLACE member.cause11 WITH paid.lastpaid, ; 
				member.cause12 with paid.paid
			SKIP 
		ENDDO 
		SELECT paid
	ELSE
		?policy_no	
	ENDIF 
ENDSCAN 	