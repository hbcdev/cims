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
gcFundCode = "ACE"
gdStartDate = DATE(YEAR(GOMONTH(DATE(),-1)), MONTH(GOMONTH(DATE(),-1)),1)
gdEndDate = DATE(YEAR(gdStartDate), MONTH(gdStartDate),IIF(INLIST(MONTH(gdStartDate), 1,3,5,7,8,10,12),31,IIF(MONTH(gdStartDate) = 2, 28,30)))
gnOption = 1
gcSaveTo = LEFT(gcTemp,3)+"Fee\"
DO FORM form\dateentry
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
lcMonth = LEFT(CMONTH(gdEndDate),3)+"_"+STR(YEAR(gdEndDate),4)
lcExcelFile = ADDBS(gcSaveTo)+gcFundCode+"_Fee_"+STR(YEAR(gdEndDate),4)+STRTRAN(STR(MONTH(gdEndDate),2), " ", "0")
*
DO Q_indi
DO Q_group
DO Genexcel
*
PROCEDURE Q_indi
* Query For HS, HI, HB, PA (Indi)
SELECT tpacode, ALLTRIM(policy_no) AS policy_no, product AS plan, policy_date AS pol_date, effective AS rid_date, ;
	IIF(EMPTY(policy_end), expiry, policy_end) AS expiry, premium, AnnPrem(premium, customer_type) AS Annual_prem, ;
	IIF(effective >= gtStartDate AND effective <= gtEndDate, TTOD(policy_date), TTOD(effective)) AS effective, ;
	IIF(customer_type = "P", "PA", IIF(customer_type = "I", "HS", "HB")) AS ptype, l_submit AS rcv_date, ;
	pay_fr, insure AS ace_prem, package AS months ;
 FROM cims!member ;
  WHERE tpacode = gcFundCode ;
  	AND expiry >= gtStartDate ;
INTO CURSOR Q_member
*
SELECT tpacode, policy_no, plan, pol_date, rid_date, expiry, premium, annual_prem, annual_prem-20 AS deduc_20, ;
	IIF(rcv_date >= TTOD(gtStartDate), IIF(TTOD(rid_date) > TTOD(gtEndDate), {}, TTOD(rid_date)), IIF(rid_date <= gtStartDate AND expiry >= gtStartDate, TTOD(gtStartDate), {})) AS start_date, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry >= gtStartDate AND expiry <= gtEndDate, TTOD(expiry), {})) AS end_date, ;
	rcv_date, ace_prem, months, (annual_prem-20)/365.25 AS prem_day, ptype ;
FROM Q_member ;
ORDER BY ptype ;
INTO CURSOR Indiv
*
SELECT tpacode, policy_no, plan, pol_date, rid_date, expiry, ;
	premium, annual_prem, annual_prem-20 AS deduc_20, start_date, end_date, ;
	rcv_date, ace_prem, months, prem_day, ptype, IIF(EMPTY(start_date), 0, 1) AS nominal, ;
	(end_date - start_date)+1 AS days, ((end_date - start_date)+1)*((annual_prem-20)/365.25) AS ep, ;
	IIF(ptype = "HS",  ((end_date - start_date)+1)*((annual_prem-20)/365.25)*(10/100), ((end_date - start_date)+1)*((annual_prem-20)/365.25)*(5/100)) AS Tpa_fee ;
FROM Indiv ;
WHERE !EMPTY(start_date) ;
ORDER BY ptype ;
INTO CURSOR Indi
**
PROCEDURE Q_group
* Query For HS, HI (Group)
SELECT ALLTRIM(policy_no) AS policy_no, plan, client_no, name, surname, policy_date AS effective, expired, ;
	VAL(cause4) AS ipd_perm, VAL(cause5) AS opd_perm, ;
	IIF(policy_date >= gtStartDate AND policy_date <= gtEndDate, TTOD(policy_date), IIF(policy_date <= gtStartDate AND expired >= gtStartDate, TTOD(gtStartDate), {})) AS start_date, ;
	IIF(expired >= gtEndDate, gdEndDate, IIF(expired >= gtStartDate AND expired <= gtEndDate, TTOD(expired), {})) AS end_date, ;
	VAL(cause4)/365.25 AS ipd_perm_day, VAL(cause5)/365.25 AS opd_perm_day, adddate AS rcv_date ;
 FROM cims!dependants ;
 WHERE fundcode = gcFundCode ;
 	AND expired >= gtStartDate ;
ORDER BY policy_no ; 	
INTO CURSOR Q_member
*
SELECT policy_no, client_no, plan, name, surname, effective, expired, opd_perm, ipd_perm, ;
	start_date, end_date, ;
	IIF(EMPTY(start_date), 0, 1) AS nominal, ;
	(end_date - start_date)+1 AS days, ;
	((end_date - start_date)+1)*opd_perm_day AS opd_ep, ;
	((end_date - start_date)+1)*ipd_perm_day AS ipd_ep, ;	
	(((end_date - start_date)+1)*opd_perm_day)*(10/100) AS opd_Total_fee, ;	
	(((end_date - start_date)+1)*ipd_perm_day)*(5/100) AS ipd_Total_fee, ;
	((((end_date - start_date)+1)*opd_perm_day)*(5/100)) + (((((end_date - start_date)+1)*ipd_perm_day)*(10/100))) AS Tpa_fee, ;
	((((((end_date - start_date)+1)*opd_perm_day)*(5/100)) + (((((end_date - start_date)+1)*ipd_perm_day)*(10/100))))) - ;
	(((((((end_date - start_date)+1)*opd_perm_day)*(5/100)) + (((((end_date - start_date)+1)*ipd_perm_day)*(10/100))))) * (30/100)) AS Net_fee, rcv_date ;	
FROM Q_member ;
ORDER BY policy_no ;
WHERE !EMPTY(start_date) ;
INTO CURSOR Grp
*
PROCEDURE genExcel
*
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()

SELECT indi
GO TOP 
DO WHILE !EOF() 
	lnRow = 2
	lcPlanType = ptype
	oSheet = oWorkBook.Worksheets.Add
	oSheet.name = ptype
	DO SetFormat
	****************	
	?ptype
	DO WHILE lcPlanType = ptype AND !EOF()
		WAIT WINDOW TRANSFORM(RECNO(),"@Z 999,999")+" Records." NOWAIT
		FOR i = 1 TO FCOUNT()
			lcField = FIELD(i)
			lcValue = &lcField
			IF !EMPTY(lcValue)
				oSheet.Cells(lnRow,i) = lcValue
			ENDIF
		ENDFOR
		lnRow = lnRow + 1
		SKIP 
	ENDDO 
	lcSum1 = ["=SUM(]+ColumnLetter(19) + [2:] + ColumnLetter(19) + ALLTRIM(STR(lnRow-1)) + [)"]
	lcSum2 = ["=SUM(]+ColumnLetter(20) + [2:] + ColumnLetter(20) + ALLTRIM(STR(lnRow-1)) + [)"]	
	oSheet.Cells(lnRow,19) = &lcSum1
	oSheet.Cells(lnRow,20) = &lcSum2
	*
	lcRange = ["]+ColumnLetter(1) + [1:] + ColumnLetter(FCOUNT()) + ALLTRIM(STR(lnRow)) + ["]
	oSheet.Range(&lcRange).Select
	oSheet.Columns.AutoFit
	oSheet.Rows.AutoFit
	*		
ENDDO
*
SELECT grp
GO TOP 
DO WHILE !EOF() 
	oSheet = oWorkBook.Worksheets.Add
	DO SetFormat
	****************
	?policy_no
	lnRow = 2
	lcPlanType = policy_no
	oSheet.name = ALLTRIM(policy_no)
	DO WHILE lcPlanType = policy_no AND !EOF()
		WAIT WINDOW TRANSFORM(RECNO(),"@Z 9,999")+" Records." NOWAIT 
		FOR i = 1 TO FCOUNT()
			lcField = FIELD(i)
			lcValue = &lcField
			IF !EMPTY(lcValue)
				oSheet.Cells(lnRow,i) = lcValue
			ENDIF
		ENDFOR
		lnRow = lnRow + 1
		SKIP 
	ENDDO 	
	lcSum1 = ["=SUM(]+ColumnLetter(17) + [2:] + ColumnLetter(17) + ALLTRIM(STR(lnRow-1)) + [)"]
	lcSum2 = ["=SUM(]+ColumnLetter(18) + [2:] + ColumnLetter(18) + ALLTRIM(STR(lnRow-1)) + [)"]
	lcSum3 = ["=SUM(]+ColumnLetter(19) + [2:] + ColumnLetter(19) + ALLTRIM(STR(lnRow-1)) + [)"]			
	oSheet.Cells(lnRow,17) = &lcSum1
	oSheet.Cells(lnRow,18) = &lcSum2
	oSheet.Cells(lnRow,19) = &lcSum3	
	*
	lcRange = ["]+ColumnLetter(1) + [1:] + ColumnLetter(FCOUNT()) + ALLTRIM(STR(lnRow)) + ["]
	oSheet.Range(&lcRange).Select
	oSheet.Columns.AutoFit
	oSheet.Rows.AutoFit
	*	
ENDDO
lcExcelFile = ADDBS(gcSaveTo)+gcFundCode+"_Fee_"+STR(YEAR(gdEndDate),4)+STRTRAN(STR(MONTH(gdEndDate),2), " ", "0")
oWorkBook.SaveAs(lcExcelFile)
oExcel.Visible = .F.
oExcel.Quit
WAIT WINDOW " Transfer Sucess ......" TIMEOUT 5
*
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

FUNCTION AnnPrem(tnPrem,tcCustype)

lnArea = SELECT()
lnVal = tnPrem
IF tcCustype = "P"
	lcAnnualDB = DATAPATH+"ace_me_annual"
	IF !USED("ACE_ME")
		USE (lcAnnualDB) IN 0 ALIAS ACE_ME
	ENDIF 	
	IF SEEK(tnPrem, "ACE_ME", "premium")
		lnVal = ace_me.annual_pre
	ENDIF 	
ENDIF 		
SELECT (lnArea)
RETURN lnVal