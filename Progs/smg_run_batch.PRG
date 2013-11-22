IF !USED("claim")
	USE cims!claim IN 0
ENDIF 	
*
lcOldDir = SYS(5)+SYS(2003)
lnDay = IIF(DAY(DATE()) > 15, 1, 16)
*
gcFundCode = "SMG"
gdEndDate = DATE() 
gdStartDate = gdEndDate - 5 
gnOption = 1
gdSendDate = DATE()
gdPayDate = gdSendDate + (11 + holidays(gdSendDate, gdSendDate+10))
gcSaveTo = ""
DO FORM form\SMG_Return_Data
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate) AND EMPTY(gnOption)
	RETURN 
ENDIF
*
m.paydate = gdPayDate
*
DO CASE 
CASE gnOption = 1  && Credit
	m.lotno = "C_" + STRTRAN(STR(DAY(gdPayDate), 2), " ", "0") + STRTRAN(STR(MONTH(gdPayDate), 2), " ", "0") + STRTRAN(STR(YEAR(gdPayDate), 4), " ", "0")
	*
	SELECT pv.pv_no, pv.pv_date, pv.tr_date, LEFT(pv_notify.notify_no, 10) AS notify_no, ;
		pv_notify.prov_id, pv_notify.prov_name ;
	FROM cims!pv INNER JOIN cims!pv_notify ;
		ON pv.pv_no = pv_notify.pv_no ;
	WHERE pv.fundcode = gcFundCode ;
		AND pv.send_to = 4 ;
		AND !EMPTY(pv_notify.notify_no) ;
		AND pv.pv_date BETWEEN gdStartDate AND gdEndDate ;	
	ORDER BY pv.pv_no ;
	INTO CURSOR curPv
	IF _TALLY = 0
		RETURN 
	ENDIF 	
	SELECT curPV
	DO WHILE !EOF()
		lcProvID = prov_id
		lcBatchNo = "C"+SUBSTR(newdateno("C", gdSendDate), 3)
		DO WHILE prov_id = lcProvID AND !EOF()
			WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
			IF SEEK(notify_no, "claim", "notify_no")
				REPLACE claim.batchno WITH lcBatchNo, claim.lotno WITH m.lotno, claim.paid_date WITH curPv.tr_date, ;
					claim.insurepaydate WITH m.paydate, claim.paytoac WITH "0652469561"
			ENDIF 
			SKIP 
		ENDDO 	
	ENDDO 
CASE gnOption = 2  && Reimb
	m.lotno = "R_" + STRTRAN(STR(DAY(gdPayDate), 2), " ", "0") + STRTRAN(STR(MONTH(gdPayDate), 2), " ", "0") + STRTRAN(STR(YEAR(gdPayDate), 4), " ", "0")
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
USE IN curPv
