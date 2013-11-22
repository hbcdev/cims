LPARAMETER tcCustID
IF PARAMETER() < 1
	RETURN
ENDIF
SELECT Claim.customer_id, Claim.notify_no, Claim.notify_date,;
  Claim.claim_type, Claim.illness1, Claim_line.cat_code, Claim_line.fadmis,;
  Claim_line.fcharge, Claim_line.fpaid, Claim_line.fremain;
 FROM  cims!claim INNER JOIN cims!claim_line ;
   ON  Claim.claim_id = Claim_line.claim_id;
 WHERE Claim.customer_id = tcCustID;
   AND Claim.type_claim = 1;
   AND Claim.claim_type = 1;
	INTO CURSOR cOPD
SELECT cOPD
BROW	