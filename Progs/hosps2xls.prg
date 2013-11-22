PARAMETERS tcTable, tcPath, tcFundCode

#Include include\excel9.h

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
SELECT IIF(ALLTRIM(bro_no) $ "IPB", "", pol_no) AS pgrp, not_no, not_date, clm_no, pol_no, cust_id, name, surname, eff_date, exp_date, plan, type_clm, clm_type, acc_date, ;
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
lcExcelFile = ADDBS(ALLTRIM(tcPath))+tcFundCode+"_Claim_Summary_"+STRTRAN(DTOC(curQuery.ret_date), "/", "")
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
*DO SheetP5
**************
oWorkBook.SaveAs(lcExcelFile)
oExcel.Quit
*********************************
USE IN curQuery
SET NOTIFY OFF
*********************************
*
PROCEDURE SheetP1
*
SELECT * FROM curQuery WHERE clm_pstat = "P1" ORDER BY pgrp, pol_no INTO CURSOR curP1

IF _TALLY = 0
	RETURN 
ENDIF 	

SELECT curP1
GO TOP
lcTitle = "ทำจ่ายลูกค้า"
oSheet = oWorkBook.WorkSheets(1)
oSheet.Name = lcTitle
*******************
DO SetFormat
*******************
lnStartRow = 2
DO WHILE !EOF()
	WAIT WINDOW hosp_name NOWAIT
	lcPgrp = pgrp
	IF !EMPTY(pgrp)
		oSheet.Cells(lnRow, 1).Value = lcPgrp
		lnRow = lnRow + 1		
	ENDIF 	
	DO WHILE pgrp = lcPgrp AND !EOF()
		m.pol_no = pol_no
		lnRow = lnStartRow
		lnRows = lnStartRow + 14
		DO WHILE pgrp = lcPgrp AND pol_no = m.pol_no AND !EOF()	
			DO WHILE lnRow <= lnStartRow + 12 AND !EOF()
				WAIT WINDOW TRANSFORM(RECNO(), "@Z 99,999")+" Records" AT 30,50 NOWAIT			
				WITH oSheet
					.Cells(lnRow, 1).value = not_no
					.Cells(lnRow, 2).value = IIF(EMPTY(not_date), "", not_date)
					.Cells(lnRow, 3).value = ALLTRIM(clm_no)
					.Cells(lnRow, 4).value = ALLTRIM(pol_no)
					.Cells(lnRow, 5).value = ALLTRIM(cust_id)
					.Cells(lnRow, 6).value = ALLTRIM(name)
					.Cells(lnRow, 7).value = ALLTRIM(surname)
					.Cells(lnRow, 8).value = TTOD(eff_date)
					.Cells(lnRow, 9).value = TTOD(exp_date)
					.Cells(lnRow, 10).value = ALLTRIM(plan)
					.Cells(lnRow, 11).value = ALLTRIM(type_clm)
					.Cells(lnRow, 12).value = ALLTRIM(clm_type)
					.Cells(lnRow, 13).value = TTOD(admit)
					.Cells(lnRow, 14).value = TTOD(disc)
					.Cells(lnRow, 15).value = hosp_amt
					.Cells(lnRow, 16).value = discount
					.Cells(lnRow, 17).value = benf_covr
					.Cells(lnRow, 18).value = non_cover
					.Cells(lnRow, 19).value = benf_paid
					.Cells(lnRow, 20).value = over_benf
					.Cells(lnRow, 21).value = ALLTRIM(hosp_name)
					.Cells(lnRow, 22).value = ALLTRIM(ill_name)
					.Cells(lnRow, 23).value = ALLTRIM(icd_10)
					.Cells(lnRow, 24).value = ALLTRIM(icd10_2)
					.Cells(lnRow, 25).value = clm_pstat
				ENDWITH 
				WITH oSheet
					.Cells(lnRows, 3).value = ALLTRIM(indication)
					lcColExp = ["C] + ALLTRIM(STR(lnRows)) + [:J] + ALLTRIM(STR(lnRows)) + ["]
					IF !oSheet.Range(&lcColExp).MergeCells
						oSheet.Range(&lcColExp).MergeCells = .T.	
					ENDIF
					.Cells(lnRows, 11).value = ALLTRIM(treatment)
					lcColExp = ["K] + ALLTRIM(STR(lnRows)) + [:R] + ALLTRIM(STR(lnRows)) + ["]
					IF !oSheet.Range(&lcColExp).MergeCells
						oSheet.Range(&lcColExp).MergeCells = .T.	
					ENDIF
				ENDWITH
				lnRow = lnRow + 1
				lnRows = lnRows + 1
				SKIP
			ENDDO 	
			*****************************************
			DO SetLine WITH ["A]+ALLTRIM(STR(lnStartRow))+[:Y]+ALLTRIM(STR(lnRow-1))+["]
			*
			DO SetLine WITH ["C]+ALLTRIM(STR(lnStartRow+14))+[:R]+ALLTRIM(STR(lnRows-1))+["]
			*****************************************
			oSheet.Cells(lnRows+1,1).Select
			oSheet.HPageBreaks.Add(oExcel.ActiveCell)	
			lnStartRow = lnRows + 1
		ENDDO 
	ENDDO
ENDDO
oSheet.Range("A:Z").AutoFit
USE IN curP1
*****************************************************
PROCEDURE SheetP5
*
SELECT * FROM curQuery WHERE clm_pstat = "P5" ORDER BY hosp_name, pgrp, pol_no INTO CURSOR curP5

IF _TALLY = 0
	RETURN 
ENDIF 	

SELECT curP5
GO TOP
lcTitle = "ทำจ่ายโรงพยาบาล"
oSheet = oWorkBook.WorkSheets(2)
oSheet.Name = lcTitle
*******************
DO SetFormat
*******************
lnRow = 2
lnRows = 12
DO WHILE !EOF()
	WAIT WINDOW hosp_name NOWAIT
 	lcHospName = hosp_name
	oSheet.Cells(lnRow, 1).Value = hosp_name
	lnRow = lnRow + 1		 		
	DO WHILE lcHospName = hosp_name AND !EOF()
		lcPgrp = pgrp	 
		IF !EMPTY(pgrp)
			oSheet.Cells(lnRow, 1).Value = pgrp
			lnRow = lnRow + 1	
		ENDIF
		*************************************************
		lnRow = lnStartRow
		lnRows = lnStartRow + 14
		DO WHILE pgrp = lcPgrp AND hosp_name = lcHospname AND !EOF()
			DO WHILE lnRow <= lnStartRow + 12 AND !EOF()
				WAIT WINDOW hosp_name+" "+TRANSFORM(RECNO(), "@Z 99,999")+" Records" NOWAIT
				WITH oSheet
					.Cells(lnRow, 1).value = not_no
					.Cells(lnRow, 2).value = not_date
					.Cells(lnRow, 3).value = ALLTRIM(clm_no)
					.Cells(lnRow, 4).value = ALLTRIM(pol_no)
					.Cells(lnRow, 5).value = ALLTRIM(cust_id)
					.Cells(lnRow, 6).value = ALLTRIM(name)
					.Cells(lnRow, 7).value = ALLTRIM(surname)
					.Cells(lnRow, 8).value = TTOD(eff_date)
					.Cells(lnRow, 9).value = TTOD(exp_date)
					.Cells(lnRow, 10).value = ALLTRIM(plan)
					.Cells(lnRow, 11).value = type_clm
					.Cells(lnRow, 12).value = clm_type
					.Cells(lnRow, 13).value = TTOD(admit)
					.Cells(lnRow, 14).value = TTOD(disc)
					.Cells(lnRow, 15).value = hosp_amt
					.Cells(lnRow, 16).value = discount
					.Cells(lnRow, 17).value = benf_covr
					.Cells(lnRow, 18).value = non_cover
					.Cells(lnRow, 19).value = benf_paid
					.Cells(lnRow, 20).value = over_benf
					.Cells(lnRow, 21).value = ALLTRIM(hosp_name)
					.Cells(lnRow, 22).value = ALLTRIM(ill_name)
					.Cells(lnRow, 23).value = ALLTRIM(icd_10)
					.Cells(lnRow, 24).value = ALLTRIM(icd10_2)
					.Cells(lnRow, 25).value = clm_pstat
				ENDWITH 
				WITH oSheet
					.Cells(lnRows, 3).value = ALLTRIM(indication)
					lcColExp = ["C] + ALLTRIM(STR(lnRows)) + [:J] + ALLTRIM(STR(lnRows)) + ["]
					IF !oSheet.Range(&lcColExp).MergeCells
						oSheet.Range(&lcColExp).MergeCells = .T.	
					ENDIF
					.Cells(lnRows, 11).value = ALLTRIM(treatment)
					lcColExp = ["K] + ALLTRIM(STR(lnRows)) + [:R] + ALLTRIM(STR(lnRows)) + ["]
					IF !oSheet.Range(&lcColExp).MergeCells
						oSheet.Range(&lcColExp).MergeCells = .T.	
					ENDIF
				ENDWITH
				lnRow = lnRow + 1
				lnRows = lnRows + 1
				SKIP
			ENDDO
			*****************************************
			DO SetLine WITH ["A]+ALLTRIM(STR(lnStartRow))+[:Y]+ALLTRIM(STR(lnRow-1))+["]
			*
			DO SetLine WITH ["C]+ALLTRIM(STR(lnStartRow+14))+[:R]+ALLTRIM(STR(lnRows-1))+["]
			*****************************************
			oSheet.Cells(30,1).Select
			oSheet.HPageBreaks.Add(oExcel.ActiveCell)
			lnStartRow = lnRows + 2				
		ENDDO 
	ENDDO
ENDDO
oSheet.Range("A:Z").AutoFit
USE IN curP5
*****************************************************
PROCEDURE SetFormat
*****************************************************
WITH oSheet.PageSetup
	.PrintTitleRows = "$1:$1"
	.CenterHeader = tcFundCode+" Claim Summary Return "+lcRetDate
       .LeftHeader = lcTitle
	.PaperSize = 5
	.Orientation = 2
	.Zoom = 55
ENDWITH	
*******************************************
WITH oSheet
	.Cells(1, 1).value = "not_no"
	.Cells(1, 2).value = "not_date"
	.Cells(1, 3).value = "clm_no"
	.Cells(1, 4).value = "pol_no"
	.Cells(1, 5).value = "cust_id"
	.Cells(1, 6).value = "name"
	.Cells(1, 7).value = "surname"
	.Cells(1, 8).value = "eff_date"
	.Cells(1, 9).value = "exp_date"
	.Cells(1, 10).value = "plan"
	.Cells(1, 11).value = "type_clm"
	.Cells(1, 12).value = "clm_type"
	.Cells(1, 13).value = "admit"
	.Cells(1, 14).value = "disc"
	.Cells(1, 15).value = "hosp_amt"
	.Cells(1, 16).value = "discount"
	.Cells(1, 17).value = "benf_covr"
	.Cells(1, 18).value = "non_cover"
	.Cells(1, 19).value = "benf_paid"
	.Cells(1, 20).value = "over_benf"
	.Cells(1, 21).value = "hosp_name"
	.Cells(1, 22).value = "ill_name"
	.Cells(1, 23).value = "icd_10"
	.Cells(1, 24).value = "icd10_2"
	.Cells(1, 25).value = "clm_pstat"	
	.Range("O:T").NumberFormat = "##,##0.00"
ENDWITH 
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
PARAMETERS r1

WITH oSheet.Range(&r1)
	.Borders(xlEdgeLeft).LineStyle = 1
	.Borders(xlEdgeLeft).Weight = 2
	.Borders(xlEdgeLeft).ColorIndex = -4105

	.Borders(xlEdgeTop).LineStyle = 1
	.Borders(xlEdgeTop).Weight = 2
	.Borders(xlEdgeTop).ColorIndex = -4105

	.Borders(xlEdgeBottom).LineStyle = 1
	.Borders(xlEdgeBottom).Weight = 2
	.Borders(xlEdgeBottom).ColorIndex = -4105

	.Borders(xlEdgeRight).LineStyle = 1
	.Borders(xlEdgeRight).Weight = 2
	.Borders(xlEdgeRight).ColorIndex = -4105

	.Borders(xlInsideVertical).LineStyle = 1
	.Borders(xlInsideVertical).Weight = 2
	.Borders(xlInsideVertical).ColorIndex = -4105

	.Borders(xlInsideHorizontal).LineStyle = 1
	.Borders(xlInsideHorizontal).Weight = 2
	.Borders(xlInsideHorizontal).ColorIndex = -4105
	.Range("A1").Select
ENDWITH 