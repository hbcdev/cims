PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcStartDate, ;
	gcEndDate, ;	
	gcSaveTo, ;
	gnOption
	
SET SAFETY OFF 	
********************	
glMonth = .T.
gcFundCode = "AII"
gdStartDate = DATE(YEAR(GOMONTH(DATE(),-1)), MONTH(GOMONTH(DATE(),-1)),1)
gdEndDate = DATE(YEAR(gdStartDate), MONTH(gdStartDate),IIF(INLIST(MONTH(gdStartDate), 1,3,5,7,8,10,12),31,IIF(MONTH(gdStartDate) = 2, 28,30)))
gnOption = 1
gcSaveTo = LEFT(gcTemp,3)+"Fee\"
gcStartDate = "Report Date"
gcEndDate = "Last update"
DO FORM form\Rollingentry
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
gtStartDate = DATETIME(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate), 00, 00)
gtEndDate = DATETIME(YEAR(gdEndDate), MONTH(gdEndDate), DAY(gdEndDate), 00, 00)
gcSaveTo = ADDBS(gcSaveTo)+ALLTRIM(CMONTH(gdStartDate))+"_"+ALLTRIM(STR(YEAR(gdStartDate)))
IF !DIRECTORY(gcSaveTo)
	MKDIR &gcSaveTo
ENDIF 	
***********************
lcOldDir = SYS(5)+SYS(2003)
lcFile = gcFundCode+"_PA_Fee_Data"
lcFile1 = gcFundCode+"_PA_Fee_New_Adjust_Data"
lcFeeCover = gcFundCode+"_PA_Fee_New_Adjust_Cover"

SELECT fundcode AS tpacode, ALLTRIM(policy_no) AS policy_no, person_no As cerno, plan, ;
	TTOD(effective) AS eff_date, ;
	TTOD(expired) AS exp_date, ;
	premium, ;	
	premium/365.25 AS prem_day, ;
	cause5 AS paid ;		
 FROM cims!dependants ;
 WHERE fundcode = gcFundCode ;
 	AND TTOD(effective) <= gdStartDate ; 
 	AND TTOD(l_update) <= gdEndDate ;		 	 	
INTO CURSOR Q_memb

*
SELECT tpacode, policy_no, plan, eff_date, exp_date, premium, ;
	(gdStartDate-eff_date)+1 AS days, paid ;
FROM Q_memb ;
order BY eff_date ;
INTO TABLE (ADDBS(gcSaveTo)+lcFile)
*
*
SELECT tpacode, policy_no, eff_date, exp_date, premium, ;
	(gdStartDate-IIF(eff_date < {^2007-08-01}, {^2007-08-01}, eff_date))+1 AS days, paid ;
FROM (lcFile) ;
WHERE EMPTY(paid) ;
ORDER BY eff_date ;
INTO TABLE (ADDBS(gcSaveTo)+lcFile1)
*
SELECT eff_date, days, ;
	COUNT(*) AS counts, SUM(premium) AS premium_re ;
FROM (lcFile1) ;
GROUP BY eff_date, days ;
ORDER BY eff_date ;
INTO TABLE (ADDBS(gcSaveTo)+lcFeeCover)
*
SELECT paid, COUNT(*) AS sum_counts, SUM(premium) AS sum_prem ;
FROM (lcFile) ;
GROUP BY paid ;
WHERE !EMPTY(paid) ;
INTO CURSOR curSum

******************************************************
*
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()
oActiveSheet = oWorkBook.Worksheets(1).Activate
oSheet = oWorkBook.Worksheets(1)
WITH oSheet.PageSetup
	.Orientation = 1
      .PaperSize = 5
      .Zoom = 100
ENDWITH       
********************************************
oSheet.name = "Cover Sheet"
oSheet.Cells(1,3) = "Eff_date"   && C
oSheet.Cells(1,4) = "Exp_date"  && D
oSheet.Cells(1,5) = "Days"        && E 
oSheet.Cells(1,6) = "Counts"     && F
oSheet.Cells(1,7) = "Premium_re"  && G
oSheet.Cells(1,8) = "Earn Premium"  && H
*
oSheet.Cells(2,1) = "ยอดยกมา เดือน "+tMonth(gdStartDate)
oSheet.Cells(2,5) = IIF(INLIST(MONTH(gdStartDate), 1, 3, 5, 7, 8, 10, 12), 31, IIF(MONTH(gdStartDate) = 2, IIF(MOD(YEAR(gdStartDate),4) = 0, 29, 28), 30))
oSheet.Cells(2,6) = curSum.sum_counts
oSheet.Cells(2,7) = curSum.sum_prem
oSheet.Cells(2,8) = "=(G2/365.25)*E2"
*
lnRows = 5
oSheet.Cells(lnRows,3) = "Eff_date"   && C
oSheet.Cells(lnRows,4) = "Exp_date"  && D
oSheet.Cells(lnRows,5) = "Days"        && E 
oSheet.Cells(lnRows,6) = "Counts"     && F
oSheet.Cells(lnRows,7) = "Premium_re"  && G
oSheet.Cells(lnRows,8) = "Earn Premium"  && H
*
lnStart = lnRows + 1
SELECT (lcFeeCover)
GO TOP 
LOCATE FOR MONTH(eff_date) = MONTH(gdStartDate)
IF FOUND()
	oSheet.Cells(lnRows,1) = "New Case"
	SCAN FOR MONTH(eff_date) = MONTH(gdStartDate)
		WAIT WINDOW "New Case "+TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
		lnRows = lnRows + 1
		oSheet.Cells(lnRows,3) = Eff_date   && C
		oSheet.Cells(lnRows,4) = eff_date+365  && D
		oSheet.Cells(lnRows,5) = Days        && E 
		oSheet.Cells(lnRows,6) = Counts     && F
		oSheet.Cells(lnRows,7) = Premium_re  && G
		oSheet.Cells(lnRows,8) = "=(G"+ALLTRIM(STR(lnRows))+"/365.25)*E"+ALLTRIM(STR(lnRows))  && H
	ENDSCAN
	lnRows = lnRows + 1
	oSheet.Cells(lnRows,1) = "Total New Case"
	oSheet.Cells(lnRows,6) = "=SUM(F"+ALLTRIM(STR(lnStart))+":F"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,7) = "=SUM(G"+ALLTRIM(STR(lnStart))+":G"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,8) = "=SUM(H"+ALLTRIM(STR(lnStart))+":H"+ALLTRIM(STR(lnRows-1))+")" 	
ENDIF 	
*
GO TOP 
LOCATE FOR MONTH(eff_date) # MONTH(gdStartDate)
IF FOUND()
	lnRows = lnRows + 3
	oSheet.Cells(lnRows,1) = "Adjust Case"	
	oSheet.Cells(lnRows,3) = "Eff_date"   && C
	oSheet.Cells(lnRows,4) = "Exp_date"  && D
	oSheet.Cells(lnRows,5) = "Days"        && E 
	oSheet.Cells(lnRows,6) = "Counts"     && F
	oSheet.Cells(lnRows,7) = "Premium_re"  && G
	oSheet.Cells(lnRows,8) = "Earn Premium"  && H
	lnStart = lnRows + 1	
	SCAN FOR MONTH(eff_date) # MONTH(gdStartDate)
		WAIT WINDOW "Adjust Case "+TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
		lnRows = lnRows + 1
		oSheet.Cells(lnRows,3) = Eff_date   && C
		oSheet.Cells(lnRows,4) = Eff_date+365  && D
		oSheet.Cells(lnRows,5) = Days        && E 
		oSheet.Cells(lnRows,6) = Counts     && F
		oSheet.Cells(lnRows,7) = Premium_re  && G
		oSheet.Cells(lnRows,8) = "=(G"+ALLTRIM(STR(lnRows))+"/365.25)*E"+ALLTRIM(STR(lnRows))  && H
	ENDSCAN
	lnRows = lnRows + 1
	oSheet.Cells(lnRows,1) = "Total Adjust Case"
	oSheet.Cells(lnRows,6) = "=SUM(F"+ALLTRIM(STR(lnStart))+":F"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,7) = "=SUM(G"+ALLTRIM(STR(lnStart))+":G"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,8) = "=SUM(H"+ALLTRIM(STR(lnStart))+":H"+ALLTRIM(STR(lnRows-1))+")" 	
ENDIF 	
*	
lcExcelCover = ADDBS(gcSaveTo)+gcFundCode+"_Group_Fee_Cover_"+ALLTRIM(CMONTH(gdStartDate))+"_"+ALLTRIM(STR(YEAR(gdStartDate)))
oWorkBook.SaveAs(lcExcelCover)
oExcel.Quit
*
 	


