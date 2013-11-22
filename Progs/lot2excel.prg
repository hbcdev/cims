*this program for print credit claim cover report 
PARAMETERS tcFundcode, tcLotNo, tcSaveTo, tdReturnDate, tnType

IF EMPTY(tcFundCode) AND EMPTY(tcLotNo) AND EMPTY(tcSaveTo) AND EMPTY(tnType)
	RETURN 
ENDIF 	
IF tnType <> 2
	=MESSAGEBOX("ไม่สามารถทำงานได้ เนื่องจากเลือกส่งออกข้อมูลการจ่ายลูกค้า",0,"Error")
	RETURN 
ENDIF 	
*
#INCLUDE "include\cims.h"
SET DELETED ON
SET SAFETY OFF
SET PROCEDURE TO progs\utility
*********************
*
WAIT WINDOW "Query Data ....." NOWAIT 
IF EMPTY(tdReturnDate)
	SELECT fund.thainame AS fundname, claim.prov_name, claim.policy_no, claim.notify_no, claim.notify_date, firstchr(claim.prov_name) AS "first", ; 	
		claim.client_name, claim.service_type, claim.admis_date, claim.disc_date, claim.scharge, claim.sdiscount, claim.inv_page AS paytype, ;
		claim.snopaid, claim.sbenfpaid, claim.snote, claim.indication_admit, claim.result, claim.diag_plan, claim.return_date, claim.acc_date, ;
		claim.note2ins, claim.tr_acno, claim.tr_name, claim.paid_date, claim.lotno, claim.batchno, claim.insurepaydate, claim.senddate ;
	FROM cims!claim LEFT JOIN cims!fund ;
		ON claim.fundcode = fund.fundcode ;
	WHERE claim.fundcode= tcFundCode ;
		AND claim.lotno = tcLotNo ;
	ORDER BY claim.batchno, claim.notify_no ;
	INTO CURSOR curLot
ELSE 
	IF tcFundCode = "SMG"
		SELECT fund.thainame AS fundname, claim.prov_name, claim.policy_no, claim.notify_no, claim.notify_date, firstchr(claim.prov_name) AS "first", ; 
			claim.client_name, claim.service_type, claim.admis_date, claim.disc_date, claim.scharge, claim.sdiscount, claim.inv_page AS paytype, ;
			claim.snopaid, claim.sbenfpaid, claim.snote, claim.indication_admit, claim.result, claim.diag_plan, claim.return_date, claim.acc_date, ;
			claim.note2ins, claim.tr_acno, claim.tr_name, claim.paid_date, claim.lotno, claim.batchno, claim.insurepaydate, claim.senddate ;		
		FROM cims!claim LEFT JOIN cims!fund ;
			ON claim.fundcode = fund.fundcode ;
		WHERE claim.fundcode= tcFundCode ;
			AND claim.lotno = tcLotNo ;
			AND claim.senddate = tdReturnDate ;
		ORDER BY claim.batchno, claim.notify_no ;	
		INTO CURSOR curLot
	ELSE 
		SELECT fund.thainame AS fundname, claim.prov_name, claim.policy_no, claim.notify_no, claim.notify_date, firstchr(claim.prov_name) AS "first", ; 
			claim.client_name, claim.service_type, claim.admis_date, claim.disc_date, claim.scharge, claim.sdiscount, claim.inv_page AS paytype, ;
			claim.snopaid, claim.sbenfpaid, claim.snote, claim.indication_admit, claim.result, claim.diag_plan, claim.return_date, claim.acc_date, ;
			claim.note2ins, claim.tr_acno, claim.tr_name, claim.paid_date, claim.lotno, claim.batchno, claim.insurepaydate, claim.senddate ;		
		FROM cims!claim LEFT JOIN cims!fund ;
			ON claim.fundcode = fund.fundcode ;
		WHERE claim.fundcode= tcFundCode ;
			AND claim.lotno = tcLotNo ;
			AND claim.return_date = tdReturnDate ;
		ORDER BY claim.batchno, claim.notify_no ;	
		INTO CURSOR curLot
	ENDIF 			
ENDIF 	
*
IF _TALLY < 0
	=MESSAGEBOX("ไม่พบข้อมูลเคลมของ Lot No. "+tcLotNo, 0, "คำเตือน")		
	RETURN 
ENDIF 	
**************************************
lnSheet = 1
lcFilePath = ADDBS(tcSaveTo)+tcLotNo
IF !DIRECTORY(lcFilePath)
	MKDIR &lcFilePath
ENDIF 
SELECT curLot
GO TOP
ldReturnDate = IIF(EMPTY(senddate), return_date, senddate)
*
lcFile = ADDBS(lcFilePath)+ALLTRIM(tcLotNo)+"_Return_"+STRTRAN(DTOC(senddate), "/", "")
******************************************************
oExcel = CREATEOBJECT("Excel.Application")
IF FILE(lcFile+".xls")
	IF MESSAGEBOX("พบไฟล์ "+lcFile+".xls อยู่ก่อนแล้ว ต้องการให้ทำต่อในไฟล์นี้ กด Yes",4+32+256, "ยืนยัน") = IDYES
		WAIT WINDOW "Open "+lcFile NOWAIT 
		oWorkBook = oExcel.Workbooks.Open(lcFile)
		lnSheet = oWorkBook.Sheets.Count
	ELSE 
		oWorkBook = oExcel.Workbooks.Add()	
	ENDIF 	
ELSE 
	oWorkBook = oExcel.Workbooks.Add()
ENDIF 	
*
lcLotNo = lotno
lcSheetName = ""
lcOldSheetName = ""
STORE "" TO lcOldCount, lcOldPaid, lcCount, lcPaid, lcThisCount, lcThisPaid
STORE 0 TO lnTotalClaim, lnTotalPaid
DO WHILE !EOF()
	IF lnSheet > 3
		oSheet = oWorkBook.WorkSheets.Add()
	ELSE
		oSheet = oWorkBook.WorkSheets(lnSheet)
		IF oSheet.Name # "Sheet"
			oSheet = oWorkBook.WorkSheets.Add()
		ENDIF 
	ENDIF	
	lcOldCount = lcCount
	lcOldPaid = lcPaid
	*****************************************
	DO LotHeading
	***************************
	lnRows = 5
	WAIT WINDOW batchno NOWAIT
	STORE 0 TO lnCount, lnPaid
	**********************************************
	lcBatchNo = batchno
	DO WHILE batchno = lcBatchNo AND !EOF()
		DO LotDetail
		*
		lnCount = lnCount + 1
		lnPaid = lnPaid + sbenfpaid
		lnRows = lnRows + 1
		SKIP 
	ENDDO 	
	oSheet.Cells(lnRows,1).Value = "จำนวนเคลมรวม: "
	oSheet.Cells(lnRows, 2).Value = [=COUNT(K5:K]+ALLTRIM(STR(lnRows-1))+[)] &&TRANSFORM(lnCount, "@Z 999,999")+" เคลม"
	oSheet.Cells(lnRows,10).Value = "ยอดจ่ายรวมทั้งสิ้น"
	oSheet.Cells(lnRows,11).Value = [=SUM(K5:K]+ALLTRIM(STR(lnRows-1))+[)]  &&TRANSFORM(lnPaid, "@Z 9,999,999.99")
	lcThisCount = [B]+ALLTRIM(STR(lnRows))
	lcThisPaid = [K]+ALLTRIM(STR(lnRows))
	*				
	lcRow = ["3:]+ALLTRIM(STR(lnRows-1))+["]
	lcRange = ["A4:N]+ALLTRIM(STR(lnRows-1))+["]
	lcB = ["B4:B]+ALLTRIM(STR(lnRows-1))+["]
	
	*	
	lnRows = lnRows + 5
	lnTotalClaim = lnTotalClaim + lnCount
	lnTotalPaid = lnTotalPaid + lnPaid	
	*
	lcCount = ALLTRIM(oSheet.name)+"!B"+ALLTRIM(STR(lnRows,4))
	*
	oSheet.Cells(lnRows, 1).Value = "จำนวนเคลมสะสมรวม: "
	oSheet.Cells(lnRows, 2).Value = "="+IIF(EMPTY(lcOldCount), lcThisCount, lcOldCount+" + " + lcThisCount) &&ALLTRIM(STR(lnCount))) &&TRANSFORM(lnTotalClaim, "@Z 999,999")+" เคลม"
	*
	lnRows = lnRows + 1
	lcPaid = ALLTRIM(oSheet.name)+"!B"+ALLTRIM(STR(lnRows,4))
	*
	oSheet.Cells(lnRows, 1).Value = "ยอดจ่ายสะสมรวมทั้งสิ้น"
	oSheet.Cells(lnRows, 2).Value = "="+IIF(EMPTY(lcOldPaid), lcThisPaid, lcOldPaid+" + " + lcThisPaid) &&STR(lnPaid))  && TRANSFORM(lnTotalPaid, "@Z 9,999,999.99")
	lnRows = lnRows + 2
	oSheet.Cells(lnRows, 1).Value = "Return Date :"
	oSheet.Cells(lnRows, 2).Value = ldReturnDate	
	*
	oSheet.Range(&lcRange).WrapText = .T.
	oSheet.Range(&lcB).WrapText = .F.	
	oSheet.Range(&lcB).ShrinkToFit = .T.
	*************************************************
	*Auto Fit All Column 
	oSheet.Activate	
	oSheet.Rows(&lcRow).Select
	oSheet.Rows(&lcRow).EntireRow.AutoFit
	*****************************
	DO SetBorder WITH  lcRange
	*****************************
	lnSheet = lnSheet + 1		
ENDDO
oWorkBook.SaveAs(lcFile)
oExcel.Quit

=MESSAGEBOX("Generate Report file to "+lcFile+" Finished...", 0, "Warning")
*****************************************************
PROCEDURE LotHeading
LPARAMETERS tcLotNo

WITH oSheet
	.Range("A1").Value = fundname	
	.PageSetup.Orientation = xlLandscape
	.PageSetup.LeftMargin = 2.5
	.PageSetup.RightMargin = 1.5
	.PageSetup.TopMargin = 1.3
	.PageSetup.BottomMargin = 1.3
	.PageSetup.Zoom = 55
	.PageSetup.PrintTitleRows = "$1:$4"
       .PageSetup.PrintTitleColumns = ""
       .PageSetup.LeftHeader = ""
       .PageSetup.CenterHeader = ""
       .PageSetup.RightHeader = ""
       .PageSetup.LeftFooter = ""
       .PageSetup.CenterFooter = ""
       .PageSetup.RightFooter = ""	
	.Range("A3:O3").RowHeight = 20	
	.Range("A4:O8").RowHeight = 30
	.Range("A4:O4").HorizontalAlignment = xlCenter	
	.Range("A1:E1").MergeCells = .T.
	.Range("A1:D1").Font.Size = 14
	.Range("A1:D1").Font.Bold = .T.	
	.Range("A2:D2").MergeCells = .T.
	.Range("A2:D2").Font.Size = 14
	.Range("A2:D2").Font.Bold = .T.
	.Range("A3:D3").Font.Size = 14	
ENDWITH 	
*
lcSheetName = LEFT(batchno,1)+ALLTRIM(SUBSTR(batchno,6))
oSheet.Name = lcSheetName
oSheet.Cells(1,12).Value = "Lot No."
oSheet.Cells(1,13).Value = lcLotNo
oSheet.Cells(2,12).Value = "กำหนดจ่าย วันที่"
oSheet.Cells(2,13).Value = insurepaydate
oSheet.Cells(3,12).Value = "Batch No."
oSheet.Cells(3,13).Value = batchno	
oSheet.Cells(2, 1).Value = "สรุปการจ่ายสินไหม(โรงพยาบาล)"
oSheet.Cells(3, 1).Value = "โรงพยาบาล"
oSheet.Cells(3, 2).Value = ALLTRIM(STRTRAN(prov_name, "(A)", ""))
oSheet.Cells(4, 1).Value = "Notify No"
oSheet.Cells(4, 2).Value = "เลขกรมธรรม์ "
oSheet.Cells(4, 3).Value = "ชื่อ-นามสกุล"
oSheet.Cells(4, 4).Value = "ประเภทบริการ"
oSheet.Cells(4, 5).Value = "วันเกิดเหตุ"		
oSheet.Cells(4, 6).Value = "วันที่เข้ารักษา"
oSheet.Cells(4, 7).Value = "วันที่ออกจาก รพ."
oSheet.Cells(4, 8).Value = "โรงพยาบาลเรียกเก็บ"
oSheet.Cells(4, 9).Value = "ส่วนลดจากโรงพยาบาล"
oSheet.Cells(4, 10).Value = "ยอดไม่คุ้มครอง"
oSheet.Cells(4, 11).Value = "ยอดจ่าย"
oSheet.Cells(4, 12).Value = "สาเหตุที่เข้ารักษา"
oSheet.Cells(4, 13).Value = "การรักษาเบื้องต้น"
oSheet.Cells(4, 14).Value = "หมายเหตุ"
oSheet.Cells(4, 15).Value = "Person Code"
oSheet.Cells(4, 16).Value = "Person No"
*		
oSheet.Range("L1:L3").HorizontalAlignment = xlRight
oSheet.Range("M1:M3").HorizontalAlignment = xlLeft	
oSheet.Range("H:K").NumberFormat = "#,##0.00"
oSheet.Range("A:P").ColumnWidth = 14
oSheet.Range("B:C").ColumnWidth = 24
oSheet.Range("E:G").ColumnWidth = 15	
oSheet.Range("L:N").ColumnWidth = 25
oSheet.Range("O:P").ColumnWidth = 10
oSheet.Range("A4:N4").WrapText = .T.		
 	
ENDPROC 
*********************************************************
PROCEDURE LotDetail

STORE "" TO lcPersonCode, lcPersonNo
lcPolicyNo = ALLTRIM(IIF(AT("-",policy_no) = 0, policy_no, STRTRAN(policy_no, "-", "")))
ldAccDate = acc_date
*
SELECT policy_no, personcode, personno ;
FROM (ADDBS(datapath)+"smg_policy1") ;
WHERE cardid = ALLTRIM(lcPolicyNo) ;
	AND exp_date > ldAccDate ;
INTO ARRAY laSmg
*
IF _TALLY = 0
	SELECT policy_no, personcode, personno ;
	FROM (ADDBS(datapath)+"smg_policy") ;
	WHERE cardid = ALLTRIM(lcPolicyNo) ;
		AND exp_date > ldAccDate ;
	INTO ARRAY laSmg
	IF _TALLY > 0
		lcPolicyNo = laSmg[1]
		lcPersonCode = laSmg[2]
		lcPersonNo = laSmg[3]
	ENDIF 		
ELSE 
	lcPolicyNo = laSmg[1]
	lcPersonCode = laSmg[2]
	lcPersonNo = laSmg[3]	
ENDIF 
*
oSheet.Cells(lnRows, 1).Value = [']+notify_no
oSheet.Cells(lnRows, 2).Value = [']+ALLTRIM(lcPolicyNo)
oSheet.Cells(lnRows, 3).Value = ALLTRIM(client_name)
oSheet.Cells(lnRows, 4).Value = service_type
oSheet.Cells(lnRows, 5).Value = iif(empty(acc_date), "", acc_date)
oSheet.Cells(lnRows, 6).Value = admis_date
oSheet.Cells(lnRows, 7).Value = disc_date
oSheet.Cells(lnRows, 8).Value = scharge
oSheet.Cells(lnRows, 9).Value = sdiscount
oSheet.Cells(lnRows, 10).Value = snopaid
oSheet.Cells(lnRows, 11).Value = sbenfpaid
oSheet.Cells(lnRows, 12).Value = ALLTRIM(indication_admit)
oSheet.Cells(lnRows, 13).Value = ALLTRIM(diag_plan)
oSheet.Cells(lnRows, 14).Value = ALLTRIM(STRTRAN(snote, CHR(13), " "))+" "+ALLTRIM(STRTRAN(note2ins, CHR(13), " "))
oSheet.Cells(lnRows, 14).Value = lcPersonCode
oSheet.Cells(lnRows, 14).Value = lcPersonNo	
ENDPROC 
*********************************************************
PROCEDURE SetFormat
lnFields = AFIELDS(laFields)
FOR iField1 = 1 TO lnFields
	lcColumn    = ColumnLetter(iField1)
	lcColumnExpression = ["] + lcColumn + [:] + lcColumn + ["]                                     
	*oSheet.Columns(&lcColumnExpression.).Select                             
	*********************************************                                                                              
	DO CASE                                                                      
	CASE (laFields[iField1,2] $ "C.L")
		lcFmtExp = ["@"]
		lnWidth = laFields[iField1,3]
		lnWidth = IIF(lnWidth > 100, 100, lnWidth)
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = lnWidth
	CASE (laFields[iField1,2] $ "M")
		lcFmtExp = ["@"]
		lnWidth = 100
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = lnWidth
	CASE (laFields[iField1,2] $ "N.I.Y")		
           	IF laFields[iField1,4] = 0
			lcFmtExp = ["#,###"]
		ELSE
			lcFmtExp = ["#,###.] + REPLICATE("0", laFields[iField1,4]) + ["]
		ENDIF 	
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = 16
	CASE (laFields[iField1,2] $ "D.T")  
     		lcFmtExp = ["dd/mm/yyyy"]          
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = 10
	ENDCASE
	oSheet.Columns(&lcColumnExpression.).NumberFormat = &lcFmtExp.
ENDFOR

ENDPROC 
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

ENDPROC 