lcPolicyNo = INPUTBOX("Enter Policy No.", "Clear SMG Blacklist")

IF EMPTY(lcPolicyNo)
	RETURN 
ELSE 	
	UPDATE cims!members SET members.polstatus = "", ;
		members.infonote = "" ;
	WHERE members.tpacode = "SMG" ;
		AND members.policy_no = ALLTRIM(lcPolicyNo)
	IF _TALLY = 0
		UPDATE cims!members_1 SET members_1.polstatus = "", ;
			members_1.infonote = "" ;
		WHERE members_1.tpacode = "SMG" ;
			AND members_1.policy_no = ALLTRIM(lcPolicyNo)
		IF _TALLY > 0
			=MESSAGEBOX("Clear Suscess...",0)		
		ENDIF 		
	ELSE 
		=MESSAGEBOX("Clear Suscess...",0)
	ENDIF 	
ENDIF 	
