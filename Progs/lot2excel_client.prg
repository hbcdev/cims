*this program for print reimbuest cover report 
PARAMETERS tcFundcode, tcLotNo, tcSaveTo, tdReturnDate, tnType

IF EMPTY(tcFundCode) AND EMPTY(tcLotNo) AND EMPTY(tcSaveTo)
	RETURN 
ENDIF 
IF tnType <> 1
	=MESSAGEBOX("ไม่สามารถทำงานได้ เนื่องจากเลือกส่งออกข้อมูลการจ่ายโรงพยาบาล",0,"Error")
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
SELECT fund.thainame AS fundname, claim.prov_name, claim.policy_no, claim.notify_no, claim.notify_date, firstchr(claim.prov_name) AS "first", ; 	
	claim.client_no, claim.client_name, claim.service_type, claim.admis_date, claim.disc_date, claim.scharge, claim.sdiscount, claim.inv_page AS paytype, ;
	claim.snopaid, claim.sbenfpaid+claim.abenfpaid AS sbenfpaid, claim.snote, claim.indication_admit, claim.result, claim.diag_plan, claim.return_date, claim.acc_date, ;
	claim.note2ins, claim.tr_acno, claim.tr_name, claim.paid_date, claim.lotno, claim.batchno, claim.insurepaydate, claim.senddate ;
FROM cims!claim LEFT JOIN cims!fund ;
	ON claim.fundcode = fund.fundcode ;
WHERE claim.fundcode= tcFundCode ;
	AND claim.lotno = tcLotNo ;
	AND claim.appr = .T. ;
ORDER BY claim.batchno, claim.pvno ;
INTO CURSOR curLot
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
ldReturnDate = paid_date
*
lcFile = ADDBS(lcFilePath)+"Claim_LotNo_"+ALLTRIM(tcLotNo)
*
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
	oSheet.Cells(lnRows,11).Value = "ยอดจ่ายรวมทั้งสิ้น"
	oSheet.Cells(lnRows,12).Value = TRANSFORM(lnPaid, "@Z 99,999,999.99")
	*				
	lcRow = ["3:]+ALLTRIM(STR(lnRows-1))+["]
	lcRange = ["A4:P]+ALLTRIM(STR(lnRows-1))+["]
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
	lcSumRange = ["B]+ALLTRIM(STR(lnRows))+[:B]+ALLTRIM(STR(lnRows))+["]
	oSheet.Range(&lcSumRange).NumberFormat = "#,##0.00"
	oSheet.Cells(lnRows, 1).Value = "ยอดจ่ายสะสมรวมทั้งสิ้น"
	oSheet.Cells(lnRows, 2).Value = IIF(EMPTY(lcOldPaid), lnTotalPaid, "="+lcOldPaid+" + " + STR(lnPaid))  && TRANSFORM(lnTotalPaid, "@Z 9,999,999.99")
	*
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

WITH oSheet
	.Range("A1").Value = fundname
	
	.PageSetup.Orientation = xlLandscape
	.PageSetup.LeftMargin = 2.5
	.PageSetup.RightMargin = 1.5
	.PageSetup.TopMargin = 1.3
	.PageSetup.BottomMargin = 1.3
	.PageSetup.Zoom = 52
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
oSheet.Name = ALLTRIM(batchno)
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
oSheet.Cells(4, 6).Value = "วันที่เกิดเหตุ"
oSheet.Cells(4, 7).Value = "วันที่เข้ารักษา"
oSheet.Cells(4, 8).Value = "วันที่ออกจาก รพ."
oSheet.Cells(4, 9).Value = "โรงพยาบาลเรียกเก็บ"
oSheet.Cells(4, 10).Value = "ส่วนลดจากโรงพยาบาล"
oSheet.Cells(4, 11).Value = "ยอดไม่คุ้มครอง"
oSheet.Cells(4, 12).Value = "ยอดจ่าย"
oSheet.Cells(4, 13).Value = "สาเหตุที่เข้ารักษา"
oSheet.Cells(4, 14).Value = "การรักษาเบื้องต้น"
oSheet.Cells(4, 15).Value = "หมายเหตุ"
*
oSheet.Range("N1:N3").HorizontalAlignment = xlRight
oSheet.Range("O1:O3").HorizontalAlignment = xlLeft		
oSheet.Range("I:L").NumberFormat = "#,##0.00"
oSheet.Range("A:R").ColumnWidth = 14
oSheet.Range("B:B").ColumnWidth = 16	
oSheet.Range("C:C").ColumnWidth = 20
oSheet.Range("E:E").ColumnWidth = 20	
oSheet.Range("F:H").ColumnWidth = 15	
oSheet.Range("M:O").ColumnWidth = 25
oSheet.Range("Q:R").ColumnWidth = 10
oSheet.Range("A:S").WrapText = .T.	

ENDPROC 
*********************************************************
PROCEDURE LotDetail

oSheet.Cells(lnRows, 1).Value = [']+notify_no
oSheet.Cells(lnRows, 2).Value = [']+ALLTRIM(client_no)
oSheet.Cells(lnRows, 3).Value = ALLTRIM(client_name)
oSheet.Cells(lnRows, 4).Value = service_type
oSheet.Cells(lnRows, 5).Value = ALLTRIM(STRTRAN(prov_name, "(A)", ""))
oSheet.Cells(lnRows, 6).Value = TTOD(acc_date)
oSheet.Cells(lnRows, 7).Value = TTOD(admis_date)
oSheet.Cells(lnRows, 8).Value = TTOD(disc_date)
oSheet.Cells(lnRows, 9).Value = scharge
oSheet.Cells(lnRows, 10).Value = sdiscount
oSheet.Cells(lnRows, 11).Value = snopaid
oSheet.Cells(lnRows, 12).Value = sbenfpaid
oSheet.Cells(lnRows, 13).Value = ALLTRIM(indication_admit)
oSheet.Cells(lnRows, 14).Value = ALLTRIM(diag_plan)
oSheet.Cells(lnRows, 15).Value = ALLTRIM(STRTRAN(snote, CHR(13), " "))+" "+ALLTRIM(STRTRAN(note2ins, CHR(13), " "))
 	
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