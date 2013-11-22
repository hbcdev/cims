PARAMETERS tcPath, tcFileName 
SET DELETED ON
SET SAFETY OFF
**********************
IF EMPTY(tcFileName) 
	RETURN
ENDIF
*********************
IF RECCOUNT() = 0
	RETURN
ENDIF	
****************
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()
oActiveSheet = oWorkBook.Worksheets(1).Activate
oSheet = oWorkBook.Worksheets(1)
DO SetFormat
****************
lnRow = 2
SCAN
	WAIT WINDOW STR(RECNO(),5)+"Records." NOWAIT 
	FOR i = 1 TO FCOUNT()
		lcField = FIELD(i)
		lcValue = &lcField
		IF !EMPTY(lcValue)
			oSheet.Cells(lnRow,i) = lcValue
		ENDIF
	ENDFOR
	lnRow = lnRow + 1
ENDSCAN
lcExcelFile = ADDBS(ALLTRIM(tcPath))+ALLTRIM(tcFileName)
oWorkBook.SaveAs(lcExcelFile)
oExcel.Visible = .F.
oExcel.Quit
WAIT WINDOW " Transfer Sucess ......" TIMEOUT 5
*****************************************************
*
PROCEDURE SetFormat

WAIT WINDOW "Create Excel formatting...." NOWAIT
lnFields = AFIELDS(laFields)
FOR i = 1 TO lnFields
	oSheet.Cells(1,i) = FIELD(i)
ENDFOR 	
****************************
FOR iField1 = 1 TO lnFields                                                     
	lcColumn    = ColumnLetter(iField1)
	lcColumnExpression = ["] + lcColumn + [:] + lcColumn + ["]                                     
	oSheet.Columns(&lcColumnExpression.).Select                             
	*********************************************                                                                              
	DO CASE                                                                      
	CASE INLIST(laFields[iField1,2], "C", "L")
		lcFmtExp = ["@"]
		lnWidth = laFields[iField1,3]
		lnWidth = IIF(lnWidth > 100, 100, lnWidth)
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = lnWidth
	CASE laFields[iField1,2] = "M"
		lcFmtExp = ["@"]
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = 100
	CASE INLIST(laFields[iField1,2], "N", "I", "Y")
      	IF (laFields[iField1,2] $ "Y")      	
	      	lcFmtExp = ["ß#,##0.00"]    
	      ELSE                              		
            	IF laFields[iField1,4] = 0
	               lcFmtExp = ["0"]               
            	ELSE                              	
	               lcFmtExp = ["0.] + REPLICATE("0", laFields[iField1,4]) + ["]     
      	      ENDIF                                                               
	      ENDIF
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = 16
	CASE (laFields[iField1,2] $ "D.T")  
      	lcFmtExp = ["dd/mm/yyyy"]          
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = 10
	ENDCASE
	oSheet.Columns(&lcColumnExpression.).NumberFormat = &lcFmtExp.
ENDFOR
WAIT CLEAR 
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
                                                                                
RETURN lcFirstLetter + lcSecondLetter