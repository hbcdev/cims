PARAMETERS tcTable, tcPath, tcFundCode
IF PARAMETERS() <> 3
	RETURN
ENDIF
	
SET DELETED ON
SET SAFETY OFF
*************************************************
cFundCode = tcFundCode
lnSheet = 0
*********************
SELECT not_no, not_date, pol_no, name, surname, eff_date, exp_date, plan, clm_type, acc_date, ;
	hosp_name, admit, disc, hosp_amt, discount, non_cover, benf_paid, exgratia, over_benf, ;
	clm_pstat, ret_date, indication, treatment, remark ;
FROM (tcTable) ;
ORDER BY hosp_name, not_no ;
INTO CURSOR clmHosp
IF _TALLY = 0
	RETURN 
ENDIF 
****************************************************
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()
*
SELECT clmHosp	
GO TOP
DO WHILE !EOF()
	lnSheet = lnSheet + 1
	lcHospName = hosp_name
	lnField = AFIELDS(laFields)
	**************************************************
	oSheet = oWorkBook.WorkSheets.Add
	oSheet.Name = ALLTRIM(hosp_name)
	oSheet.Cells(1, 1).Value = "โรงพยาบาล"+ALLTRIM(hosp_name)
	oSheet.Cells(3, 1).Value = "Notify No"
	oSheet.Cells(3, 2).Value = "Notify Date"
	oSheet.Cells(3, 3).Value = "Policy No"
	oSheet.Cells(3, 4).Value = "Name"
	oSheet.Cells(3, 5).Value = "Surname"
	oSheet.Cells(3, 6).Value = "Effective"
	oSheet.Cells(3, 7).Value = "Expiry"
	oSheet.Cells(3, 8).Value = "Plan"
	oSheet.Cells(3, 9).Value = "Service Type"
	oSheet.Cells(3, 10).Value = "Accident Date"
	oSheet.Cells(3, 11).Value = "Hospital"
	oSheet.Cells(3, 12).Value = "Admit"
	oSheet.Cells(3, 13).Value = "Discharge"
	oSheet.Cells(3, 14).Value = "Charge"
	oSheet.Cells(3, 15).Value = "Discount"
	oSheet.Cells(3, 16).Value = "Non Cover"
	oSheet.Cells(3, 17).Value = "Paid"
	oSheet.Cells(3, 18).Value = "Exgratia"
	oSheet.Cells(3, 19).Value = "Client Paid"
	oSheet.Cells(3, 20).Value = "Status"
	oSheet.Cells(3, 21).Value = "Admit"
	oSheet.Cells(3, 22).Value = "Return Date"
	oSheet.Cells(3, 23).Value = "Indication"
	oSheet.Cells(3, 24).Value = "Treatment"
	oSheet.Cells(3, 25).Value = "Remark"	
	***********
	DO SetFormat
	***********
	lnRow = 3
	WAIT WINDOW hosp_name NOWAIT
	STORE 0 TO lnCharge, lnNopaid, lnPaid
	DO WHILE hosp_name = lcHospName AND !EOF()
		FOR i = 1 TO FCOUNT()
			lcField = FIELD(i)
			lcValue = &lcField
			IF !EMPTY(lcValue)
				oSheet.Cells(lnRow,i) = lcValue
			ENDIF 	
		ENDFOR
		**************************
		lnCharge = lnCharge + hosp_amt
		lnNopaid = lnNoPaid + non_cover
		lnPaid = lnPaid + benf_paid
		**************************
		lnRow = lnRow + 1
		SKIP
	ENDDO
	******************
	oSheet.Cells(lnRow,1) = hosp_name
	oSheet.Cells(lnRow,18) = lnCharge
	oSheet.Cells(lnRow,19) = lnNoPaid
	oSheet.Cells(lnRow,21) = lnPaid
ENDDO
lcExcelFile = ADDBS(ALLTRIM(tcPath))+"Hospital"
oWorkBook.SaveAs(lcExcelFile)
oExcel.Quit
*****************************************************
PROCEDURE SetFormat
lnFields = AFIELDS(laFields)
FOR iField1 = 1 TO lnFields
	oSheet.Cells(1,iField1) = FIELD(iField1)
	*********************
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