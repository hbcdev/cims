PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption
	
SET SAFETY OFF 	
********************	
gcStartDate = "From"
gcEndDate = "To"
glMonth = .T.
gcFundCode = "KTA"
gdStartDate = DATE(YEAR(GOMONTH(DATE(),-1)), MONTH(GOMONTH(DATE(),-1)),1)
gdEndDate = DATE(YEAR(gdStartDate), MONTH(gdStartDate),IIF(INLIST(MONTH(gdStartDate), 1,3,5,7,8,10,12),31,IIF(MONTH(gdStartDate) = 2, 28,30)))
gnOption = 1
gcSaveTo = LEFT(gcTemp,3)+"Fee\"
DO FORM form\Rollingentry
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
gtStartDate = DATETIME(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate), 00, 00)
gtEndDate = DATETIME(YEAR(gdEndDate), MONTH(gdEndDate), DAY(gdEndDate), 00, 00)

IF !DIRECTORY(gcSaveTo)
	MKDIR gcSaveTo
ENDIF 	
***********************
lcOldDir = SYS(5)+SYS(2003)
lcFile = gcFundCode+"_Fee"
SELECT tpacode, ALLTRIM(policy_no) AS policy_no, product AS plan, effective, expiry, premium, birth_date AS dob, ;
	IIF(effective >= gtStartDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtStartDate AND expiry >= gtStartDate, TTOD(gtStartDate), {})) AS start_date, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry >= gtStartDate AND expiry <= gtEndDate, TTOD(expiry), {})) AS end_date ;
 FROM cims!member ;
 WHERE tpacode = gcFundCode ;
 	AND expiry >= gdStartDate ;
 	AND customer_type = "I" ;
 	AND !INLIST(LEFT(product,2), "AI", "HB") ;
ORDER BY policy_no 	;
INTO CURSOR Q_memb
*
SET NULL ON 
SELECT policy_no, plan, effective, expiry, premium, dob, start_date, end_date, ;
	IIF(EMPTY(start_date), 0, 1) AS nominal, 	premium/365.25 AS prem_day, ;
	kta_mea_hb_premium(plan, dob) AS hb_premium, ;
	(end_date - start_date)+1 AS days, ((end_date - start_date)+1)*(premium/365.25) AS ep ;	
FROM Q_memb ;
WHERE !EMPTY(start_date) ;
ORDER BY policy_no ;
INTO DBF (ADDBS(gcSaveTo)+lcFile)	
*
SELECT kta_fee.policy_no, kta_fee.plan, kta_fee.effective, kta_fee.expiry, kta_fee.premium, kta_fee.hb_premium, ;
	kta_fee.start_date, kta_fee.end_date, kta_fee.nominal, kta_fee.days ;		
FROM kta_fee ;
ORDER BY plan, policy_no ;
INTO CURSOR curKtaFee
*
SET NULL OFF 
**********************************************************
*
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()

SELECT curKtaFee 
DO WHILE !EOF()
	lcPol = LEFT(plan,1)
	oSheet = oWorkBook.Worksheets.Add()
	oSheet.Name = IIF(lcPol # "M", "HS & HI Member", "MEA Member")	
	DO SetFormat
	****************
	lnRow = 2
	DO WHILE LEFT(plan, 1) = lcPol AND !EOF()
		WAIT WINDOW STR(RECNO(),5)+" Records." NOWAIT 
		FOR i = 1 TO FCOUNT()
			lcField = FIELD(i)
			lcValue = &lcField
			IF !EMPTY(lcValue)
				oSheet.Cells(lnRow,i) = lcValue
			ENDIF
		ENDFOR
		oSheet.Cells(lnRow,i) = "=(E"+ALLTRIM(STR(lnRow))+"-F"+ALLTRIM(STR(lnRow))+")/365.25"
		oSheet.Cells(lnRow,i+1) = "=J"+ALLTRIM(STR(lnRow))+"*K"+ALLTRIM(STR(lnRow))
		lnRow = lnRow + 1
		SKIP 
	ENDDO 
ENDDO 	
	
lcExcelFile = ADDBS(ALLTRIM(gcSaveTo))+"KTA_FEE_"+CMONTH(gdStartDate)+"_"+ALLTRIM(STR(YEAR(gdStartDate)))
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
