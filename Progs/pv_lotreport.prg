PARAMETERS tcFundCode, tcLotNo
IF EMPTY(tcFundCode) AND EMPTY(tcLotNo)
	RETURN 
ENDIF 	
*
#INCLUDE "include\cims.h"
SET DELETED ON
SET SAFETY OFF
SET PROCEDURE TO progs\utility
*********************
WAIT WINDOW "Query Data ....." NOWAIT 
SELECT claim.pvdate, pv.pv_no, claim.client_name, claim.notify_no, claim.policy_no, pv.amount, pv.wt_amount, ;
	claim.batchno, claim.prov_name, claim.paid_date, claim.tr_acno, claim.tr_name, claim.tr_bank, pv.remarks, claim.insurepaydate ;
FROM cims!claim INNER JOIN cims!pv_notify pv ;
	ON claim.notify_no = pv.notify_no ;
WHERE claim.fundcode = tcFundCode ;
	AND claim.lotno = tcLotNo ;
ORDER BY batchno ;
INTO CURSOR curLot
IF _TALLY < 0
	=MESSAGEBOX("ไม่พบข้อมูลเคลมของ Lot No. "+tcLotNo, 0, "คำเตือน")		
	RETURN 
ENDIF 	
**************************************
lnRows = 4
lcFilePath = ADDBS(gcTemp)+ALLTRIM(tcFundCode)+"\"+tcLotNo
IF !DIRECTORY(lcFilePath)
	MKDIR &lcFilePath
ENDIF 
lcFile = ADDBS(lcFilePath)+"Pv_Report_LotNo_"+tcLotNo	
******************************************************
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()	
oSheet = oWorkBook.WorkSheets.Add()
**************************
DO LotHeading
**************************
SELECT curLot
GO TOP
DO WHILE !EOF()
	WAIT WINDOW batchno NOWAIT
	STORE 0 TO lnCount, lnPaid, lnAmount, lnTax, lnSumAmt, lnSumPaid
	**********************************************
	lcBatchNo = batchno
	lcProvName = ALLTRIM(prov_name)
	lcTrNo = ALLTRIM(tr_acno)
	lcTrName = ALLTRIM(tr_Name)
	lcTrBank = ALLTRIM(tr_bank)
	ldTrDate = paid_date
	DO WHILE batchno = lcBatchNo AND !EOF()
		lnCount = lnCount + 1	
		DO LotDetail
		*
		lnSumAmt = lnSumAmt + 1
		lnSumPaid = lnSumPaid + amount
		lnAmount = lnAmount + amount
		lnTax = lnTax + wt_amount
		lnPaid = lnPaid + (amount - wt_amount)
		lnRows = lnRows + 1
		SKIP 		
	ENDDO 	
	*	
	IF LEFT(tcLotNo,1) = "C"
		oSheet.Cells(lnRows,5) = "Batch No: "+lcBatchNo
		oSheet.Cells(lnRows,6) = "โรงพยาบาล "+lcProvName
		oSheet.Cells(lnRows,10) = lnAmount
		oSheet.Cells(lnRows,11) = lnTax
		oSheet.Cells(lnRows,12) = lnPaid
		oSheet.Cells(lnRows,14).Value = lcTrNo
		oSheet.Cells(lnRows,15).Value = lcTrName
		oSheet.Cells(lnRows,16).Value = lcTrBank		
	ELSE 
		oSheet.Cells(lnRows,5) = "Batch No: "+lcBatchNo
		oSheet.Cells(lnRows,6) = STRTRAN(DTOC(ldTrDate), "/", "-")
		oSheet.Cells(lnRows,10) = lnAmount
	ENDIF 	
	lnRows = lnRows + 1	
	*************************************************
ENDDO
oSheet.Cells(lnRows,6) = "ยอดรวมทั้งสิ้น "
oSheet.Cells(lnRows,10) = "=SUM(J4:J"+ALLTRIM(STR(lnRows-1))+")"
IF LEFT(tcLotNo,1) = "C"
	oSheet.Cells(lnRows,11) = "=SUM(K4:K"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,12) = "=SUM(L4:L"+ALLTRIM(STR(lnRows-1))+")"
ENDIF 	
*
oWorkBook.SaveAs(lcFile)
oExcel.Quit

=MESSAGEBOX("Generate Report file to "+lcFile+" Finished...", 0, "Warning")
*****************************************************
PROCEDURE LotHeading
LPARAMETERS tcLotNo

WITH oSheet
	.Range("A1").Value = "บริษัท ไทยพาณิชย์สามัคคี ประกันภัย จำกัด"	
	.PageSetup.Orientation = xlLandscape
	.PageSetup.LeftMargin = 2.5
	.PageSetup.RightMargin = 1.5
	.PageSetup.TopMargin = 1.3
	.PageSetup.BottomMargin = 1.3
	.PageSetup.Zoom = 63	
	.PageSetup.PrintTitleRows = "$1:$4"
       .PageSetup.PrintTitleColumns = ""
       .PageSetup.LeftHeader = ""
       .PageSetup.CenterHeader = ""
       .PageSetup.RightHeader = ""
       .PageSetup.LeftFooter = ""
       .PageSetup.CenterFooter = ""
       .PageSetup.RightFooter = ""	
	.Range("A3:O3").RowHeight = 20	
	.Range("A1:E1").MergeCells = .T.
	.Range("A1:D1").Font.Size = 14
	.Range("A1:D1").Font.Bold = .T.	
	.Range("A2:D2").MergeCells = .T.
	.Range("A2:D2").Font.Size = 14
	.Range("A2:D2").Font.Bold = .T.
ENDWITH 	
oSheet.Name = tcLotno
oSheet.Cells(1,12).Value = "Lot No."
oSheet.Cells(1,13).Value = tcLotNo
oSheet.Cells(2,12).Value = "กำหนดจ่าย วันที่"
oSheet.Cells(2,13).Value = insurepaydate
oSheet.Cells(2, 1).Value = "รายงานสรุปการเบิกค่าใช้จ่ายในการจ่ายค่ารักษาพยาบาลให้กับลูกค้า" 
oSheet.Cells(3, 1).Value = "No."
oSheet.Cells(3, 2).Value = "Pv Date"
oSheet.Cells(3, 3).Value = "Pv No"
oSheet.Cells(3, 4).Value = "ชื่อ-นามสกุล"
oSheet.Cells(3, 5).Value = "Notify No"
oSheet.Cells(3, 6).Value = "เลขกรมธรรม์ "
oSheet.Cells(3, 7).Value = "ยอดจ่าย"
oSheet.Cells(3, 8).Value = "ภาษี"
oSheet.Cells(3, 9).Value = "ยอดจ่ายสุทธิ"
oSheet.Cells(3,10).Value = "ยอดจ่าย"
oSheet.Cells(3,11).Value = "ภาษี"
oSheet.Cells(3,12).Value = "ยอดจ่ายสุทธิ"
oSheet.Cells(3,13).Value = "ค่าธรรมเนียมการโอน"
oSheet.Cells(3,14).Value = "โอนเข้าบัญชี เลขที่"
oSheet.Cells(3,15).Value = "ชื่อบัญชี"
oSheet.Cells(3,16).Value = "ธนาคาร"
oSheet.Cells(3,17).Value = "Invoice"
*		
oSheet.Range("L1:L3").HorizontalAlignment = xlRight
oSheet.Range("M1:M3").HorizontalAlignment = xlLeft	
oSheet.Range("G:M").NumberFormat = "#,##0.00"
oSheet.Range("A:A").ColumnWidth = 10
oSheet.Range("B:P").ColumnWidth = 15
oSheet.Range("D:D").ColumnWidth = 20
 	
ENDPROC 
*********************************************************
PROCEDURE LotDetail

oSheet.Cells(lnRows, 1).Value = lnCount
oSheet.Cells(lnRows, 2).Value = pvdate
oSheet.Cells(lnRows, 3).Value = "'"+ALLTRIM(pv_no)
oSheet.Cells(lnRows, 4).Value = ALLTRIM(client_name)
oSheet.Cells(lnRows, 5).Value = "'"+notify_no
oSheet.Cells(lnRows, 6).Value = "=TEXT("+ALLTRIM(policy_no)+",0)"
oSheet.Cells(lnRows, 7).Value = amount
oSheet.Cells(lnRows, 8).Value = wt_amount
oSheet.Cells(lnRows, 9).Value = amount-wt_amount
oSheet.Cells(lnRows,17).Value = ALLTRIM(remarks)
IF LEFT(tcLotNo,1) = "R"
	oSheet.Cells(lnRows,14).Value = "'"+tr_acno
	oSheet.Cells(lnRows,15).Value = tr_name
	oSheet.Cells(lnRows,16).Value = tr_bank
	oSheet.Cells(lnRows,18).Value = IIF(EMPTY(paid_date), "", paid_date)
ENDIF 	
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