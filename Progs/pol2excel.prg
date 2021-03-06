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
**********************
IF _TALLY = 0
	RETURN
ENDIF 	
****************************************
oExcel = CREATEOBJECT("Excel.Application")
SELECT curPol
INDEX ON pol_no+type_clm TAG pol_type
DO WHILE !EOF()
	lnSheet = 1
	lcPolicyNo = pol_no
	oWorkBook = oExcel.Workbooks.Add()
	WAIT WINDOW pol_no NOWAIT
	DO WHILE pol_no = lcPolicyNo AND !EOF()
		lcType = type_clm
		lnField = AFIELDS(laFields)
		**************************************************
		oActiveSheet = oWorkBook.Worksheets(lnSheet).Activate
		oSheet = oWorkBook.Worksheets(lnSheet)
		oSheet.Name = ALLTRIM(type_clm)
		***********
		DO SetFormat
		***********
		lnRow = 2
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
			lnRow = lnRow + 1
			SKIP
		ENDDO
		lnSheet = lnSheet + 1
	ENDDO
	lcPolicyNo = STRTRAN(lcPolicyNo, ".", "")
	lcPolicyNo = STRTRAN(lcPolicyNo, "/", "-")
	lcExcelFile = ADDBS(ALLTRIM(tcPath))+ALLTRIM(STRTRAN(lcPolicyNo, ".", ""))
	oWorkBook.SaveAs(lcExcelFile)
ENDDO
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
	      	lcFmtExp = ["##,##0.00"]    
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