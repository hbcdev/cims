LPARAMETERS tcFollowUp
LOCAL lClose,;
	lnArea,;
	lnVisitNo
	
lnArea = SELECT()
llUseClaim = USED("claim")
SELECT notify_no, visit_no, benf_cover, IIF(EMPTY(fax_by), sbenfpaid, fbenfpaid) AS paid ;
FROM cims!claim ;
WHERE followup = tcFollowup OR (notify_no = tcFollowUp AND visit_no = 1);
ORDER BY notify_no;
INTO CURSOR curClaimFollowUp ;
READWRITE 
**************************
IF _TALLY > 1
	SELECT curClaimFollowUp
	lnMedBal = benf_cover - paid
	lnVisitNo = 2
	SCAN
		IF visit_no = lnVisitNo
			REPLACE benf_cover WITH lnMedBal
			lnMedBal = benf_cover - paid
			lnVisitNo = lnVisitNo + 1
		ENDIF 	
	ENDSCAN
	**********************************
	IF .F.
		IF USED("claim")
			GO TOP
			SCAN
				IF SEEK(notify_no, "claim", "notify_no")
					REPLACE claim.benf_cover WITH benf_cover
				ENDIF
			ENDSCAN
		ENDIF	
	ENDIF
ENDIF
SELECT (lnArea)
*USE IN curClaimFollowup
IF !llUseClaim
	USE IN claim
ENDIF