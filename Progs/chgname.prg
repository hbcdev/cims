lcOldCard = INPUTBOX("Enter Old Card No.", "Change SMG Debit Card No")
lcNewCard = INPUTBOX("Enter New Card No.","Change SMG Debit Card No")

IF EMPTY(lcOldCard) AND EMPTY(lcNewCard)
	RETURN 
ELSE 	
	lnSelect = SELECT()
	? " Update new card to Claim Table"
	UPDATE cims!claim ;
	SET claim.policy_no = lcNewCard, ;
		claim.cardno = lcNewCard ;
	WHERE claim.fundcode = "SMG" ;
	AND claim.policy_no = lcOldCard  
	*
	? " Update new card to Percert Table"
	UPDATE cims!notify ;
	SET notify.policy_no = lcNewCard, ;
		notify.cardno = lcNewCard ;
	WHERE notify.fundcode = "SMG" ;
	AND notify.policy_no = lcOldCard  
	*
	? " Update new card to Logbook Table"
	UPDATE cims!notify_log ;
	SET notify_log.policy_no = lcNewCard, ;
		notify_log.cardno = lcNewCard ;
	WHERE notify_log.fundcode = "SMG" ;
	AND notify_log.policy_no = lcOldCard  
	*	
	? " Update new card to Disability Table"
	UPDATE cims!notify_period ;
	SET notify_period.policy_no = lcNewCard ;
	WHERE notify_period.fundcode = "SMG" ;
	AND notify_period.policy_no = lcOldCard  
ENDIF 	
SELECT (lnSelect)
