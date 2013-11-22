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
SET TALK ON
SELECT IIF(bro_no $ "IP", "", pol_no) AS pgrp, not_no, not_date, clm_no, pol_no, cust_id, name, surname, eff_date, exp_date, plan, type_clm, clm_type, acc_date, ;
	admit, disc, hosp_amt, discount, benf_covr, non_cover, benf_paid, over_benf,	hosp_name, ill_name, icd_10, icd10_2, ;
	clm_pstat, remark, indication, treatment, ret_date  ;
FROM (tcTable) ;
ORDER BY clm_pstat, hosp_name DESC , 1, pol_no ;
INTO CURSOR curQuery
IF _TALLY = 0
	RETURN
ENDIF 
SET TALK OFF 
**********************
lcRetDate = CMONTH(curquery.ret_date)+" "+ALLTRIM(STR(DAY(curquery.ret_date),2))+","+STR(YEAR(curquery.ret_date),4)
lnSheet = 0
oExcel = CREATEOBJECT("Excel.Application")
IF ISNULL(oExcel)
	=MESSAGEBOX("ไม่ได้ติดตั้ง โปรแกรม Excel", 0, "Error")
	RETURN
ENDIF 	
***********************************
oWorkBook = oExcel.Workbooks.Add()
m.att_no = 0
m.retdate = curquery.ret_date
****************
DO SheetP1
DO SheetP5
*********************************
*
PROCEDURE SheetP1
*

SELECT * FROM curQuery WHERE clm_pstat = "P5" INTO CURSOR curP1

IF _TALLY = 0
	RETURN 
ENDIF 	

SELECT curP1
GO TOP
oSheet = oWorkBook.WorkSheets(1)
oSheet.Name = "ทำจ่ายลูกค้า"
*******************
DO SetFormat
*******************
lnRow = 2
DO WHILE !EOF()
	WAIT WINDOW hosp_name NOWAIT
	lcPgrp = pgrp
	oSheet.Cells(lnRow, 1).Value = lcPgrp
	lnRow = lnRow + 1		
	DO WHILE pgrp = lcPgrp AND !EOF()
		m.pol_no = pol_no
		DO WHILE pgrp = lcPgrp AND pol_no = m.pol_no AND !EOF()	
			WAIT WINDOW hosp_name+" "+TRANSFORM(RECNO(), "@Z 99,999")+" Records" AT 30,50 NOWAIT
			WITH oSheet
				.Cells(lnRow, 1).value = not_no
				.Cells(lnRow, 2).value = not_date
				.Cells(lnRow, 3).value = clm_no
				.Cells(lnRow, 4).value = pol_no
				.Cells(lnRow, 5).value = cust_id
				.Cells(lnRow, 6).value = name
				.Cells(lnRow, 7).value = surname
				.Cells(lnRow, 8).value = eff_date
				.Cells(lnRow, 9).value = exp_date
				.Cells(lnRow, 10).value = plan
				.Cells(lnRow, 11).value = type_clm
				.Cells(lnRow, 12).value = clm_type
				.Cells(lnRow, 13).value = admit
				.Cells(lnRow, 14).value = disc
				.Cells(lnRow, 15).value = hosp_amt
				.Cells(lnRow, 16).value = discount
				.Cells(lnRow, 17).value = benf_covr
				.Cells(lnRow, 18).value = non_cover
				.Cells(lnRow, 19).value = benf_paid
				.Cells(lnRow, 20).value = over_benf
				.Cells(lnRow, 21).value = hosp_name
				.Cells(lnRow, 22).value = ill_name
				.Cells(lnRow, 23).value = icd_10
				.Cells(lnRow, 23).value = icd10_2
				.Cells(lnRow, 23).value = clm_pstat
			ENDWITH 
			WITH oSheet
				.Cells(lnRow, 1).value = indication
				.Cells(lnRow, 2).value = treatment
			ENDWITH 				
			
			
			lnRow = lnRow + 1
			SKIP
		ENDDO 
		
		IF SEEK(tcFundCode+m.pol_no, "member", "policy_no")
			lcInsure = member.name
		ELSE
			lcInsure = m.pol_no
		ENDIF 
		********************************
		oSheet.Cells(lnRow,2) = lcInsure
		oSheet.Cells(lnRow,14) = "รวม"
		oSheet.Cells(lnRow,15) = m.nopaid
		oSheet.Cells(lnRow,16) = m.nofee
		oSheet.Cells(lnRow,17) = m.paid
		oSheet.Cells(lnRow,18) = m.fee
		********************************
		lnRow = lnRow + 1
		*****************
		m.att_no = m.att_no+1
		oSheet.Cells(lnRow,1).Select
		oSheet.HPageBreaks.Add(oExcel.ActiveCell)
		************************************
		INSERT INTO sumquery FROM MEMVAR 
		************************************
		oSheet.Select
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
*****************************
DO Print_sum
**************
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
PROCEDURE SheetP5
*

SELECT * FROM curQuery WHERE clm_pstat = "P5" INTO CURSOR curP1

IF _TALLY = 0
	RETURN 
ENDIF 
	

SELECT curP1
GO TOP
oSheet = oWorkBook.WorkSheets(1)
oSheet.Name = "ทำจ่ายลูกค้า"
*******************
DO SetFormat
*******************
lnRow = 2
DO WHILE !EOF()
	WAIT WINDOW hosp_name NOWAIT
	DO WHILE hosp_code = lcHospCode AND !EOF()
		m.pol_no = pol_no
		
		oSheet.Cells(lnRow, 1).Value = hosp_name
		lnRow = lnRow + 1	
		
		
		
			
		DO WHILE hosp_code = lcHospCode AND pol_no = m.pol_no AND !EOF()	
			WAIT WINDOW hosp_name+" "+TRANSFORM(RECNO(), "@Z 99,999")+" Records" AT 30,50 NOWAIT
			FOR i = 1 TO FCOUNT()
				lcField = FIELD(i)
				lcValue = &lcField
				IF !EMPTY(lcValue)
					oSheet.Cells(lnRow,i).Value = lcValue
				ENDIF 	
			ENDFOR
			****************************
			m.paid = m.paid + benf_paid
			m.fee = m.fee + fee
			m.nopaid = m.nopaid + non_cover
			m.nofee = m.nofee + non_fee
			****************************
			lnHPaid = lnHPaid + benf_paid
			lnHFee = lnHfee + fee
			lnHNoPaid = lnHNoPaid + non_cover
			lnHNofee = lnHNofee + non_fee
			****************************
			lnRow = lnRow + 1
			SKIP
		ENDDO 
		IF SEEK(tcFundCode+m.pol_no, "member", "policy_no")
			lcInsure = member.name
		ELSE
			lcInsure = m.pol_no
		ENDIF 
		********************************
		oSheet.Cells(lnRow,2) = lcInsure
		oSheet.Cells(lnRow,14) = "รวม"
		oSheet.Cells(lnRow,15) = m.nopaid
		oSheet.Cells(lnRow,16) = m.nofee
		oSheet.Cells(lnRow,17) = m.paid
		oSheet.Cells(lnRow,18) = m.fee
		********************************
		lnRow = lnRow + 1
		*****************
		m.att_no = m.att_no+1
		oSheet.Cells(lnRow,1).Select
		oSheet.HPageBreaks.Add(oExcel.ActiveCell)
		************************************
		INSERT INTO sumquery FROM MEMVAR 
		************************************
		oSheet.Select
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
*****************************
DO Print_sum
**************
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
*********************************
PROCEDURE Print_sum

oSheet1 = oWorkbook.WorkSheets.Add
oSheet1.Name = "Cover Sheet"
************
WITH oSheet1
      .PageSetup.LeftHeader = "Cover Sheet"
	.PageSetup.Zoom = 75
	.Columns("C:I").NumberFormat = "##,##0.00"
ENDWITH 	
***********************************
SELECT sumquery
INDEX ON branch+pol_no TAG polno
SET ORDER TO polno
GO TOP 
lnRow1 = 1
DO WHILE !EOF()
	DO Sum_heading
	lnRow1 = lnRow1 + 4
	lnSumRow = lnRow1
	m.att_no = 0
	m.branch = branch
	DO WHILE branch = m.branch AND !EOF()
		m.att_no = m.att_no + 1
		WITH oSheet1
			.Cells(lnRow1,1) = m.att_no
			.Cells(lnRow1,2) = pol_no
			.Cells(lnRow1,3) = nopaid
			.Cells(lnRow1,4) = nofee
			.Cells(lnRow1,5) = paid
			.Cells(lnRow1,6) = fee
			.Cells(lnRow1,7) = "=D"+ALLTRIM(STR(lnRow1))+"+F"+ALLTRIM(STR(lnRow1))
			.Cells(lnRow1,8) = "=G"+ALLTRIM(STR(lnRow1))+"*0.07"
			.Cells(lnRow1,9) = "=G"+ALLTRIM(STR(lnRow1))+"+H"+ALLTRIM(STR(lnRow1))
		ENDWITH
		lnRow1 = lnRow1 + 1
		SKIP
	ENDDO
	****************************************************
	lcCsum = lcCsum+"C"+ALLTRIM(STR(lnRow1-1))+"+"
	lcDsum = lcDsum+"D"+ALLTRIM(STR(lnRow1-1))+"+"
	lcEsum = lcEsum+"E"+ALLTRIM(STR(lnRow1-1))+"+"
	lcFsum = lcFsum+"F"+ALLTRIM(STR(lnRow1-1))+"+"
	lcGsum = lcGsum+"G"+ALLTRIM(STR(lnRow1-1))+"+"
	lcHsum = lcHsum+"H"+ALLTRIM(STR(lnRow1-1))+"+"
	lcIsum = lcIsum+"I"+ALLTRIM(STR(lnRow1-1))+"+"
	****************************************************
	lcC = "C"+ALLTRIM(STR(lnSumRow))+":C"+ALLTRIM(STR(lnRow1-1))
	lcD = "D"+ALLTRIM(STR(lnSumRow))+":D"+ALLTRIM(STR(lnRow1-1))
	lcE = "E"+ALLTRIM(STR(lnSumRow))+":E"+ALLTRIM(STR(lnRow1-1))
	lcF = "F"+ALLTRIM(STR(lnSumRow))+":F"+ALLTRIM(STR(lnRow1-1))
	lcG = "G"+ALLTRIM(STR(lnSumRow))+":G"+ALLTRIM(STR(lnRow1-1))
	lcH = "H"+ALLTRIM(STR(lnSumRow))+":H"+ALLTRIM(STR(lnRow1-1))
	lcI = "I"+ALLTRIM(STR(lnSumRow))+":I"+ALLTRIM(STR(lnRow1-1))
	WITH oSheet1
		.Cells(lnRow1,2) = "รวม"
		.Cells(lnRow1,3) = [=SUM(&lcC)] &&lnTotalNoPaid
		.Cells(lnRow1,4) = [=SUM(&lcD)] &&lnTotalNoFee
		.Cells(lnRow1,5) = [=SUM(&lcE)] &&lnTotalPaid
		.Cells(lnRow1,6) = [=SUM(&lcF)] &&lnTotalFee
		.Cells(lnRow1,7) = [=SUM(&lcG)] &&lnTotalNoPaid
		.Cells(lnRow1,8) = [=SUM(&lcH)] &&lnTotalNoFee
		.Cells(lnRow1,9) = [=SUM(&lcI)] &&lnTotalPaid
	ENDWITH
	lnRow1 = lnRow1 + 3
	oSheet1.Cells(lnRow1,1).Select
	oSheet1.HPageBreaks.Add(oExcel.ActiveCell)
	oSheet1.Select
ENDDO 	
*
lcCsum = LEFT(lcCsum, LEN(lcCsum)-1)
lcDsum = LEFT(lcDsum, LEN(lcDsum)-1)
lcEsum = LEFT(lcEsum, LEN(lcEsum)-1)
lcFsum = LEFT(lcFsum, LEN(lcFsum)-1)
lcGsum = LEFT(lcGsum, LEN(lcGsum)-1)
lcHsum = LEFT(lcHsum, LEN(lcHsum)-1)
lcIsum = LEFT(lcIsum, LEN(lcIsum)-1)
*
lnRow1 = lnRow1 + 1
WITH oSheet1
	.Cells(lnRow1,2) = "รวมทั้งหมด"
	.Cells(lnRow1,3) = "="+lcCsum
	.Cells(lnRow1,4) = "="+lcDsum
	.Cells(lnRow1,5) = "="+lcEsum
	.Cells(lnRow1,6) = "="+lcFsum
	.Cells(lnRow1,7) = "="+lcGsum
	.Cells(lnRow1,8) = "="+lcHsum
	.Cells(lnRow1,9) = "="+lcIsum
ENDWITH
*
*
PROCEDURE Sum_border
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
***********************
PROCEDURE Sum_heading

WITH oSheet1
	.Cells(lnRow1,1) = "DETAILS BACK UP FOR THE RETURN DATE "+DTOC(m.retdate)
	.Cells(lnRow1+1,1) = "REF. INVOICE NO."
	.Cells(lnRow1+1,4) = "DATE"
	.Cells(lnRow1+2,1) = "ATTACHMENT"
	.Cells(lnRow1+2,2) = "POLICY NO"
	.Cells(lnRow1+2,3) = "NON COVERED"
	.Cells(lnRow1+2,5) = "BENEFIT PAID"
	.Cells(lnRow1+2,7) = "TOTAL FEE"
	.Cells(lnRow1+2,8) = "VAT 7%"
	.Cells(lnRow1+2,9) = "TOTAL"
	.Cells(lnRow1+3,1) = "NO"
	.Cells(lnRow1+3,3) = "AMOUNT"
	.Cells(lnRow1+3,4) = "FEE%"
	.Cells(lnRow1+3,5) = "AMOUNT"
	.Cells(lnRow1+3,6) = "FEE%"
	.Cells(lnRow1+3,9) = "AMOUNT"
	.Range("B:I").HorizontalAlignment = 3
	.Range("A1:D1").Merge
	.Range("C3:D3").Merge
	.Range("E3:F3").Merge
ENDWITH

