PARAMETERS tcClmhead, tcfile

SELECT not_no, not_date, clm_no, pol_no, cust_id, name, surname, eff_date, exp_date, plan, type_clm, clm_type, acc_date, admit, disc, ;
	 hosp_amt, discount, non_cover, benf_paid, over_benf, hosp_name, ill_name, icd_10, icd10_2, clm_pstat, remark, indication, treatment ;
FROM (tcClmHead) ;
ORDER BY not_no ;
INTO CURSOR curClaim
IF RECCOUNT("curClaim") = 0
	RETURN 
ENDIF 	
SELECT curClaim
GO TOP 
****************
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()
oActiveSheet = oWorkBook.Worksheets(1).Activate
oSheet = oWorkBook.Worksheets(1)
WITH oSheet.PageSetup
	.Orientation = 2
      .PaperSize = 9
      .Zoom = 60
ENDWITH       
********************************************
oSheet.Cells(1,1) = "Claim Summary Return "+STRTRAN(DTOC(m.startdate), "/", "-")
lnRow = 2
DO SetFormat
lnRow = lnRow+1
SCAN
	WAIT WINDOW STR(RECNO(),5)+" Records." NOWAIT
	FOR i = 1 TO FCOUNT() 
		lcField = FIELD(i)
		IF !INLIST(UPPER(lcField), "REMARK", "INDICATION", "TREATMENT")
			lcValue = &lcField
			IF !EMPTY(lcValue)
				IF TYPE("lcValue") $ "CM"
					oSheet.Cells(lnRow,i) = ALLTRIM(lcValue)
				ELSE 
					oSheet.Cells(lnRow,i) = lcValue
				ENDIF 
			ENDIF
		ENDIF 	
	ENDFOR
	lnRow = lnRow + 1
ENDSCAN
lcRange = ["]+ColumnLetter(1) + [2:] + ColumnLetter(FCOUNT()) + ALLTRIM(STR(lnRow-1)) + ["]
oSheet.Range(&lcRange).Select
oSheet.Columns.AutoFit
oSheet.Rows.AutoFit
oSheet.Cells(lnRow+2,1) = "Managed By HBC"
******************************************
lcExcelFile = tcfile
oWorkBook.SaveAs(lcExcelFile)
oExcel.Visible = .F.
oExcel.Quit
USE IN curAce
WAIT WINDOW " Transfer Sucess ......" TIMEOUT 5
*
******************
PROCEDURE SetFormat
WAIT WINDOW "Create Excel formatting...." NOWAIT
****************************
lnFields = AFIELDS(laFields)
FOR iField1 = 1 TO lnFields
	IF !INLIST(UPPER(FIELD(ifield1)), "REMARK", "INDICATION", "TREATMENT")
		oSheet.Cells(lnRow,ifield1) = FIELD(ifield1)
		lcColumn    = ColumnLetter(iField1)
		lcColumnExpression = ["] + lcColumn + [:] + lcColumn + ["]                                     
		oSheet.Columns(&lcColumnExpression.).Select                             
		*********************************************                                                                              
		DO CASE                                                                      
		CASE INLIST(laFields[iField1,2], "C", "L")
			lcFmtExp = ["@"]
			lnWidth = laFields[iField1,3]
			lnWidth = IIF(lnWidth > 30, 30, lnWidth)
			oSheet.Columns(&lcColumnExpression.).ColumnWidth = lnWidth
		CASE laFields[iField1,2] = "M"
			lcFmtExp = ["@"]
			oSheet.Columns(&lcColumnExpression.).ColumnWidth = 40
		CASE INLIST(laFields[iField1,2], "N", "I", "Y")
      		IF (laFields[iField1,2] $ "Y")      	
	      		lcFmtExp = ["##,##0.00"]    
		      ELSE                              		
      	      	IF laFields[iField1,4] = 0
	      	         lcFmtExp = ["0"]               
            		ELSE                              	
		               lcFmtExp = ["0.] + REPLICATE("0", laFields[iField1,4]) + ["]     
      		      ENDIF                                                               
	      	ENDIF
			oSheet.Columns(&lcColumnExpression.).ColumnWidth = 10
		CASE (laFields[iField1,2] $ "D.T")  
	      	lcFmtExp = ["dd/mm/yyyy"]          
			oSheet.Columns(&lcColumnExpression.).ColumnWidth = 10
		ENDCASE
		oSheet.Columns(&lcColumnExpression.).NumberFormat = &lcFmtExp.
	ENDIF 	
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
                                                                                
RETURN lcFirstLetter + lcSecondLetter
