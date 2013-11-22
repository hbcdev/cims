#INCLUDE "INCLUDE\cims.h"
PUBLIC gcFundCode, gdStartDate, gdEndDate, ;
	gnOption, gcSaveTo

STORE DATE() TO gdStartDate, gdEndDate
gcFundCode = ""
gnOption = 3
gcSaveTo = ADDBS(gcTemp)
DO FORM FORM\dateentry1
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	=MESSAGEBOX("กรุณาเลือก บริษัทประกันภัยที่ต้องการให้จัดทำรายงานประจำวันด้วย ", MB_OK,"Dialy Report")
	RETURN
ENDIF
ltStartDate = DATETIME(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate), 00, 00)
ltEndDate = DATETIME(YEAR(gdEndDate), MONTH(gdEndDate), DAY(gdEndDate), 23, 59)
**************************************
IF !USED("icd10")
	USE cims!icd10 IN 0
	llIcd10 = .T.
ENDIF
IF !USED("disease")
	USE (DataPath+"disease") IN 0
	llDisease = .T.
ENDIF
**************************************
DIMENSION laComment[7,1], laTitle[43], laClaim[34], laFormat[43], laType[3,2]

laType[1,1] = "P"
laType[1,2] = "PA"
laType[2,1] = "I"
laType[2,2] = "HC"
laType[3,1] = "T"
laType[3,2] = "Group"
**************************************
laComment[1] = "Patient benefit for admission"
laComment[2] = "Policy expired"
laComment[3] = "Non health rider"
laComment[4] = "Exclusion"
laComment[5] = "Reimbursement"
laComment[6] = "Unnessessary admit."
laComment[7] = "Other"
*********************************
laTitle[1] = "Notify No"
laTitle[2] = "Notify Date"
laTitle[3] = "Type"
laTitle[4] = "สาเหตุ"
laTitle[5] = "กรมธรรม์"
laTitle[6] = "บริษัท"
laTitle[7] = "เลขที่สมาชิก"
laTitle[8] = "แผน"
laTitle[9] = "ชื่อผู้เอาประกัน"
laTitle[10] = "เริ่มคุ้มครอง"
laTitle[11] = "สิ้นสุด"
laTitle[12] = "เลขที่เคลม/โรค"
laTitle[13] = "ครั้งที่เคลม/โรค"
laTitle[14] = "อาการที่เข้ารักษา"
laTitle[15] = "วันเกิดเหตุ"
laTitle[16] = "โรงพยาบาล"
laTitle[17] = "วันที่เข้ารักษา"
laTitle[18] = "วันที่ออกจาก รพ."
laTitle[19] = "ICD 10 #1"
laTitle[20] = "ICD 10 #2"
laTitle[21] = "ICD 10 #3"
laTitle[22] = "รายการ"
laTitle[23] = "จำนวนวัน"
laTitle[24] = "จำนวนเงินร้องขอ"
laTitle[25] = "ส่วนลด"
laTitle[26] = "จำนวนที่เคลมได้"
laTitle[27] = "ส่วนเกิน"
laTitle[28] = "ไม่คุ้มครอง"
laTitle[29] = "อนุโลมจ่าย"
laTitle[30] = "ค่าธรรมเนียมผ่าตัด %"
laTitle[31] = "สถานะ"
laTitle[32] = "หมายเหตุ"
laTitle[33] = "Thai Disease 1"
laTitle[34] = "Thai Disease 2"
laTitle[35] = "Thai Disease 3"
laTitle[36] = "Disease 1"
laTitle[37] = "Disease 2"
laTitle[38] = "Disease 3"
laTitle[39] = "วันที่รับเคลม"
laTitle[40] = "วันทีส่งเคลมกลับ"
laTitle[41] = "ค่าชดเชยฯ"
laTitle[42] = "ยอดรวมค่าชดเชย"
laTitle[43] = "ค่าชดเชยจ่าย"
****************************************
laClaim[1] = "Notify_No"
laClaim[2] = "Notify_Date"
laClaim[3] = "service_type"
laClaim[4] = "cause_type"
laClaim[5] = "policy_no"
laClaim[6] = "policy_holder"
laClaim[7] = "family_no"
laClaim[8] = "plan"
laClaim[9] = "client_name"
laClaim[10] = "effective"
laClaim[11] = "expried"
laClaim[12] = "ds_no"
laClaim[13] = "claimitem"
laClaim[14] = "indication_admit"
laClaim[15] = "acc_date"
laClaim[16] = "prov_name"
laClaim[17] = "admis_date"
laClaim[18] = "disc_date"
laClaim[19] = "illness1"
laClaim[20] = "illness2"
laClaim[21] = "illness3"
laClaim[22] = "description"
laClaim[23] = "admit"
laClaim[24] = "charge"
laClaim[25] = "discount"
laClaim[26] = "paid"
laClaim[27] = "overpaid"
laClaim[28] = "nopaid"
laClaim[29] = "exgratia"
laClaim[30] = "fee"
laClaim[31] = "result"
laClaim[32] = "note2ins"
laClaim[33] = "ref_date"
laClaim[34] = "return_date"
****************************************
laFormat[1] = "@"
laFormat[2] = "dd-mm-yyyy"
laFormat[3] = "@"
laFormat[4] = "@"
laFormat[5] = "@"
laFormat[6] = "@"
laFormat[7] = "0000"
laFormat[8] = "@"
laFormat[9] = "@"
laFormat[10] = "dd-mm-yyyy"
laFormat[11] = "dd-mm-yyyy"
laFormat[12] = "0000"
laFormat[13] = "0000"
laFormat[14] = "@"
laFormat[15] = "dd-mm-yyyy"
laFormat[16] = "@"
laFormat[17] = "dd-mm-yyyy"
laFormat[18] = "dd-mm-yyyy"
laFormat[19] = "@"
laFormat[20] = "@"
laFormat[21] = "@"
laFormat[22] = "@"
laFormat[23] = "#,##0"
laFormat[24] = "#,##0.00"
laFormat[25] = "#,##0.00"
laFormat[26] = "#,##0.00"
laFormat[27] = "#,##0.00"
laFormat[28] = "#,##0.00"
laFormat[29] = "#,##0.00"
laFormat[30] = "#,##0.00"
laFormat[31] = "@"
laFormat[32] = "@"
laFormat[33] = "@"
laFormat[34] = "@"
laFormat[35] = "@"
laFormat[36] = "@"
laFormat[37] = "@"
laFormat[38] = "@"
laFormat[39] = "dd-mm-yyyy"
laFormat[40] = "dd-mm-yyyy"
laFormat[41] = "#,##0.00"
laFormat[42] = "#,##0.00"
laFormat[43] = "#,##0.00"
****************************************
* Precert Report
SELECT Notify_log.notify_no, Notify_log.summit, Notify_log.claim_no, ;
	Notify_log.policy_no, Notify_log.family_no,  Notify_log.client_name, ;
	Notify_log.plan, Notify_log.effective, Notify_log.expried, Notify_log.acc_date, ;
	Notify_log.prov_name, Notify_log.admis_date, Notify_log.indication_admit, ;
	Notify_log.STATUS, Notify_log.result, ;
	IIF(Notify_log.customer_type = "A", "P", Notify_log.customer_type) AS customer_type ;
	FROM  cims!Notify_log ;
	WHERE Notify_log.fundcode = gcFundCode;
	AND Notify_log.summit BETWEEN gdStartDate AND gdEndDate ;
	AND !EMPTY(Notify_log.result) ;
	ORDER BY Notify_log.customer_type ;
	INTO CURSOR curLog
***********************************************************
* Precert Report
SELECT NOTIFY.notify_no, NOTIFY.notify_date, ;
	NOTIFY.service_type AS TYPE, NOTIFY.policy_no, NOTIFY.policy_name, ;
	NOTIFY.client_name, NOTIFY.plan, NOTIFY.effective, NOTIFY.expried, NOTIFY.acc_date, ;
	NOTIFY.prov_name, NOTIFY.admis_date, NOTIFY.basic_diag, NOTIFY.COMMENT, ;
	NOTIFY.note2ins, NOTIFY.STATUS, ;
	IIF(Notify.notify_with = "A", "P", Notify.notify_with) AS notify_with ;
	FROM  cims!NOTIFY ;
	WHERE NOTIFY.fundcode = gcFundCode;
	AND NOTIFY.notify_date BETWEEN ltStartDate AND ltEndDate ;
	ORDER BY notify_with ;
	INTO CURSOR curPercert
***********************************************************
*Query Claim
SELECT IIF(Claim.result = "P5", "I", IIF(Claim.result = "W5", "F", IIF(Claim.result = "W6", "U", LEFT(Claim.result,1)))) AS clm_status, ;
	IIF(Claim.claim_with = "A",  "P", Claim.claim_with) AS claim_with, ;
	Claim.notify_no, Claim.notify_date, Claim.service_type, Claim.cause_type, ;
	Claim.policy_no, Claim.policy_holder, Claim.family_no, Claim.plan, Claim.client_name, Claim.effective, Claim.expried, ;
	Claim.visit AS ds_no, Claim.visit_no AS claimitem, Claim.indication_admit, Claim.diag_plan, Claim.acc_date, ;
	Claim.prov_name, Claim.admis_date, Claim.disc_date, Claim.illness1, Claim.illness2, Claim.illness3, ;
	Claim_line.cat_code, Claim_line.description, IIF(Claim.result = "W5", Claim_line.fadmis, Claim_line.sadmis) AS admit, ;
	IIF(Claim.result = "W5", Claim_line.fcharge, Claim_line.scharge) AS charge, ;
	IIF(Claim.result = "W5", Claim_line.fdiscount, Claim_line.sdiscount) AS discount, ;
	IIF(Claim.result = "W5", Claim_line.fpaid+Claim_line.deduc, Claim_line.spaid+Claim_line.dpaid) AS paid, ;
	IIF(Claim.result = "W5", Claim_line.fremain, Claim_line.sremain) AS overpaid, ;
	IIF(Claim.result = "W5", Claim_line.exgratia, Claim_line.apaid) AS exgratia, ;
	IIF(Claim.result = "W5", Claim_line.nopaid, Claim_line.snoncover) AS nopaid, ;
	Claim_line.total_fee AS fee, Claim.hb_cover, Claim.hb_act, Claim.hb_app, ;
	Claim.result, Claim.snote, Claim.note2ins, Claim.ref_date, Claim.return_date ;
	FROM  cims!Claim INNER JOIN cims!Claim_line ;
	ON Claim.notify_no = Claim_line.notify_no ;
	WHERE Claim.fundcode = gcFundCode ;
	HAVING Claim.fundcode = gcFundCode ;
		AND (Claim.fax_date BETWEEN ltStartDate AND ltEndDate ;
		OR Claim.return_date BETWEEN gdStartDate AND gdEndDate ;
		OR (Claim.audit_date BETWEEN ltStartDate AND ltEndDate AND result = "W")) ;
	ORDER BY 2, 1 ;
	INTO CURSOR curClaim
************************************
lcType = "P"
DO WHILE !EMPTY(lcType)
	lnSheet = 0
	oExcel = CREATEOBJECT("Excel.Application")
	oWorkBook = oExcel.Workbooks.ADD()
	****
	DO Log2Xls
	****
	DO Percert2Xls
	****
	DO Claim2Xls
	***************
	gcSaveTo = ALLTRIM(gcSaveTo)
	IF !DIRECTORY(gcSaveTo)
		MD &gcSaveTo
	ENDIF
	***************
	DO CASE 
	CASE lcType = "P"
		lcTypeMess = "PA"
	CASE lcType = "I"
		lcTypeMess = "HC"
	CASE lcType = "T"
		lcTypeMess = "Group"
	CASE lcType = "S"
		lcTypeMess = "PAS"		
	ENDCASE
	lcExcelFile = ADDBS(gcSaveTo)+lcTypeMess+"_Dialy_Report_"+STRTRAN(DTOC(gdStartDate), "/", "")+"_"+STRTRAN(DTOC(gdEndDate), "/", "")
	oWorkBook.SAVEAS(lcExcelFile)
	oExcel.QUIT
	***
	IF lcType = "P"
		lcType = "T"
	ELSE 
		IF lcType = "T"
			lcType = "I"
		ELSE 
			IF lcType = "I"
				lcType = "S"
			ELSE 	
				lcType = ""
			ENDIF 	
		ENDIF 
	ENDIF 				
ENDDO
USE IN nstatus
USE IN curLog
USE IN curPercert
USE IN curClaim
=MESSAGEBOX("โอนข้อมูลเข้าไปที่ excel เรียบร้อยแล้ว จัดเก็บอยู่ที่ "+gcSaveTo,0,TITLE_LOC)
*********************
PROCEDURE Log2Xls
*********************
IF !USED("curLog")
	RETURN
ENDIF
**************************
SELECT * ;
	FROM cims!notify_pending ;
	WHERE TYPE = 2 ;
	INTO CURSOR nstatus
************************
lnRow = 1
oSheet = oWorkBook.WorkSheets.ADD
oSheet.NAME = "InCompleate"
SELECT curLog
SET FILTER TO customer_type = lcType
GO TOP
***********
DO SETFORMAT
***********
?IIF(lcType = "P", "PA", IIF(lcType = "T", "Group", "HC"))+" Data Transfer Logbook to Excel"
oSheet.Cells(lnRow,FCOUNT()+1) = "Status Text"
lnRow = 2
DO WHILE !EOF()
	WAIT WINDOW notify_no NOWAIT
	FOR i = 1 TO FCOUNT()
		lcField = FIELD(i)
		lcValue = &lcField
		IF !EMPTY(lcValue)
			oSheet.Cells(lnRow,i) = IIF(TYPE("lcValue") = "T", TTOD(lcValue), lcValue)
		ENDIF
	ENDFOR
	SELECT nstatus
	LOCATE FOR curPercert.STATUS = pending_code
	IF FOUND()
		oSheet.Cells(lnRow,i) = nstatus.DESCRIPTION
	ENDIF
	lnRow = lnRow + 1
	SELECT curLog
	SKIP
ENDDO

************************
PROCEDURE Percert2Xls
************************
SELECT * ;
	FROM cims!notify_pending ;
	WHERE TYPE = 1 ;
	INTO CURSOR nstatus
************************
?IIF(lcType = "P", "PA", IIF(lcType = "T", "Group", "HC"))+" Data Transfer Percert to Excel"
lnRow = 1
oSheet = oWorkBook.WorkSheets.ADD
oSheet.NAME = "Percertification"
SELECT curPercert
SET FILTER TO notify_with = lcType
GO TOP
***********
DO SETFORMAT
***********
oSheet.Cells(lnRow,FCOUNT()+1) = "Status Text"
lnRow = 2
DO WHILE !EOF()
	WAIT WINDOW notify_no NOWAIT
	FOR i = 1 TO FCOUNT()
		lcField = FIELD(i)
		lcValue = &lcField
		IF !EMPTY(lcValue)
			oSheet.Cells(lnRow,i) = IIF(TYPE("lcValue") = "T", TTOD(lcValue), lcValue)
		ENDIF
	ENDFOR
	SELECT nstatus
	LOCATE FOR curPercert.STATUS = pending_code
	IF FOUND()
		oSheet.Cells(lnRow,i) = nstatus.DESCRIPTION
	ENDIF
	lnRow = lnRow + 1
	SELECT curPercert
	SKIP
ENDDO
*****************************************************
PROCEDURE Claim2Xls

?IIF(lcType = "P", "PA", IIF(lcType = "T", "Group", "HC"))+" Data Transfer Claim to Excel"
SELECT curClaim
SET FILTER TO claim_with = lcType
GO TOP
DO WHILE !EOF()
	IF INLIST(clm_status, "D", "W", "P", "I", "F")
		lnSheet = lnSheet + 1
		lnField = AFIELDS(laFields)
		*********************************
		DO CASE
		CASE clm_status = "D"
			lcResult = "Denied"
		CASE clm_status = "W"
			lcResult = "Waiting"
		CASE clm_status = "P"
			lcResult = "Reimbursement"
		CASE clm_status = "I"
			lcResult = "วางบิล"
		CASE clm_status = "F"
			lcResult = "Fax claim"
		ENDCASE
		oSheet = oWorkBook.WorkSheets.ADD
		oSheet.NAME = lcResult
		lnRow = 1
		*******************************
		lnMax = ALEN(laTitle)
		FOR i = 1 TO lnMax
			lcValue = laTitle[i]
			lcFmtExp = ["]+laFormat[i]+["]
			oSheet.Cells(lnRow,i) = lcValue
			**
			lcColumn = ColumnLetter(i)
			lcColumnExpression = ["] + lcColumn + [:] + lcColumn + ["]
			oSheet.COLUMNS(&lcColumnExpression.).SELECT
			oSheet.COLUMNS(&lcColumnExpression.).NumberFormat = &lcFmtExp.
			oSheet.COLUMNS(&lcColumnExpression.).WrapText = .F.
			IF i = 32
				oSheet.COLUMNS(&lcColumnExpression.).COLUMNWIDTH = 100
			ENDIF
		ENDFOR
		*******************
		lnRow = 2
		lnMax = ALEN(laClaim)
		lcStatus = clm_status
		STORE 0 TO lnCharge, lnDiscount, lnPaid , lnOver, lnNopaid, lnExgratia
		WAIT WINDOW lcResult NOWAIT
		DO WHILE clm_status = lcStatus AND !EOF()
			STORE 0 TO lnCharge, lnDiscount, lnPaid , lnOver, lnNopaid, lnExgratia
			IF clm_status = "D"
				FOR i = 1 TO lnMax && Fcount()
					IF laClaim[i] = "note2ins"
						IF EMPTY(note2ins)
							laClaim[i] = "snote"
						ENDIF
					ENDIF
					*******************************
					lcField = laClaim[i] &&FIELD(i)
					lcValue = &lcField
					IF !EMPTY(lcValue)
						IF INLIST(lcField, "snote", "note2ins")
							lcValue = ALLTRIM(STRTRAN(lcValue, CHR(13), " "))
						ENDIF
						IF TYPE("lcValue") = "C"
							oSheet.Cells(lnRow,i) = IIF(laFormat[i] = "@", ALLTRIM(lcValue), lcValue)
						ENDIF
					ENDIF
				ENDFOR
				****************************
				IF SEEK(LEFT(illness1,3),"disease", "code")
					oSheet.Cells(lnRow,33)  = ALLTRIM(disease.detail)
				ENDIF
				IF SEEK(LEFT(illness2,3),"disease", "code")
					oSheet.Cells(lnRow,34)  = ALLTRIM(disease.detail)
				ENDIF
				IF SEEK(LEFT(illness3,3),"disease", "code")
					oSheet.Cells(lnRow,35)  = ALLTRIM(disease.detail)
				ENDIF
				IF SEEK(illness1, "icd10", "code")
					oSheet.Cells(lnRow,36) = ALLTRIM(icd10.DESCRIPTION)
				ENDIF
				IF SEEK(illness2, "icd10", "code")
					oSheet.Cells(lnRow,37) = ALLTRIM(icd10.DESCRIPTION)
				ENDIF
				IF SEEK(illness3, "icd10", "code")
					oSheet.Cells(lnRow,38) = ALLTRIM(icd10.DESCRIPTION)
				ENDIF
				*************************
				oSheet.Cells(lnRow,39) = IIF(EMPTY(ref_date), "" , ref_date)
				oSheet.Cells(lnRow,40) = IIF(EMPTY(return_date), "", return_date)
				*************************								
				lcNotifyNo = notify_no
				DO WHILE clm_status = lcStatus AND notify_no = lcNotifyNo AND !EOF()
					lnCharge = lnCharge + charge
					lnDiscount = lnDiscount + discount
					lnPaid = lnPaid + paid
					lnOver = lnOver + overpaid
					lnNopaid = lnNopaid + nopaid
					lnExgratia = lnExgratia + exgratia
					SKIP
				ENDDO 
				oSheet.Cells(lnRow,24) = lnCharge
				oSheet.Cells(lnRow,25) = lnDiscount
				oSheet.Cells(lnRow,26) = lnPaid
				oSheet.Cells(lnRow,27) = lnOver
				oSheet.Cells(lnRow,28) = lnNopaid
				oSheet.Cells(lnRow,29) = lnExgratia
				lnRow = lnRow + 1
			ELSE
				lcNotifyNo = notify_no
				DO WHILE clm_status = lcStatus AND notify_no = lcNotifyNo AND !EOF()
					FOR i = 1 TO lnMax && Fcount()
						IF laClaim[i] = "note2ins"
							IF EMPTY(note2ins)
								laClaim[i] = "snote"
							ENDIF
						ENDIF
						*******************************
						lcField = laClaim[i] &&FIELD(i)
						lcValue = &lcField
						IF !EMPTY(lcValue)
							IF INLIST(lcField, "snote", "note2ins")
								lcValue = ALLTRIM(STRTRAN(lcValue, CHR(13), " "))
							ENDIF							
							IF TYPE("lcValue") = "C"
								oSheet.Cells(lnRow,i) = IIF(laFormat[i] = "@", ALLTRIM(lcValue), lcValue)
							ENDIF 	
						ENDIF
					ENDFOR
					****************************
					IF SEEK(LEFT(illness1,3),"disease", "code")
						oSheet.Cells(lnRow,33)  = ALLTRIM(disease.detail)
					ENDIF
					IF SEEK(LEFT(illness2,3),"disease", "code")
						oSheet.Cells(lnRow,34)  = ALLTRIM(disease.detail)
					ENDIF
					IF SEEK(LEFT(illness3,3),"disease", "code")
						oSheet.Cells(lnRow,35)  = ALLTRIM(disease.detail)
					ENDIF
					IF SEEK(illness1, "icd10", "code")
						oSheet.Cells(lnRow,36) = ALLTRIM(icd10.DESCRIPTION)
					ENDIF
					IF SEEK(illness2, "icd10", "code")
						oSheet.Cells(lnRow,37) = ALLTRIM(icd10.DESCRIPTION)
					ENDIF
					IF SEEK(illness3, "icd10", "code")
						oSheet.Cells(lnRow,38) = ALLTRIM(icd10.DESCRIPTION)
					ENDIF
					*************************
					oSheet.Cells(lnRow,39) = IIF(EMPTY(ref_date), "" , ref_date)
					oSheet.Cells(lnRow,40) = IIF(EMPTY(return_date), "", return_date)
					oSheet.Cells(lnRow,41) = hb_cover
					oSheet.Cells(lnRow,42) = hb_act
					oSheet.Cells(lnRow,43) = hb_app
					****************************
					lnCharge = lnCharge + charge
					lnDiscount = lnDiscount + discount
					lnPaid = lnPaid + paid
					lnOver = lnOver + overpaid
					lnNopaid = lnNopaid + nopaid
					lnExgratia = lnExgratia + exgratia
					******************************
					lnRow = lnRow + 1
					SKIP
				ENDDO
				********************************
				oSheet.Cells(lnRow,1) = lcNotifyNo
				oSheet.Cells(lnRow,22) = "รวม"
				oSheet.Cells(lnRow,24) = lnCharge
				oSheet.Cells(lnRow,25) = lnDiscount
				oSheet.Cells(lnRow,26) = lnPaid
				oSheet.Cells(lnRow,27) = lnOver
				oSheet.Cells(lnRow,28) = lnNopaid
				oSheet.Cells(lnRow,29) = lnExgratia
				lnRow = lnRow + 1
				************************************
				oSheet.SELECT
			ENDIF
		ENDDO
	ELSE 
		SELECT curClaim
		SKIP 	
	ENDIF 	
ENDDO
************************
PROCEDURE CoverSheet
************************
SELECT notify_no, notify_date, policy_no, client_name, plan, ;
	prov_name, admis_date, disc_date, IIF(result = "P5", "I", "P") AS clm_status ;
	FROM curClaim ;
	WHERE clm_status # "F" ;
	GROUP BY notify_no ;
	ORDER BY 9 ;
	INTO CURSOR curCover
************************
lnRow = 1
oSheet = oWorkBook.WorkSheets.ADD
oSheet.NAME = "Cover Sheet"
SELECT curCover
DO WHILE !EOF()
	DO CASE
	CASE clm_status = "P"
		oSheet.Cells(lnRow, 1) = "สรุปการทำจ่ายผู้เอาประกัน"
	CASE clm_status = "I"
		oSheet.Cells(lnRow, 1) = "สรุปการทำจ่ายโรงพยาบาล"
	ENDCASE
	*************************************
	lnRow = lnRow + 1
	oSheet.Cells(lnRow,1) = "Notify No"
	oSheet.Cells(lnRow,2) = "Notify Date"
	oSheet.Cells(lnRow,3) = "กรมธรรม์"
	oSheet.Cells(lnRow,4) = "ชื่อ"
	oSheet.Cells(lnRow,5) = "แผน"
	oSheet.Cells(lnRow,6) = "โรงพยาบาล"
	oSheet.Cells(lnRow,7) = "Admit"
	oSheet.Cells(lnRow,8) = "Discharged"
	*************************************************
	lnRow = lnRow + 1
	lnMax = ALEN(laClaim)
	lcStatus = clm_status
	DO WHILE clm_status = lcStatus AND !EOF()
		oSheet.Cells(lnRow,1) = notify_no
		oSheet.Cells(lnRow,2) = notify_date
		oSheet.Cells(lnRow,3) = policy_no
		oSheet.Cells(lnRow,4) = client_name
		oSheet.Cells(lnRow,5) = plan
		oSheet.Cells(lnRow,6) = prov_name
		oSheet.Cells(lnRow,7) = admis_date
		oSheet.Cells(lnRow,8) = disc_date
		lnRow = lnRow + 1
		SKIP
	ENDDO
	oSheet.Cells(lnRow,1).SELECT
	oSheet.HPageBreaks.ADD(oExcel.ActiveCell)
	lnRow = lnRow + 1
ENDDO
*****************************************************
PROCEDURE SETFORMAT
lnFields = AFIELDS(laFields)
FOR iField1 = 1 TO lnFields
	oSheet.Cells(1,iField1) = FIELD(iField1)
	*********************
	lcColumn    = ColumnLetter(iField1)
	lcColumnExpression = ["] + lcColumn + [:] + lcColumn + ["]
	oSheet.COLUMNS(&lcColumnExpression.).SELECT
	*********************************************
	DO CASE
	CASE (laFields[iField1,2] $ "C.L")
		lcFmtExp = ["@"]
		lnWidth = laFields[iField1,3]
		lnWidth = IIF(lnWidth > 100, 100, lnWidth)
		oSheet.COLUMNS(&lcColumnExpression.).COLUMNWIDTH = lnWidth
	CASE (laFields[iField1,2] $ "M")
		lcFmtExp = [""]
		lnWidth = 100
		oSheet.COLUMNS(&lcColumnExpression.).COLUMNWIDTH = lnWidth
	CASE (laFields[iField1,2] $ "N.I.Y")
		IF laFields[iField1,4] = 0
			lcFmtExp = ["0"]
		ELSE
			lcFmtExp = ["0.] + REPLICATE("0", laFields[iField1,4]) + ["]
		ENDIF
		oSheet.COLUMNS(&lcColumnExpression.).COLUMNWIDTH = 16
	CASE (laFields[iField1,2] $ "D.T")
		lcFmtExp = ["dd/mm/yyyy"]
		oSheet.COLUMNS(&lcColumnExpression.).COLUMNWIDTH = 10
	ENDCASE
	IF lcFmtExp # [""]
		oSheet.COLUMNS(&lcColumnExpression.).NumberFormat = &lcFmtExp.
	ENDIF
ENDFOR
*!****************************************************************************!*
*!* Beginning of PROCEDURE ColumnLetter                                      *!*
*!* This procedure derives a letter reference based on a numeric value.  It  *!*
*!* uses the basis of the ASCII Value of the upper case letters A to Z (65   *!*
*!* through 90) to return the proper letter (or letter combination) for a    *!*
*!* provided numeric value.                                                  *!*
*!****************************************************************************!*

PROCEDURE ColumnLetter
PARAMETER lnColumnNumber
lnFirstValue = INT(lnColumnNumber/27)
lcFirstLetter = IIF(lnFirstValue=0,"",CHR(64+lnFirstValue))
lnMod =  MOD(lnColumnNumber,26)
lcSecondLetter = CHR(64+IIF(lnMod=0, 26, lnMod))

RETURN lcFirstLetter + lcSecondLetter
******************************************************************
PROCEDURE SetLine

oSheet.Cells.BORDERS(7).LineStyle = 1
oSheet.Cells.BORDERS(7).Weight = 2
oSheet.Cells.BORDERS(7).ColorIndex = -4105
oSheet.Cells.BORDERS(8).LineStyle = 1
oSheet.Cells.BORDERS(8).Weight = 2
oSheet.Cells.BORDERS(8).ColorIndex = -4105
oSheet.Cells.BORDERS(9).LineStyle = 1
oSheet.Cells.BORDERS(9).Weight = 2
oSheet.Cells.BORDERS(9).ColorIndex = -4105
oSheet.Cells.BORDERS(10).LineStyle = 1
oSheet.Cells.BORDERS(10).Weight = 2
oSheet.Cells.BORDERS(10).ColorIndex = -4105
oSheet.Cells.BORDERS(11).LineStyle = 1
oSheet.Cells.BORDERS(11).Weight = 2
oSheet.Cells.BORDERS(11).ColorIndex = -4105
oSheet.Cells.BORDERS(12).LineStyle = 1
oSheet.Cells.BORDERS(12).Weight = 2
oSheet.Cells.BORDERS(12).ColorIndex = -4105
oSheet.Cells.SELECT
oSheet.Cells.EntireColumn.AutoFit
oSheet.RANGE("A1").SELECT
****************************************************************************
PROCEDURE outStandingClaim
***********************************************************
*Query Claim
SELECT IIF(Claim.result = "P5", "I", IIF(Claim.result = "W5", "F", IIF(Claim.result = "W6", "U", LEFT(Claim.result,1)))) AS clm_status, ;
	IIF(Claim.claim_with = "A",  "P", Claim.claim_with) AS claim_with, ;
	Claim.notify_no, Claim.notify_date, Claim.service_type, Claim.cause_type, ;
	Claim.policy_no, Claim.policy_holder, Claim.family_no, Claim.plan, Claim.client_name, Claim.effective, Claim.expried, ;
	Claim.visit AS ds_no, Claim.visit_no AS claimitem, Claim.indication_admit, Claim.diag_plan, Claim.acc_date, ;
	Claim.prov_name, Claim.admis_date, Claim.disc_date, Claim.illness1, Claim.illness2, Claim.illness3, ;
	Claim_line.cat_code, Claim_line.description, IIF(Claim.result = "W5", Claim_line.fadmis, Claim_line.sadmis) AS admit, ;
	IIF(Claim.result = "W5", Claim_line.fcharge, Claim_line.scharge) AS charge, ;
	IIF(Claim.result = "W5", Claim_line.fdiscount, Claim_line.sdiscount) AS discount, ;
	IIF(Claim.result = "W5", Claim_line.fpaid+Claim_line.deduc, Claim_line.spaid+Claim_line.dpaid) AS paid, ;
	IIF(Claim.result = "W5", Claim_line.fremain, Claim_line.sremain) AS overpaid, ;
	IIF(Claim.result = "W5", Claim_line.exgratia, Claim_line.apaid) AS exgratia, ;
	IIF(Claim.result = "W5", Claim_line.nopaid, Claim_line.snoncover) AS nopaid, ;
	Claim_line.total_fee AS fee, Claim.hb_cover, Claim.hb_act, Claim.hb_app, ;
	Claim.result, Claim.snote, Claim.note2ins, Claim.ref_date, Claim.return_date ;
	FROM  cims!Claim INNER JOIN cims!Claim_line ;
	ON Claim.notify_no = Claim_line.notify_no ;
	WHERE Claim.fundcode = gcFundCode ;
		AND result = "W" ;
	ORDER BY 2, 1 ;
	INTO CURSOR curClaim
************************************





