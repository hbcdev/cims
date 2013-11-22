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
gcFundCode = "OLI"
gcCaption = "OLI PA Fee Report"
gdStartDate = DATE(YEAR(GOMONTH(DATE(),-1)), MONTH(GOMONTH(DATE(),-1)),1)
gdStartDate = DATE(YEAR(gdStartDate), MONTH(gdStartDate),IIF(INLIST(MONTH(gdStartDate), 1,3,5,7,8,10,12),31,IIF(MONTH(gdStartDate) = 2, 28,30)))
gdEndDate = DATE()
gnOption = 1
gnAll = 1
gnCover = 1
gnData = 0
gnType = 1
gcSaveTo = LEFT(gcTemp,3)+"Fee\"
gcStartDate = "Report Date"
gcEndDate = "Last File Date"
DO FORM form\Rollingentry
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
gtStartDate = DATETIME(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate), 00, 00)
gtEndDate = DATETIME(YEAR(gdEndDate), MONTH(gdEndDate), DAY(gdEndDate), 00, 00)
gcSaveTo = ALLTRIM(gcSaveTo)+ALLTRIM(CMONTH(gdStartDate))+"_"+ALLTRIM(STR(YEAR(gdStartDate)))
IF !DIRECTORY(gcSaveTo)
	MKDIR &gcSaveTo
ENDIF 	
***********************
lcOldDir = SYS(5)+SYS(2003)
lcFile = gcFundCode+"_PAS_Fee_Data"
lcCoverFile = gcFundCode+"_PAS_Fee_New_Adjust_Data"
lcFeeCover = gcFundCode+"_PAS_Fee_New_Adjust_Cover"
lcVoid = gcFundCode+"_PAS_Fee_Void_Data"
*
SELECT tpacode, ALLTRIM(policy_no) AS policy_no, product AS plan, ;
	TTOD(effective) AS eff_date, ;
	TTOD(expiry) AS exp_date, ;
	premium AS premium, ;	
	premium/(5*365.25) AS prem_day, ;	
	cause12 AS paid, status, ;
	cause11 AS lastpaid, TTOD(adj_plan_date) AS void_date ;		
 FROM cims!member ;
 WHERE tpacode = gcFundCode ;
  	AND customer_type = "P" ; 		 	
  	AND RIGHT(ALLTRIM(product),1) = "S" ;
 	AND TTOD(effective) <= gdStartDate ;  	 	
 	AND l_submit <= gdEndDate ;	 	 	 	
INTO CURSOR Q_memb
*
SELECT tpacode, policy_no, plan, eff_date, exp_date, premium, ;
	IIF(status $ "VD" AND YEAR(exp_date) # YEAR(eff_date+(365.25*5)), IIF(exp_date > gdStartDate, 0, (gdStartDate-exp_date)+1), (gdStartDate-eff_date)+1) AS days, ;
	paid, lastpaid, status ;
FROM Q_memb ;
WHERE EMPTY(status) ;
	AND exp_date >= DATE(YEAR(gdStartDate), MONTH(gdStartDate),1) ;
ORDER BY eff_date ;
INTO TABLE (ADDBS(gcSaveTo)+lcFile)
*
SELECT tpacode, policy_no, plan, eff_date, exp_date, premium, ;
	IIF(status $ "VD" AND YEAR(exp_date) # YEAR(eff_date+(365*5)), IIF(exp_date > gdStartDate, 0, (gdStartDate-exp_date)+1), (gdStartDate-eff_date)+1) AS days, ;
	paid, lastpaid, status ;
FROM Q_memb ;
WHERE !EMPTY(status) ;
	AND void_date >= gdEndDate ;
ORDER BY eff_date ;
INTO TABLE (ADDBS(gcSaveTo)+lcVoid)
*
SELECT eff_date, exp_date, days, COUNT(*) AS counts, SUM(premium) AS premium_re ;
FROM (lcVoid) ;
WHERE lastpaid = "P" AND status $ "V" ;
GROUP BY eff_date, exp_date, days ;
ORDER BY eff_date ;
INTO CURSOR curVoid
*
SELECT eff_date, exp_date, days, COUNT(*) AS counts, SUM(premium) AS premium_re ;
FROM (lcVoid) ;
WHERE lastpaid = "P" ;
	AND status $ "C" ;
GROUP BY eff_date, exp_date, days ;
ORDER BY eff_date ;
INTO CURSOR curCancel
*
SELECT eff_date, exp_date, days, COUNT(*) AS counts, SUM(premium) AS premium_re ;
FROM (lcVoid) ;
WHERE lastpaid = "P" AND status = "D" ;
GROUP BY eff_date, exp_date, days ;
ORDER BY eff_date ;
INTO CURSOR curDead
*
SELECT eff_date, exp_date, (gdStartDate - exp_Date)+1 AS days, ;
	COUNT(*) AS counts, SUM(premium) AS premium_re ;
FROM (lcFile) ;
WHERE exp_date BETWEEN DATE(YEAR(gdStartDate), MONTH(gdStartDate),1) AND gdStartDate AND EMPTY(status) ;
GROUP BY eff_date, exp_date ;
INTO CURSOR curExp
********************************
SELECT * ;
FROM (lcFile) ;
WHERE EMPTY(paid) ;
	AND exp_date > gdStartDate ;
ORDER BY eff_date ;
INTO TABLE (ADDBS(gcSaveTo)+lcCoverFile)
*
SELECT eff_date, exp_date, days, COUNT(*) AS counts, SUM(premium) AS premium_re ;
FROM (lcCoverFile) ;
WHERE EMPTY(status) ;
GROUP BY eff_date, exp_date, days ;
ORDER BY eff_date ;
INTO TABLE (ADDBS(gcSaveTo)+lcFeeCover) 
*
ldFirstDate = DATE(YEAR(gdStartDate), MONTH(gdStartDate), 1)
SELECT lastpaid, ;
	SUM(IIF(EMPTY(status) AND exp_date >= ldFirstDate, 1, 0)) AS sum_counts, ;	
	SUM(IIF(EMPTY(status) AND exp_date >= ldFirstdate, premium, 0)) AS sum_prem, ;	
	SUM(IIF(status $ "VC" AND void_date >= gdenddate AND exp_date >= ldFirstDate, 1, 0)) AS sum_vcounts, ;	
	SUM(IIF(status $ "VC" AND void_date >= gdenddate AND exp_date >= ldfirstDate, premium, 0)) AS sum_vprem, ;
	SUM(IIF(status = "D" AND void_date >= gdenddate AND eff_date+365 >= ldFirstDate, 1, 0)) AS sum_dcounts, ;
	SUM(IIF(status = "D" AND void_date >= gdenddate AND eff_date+365 >= ldFirstDate, premium, 0)) AS sum_dprem ;		
FROM q_memb ;
GROUP BY lastpaid ;
WHERE lastpaid = "P" ;	
INTO CURSOR curSum
SELECT curSum
COPY TO (ADDBS(gcSaveTo)+"Lastpaid_sum")
GO TOP 
*
***********************************************************
*
IF gnCover = 0
	RETURN 
ENDIF 	

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
oSheet.Cells(2,6) = curSum.sum_counts+curSum.sum_vcounts+curSum.sum_dcounts
oSheet.Cells(2,7) = curSum.sum_prem+curSum.sum_vprem+curSum.sum_dprem
oSheet.Cells(2,8) = "=(G2/(5*365.25))*E2"
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
		oSheet.Cells(lnRows,4) = Exp_date  && D
		oSheet.Cells(lnRows,5) = Days        && E 
		oSheet.Cells(lnRows,6) = Counts     && F
		oSheet.Cells(lnRows,7) = Premium_re  && G
		oSheet.Cells(lnRows,8) = "=(G"+ALLTRIM(STR(lnRows))+"/(5*365.25))*E"+ALLTRIM(STR(lnRows))  && H
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
		oSheet.Cells(lnRows,4) = Exp_date  && D
		oSheet.Cells(lnRows,5) = Days        && E 
		oSheet.Cells(lnRows,6) = Counts     && F
		oSheet.Cells(lnRows,7) = Premium_re  && G
		oSheet.Cells(lnRows,8) = "=(G"+ALLTRIM(STR(lnRows))+"/(5*365.25))*E"+ALLTRIM(STR(lnRows))  && H
	ENDSCAN
	lnRows = lnRows + 1
	oSheet.Cells(lnRows,1) = "Total Adjust Case"
	oSheet.Cells(lnRows,6) = "=SUM(F"+ALLTRIM(STR(lnStart))+":F"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,7) = "=SUM(G"+ALLTRIM(STR(lnStart))+":G"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,8) = "=SUM(H"+ALLTRIM(STR(lnStart))+":H"+ALLTRIM(STR(lnRows-1))+")" 	
ENDIF 	
*
SELECT curExp
IF RECCOUNT() # 0
	lnRows = lnRows + 3
	oSheet.Cells(lnRows,1) = "Less Expired Case"	
	oSheet.Cells(lnRows,3) = "Eff_date"   && C
	oSheet.Cells(lnRows,4) = "Exp_date"  && D
	oSheet.Cells(lnRows,5) = "Days"        && E 
	oSheet.Cells(lnRows,6) = "Counts"     && F
	oSheet.Cells(lnRows,7) = "Premium_re"  && G
	oSheet.Cells(lnRows,8) = "Earn Premium"  && H
	lnStart = lnRows + 1	
	SCAN 
		WAIT WINDOW "Void Case "+TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
		lnRows = lnRows + 1
		oSheet.Cells(lnRows,3) = Eff_date   && C
		oSheet.Cells(lnRows,4) = Exp_date  && D
		oSheet.Cells(lnRows,5) = Days        && E 
		oSheet.Cells(lnRows,6) = Counts     && F
		oSheet.Cells(lnRows,7) = Premium_re  && G
		oSheet.Cells(lnRows,8) = "=(G"+ALLTRIM(STR(lnRows))+"/(5*365.25))*E"+ALLTRIM(STR(lnRows))  && H
	ENDSCAN
	lnRows = lnRows + 1
	oSheet.Cells(lnRows,1) = "Total Less Expired Case"
	oSheet.Cells(lnRows,6) = "=SUM(F"+ALLTRIM(STR(lnStart))+":F"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,7) = "=SUM(G"+ALLTRIM(STR(lnStart))+":G"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,8) = "=SUM(H"+ALLTRIM(STR(lnStart))+":H"+ALLTRIM(STR(lnRows-1))+")" 	
ENDIF 	
*
SELECT curVoid
IF RECCOUNT() # 0
	lnRows = lnRows + 3
	oSheet.Cells(lnRows,1) = "Less Void Case"	
	oSheet.Cells(lnRows,3) = "Eff_date"   && C
	oSheet.Cells(lnRows,4) = "Exp_date"  && D
	oSheet.Cells(lnRows,5) = "Days"        && E 
	oSheet.Cells(lnRows,6) = "Counts"     && F
	oSheet.Cells(lnRows,7) = "Premium_re"  && G
	oSheet.Cells(lnRows,8) = "Earn Premium"  && H
	lnStart = lnRows + 1	
	SCAN FOR MONTH(eff_date) # MONTH(gdStartDate)
		WAIT WINDOW "Void Case "+TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
		lnRows = lnRows + 1
		oSheet.Cells(lnRows,3) = Eff_date   && C
		oSheet.Cells(lnRows,4) = Exp_date  && D
		oSheet.Cells(lnRows,5) = Days        && E 
		oSheet.Cells(lnRows,6) = Counts     && F
		oSheet.Cells(lnRows,7) = Premium_re  && G
		oSheet.Cells(lnRows,8) = "=(G"+ALLTRIM(STR(lnRows))+"/(5*365.25))*E"+ALLTRIM(STR(lnRows))  && H
	ENDSCAN
	lnRows = lnRows + 1
	oSheet.Cells(lnRows,1) = "Total Void Case"
	oSheet.Cells(lnRows,6) = "=SUM(F"+ALLTRIM(STR(lnStart))+":F"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,7) = "=SUM(G"+ALLTRIM(STR(lnStart))+":G"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,8) = "=SUM(H"+ALLTRIM(STR(lnStart))+":H"+ALLTRIM(STR(lnRows-1))+")" 	
ENDIF 	
*
SELECT curCancel
IF RECCOUNT() # 0
	lnRows = lnRows + 3
	oSheet.Cells(lnRows,1) = "Less Cancel Case"	
	oSheet.Cells(lnRows,3) = "Eff_date"   && C
	oSheet.Cells(lnRows,4) = "Exp_date"  && D
	oSheet.Cells(lnRows,5) = "Days"        && E 
	oSheet.Cells(lnRows,6) = "Counts"     && F
	oSheet.Cells(lnRows,7) = "Premium_re"  && G
	oSheet.Cells(lnRows,8) = "Earn Premium"  && H
	lnStart = lnRows + 1	
	SCAN FOR MONTH(eff_date) # MONTH(gdStartDate)
		WAIT WINDOW "Cancel Case "+TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
		lnRows = lnRows + 1
		oSheet.Cells(lnRows,3) = Eff_date   && C
		oSheet.Cells(lnRows,4) = Exp_date  && D
		oSheet.Cells(lnRows,5) = Days        && E 
		oSheet.Cells(lnRows,6) = Counts     && F
		oSheet.Cells(lnRows,7) = Premium_re  && G
		oSheet.Cells(lnRows,8) = "=(G"+ALLTRIM(STR(lnRows))+"/(5*365.25))*E"+ALLTRIM(STR(lnRows))  && H
	ENDSCAN
	lnRows = lnRows + 1
	oSheet.Cells(lnRows,1) = "Total Cancel Case"
	oSheet.Cells(lnRows,6) = "=SUM(F"+ALLTRIM(STR(lnStart))+":F"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,7) = "=SUM(G"+ALLTRIM(STR(lnStart))+":G"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,8) = "=SUM(H"+ALLTRIM(STR(lnStart))+":H"+ALLTRIM(STR(lnRows-1))+")" 	
ENDIF 	
*
SELECT curDead
IF RECCOUNT() # 0
	lnRows = lnRows + 3
	oSheet.Cells(lnRows,1) = "Less Dead Case"	
	oSheet.Cells(lnRows,3) = "Eff_date"   && C
	oSheet.Cells(lnRows,4) = "Exp_date"  && D
	oSheet.Cells(lnRows,5) = "Days"        && E 
	oSheet.Cells(lnRows,6) = "Counts"     && F
	oSheet.Cells(lnRows,7) = "Premium_re"  && G
	oSheet.Cells(lnRows,8) = "Earn Premium"  && H
	lnStart = lnRows + 1	
	SCAN FOR MONTH(eff_date) # MONTH(gdStartDate)
		WAIT WINDOW "Dead Case "+TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
		lnRows = lnRows + 1
		oSheet.Cells(lnRows,3) = Eff_date   && C
		oSheet.Cells(lnRows,4) = Exp_date  && D
		oSheet.Cells(lnRows,5) = Days        && E 
		oSheet.Cells(lnRows,6) = Counts     && F
		oSheet.Cells(lnRows,7) = Premium_re  && G
		oSheet.Cells(lnRows,8) = "=(G"+ALLTRIM(STR(lnRows))+"/(5*365.25))*E"+ALLTRIM(STR(lnRows))  && H
	ENDSCAN
	lnRows = lnRows + 1
	oSheet.Cells(lnRows,1) = "Total Dead Case"
	oSheet.Cells(lnRows,6) = "=SUM(F"+ALLTRIM(STR(lnStart))+":F"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,7) = "=SUM(G"+ALLTRIM(STR(lnStart))+":G"+ALLTRIM(STR(lnRows-1))+")"
	oSheet.Cells(lnRows,8) = "=SUM(H"+ALLTRIM(STR(lnStart))+":H"+ALLTRIM(STR(lnRows-1))+")" 	
ENDIF 	
*	
lcExcelCover = ADDBS(gcSaveTo)+gcFundCode+"_PAS_Fee_Cover_"+ALLTRIM(CMONTH(gdStartDate))+"_"+ALLTRIM(STR(YEAR(gdStartDate)))+IIF(gnType = 2, "(Actual)", "(EST)")
oWorkBook.SaveAs(lcExcelCover)
oExcel.Quit
*
************************************************
IF gnData = 0
	RETURN 
ENDIF 	

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


SELECT (lcfile)
GO TOP 
DO WHILE !EOF()
	oSheet = oWorkbook.Worksheets.Add()
	*
	ldStart = DATE(YEAR(eff_date), MONTH(eff_date), 1)
	IF MONTH(ldStart) >= 11
		ldEnd = ldStart+91
		ldEnd = DATE(YEAR(ldEnd), MONTH(ldEnd), IIF(INLIST(MONTH(ldEnd), 1,3,5,7,8,10,12),31,IIF(MONTH(ldEnd) = 2, 28,30)))	
	ELSE 
		ldEnd = DATE(YEAR(eff_date), MONTH(eff_date)+2, IIF(INLIST(MONTH(eff_date)+2, 1,3,5,7,8,10,12),31,IIF(MONTH(eff_date)+2 = 2, 28,30)))	
	ENDIF 	
	lcName = LEFT(CMONTH(ldStart),3)+"-"+LEFT(CMONTH(ldEnd),3)+" "+RIGHT(STR(YEAR(ldEnd)),2)
	*
	oSheet.name = lcName	
	oSheet.Cells(1,1) = "Policy No"
	oSheet.Cells(1,2) = "Plan"
	oSheet.Cells(1,3) = "Eff Date"
	oSheet.Cells(1,4) = "Exp Date"
	oSheet.Cells(1,5) = "Premium"
	oSheet.Cells(1,6) = "Days"
	lnRow = 2	
	*
	?"Sheet "+lcName
	DO WHILE eff_date >= ldStart AND eff_date <= ldEnd AND EMPTY(status) AND !EOF()
		WAIT WINDOW TRANSFORM(RECNO(), "@Z 9,999,999") NOWAIT 
		oSheet.Cells(lnRow,1) = policy_no
		oSheet.Cells(lnRow,2) = plan
		oSheet.Cells(lnRow,3) = eff_date
		oSheet.Cells(lnRow,4) = exp_date
		oSheet.Cells(lnRow,5) = premium
		oSheet.Cells(lnRow,6) = days
		lnRow = lnRow + 1
		SKIP 		
	ENDDO
ENDDO 	
lcExcelCover = ADDBS(gcSaveTo)+gcFundCode+"_PAS_Fee_Data_"+ALLTRIM(CMONTH(gdStartDate))+"_"+ALLTRIM(STR(YEAR(gdStartDate)))+IIF(gnType = 2, "(Actual)", "(EST)")
oWorkBook.SaveAs(lcExcelCover)
oExcel.Quit
