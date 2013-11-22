PARAMETERS tcFundCode
DO CASE 
CASE tcFundCode = "KTA"
	SELECT policy_no, product, effective, expiry, tpacode ;
	FROM cims!member ;
	GROUP BY 1 ;
	WHERE tpacode = tcFundCode ;
		AND INLIST(product, "HS10-S1", "HS16-S1", "HS22-S1") ;
	INTO CURSOR curStaffPol
	SELECT curStaffPol
	SCAN 
		WAIT WINDOW policy_no NOWAIT 
		DO KTA WITH tpacode, policy_no
	ENDSCAN 	
ENDCASE 
************************************
PROCEDURE kta 	
PARAMETERS tcFundCode, tcPolicyNo
*
SELECT policy_no, product, effective, expiry ;
FROM cims!member ;
WHERE tpacode = tcFundCode ;
	AND policy_no = tcPolicyNo ;
INTO CURSOR curLastPol
IF _TALLY > 1
	?policy_no

	GO BOTTOM 
	ldLastEff = effective  && Effective of last policy
	********************
	GO TOP 
	ldEffDate = effective && Effective Start policy
	IF SEEK(tcFundCode+policy_no+product, "member", "pol_plan")
		REPLACE member.expiry WITH ldLasteff
	ENDIF 	
	SKIP 
	***************************************
	DO WHILE !EOF()
		IF SEEK(tcFundCode+policy_no+product, "member", "pol_plan")	
			REPLACE member.expiry WITH DATETIME(YEAR(ldEffDate)+1, MONTH(ldEffDate), DAY(ldEffDate), 00, 00)
		ENDIF 	
		SKIP 
	ENDDO  	
ENDIF 
USE IN curLastPol		
