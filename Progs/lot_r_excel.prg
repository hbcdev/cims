PARAMETERS tcFundcode, tcLotNo, tcSaveTo, tdReturnDate

IF EMPTY(tcFundCode) AND EMPTY(tcLotNo) AND EMPTY(tcSaveTo)
	RETURN 
ENDIF 	
*
IF !INLIST(LEFT(tcLotNo,1), "R", "E") 
	RETURN 
ENDIF 	

#INCLUDE "include\cims.h"
SET DELETED ON
SET SAFETY OFF
SET PROCEDURE TO progs\utility
*********************
*
WAIT WINDOW "Query Data ....." NOWAIT 
IF EMPTY(tdReturnDate)
	SELECT fund.thainame AS fundname, claim.policy_no, claim.notify_no, claim.notify_date, ; 	
		claim.client_name, claim.service_type, claim.admis_date, claim.disc_date, claim.scharge, claim.sdiscount, ;
		claim.snopaid, claim.sbenfpaid, claim.snote, claim.indication_admit, claim.result, claim.diag_plan, claim.return_date, ;
		claim.note2ins, claim.tr_acno, claim.tr_name, claim.paid_date, claim.lotno, claim.batchno, claim.insurepaydate, ;
		claim.pvno, claim.pv_date, claim.paid_date
	FROM cims!claim LEFT JOIN cims!fund ;
		ON claim.fundcode = fund.fundcode ;
	WHERE claim.fundcode= tcFundCode ;
		AND claim.lotno = tcLotNo ;
	ORDER BY claim.lotno, claim.batchno, claim.notify_no ;
	INTO CURSOR curLot
ELSE 
	SELECT fund.thainame AS fundname, claim.policy_no, claim.notify_no, claim.notify_date, ; 	
		claim.client_name, claim.service_type, claim.admis_date, claim.disc_date, claim.scharge, claim.sdiscount, ;
		claim.snopaid, claim.sbenfpaid, claim.snote, claim.indication_admit, claim.result, claim.diag_plan, claim.return_date, ;
		claim.note2ins, claim.tr_acno, claim.tr_name, claim.paid_date, claim.lotno, claim.batchno, claim.insurepaydate, ;
		claim.pvno, claim.pv_date, claim.paid_date
	FROM cims!claim LEFT JOIN cims!fund ;
		ON claim.fundcode = fund.fundcode ;
	WHERE claim.fundcode= tcFundCode ;
		AND claim.lotno = tcLotNo ;
		AND claim.return_date = tdReturnDate ;
	ORDER BY claim.lotno, claim.batchno, claim.notify_no ;	
	INTO CURSOR curLot
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
*
lcFile = ADDBS(lcFilePath)+ALLTRIM(tcLotNo)
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
STORE "" TO lcOldCount, lcOldPaid, lcCount, lcPaid
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
	ldPaidDate = 
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
	oSheet.Cells(lnRows, 2).Value = TRANSFORM(lnCount, "@Z 999,999")+" เคลม"
	oSheet.Cells(lnRows,9).Value = "ยอดจ่ายรวมทั้งสิ้น"
	oSheet.Cells(lnRows,10).Value = TRANSFORM(lnPaid, "@Z 9,999,999.99")
	*				
	lcRow = ["3:]+ALLTRIM(STR(lnRows-1))+["]
	lcRange = ["A4:]+ICASE("C" $ lcLotNo, "M", "R" $ lcLotNo, "O", "O")+ALLTRIM(STR(lnRows-1))+["]
	*	
	lnRows = lnRows + 5
	lnTotalClaim = lnTotalClaim + lnCount
	lnTotalPaid = lnTotalPaid + lnPaid	
	*
	lcCount = ALLTRIM(oSheet.name)+"!B"+ALLTRIM(STR(lnRows,4))
	*
	oSheet.Cells(lnRows, 1).Value = "จำนวนเคลมสะสมรวม: "
	oSheet.Cells(lnRows, 2).Value = IIF(EMPTY(lcOldCount), lnTotalClaim, "="+lcOldCount+" + " + ALLTRIM(STR(lnCount))) &&TRANSFORM(lnTotalClaim, "@Z 999,999")+" เคลม"
	*
	lnRows = lnRows + 1
	lcPaid = ALLTRIM(oSheet.name)+"!B"+ALLTRIM(STR(lnRows,4))
	*
	oSheet.Cells(lnRows, 1).Value = "ยอดจ่ายสะสมรวมทั้งสิ้น"
	oSheet.Cells(lnRows, 2).Value = IIF(EMPTY(lcOldPaid), lnTotalPaid, "="+lcOldPaid+" + " + STR(lnPaid))  && TRANSFORM(lnTotalPaid, "@Z 9,999,999.99")
	lnRows = lnRows + 2
	
	oSheet.Cells(lnRows, 1).Value = "Paid Date :"
	oSheet.Cells(lnRows, 2).Value = ldReturnDate	
	oSheet.Range(&lcRange).WrapText = .T.	
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
	.PageSetup.Zoom = 60
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
DO CASE 
CASE LEFT(lcLotNo, 1) = "C"
	lcSheetName = LEFT(batchno,1)+RIGHT(ALLTRIM(batchno),4)
	oSheet.Name = lcSheetName
	oSheet.Cells(1,12).Value = "Lot No."
	oSheet.Cells(1,13).Value = lcLotNo
	oSheet.Cells(2,12).Value = "กำหนดจ่าย วันที่"
	oSheet.Cells(2,13).Value = insurepaydate
	oSheet.Cells(3,12).Value = "Batch No."
	oSheet.Cells(3,13).Value = batchno	
	oSheet.Cells(2, 1).Value = "สรุปการจ่ายสินไหม(ลูกค้า)"
	oSheet.Cells(3, 1).Value = "โรงพยาบาล"
	oSheet.Cells(3, 2).Value = ALLTRIM(prov_name)
	oSheet.Cells(4, 1).Value = "Notify No"
	oSheet.Cells(4, 2).Value = "เลขกรมธรรม์ "
	oSheet.Cells(4, 3).Value = "ชื่อ-นามสกุล"
	oSheet.Cells(4, 4).Value = "ประเภทบริการ"
	oSheet.Cells(4, 5).Value = "วันที่เข้ารักษา"
	oSheet.Cells(4, 6).Value = "วันที่ออกจาก รพ."
	oSheet.Cells(4, 7).Value = "โรงพยาบาลเรียกเก็บ"
	oSheet.Cells(4, 8).Value = "ส่วนลดจากโรงพยาบาล"
	oSheet.Cells(4, 9).Value = "ยอดไม่คุ้มครอง"
	oSheet.Cells(4, 10).Value = "ยอดจ่าย"
	oSheet.Cells(4, 11).Value = "สาเหตุที่เข้ารักษา"
	oSheet.Cells(4, 12).Value = "การรักษาเบื้องต้น"
	oSheet.Cells(4, 13).Value = "หมายเหตุ"
	*		
	oSheet.Range("L1:L3").HorizontalAlignment = xlRight
	oSheet.Range("M1:M3").HorizontalAlignment = xlLeft	
	oSheet.Range("G:J").NumberFormat = "#,##0.00"
	oSheet.Range("A:O").ColumnWidth = 14
	oSheet.Range("B:B").ColumnWidth = 18		
	oSheet.Range("C:C").ColumnWidth = 20
	oSheet.Range("E:F").ColumnWidth = 15	
	oSheet.Range("K:M").ColumnWidth = 25
	oSheet.Range("A4:N4").WrapText = .T.		
CASE INLIST(LEFT(lcLotNo, 1), "R", "E")
	oSheet.Name = LEFT(batchno,1)+RIGHT(ALLTRIM(batchno),3)
	oSheet.Cells(1,14).Value = "Lot No."
	oSheet.Cells(1,15).Value = lcLotNo
	oSheet.Cells(2,14).Value = "กำหนดจ่าย วันที่"
	oSheet.Cells(2,15).Value = insurepaydate
	oSheet.Cells(3,14).Value = "Batch No."
	oSheet.Cells(3,15).Value = batchno		
	oSheet.Cells(2, 1).Value = "สรุปการจ่ายสินไหม(จ่ายลูกค้า)"
	oSheet.Cells(3, 1).Value = "วันที่โอนเงินเข้าบัญชี"
	oSheet.Cells(3, 2).Value = IIF(EMPTY(paid_date), "", paid_date)
	oSheet.Cells(4, 1).Value = "Notify No"
	oSheet.Cells(4, 2).Value = "เลขกรมธรรม์ "
	oSheet.Cells(4, 3).Value = "ชื่อ-นามสกุล"
	oSheet.Cells(4, 4).Value = "ประเภทบริการ"
	oSheet.Cells(4, 5).Value = "โรงพยาบาล"
	oSheet.Cells(4, 6).Value = "วันที่เข้ารักษา"
	oSheet.Cells(4, 7).Value = "วันที่ออกจาก รพ."
	oSheet.Cells(4, 8).Value = "โรงพยาบาลเรียกเก็บ"
	oSheet.Cells(4, 9).Value = "ส่วนลดจากโรงพยาบาล"
	oSheet.Cells(4, 10).Value = "ยอดไม่คุ้มครอง"
	oSheet.Cells(4, 11).Value = "ยอดจ่าย"
	oSheet.Cells(4, 12).Value = "สาเหตุที่เข้ารักษา"
	oSheet.Cells(4, 13).Value = "การรักษาเบื้องต้น"
	oSheet.Cells(4, 14).Value = "หมายเหตุ"
	oSheet.Cells(4, 15).Value = "โอนเข้าบัญชีเลขที่"	
	*
	oSheet.Range("N1:N3").HorizontalAlignment = xlRight
	oSheet.Range("O1:O3").HorizontalAlignment = xlLeft		
	oSheet.Range("H:K").NumberFormat = "#,##0.00"
	oSheet.Range("A:O").ColumnWidth = 14
	oSheet.Range("B:B").ColumnWidth = 16	
	oSheet.Range("C:C").ColumnWidth = 20
	oSheet.Range("E:E").ColumnWidth = 20	
	oSheet.Range("F:G").ColumnWidth = 15	
	oSheet.Range("L:N").ColumnWidth = 25
	oSheet.Range("A:O").WrapText = .T.	
ENDCASE
 	
ENDPROC 
*********************************************************
PROCEDURE LotDetail
LPARAMETERS tcLotNo

DO CASE 
CASE LEFT(lcLotNo, 1) = "C"
	oSheet.Cells(lnRows, 1).Value = [']+notify_no
	oSheet.Cells(lnRows, 2).Value = [']+ALLTRIM(policy_no)+CHR(160)
	oSheet.Cells(lnRows, 3).Value = ALLTRIM(client_name)
	oSheet.Cells(lnRows, 4).Value = service_type
	oSheet.Cells(lnRows, 5).Value = admis_date
	oSheet.Cells(lnRows, 6).Value = disc_date
	oSheet.Cells(lnRows, 7).Value = scharge
	oSheet.Cells(lnRows, 8).Value = sdiscount
	oSheet.Cells(lnRows, 9).Value = snopaid
	oSheet.Cells(lnRows, 10).Value = sbenfpaid
	oSheet.Cells(lnRows, 11).Value = ALLTRIM(indication_admit)
	oSheet.Cells(lnRows, 12).Value = ALLTRIM(diag_plan)
	oSheet.Cells(lnRows, 13).Value = ALLTRIM(snote)+" "+ALLTRIM(note2ins)
CASE INLIST(LEFT(lcLotNo, 1), "R", "E")
	oSheet.Cells(lnRows, 1).Value = [']+notify_no
	oSheet.Cells(lnRows, 2).Value = [']+ALLTRIM(policy_no)+CHR(160)
	oSheet.Cells(lnRows, 3).Value = ALLTRIM(client_name)
	oSheet.Cells(lnRows, 4).Value = service_type
	oSheet.Cells(lnRows, 5).Value = ALLTRIM(prov_name)
	oSheet.Cells(lnRows, 6).Value = TTOD(admis_date)
	oSheet.Cells(lnRows, 7).Value = TTOD(disc_date)
	oSheet.Cells(lnRows, 8).Value = scharge
	oSheet.Cells(lnRows, 9).Value = sdiscount
	oSheet.Cells(lnRows, 10).Value = snopaid
	oSheet.Cells(lnRows, 11).Value = sbenfpaid
	oSheet.Cells(lnRows, 12).Value = ALLTRIM(indication_admit)
	oSheet.Cells(lnRows, 13).Value = ALLTRIM(diag_plan)
	oSheet.Cells(lnRows, 14).Value = ALLTRIM(snote)+" "+ALLTRIM(note2ins)
	oSheet.Cells(lnRows, 15).Value = tr_acno
ENDCASE
 	
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