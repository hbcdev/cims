PARAMETERS tcFundCode, tcLotNo, tcSaveTo, tnType
IF EMPTY(tcFundCode) AND EMPTY(tcLotNo) 
	RETURN 
ENDIF 	
**
IF tnType <> 2
	=MESSAGEBOX("ไม่สามารถทำงานได้ เนื่องจากเลือกส่งออกข้อมูลการจ่ายลูกค้า",0,"Error")
	RETURN 
ENDIF 	

IF EMPTY(tcSaveTo)
	lcSaveTo = tcSaveTo
ELSE 
	lcSaveTo = ADDBS(gcTemp)+ALLTRIM(tcFundCode)
ENDIF 		
*
#INCLUDE "include\cims.h"
SET DELETED ON
SET SAFETY OFF
SET PROCEDURE TO progs\utility
************************************************
WAIT WINDOW "Query Data ....." NOWAIT 
IF tcFundCode = "SMG"
	SELECT claim.notify_no, claim.policy_no, claim.family_no, claim.client_name, ;
		firstChr(claim.prov_name) AS "first", claim.sbenfpaid+claim.abenfpaid AS sbenfpaid, ;
		((claim.sbenfpaid+claim.abenfpaid) * provider.wt)/100 AS wt_amount, ;
		claim.batchno, claim.prov_id, STRTRAN(claim.prov_name, "(A)", "") AS prov_name, ;
		claim.refno, claim.paid_date, claim.tr_acno, claim.tr_name, claim.tr_bank, ;
		claim.insurepaydate,  claim.lotno, ;
		provider.account_no, provider.acc_name, provider.bankcode, provider.bank, provider.wt ;
	FROM cims!claim LEFT JOIN cims!provider ;
		ON claim.prov_id = provider.prov_id ;
	WHERE claim.fundcode = tcFundCode ;
		AND claim.lotno = tcLotNo ;	
		AND claim.appr = .T. ;
	ORDER BY 5, claim.prov_id, claim.batchno ;
	INTO CURSOR curLot
ELSE 
	SELECT claim.notify_no, claim.policy_no, claim.family_no, claim.client_name, ;
		firstChr(claim.prov_name) AS "first", claim.sbenfpaid+claim.abenfpaid AS sbenfpaid, ;
		((claim.sbenfpaid+claim.abenfpaid) * provider.wt)/100 AS wt_amount, ;
		claim.batchno, claim.prov_id, STRTRAN(claim.prov_name, "(A)", "") AS prov_name, ;
		claim.refno, claim.paid_date, claim.tr_acno, claim.tr_name, claim.tr_bank, ;
		claim.insurepaydate,  claim.lotno, ;
		provider.account_no, provider.acc_name, provider.bankcode, provider.bank, provider.wt ;
	FROM cims!claim LEFT JOIN cims!provider ;
		ON claim.prov_id = provider.prov_id ;
	WHERE claim.fundcode = tcFundCode ;
		AND claim.lotno = tcLotNo ;	
	ORDER BY 5, claim.prov_id, claim.batchno ;
	INTO CURSOR curLot
ENDIF 	
*
IF _TALLY = 0
	=MESSAGEBOX("ไม่พบข้อมูลเคลมของ Lot No. "+tcLotNo, 0, "คำเตือน")		
	RETURN 
ENDIF 	
*
lcFundName = tcFundCode
SELECT thainame FROM cims!fund WHERE fundcode = tcFundCode INTO ARRAY aFund
IF _TALLY > 0
	lcFundName = aFund[1]
ENDIF 	
**************************************
lnRows = 4
lcFilePath = ADDBS(lcSaveTo)+ALLTRIM(tcLotNo)
IF !DIRECTORY(lcFilePath)
	MKDIR &lcFilePath
ENDIF 
lcFile = ADDBS(lcFilePath)+"Pv_Report_LotNo_"+ALLTRIM(tcLotNo)	
******************************************************
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()	
oSheet = oWorkBook.WorkSheets.Add()
*
SELECT curLot
GO TOP
**************************
DO LotHeading
**************************
DO WHILE !EOF()
	WAIT WINDOW prov_name NOWAIT
	STORE 0 TO lnCount, lnPaid, lnAmount, lnTax, lnSumAmt, lnSumPaid
	**********************************************
	lcFirst = first
	lcProvID = prov_id
	lcProvName = ALLTRIM(prov_name)
	lcTrNo = [']+ALLTRIM(account_no)
	lcTrName = ALLTRIM(acc_name)
	lcTrBank = ALLTRIM(bank)
	ldTrDate = paid_date
	DO WHILE first = lcFirst AND prov_id = lcProvID AND !EOF()
		lnCount = lnCount + 1	
		DO LotDetail
		*
		lnSumAmt = lnSumAmt + 1
		lnSumPaid = lnSumPaid + sbenfpaid
		lnAmount = lnAmount + sbenfpaid
		lnTax = lnTax + wt_amount
		lnPaid = lnPaid + (sbenfpaid - wt_amount)
		lnRows = lnRows + 1
		SKIP 		
	ENDDO 	
	*	
	oSheet.Cells(lnRows, 5) = "โรงพยาบาล "+lcProvName
	oSheet.Cells(lnRows, 9) = lnAmount
	oSheet.Cells(lnRows, 10) = lnTax
	*
	IF lnPaid > 100000
		oSheet.Cells(lnRows, 11) = lnPaid/2
		oSheet.Cells(lnRows, 12) = 10
		lnRows = lnRows + 1
		oSheet.Cells(lnRows, 11) = lnPaid/2
		oSheet.Cells(lnRows, 12) = 10
	ELSE 
		oSheet.Cells(lnRows, 11) = lnPaid				
		oSheet.Cells(lnRows, 12) = 10
	ENDIF 
	*	
	oSheet.Cells(lnRows,13).Value = lcTrNo
	oSheet.Cells(lnRows,14).Value = lcTrName
	oSheet.Cells(lnRows,15).Value = lcTrBank		
	*
	lnRows = lnRows + 1	
	*************************************************
ENDDO
oSheet.Cells(lnRows,8) = "Total "
oSheet.Cells(lnRows,9) = "=SUM(I4:I"+ALLTRIM(STR(lnRows-1))+")"
oSheet.Cells(lnRows,10) = "=SUM(J4:J"+ALLTRIM(STR(lnRows-1))+")"
oSheet.Cells(lnRows,11) = "=SUM(K4:K"+ALLTRIM(STR(lnRows-1))+")"
oSheet.Cells(lnRows,12) = "=SUM(L4:L"+ALLTRIM(STR(lnRows-1))+")"	
*
oWorkBook.SaveAs(lcFile)
oExcel.Quit

=MESSAGEBOX("Generate Report file to "+lcFile+" Finished...", 0, "Warning")
*****************************************************
PROCEDURE LotHeading
LPARAMETERS tcLotNo


WITH oSheet
	.Range("A1").Value = lcFundName
	.PageSetup.Orientation = xlLandscape
	.PageSetup.LeftMargin = 2.5
	.PageSetup.RightMargin = 1
	.PageSetup.TopMargin = 1.5
	.PageSetup.BottomMargin = 1.5
	.PageSetup.Zoom = 55
	.PageSetup.PrintTitleRows = "$1:$3"
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
oSheet.Name = lotno
oSheet.Cells(1,12).Value = "Lot No."
oSheet.Cells(1,13).Value = lotno
oSheet.Cells(2,12).Value = "กำหนดจ่าย วันที่"
oSheet.Cells(2,13).Value = insurepaydate
oSheet.Cells(2, 1).Value = "รายงานสรุปการเบิกค่าใช้จ่ายในการจ่ายค่ารักษาพยาบาลให้กับโรงพยาบาล" 
oSheet.Cells(3, 1).Value = "No."
oSheet.Cells(3, 2).Value = "Hospital"
oSheet.Cells(3, 3).Value = "Client Name"
oSheet.Cells(3, 4).Value = "Notify No"
oSheet.Cells(3, 5).Value = "Policy No"
oSheet.Cells(3, 6).Value = "Amount"
oSheet.Cells(3, 7).Value = "Tax"
oSheet.Cells(3, 8).Value = "Paid"
oSheet.Cells(3,9).Value = "Amount"
oSheet.Cells(3,10).Value = "Tax"
oSheet.Cells(3,11).Value = "Paid"
oSheet.Cells(3,12).Value = "Bank charge"
oSheet.Cells(3,13).Value = "tr_acno"
oSheet.Cells(3,14).Value = "tr_accname"
oSheet.Cells(3,15).Value = "tr_bank"
oSheet.Cells(3,16).Value = "Invoice No"
oSheet.Cells(3,17).Value = "Batch No"
*		
oSheet.Range("L1:L3").HorizontalAlignment = xlRight
oSheet.Range("M1:M3").HorizontalAlignment = xlLeft	
oSheet.Range("F:L").NumberFormat = "#,##0.00"
oSheet.Range("A:A").ColumnWidth = 5
oSheet.Range("D:P").ColumnWidth = 15
oSheet.Range("B:C").ColumnWidth = 24
oSheet.Range("E:E").ColumnWidth = 30
oSheet.Range("N:N").ColumnWidth = 30
oSheet.Range("O:O").ColumnWidth = 27
oSheet.Range("B:O").ShrinkToFit = .T.
* 	
ENDPROC 
*********************************************************
PROCEDURE LotDetail

oSheet.Cells(lnRows, 1).Value = lnCount
oSheet.Cells(lnRows, 2).Value = ALLTRIM(prov_name)
oSheet.Cells(lnRows, 3).Value = ALLTRIM(client_name)
oSheet.Cells(lnRows, 4).Value = [']+notify_no
oSheet.Cells(lnRows, 5).Value = [']+ALLTRIM(policy_no)
oSheet.Cells(lnRows, 6).Value = sbenfpaid
oSheet.Cells(lnRows, 7).Value = wt_amount
oSheet.Cells(lnRows, 8).Value = sbenfpaid-wt_amount
oSheet.Cells(lnRows,16).Value = ALLTRIM(refno)
oSheet.Cells(lnRows,17).Value = ALLTRIM(batchno)
 	
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