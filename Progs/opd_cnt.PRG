SET TALK OFF
SET MULTI ON
SET PATH TO \\VACHARA\HEALTHPAC\DATA
LOCAL lnCharge,;
	lnThisClaim
******************************
*OPEN DATA \healthpacapp\data\cims
IF !USED("claim")
	USE cims!claim IN 0 ORDER customer_i
ENDIF	
=CURSORSETPROP("Buffering",5,"claim")
IF !USED("claim_line")
	USE cims!claim_line IN 0 ORDER claim_id
ENDIF	
=CURSORSETPROP("Buffering",5,"claim_line")

SELECT claim
SET RELATION TO claim_id INTO claim_line
SET FILT TO claim_type = 1
GO TOP
DO WHILE !EOF("claim")
	IF claim.claim_type = 1 AND claim.type_claim = 1
		lcCustID = customer_id
		lnOpdCnt = 0
		WAIT WINDOW claim.customer_id NOWAIT
		DO WHILE claim.customer_id = lcCustID AND !EOF()
			lnOpdCnt = lnOpdCnt + 1
			WAIT WINDOW claim.customer_id+" Seq No "+STR(lnOpdCnt,2)  NOWAIT
			SELECT claim_line
			DO WHILE claim.claim_id = claim_id AND !EOF()
				REPLACE fadmis WITH lnOpdCnt
				SKIP
			ENDDO
			SELECT claim
			SKIP
		ENDDO
	ELSE
		SKIP IN claim	
	ENDIF	
ENDDO