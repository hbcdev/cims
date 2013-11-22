PARAMETERS tdReturnDate, tcLotNo, tnBatch, tcBatch

IF EMPTY(tdReturnDate) AND EMPTY(tcLotNo) AND EMPTY(tnBatch) AND EMPTY(tcBatch)
	RETURN 
ENDIF 	

CLOSE ALL 
lcOldDir = SYS(5)+SYS(2003)
*
gcFundCode = "SMG"
gdEndDate = tdReturnDate
gdStartDate = tdReturnDate
gnOption = 1
gnBatchNo = tnBatch
gcBatchNo  = tcBatch
gcLotNo = tcLotNo
gdPayDate = CTOD(STRTRAN(SUBSTR(tcLotNo, 3, 8), "-", "/"))
gcSaveTo = "D:\report\"

IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate) AND EMPTY(gnOption)
	RETURN 
ENDIF

DO CASE 
CASE gnOption = 1  && Credit
	m.lotno = "C_" + STRTRAN(STR(DAY(gdPayDate), 2), " ", "0") + "-" + STRTRAN(STR(MONTH(gdPayDate), 2), " ", "0") + "-"+ RIGHT(STR(YEAR(gdPayDate), 4), 2)
	*
	SELECT claim.notify_no, claim.policy_no, claim.prov_id, claim.prov_name, firstchr(claim.prov_name) AS "first" ;
	FROM cims!claim ;
	WHERE claim.fundcode = gcFundCode ;
		AND INLIST(claim.result, "P62", "A11") ;
		AND claim.return_date BETWEEN gdStartDate AND gdEndDate ;
	ORDER BY 5, claim.prov_name, claim.notify_no ;
	INTO CURSOR curClaim		
	IF _TALLY = 0
		RETURN 
	ENDIF 	
	SELECT curClaim
	DO WHILE !EOF()
		lcProvID = prov_id
		gnBatchNo = gnBatchNo + 1
		lcBatchNo = gcBatchNo + STRTRAN(STR(gnBatchNo,4), " ", "0")
		DO WHILE prov_id = lcProvID AND !EOF()
			WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
			IF SEEK(notify_no, "claim", "notify_no")
				REPLACE claim.batchno WITH lcBatchNo, claim.lotno WITH m.lotno, ;
					claim.insurepaydate WITH gdPayDate, claim.paytoac WITH "0652469561"
			ENDIF 
			SKIP 
		ENDDO 	
	ENDDO 
CASE gnOption = 2  && Reimb
	m.lotno = "R_" + STRTRAN(STR(DAY(gdPayDate), 2), " ", "0") + "-" + STRTRAN(STR(MONTH(gdPayDate), 2), " ", "0") + "-"+ RIGHT(STR(YEAR(gdPayDate), 4),2)
	*
	SELECT pv.pv_no, pv.pv_date, pv.tr_date, LEFT(pv_notify.notify_no, 10) AS notify_no, pv_notify.prov_name ;
	FROM cims!pv INNER JOIN cims!pv_notify ;
		ON pv.pv_no = pv_notify.pv_no ;
	WHERE pv.fundcode = gcFundCode ;
		AND pv.send_to = 3 ;
		AND !EMPTY(pv_notify.notify_no) ;
		AND !EMPTY(pv.tr_date) ;
		AND pv.pv_date BETWEEN gdStartDate AND gdEndDate ;	
	ORDER BY pv.tr_date, pv.pv_no ;
	INTO CURSOR curPv
	IF _TALLY = 0
		RETURN 
	ENDIF 	
	SELECT curPV
	DO WHILE !EOF()
		ldTrDate = tr_date
		lcBatchNo = "R"+SUBSTR(newdateno("R", gdSendDate), 3)
		DO WHILE tr_date = ldTrDate AND !EOF()
			WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
			IF SEEK(notify_no, "claim", "notify_no")
				REPLACE claim.batchno WITH lcBatchNo, claim.lotno WITH m.lotno, claim.paid_date WITH curPv.tr_date, ;
					claim.insurepaydate WITH m.paydate, claim.paytoac WITH "0652469561"
			ELSE 
				?notify_no		
			ENDIF 
			SKIP 
		ENDDO 	
	ENDDO 
ENDCASE 
*
