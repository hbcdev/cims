PARAMETERS tcTable, tcPath, tcFundCode
IF PARAMETERS() <> 3
	RETURN
ENDIF
*********************************************
*แปลงเป็น Excel แบ่งชีตตาม โรงพยาบาลและ Subtotal ตาม Policy
*
*  tcTable = DBF File ที่ต้องการให้แปลง
*  tcPath = พื้นที่เก็บ xls file 
*  tcFundcode = รหัสบริษัทประกันภัย
*********************************************
SET NOTIFY ON
SET DELETED ON
SET SAFETY OFF
************************
STORE 0 TO lnFee, lnNon
llCloseMember = .F.
SELECT fee FROM cims!fund WHERE fundcode = tcFundCode INTO CURSOR FundFee
IF _TALLY > 0
	lnFee = fundfee.fee/100
	lnNon = 500
ENDIF 
USE IN fundfee
************************	
IF !USED("member")
	USE cims!member IN 0
	llCloseMember = .T.
ENDIF
************************	
SET TALK ON
SELECT not_no, pol_no, name, surname, eff_date, exp_date, type_clm, clm_type, acc_date,;
	admit, disc, hosp_amt, discount, benf_covr, non_cover, IIF(non_cover * lnFee > lnNon, lnNon, non_cover*lnFee) AS non_fee,;
	benf_paid, benf_paid*lnFee AS fee,  exgratia, over_benf,hosp_code,;
	hosp_name, clm_pstat, ret_date, remark, indication, treatment;
FROM (tcTable);
ORDER BY hosp_name DESC , pol_no;
INTO CURSOR curQuery
IF _TALLY = 0
	RETURN
ENDIF 
SET TALK OFF 
*********************
lcRetDate = CMONTH(curquery.ret_date)+" "+ALLTRIM(STR(DAY(curquery.ret_date),2))+","+STR(YEAR(curquery.ret_date),4)
lcTitle = INPUTBOX("Heading ของรายงาน","Heading Input", "CLAIM SUMMARY REPORT OF "+lcRetDate) 
lnSheet = 0
oExcel = CREATEOBJECT("Excel.Application")
IF ISNULL(oExcel)
	=MESSAGEBOX("ไม่ได้ติดตั้ง โปรแกรม Excel", 0, "Error")
	RETURN
ENDIF 	
***********************************
oWorkBook = oExcel.Workbooks.Add()
************
m.att_no = 0
STORE 0 TO lnTotalPaid, lnTotalFee, lnTotalNoPaid , lnTotalNoFee
SELECT curQuery
GO TOP
DO WHILE !EOF()
	lnSheet = lnSheet + 1
	lcHospCode = hosp_code
	lnField = AFIELDS(laFields)
	**************************************************
	oSheet = oWorkBook.WorkSheets.Add
	oSheet.Name = ALLTRIM(hosp_name)
	*******************
	DO SetFormat
	*******************
	lnRow = 2
	STORE 0 TO lnHPaid, lnHfee, lnHNoPaid , lnHNoFee
	DO WHILE hosp_code = lcHospCode AND !EOF()
		STORE 0 TO lnPaid, lnfee, lnNoPaid , lnNoFee
		lcPolicy = pol_no
		DO WHILE pol_no = lcPolicy AND !EOF()	
			WAIT WINDOW hosp_name+" "+TRANSFORM(RECNO(), "@Z 99,999")+" Records" AT 20,44 NOWAIT
			FOR i = 1 TO FCOUNT()
				lcField = FIELD(i)
				lcValue = &lcField
				IF !EMPTY(lcValue)
					oSheet.Cells(lnRow,i) = lcValue
				ENDIF 	
			ENDFOR
			****************************
			lnPaid = lnPaid + benf_paid
			lnFee = lnfee + fee
			lnNoPaid = lnNoPaid + non_cover
			lnNofee = lnNofee + non_fee
			****************************
			lnHPaid = lnHPaid + benf_paid
			lnHFee = lnHfee + fee
			lnHNoPaid = lnHNoPaid + non_cover
			lnHNofee = lnHNofee + non_fee
			****************************
			lnRow = lnRow + 1
			SKIP
		ENDDO 
		IF SEEK(tcFundCode+lcPolicy, "member", "policy_no")
			lcInsure = member.name
		ELSE
			lcInsure = lcPolicy	
		ENDIF 
		********************************
		oSheet.Cells(lnRow,2) = lcInsure
		oSheet.Cells(lnRow,14) = "รวม"
		oSheet.Cells(lnRow,15) = lnNoPaid
		oSheet.Cells(lnRow,16) = lnNoFee
		oSheet.Cells(lnRow,17) = lnPaid
		oSheet.Cells(lnRow,18) = lnFee
		********************************
		lnTotalPaid = lnTotalPaid + lnPaid
		lnTotalNoPaid = lnTotalNoPaid + lnNoPaid
		lnTotalFee = lnTotalFee + lnFee
		lnTotalNoFee = lnTotalNoFee + lnNoFee
		********************************
		lnRow = lnRow + 1
		*****************
		IF !EOF()
			oSheet.Cells(lnRow,1).Select
			oSheet.HPageBreaks.Add(oExcel.ActiveCell)
			oSheet.Select
		ENDIF	
	ENDDO
	oSheet.Cells(lnRow,14) = "รวมทั้งสิ้น"
	oSheet.Cells(lnRow,15) = lnHNoPaid
	oSheet.Cells(lnRow,16) = lnHNoFee
	oSheet.Cells(lnRow,17) = lnHPaid
	oSheet.Cells(lnRow,18) = lnHFee
	*************************
	DO SetLine
	*************************
ENDDO
*************
DO Summary_All
*****************************
lcExcelFile = ADDBS(ALLTRIM(tcPath))+lcTitle
oWorkBook.SaveAs(lcExcelFile)
oExcel.Quit
***********
USE IN curQuery
IF llCloseMember
	USE IN member
ENDIF 	
SET NOTIFY OFF
*****************************************************
PROCEDURE SetFormat
WITH oSheet.PageSetup
	.PrintTitleRows = "$1:$1"
	.PrintTitleColumns = "$A:$A"
      .LeftHeader = lcTitle
	.PaperSize = 5
	.Orientation = 2
	.Zoom = 75
ENDWITH	
********************************
lnFields = AFIELDS(laFields)
FOR i = 1 TO lnField
	oSheet.Cells(1,i) = FIELD(i)
ENDFOR 	
********************************
FOR iField1 = 1 TO lnFields
	lcColumn    = ColumnLetter(iField1)
	lcColumnExpression = ["] + lcColumn + [:] + lcColumn + ["]                                     
	oSheet.Columns(&lcColumnExpression.).Select                             
	****************************************************                                                                              
	DO CASE                                                                      
	CASE (laFields[iField1,2] $ "C.L")
		lcFmtExp = ["@"]
		lnWidth = laFields[iField1,3]
		lnWidth = IIF(lnWidth > 20, 20, lnWidth)
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = lnWidth
	CASE (laFields[iField1,2] $ "M")
		lcFmtExp = ["@"]
		lnWidth = 20
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = lnWidth
	CASE (laFields[iField1,2] $ "N.I.Y")		
      	IF (laFields[iField1,2] $ "Y")      	
	      	lcFmtExp = ["##,##0.00"]    
      	ELSE                              		
            	IF laFields[iField1,4] = 0
	               lcFmtExp = ["0"]               
           		ELSE                              	
	               lcFmtExp = ["0.] + REPLICATE("0", laFields[iField1,4]) + ["]     
     		      ENDIF                                                               
      	ENDIF
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = 8
	CASE (laFields[iField1,2] $ "D.T")  
     		lcFmtExp = ["dd/mm/yyyy"]          
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = 5
	ENDCASE
	oSheet.Columns(&lcColumnExpression.).NumberFormat = &lcFmtExp.
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
*************************************************
PROCEDURE SetLine

osheet.Cells.Borders(7).LineStyle = 1
osheet.Cells.Borders(7).Weight = 2
osheet.Cells.Borders(7).ColorIndex = -4105
osheet.Cells.Borders(8).LineStyle = 1
osheet.Cells.Borders(8).Weight = 2
osheet.Cells.Borders(8).ColorIndex = -4105
osheet.Cells.Borders(9).LineStyle = 1
osheet.Cells.Borders(9).Weight = 2
osheet.Cells.Borders(9).ColorIndex = -4105
osheet.Cells.Borders(10).LineStyle = 1
osheet.Cells.Borders(10).Weight = 2
osheet.Cells.Borders(10).ColorIndex = -4105
osheet.Cells.Borders(11).LineStyle = 1
osheet.Cells.Borders(11).Weight = 2
osheet.Cells.Borders(11).ColorIndex = -4105
osheet.Cells.Borders(12).LineStyle = 1
osheet.Cells.Borders(12).Weight = 2
osheet.Cells.Borders(12).ColorIndex = -4105
oSheet.Range("A1").Select
******************************************
PROCEDURE Summary_All

SELECT pol_no, ;
	SUM(non_cover) AS non_cover, SUM(IIF(non_cover * lnFee > lnNon, lnNon, non_cover*lnFee)) AS non_fee,;
	SUM(benf_paid) AS paid, SUM(benf_paid*lnFee) AS fee ;
FROM (tcTable) ;
GROUP BY pol_no ; 
ORDER BY pol_no ;
INTO CURSOR curSumQuery
IF _TALLY = 0
	RETURN
ENDIF 
SET TALK OFF 
***********************************
oSheet1 = oWorkbook.WorkSheets.Add
oSheet1.Name = "Fee Summary"
WITH oSheet1
	.Select
	.Cells(1,1) = "DETAILS BACK UP FOR THE RETURN DATE "+DTOC(curquery.ret_date)
	.Cells(2,1) = "REF. INVOICE NO."
	.Cells(2,4) = "DATE"
	.Cells(3,1) = "ATTACHMENT"
	.Cells(3,2) = "POLICY NO"
	.Cells(3,3) = "NON COVERED"
	.Cells(3,5) = "BENEFIT PAID"
	.Cells(3,7) = "TOTAL FEE"
	.Cells(3,8) = "VAT 7%"
	.Cells(3,9) = "TOTAL"
	.Cells(4,1) = "NO"
	.Cells(4,3) = "AMOUNT"
	.Cells(4,4) = "FEE%"
	.Cells(4,5) = "AMOUNT"
	.Cells(4,6) = "FEE%"
	.Cells(4,9) = "AMOUNT"
ENDWITH
************
WITH oSheet1
	.Range("B:I").HorizontalAlignment = 3
	.Range("A1:D1").Merge
	.Range("C3:D3").Merge
	.Range("E3:F3").Merge
	.Columns("C:I").NumberFormat = "##,##0.00"
	.Columns("B1:I4").Autofit
ENDWITH 	
***********************************
lnRow1 = 4
lcRow1 = "4"
STORE 0 TO lnTotalPaid, lnTotalFee, lnTotalNoPaid , lnTotalNoFee
SELECT curSumQuery
GO TOP
DO WHILE !EOF()
	lnTotalPaid = lnTotalPaid + paid
	lnTotalNoPaid = lnTotalNoPaid + non_cover
	lnTotalFee = lnTotalFee + fee
	lnTotalNoFee = lnTotalNoFee + non_fee
	***************************************
	m.att_no = m.att_no+1
	lnRow1 = lnRow1 + 1
	WITH oSheet1
		.Cells(lnRow1,1) = m.att_no
		.Cells(lnRow1,2) = pol_no
		.Cells(lnRow1,3) = non_cover
		.Cells(lnRow1,4) = non_fee
		.Cells(lnRow1,5) = paid
		.Cells(lnRow1,6) = fee
		.Cells(lnRow1,7) = "=D"+ALLTRIM(STR(lnRow1))+"+F"+ALLTRIM(STR(lnRow1))
		.Cells(lnRow1,8) = "=G"+ALLTRIM(STR(lnRow1))+"*0.07"
		.Cells(lnRow1,9) = "=G"+ALLTRIM(STR(lnRow1))+"+H"+ALLTRIM(STR(lnRow1))
	ENDWITH
	SKIP 
ENDDO
*****************************
lnRow1 = lnRow1 + 1
WITH oSheet1
	.Cells(lnRow1,2) = "รวม"
	.Cells(lnRow1,3) = lnTotalNoPaid
	.Cells(lnRow1,4) = lnTotalNoFee
	.Cells(lnRow1,5) = lnTotalPaid
	.Cells(lnRow1,6) = lnTotalFee
	.Cells(lnRow1,7) = "=SUM(G"+lcRow+":G"+ALLTRIM(STR(lnRow1-1))+")"
	.Cells(lnRow1,8) = "=SUM(H"+lcRow+":H"+ALLTRIM(STR(lnRow1-1))+")"
	.Cells(lnRow1,9) = "=SUM(I"+lcRow+":I"+ALLTRIM(STR(lnRow1-1))+")"
ENDWITH
***********************************
WITH oSheet1
	.Select
	.Cells.Borders(7).LineStyle = 1
	.Cells.Borders(7).Weight = 2
	.Cells.Borders(7).ColorIndex = -4105
	.Cells.Borders(8).LineStyle = 1
	.Cells.Borders(8).Weight = 2
	.Cells.Borders(8).ColorIndex = -4105
	.Cells.Borders(9).LineStyle = 1
	.Cells.Borders(9).Weight = 2
	.Cells.Borders(9).ColorIndex = -4105
	.Cells.Borders(10).LineStyle = 1
	.Cells.Borders(10).Weight = 2
	.Cells.Borders(10).ColorIndex = -4105
	.Cells.Borders(11).LineStyle = 1
	.Cells.Borders(11).Weight = 2
	.Cells.Borders(11).ColorIndex = -4105
	.Cells.Borders(12).LineStyle = 1
	.Cells.Borders(12).Weight = 2
	.Cells.Borders(12).ColorIndex = -4105
	.Cells(1,1).Select
ENDWITH	
*************************************
