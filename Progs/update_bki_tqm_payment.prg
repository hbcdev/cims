USE ? IN 0 ALIAS bkipayment
SELECT bkipayment
DO WHILE !EOF()
	ldPaidDate = {}
	lnPayFreq = 0	
	lcPolicyNo = policy_no
	STORE 0 TO lnPayFreq, lnPremium	
	DO WHILE policy_no = lcPolicyNo AND !EOF()
		ldPaidDate = IIF(EMPTY(paiddate), ldPaidDate, paiddate)
		lnPayFreq = IIF(EMPTY(paiddate), lnPayFreq, period)
		SKIP 	
	ENDDO 
	*****************************************
	UPDATE cims!member SET ;
		member.lastpaid = LdPaidDate, ;
		member.pay_fr = STR(lnPayfreq,1) ;
	WHERE member.tpacode = "BKI" ;
		AND member.policy_no = lcPolicyNo	
	IF _TALLY = 0
		= STRTOFILE(lcPolicyNo+CHR(13), "BKI_ERROR.TXT", 1)
	ENDIF 	
	*****************************************	
ENDDO 	
