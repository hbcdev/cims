PARAMETERS tcTable, tcPath, tcFundcode
IF PARAMETERS() <> 3
	RETURN
ENDIF
************************	
SET DELETED ON
SET SAFETY OFF
****************************************
lcFieldList = CheckFld(tcFundcode)
IF EMPTY(lcFieldList)
	SELECT *;
	FROM (tcTable);
	ORDER BY pol_no, type_clm;
	INTO CURSOR curPol
ELSE
	SELECT &lcFieldList;
	FROM (tcTable);
	ORDER BY pol_no, type_clm;
	INTO CURSOR curPol
ENDIF 	
IF !USED("curpol")
	RETURN 
ENDIF 	
*********************
IF _TALLY = 0
	RETURN
ENDIF 	
**********************************************************
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()
oSheet = oWorkBook.Worksheets("Sheet1")
oSheet.Name = "Claim Return"
WITH oSheet.PageSetup
	.PrintTitleRows = "$1:$1"
	.PrintTitleColumns = "$A:$A"
	.PaperSize = 5
	.Orientation = 2
	.Zoom = 60
ENDWITH	
*****************************************
lnRow = 2
lnTotPaid = 0
SELECT curPol
DO SetFormat
DO WHILE !EOF()
	lcPolicyNo = pol_no
	WAIT WINDOW pol_no NOWAIT
	DO WHILE pol_no = lcPolicyNo AND !EOF()
		lnPaid = 0
		lcType = type_clm
		lnField = AFIELDS(laFields)
		oSheet.Cells(lnRow,1) = pol_no
		lnRow = lnRow+1 
		DO WHILE pol_no = lcPolicyNo AND type_clm = lcType AND !EOF()
			FOR i = 1 TO FCOUNT()
				lcField = FIELD(i)
				IF !EMPTY(lcField)
					lcValue = &lcField
					IF !EMPTY(lcValue)
						oSheet.Cells(lnRow,i) = IIF(TYPE("lcValue") = "T", TTOD(lcValue), lcValue)
					ENDIF
				ENDIF 	
			ENDFOR
			lnPaid = lnPaid + benf_paid
			lnTotPaid = lnTotPaid + benf_paid
			lnRow = lnRow + 1
			SKIP
		ENDDO
		WITH oSheet
			.Cells(lnRow,14) = "รวม"
			.Cells(lnRow,16) = lnPaid
			lnRow = lnRow + 1
			****
			IF EOF()
				.Cells(lnRow,14) = "รวมทั้งสิ้น"
				.Cells(lnRow,16) = lnTotPaid
				lnRow = lnRow + 1
			ENDIF 	
			****
			.Cells(lnRow,1).Select
			.HPageBreaks.Add(oExcel.ActiveCell)
		ENDWITH
		***************
		DO setline
		***************
		lnRow = lnRow + 1
	ENDDO
ENDDO
lcExcelFile = ADDBS(ALLTRIM(tcPath))+"Claim_Return_Printout"
oWorkBook.SaveAs(lcExcelFile)
oExcel.Quit
*****************************************************
*
PROCEDURE SetFormat
lnField = AFIELDS(laFields)
FOR i = 1 TO lnField
	oSheet.Cells(1,i) = FIELD(i)
ENDFOR 	
****************************
lnFields = AFIELDS(laFields)
FOR iField1 = 1 TO lnFields                                                     
	lcColumn    = ColumnLetter(iField1)
	lcColumnExpression = ["] + lcColumn + [:] + lcColumn + ["]                                     
	oSheet.Columns(&lcColumnExpression.).Select                             
	*********************************************                                                                              
	DO CASE                                                                      
	CASE (laFields[iField1,2] $ "C.L")
		lcFmtExp = ["@"]
		lnWidth = laFields[iField1,3]
		lnWidth = IIF(lnWidth > 15, 15, lnWidth)
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
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = 12
	CASE (laFields[iField1,2] $ "D.T")  
      	lcFmtExp = ["dd/mm/yyyy"]          
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = 10
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
