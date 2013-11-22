PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption
********************	
gcFundCode = "KTA"
gdEndDate = DATE()
gdStartDate = DATE(YEAR(gdEndDate), MONTH(gdEndDate), 1)
gnOption = 3
gcSaveTo = gcTemp
DO FORM form\dateentry1
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
gcSaveTo = IIF(EMPTY(gcSaveTo), gcTemp, gcSaveTo) 	
lcName = gcFundCode+"_hb_ep_"+STRTRAN(DTOC(gdStartDate),"/", "")+"_"+STRTRAN(DTOC(gdEndDate),"/", "")
****************************************************
SET TALK ON NOWINDOW 
SELECT tpacode, policy_no, product, ;
	effective, expiry, premium,  IIF(effective < gdStartDate, gdStartDate, TTOD(effective)) AS start_roll, ;
	IIF(expiry > gdEndDate, gdEndDate, TTOD(expiry)) AS end_roll, ;
	IIF(expiry > gdEndDate, gdEndDate, TTOD(expiry))-IIF(effective < gdStartDate, gdStartDate, TTOD(effective))+1 AS active_day, ;
	premium/365.25 AS ep_day, ;
	(IIF(expiry > gdEndDate, gdEndDate, TTOD(expiry))-IIF(effective < gdStartDate, gdStartDate, TTOD(effective))+1)*(premium/365.25) AS ep, product AS other ;
 FROM cims!member ;
 WHERE tpacode = gcFundCode ;
 	AND effective <= gdEndDate ;
 	AND expiry >= gdStartDate ;
 	AND product LIKE "HB%" ;
 INTO DBF (ADDBS(gcSaveTo)+lcName)
 SET TALK OFF
 **************************************
 IF !USED(lcName)
 	RETURN 
 ENDIF 
SELECT member
SET ORDER TO policy_no
** 
 SELECT (lcName)
 GO TOP 
 SCAN 
 	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	lcOther = ""
	lcPolicyNo = tpacode+policy_no
	lcPolNo = policy_no
 	IF SEEK(lcPolicyNo, "member", "policy_no")
 		SELECT member
		DO WHILE lcPolno = policy_no AND !EOF()
			IF !INLIST(LEFT(product,2),"HB", "AI")
				lcOther = lcOther + LEFT(product,2)+","
			ENDIF 		
			SKIP
		ENDDO 
	ENDIF 
	SELECT (lcName)
	REPLACE other WITH LEFT(lcOther,LEN(lcOther)-1)
ENDSCAN
******************************************************
DO CASE 
CASE gnOption = 1
CASE gnOption = 2
CASE gnOption = 3
	DO ToExcel
ENDCASE 
*
*****************
PROCEDURE ToExcel
SELECT tpacode, policy_no, product, start_roll, end_roll, active_day, ep_day, ep, other, LEFT(other,1) AS status ;
FROM (lcName) ;
ORDER BY other ;
INTO CURSOR curHb
IF _TALLY = 0
	RETURN 
ENDIF 	
lnSheet = 1
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()
SELECT curHb
DO WHILE !EOF()
	lnRow = 2
	lcOther = status
	oSheet = oWorkBook.Worksheets(lnSheet)
	oSheet.Name = IIF(EMPTY(lcOther), "HB Only", "HB - Other Rider")
	*************
	DO WHILE status = lcOther AND !EOF()
		WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT
		***********
		DO SetFormat
		***********
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
lcExcelFile = ADDBS(gcSaveTo)+lcName
oWorkBook.SaveAs(lcExcelFile)
oExcel.Quit
USE IN curhb
*****************************************************
*
PROCEDURE SetFormat


lnFields = AFIELDS(laFields)
*
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


