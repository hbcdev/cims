PARAMETERS tcTable, tcPath, tcFundCode
IF PARAMETERS() <> 3
	RETURN
ENDIF
************************	
SET DELETED ON
SET SAFETY OFF
****************************************
lnSheet = 1
oExcel = CREATEOBJECT("Excel.Application")
SELECT (tcTable)
INDEX ON clm_no TAG clm_no
DO WHILE !EOF()
	lnSheet = lnSheet + 1
	lcClmNo = clm_no
	lnField = AFIELDS(laFields)
	WAIT WINDOW clm_no NOWAIT
	oWorkBook = oExcel.Workbooks.Add()
	oActiveSheet = oWorkBook.Worksheets(lnSheet).Activate
	oSheet = oWorkBook.Worksheets(lnSheet)
	oSheet.Name = ALLTRIM(clm_no)
	DO SetFormat
	***********
	lnRow = 2
	DO WHILE clm_no = lcClmNo AND !EOF()
		FOR i = 1 TO FCOUNT()
			lcField = FIELD(i)
			lcField = CheckFld(tcFundCode, lcField)
			IF !EMPTY(lcField)
				lcValue = &lcField
				IF !EMPTY(lcValue)
					oSheet.Cells(lnRow,i) = lcValue
				ENDIF
			ENDIF 	
		ENDFOR
		lnRow = lnRow + 1
		SKIP
	ENDDO
ENDDO
lcExcelFile = ADDBS(ALLTRIM(tcPath))+ALLTRIM(lcPolicyNo)
oWorkBook.SaveAs(lcExcelFile)
oExcel.Quit
*****************************************************
*
PROCEDURE SetFormat

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
		lnWidth = IIF(lnWidth > 100, 100, lnWidth)
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = lnWidth
	CASE (laFields[iField1,2] $ "N.I.Y")		
      	IF (laFields[iField1,2] $ "Y")      	
	      	lcFmtExp = ["#,##0.00"]    
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