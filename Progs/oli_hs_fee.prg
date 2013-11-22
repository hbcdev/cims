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
gdStartDate = DATE(YEAR(GOMONTH(DATE(),-1)), MONTH(GOMONTH(DATE(),-1)),1)
gdEndDate = DATE(YEAR(gdStartDate), MONTH(gdStartDate),IIF(INLIST(MONTH(gdStartDate), 1,3,5,7,8,10,12),31,IIF(MONTH(gdStartDate) = 2, 28,30)))
gnOption = 1
gcSaveTo = LEFT(gcTemp,3)+"Fee\"
gcStartDate = "Start Date"
gcEndDate = "End update"
DO FORM form\Rollingentry
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
gtStartDate = DATETIME(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate), 00, 00)
gtEndDate = DATETIME(YEAR(gdEndDate), MONTH(gdEndDate), DAY(gdEndDate), 23, 59)
gcSaveTo = ADDBS(gcSaveTo)+ALLTRIM(CMONTH(gdStartDate))+"_"+ALLTRIM(STR(YEAR(gdStartDate)))
IF !DIRECTORY(gcSaveTo)
	MKDIR &gcSaveTo
ENDIF 	
***********************
lcOldDir = SYS(5)+SYS(2003)
lcFile = gcFundCode+"_HC_Fee_Data"
lcFile1 = gcFundCode+"_HC_Fee_New_Adjust_Data"
lcFeeCover = gcFundCode+"_HC_Fee_New_Adjust_Cover"
lcReceiveCover = gcFundCode+"_HC_Fee_Receive_Cover"
lcVoid = gcFundCode+"_HC_Fee_Void_Data"
lcAdjust = gcFundCode+"_HC_Fee_Adjust_Data"
*
SELECT tpacode, ALLTRIM(policy_no) AS policy_no, product AS plan, ;
	TTOD(effective) AS eff_date, ;
	TTOD(expiry) AS exp_date, ;
	premium, ;	
	status, renew, ;
	TTOD(adj_plan_date) AS void_date, ;
	oldperiumn As old_perm, ;
	TTOD(adj_permium_date) AS adj_date, ;
	l_submit AS recv_date ;
 FROM cims!member ;
 WHERE tpacode = gcFundCode ;
 	AND customer_type = "I" ;  
 	AND l_submit <= gdEndDate ;
INTO CURSOR Q_memb
*
SELECT tpacode, policy_no, plan, eff_date, exp_date, premium, ;
	(gdEndDate-eff_date)+1 AS days, recv_date, status, void_date, ;
	old_perm, adj_date, renew ;	
FROM Q_memb ;
order BY eff_date ;
INTO TABLE (ADDBS(gcSaveTo)+lcFile)
*
SELECT tpacode, policy_no, eff_date, exp_date, premium, old_perm, ;
	days, recv_date, renew ;
FROM (lcFile) ;
WHERE recv_date BETWEEN gdStartDate AND gdEndDate ;
	AND (EMPTY(void_date) OR void_date > gdStartDate) ;
ORDER BY eff_date ;
INTO TABLE (ADDBS(gcSaveTo)+lcFile1)
*
SELECT recv_date, ;
	SUM(IIF(eff_date >= gdStartDate, 1, 0)) AS new_case, ;
	SUM(IIF(eff_date >= gdStartDate, IIF(old_perm = 0, premium, old_perm), 0)) AS new_prem, ;
	SUM(IIF(eff_date >= gdStartDate, IIF(days < 365, days*(IIF(old_perm = 0, premium, old_perm)/365.25), IIF(old_perm = 0, premium, old_perm)), 0)) AS new_ep, ;		
	SUM(IIF(eff_date < gdStartDate, 1, 0)) AS adj_case, ;	
	SUM(IIF(eff_date < gdStartDate, IIF(old_perm = 0, premium, old_perm), 0)) AS adj_prem, ;		
	SUM(IIF(eff_date < gdStartDate, days*(IIF(old_perm = 0, premium, old_perm)/365.25), 0)) AS adj_ep ;			
FROM (lcFile1) ;
GROUP BY recv_date ;
ORDER BY recv_date ;
INTO TABLE (ADDBS(gcSaveTo)+lcReceiveCover)
*
SELECT tpacode, policy_no, eff_date, exp_date, premium, ;
	days, recv_date, void_date, status ;		
FROM (lcFile) ;
WHERE void_date BETWEEN gdStartDate AND gdEndDate ;
ORDER BY status, eff_date ;
INTO TABLE (ADDBS(gcSaveTo)+lcVoid)
*
SELECT void_date, ;
	SUM(IIF(status = "V", 1, 0)) As void, ;
	SUM(IIF(status = "V", premium, 0)) As v_prem, ;	
	SUM(IIF(status = "V", IIF(days >= 365, premium, days*(premium/365.25)), 0)) As v_ep, ;		
	SUM(IIF(status = "C", 1, 0)) As canceled, ;
	SUM(IIF(status = "C", premium, 0)) As c_prem, ;	
	SUM(IIF(status = "C", IIF(days >= 365, premium, days*(premium/365.25)), 0)) As c_ep, ;			
	SUM(IIF(status = "D", 1, 0)) As dead, ;		
	SUM(IIF(status = "D", premium, 0)) As d_prem, ;	
	SUM(IIF(status = "D", IIF(days >= 365, premium, days*(premium/365.25)), 0)) As v_ep ;			
FROM (lcvoid) ;
GROUP BY void_date ;
ORDER BY void_date ;
INTO CURSOR curVoid
*	
SELECT policy_no, eff_date, exp_date, premium, old_perm, premium-old_perm AS perm_diff, ;
	days, recv_date, adj_date, renew ;
FROM (lcFile) ;
WHERE adj_date BETWEEN gdStartDate AND gdEndDate ;
	AND old_perm # 0 ;
	AND renew <= 1 ;
ORDER BY eff_date ;
INTO TABLE (ADDBS(gcSaveTo)+lcAdjust)	
*
*		
SELECT eff_date, days, ;
	COUNT(*) AS counts, SUM(premium) AS premium_re ;
FROM (lcFile1) ;
GROUP BY eff_date, days ;
ORDER BY eff_date ;
INTO TABLE (ADDBS(gcSaveTo)+lcFeeCover)
*
SELECT COUNT(*) AS sum_counts, SUM(premium) AS sum_prem ;
FROM (lcFile) ;
WHERE recv_date < gdStartDate ;
	AND (EMPTY(void_date) OR void_date > gdStartDate) ;
INTO CURSOR curSum
*
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
oSheet.name = "Cover By receive date"
lnRows = 1
oSheet.Cells(lnRows,1) = "New Case"
oSheet.Cells(lnRows,3) = "Receive Date" 		&& C
oSheet.Cells(lnRows,4) = "New Case"  		&& D
oSheet.Cells(lnRows,5) = "Permium Re"        && E 
oSheet.Cells(lnRows,6) = "Earn Premium"     && F
oSheet.Cells(lnRows,7) = "Adjest Case"  		&& G
oSheet.Cells(lnRows,8) = "Permium Re"        && H 
oSheet.Cells(lnRows,9) = "Earn Premium"     && I
*
oSheet.Columns("A:A").ColumnWidth = 20
oSheet.Columns("C:C").ColumnWidth = 10
oSheet.Columns("D:D").ColumnWidth = 10
oSheet.Columns("E:E").ColumnWidth = 10
oSheet.Columns("F:F").ColumnWidth = 10
oSheet.Columns("G:G").ColumnWidth = 10
oSheet.Columns("H:H").ColumnWidth = 10
oSheet.Columns("I:I").ColumnWidth = 10
*
oSheet.Columns("D:F").NumberFormat = "#,##0"
oSheet.Columns("E:G").NumberFormat = "#,##0.00"
oSheet.Columns("F:F").NumberFormat = "#,##0.0000"
oSheet.Columns("G:G").NumberFormat = "#,##0"
oSheet.Columns("H:H").NumberFormat = "#,##0.00"
oSheet.Columns("I:I").NumberFormat = "#,##0.0000"
*
lnRows = 2
SELECT (lcReceiveCover)
GO TOP 
SCAN 
	oSheet.Cells(lnRows,3) = recv_date   && C
	oSheet.Cells(lnRows,4) = new_case  && D
	oSheet.Cells(lnRows,5) = new_prem        && E 
	oSheet.Cells(lnRows,6) = new_ep     && F
	oSheet.Cells(lnRows,7) = adj_case  && G
	oSheet.Cells(lnRows,8) = adj_prem  && H
	oSheet.Cells(lnRows,9) = adj_ep	  && I
	lnRows = lnRows + 1
ENDSCAN 
*
oSheet.Cells(lnRows,4) = "=SUM(D2:D"+ALLTRIM(STR(lnRows-1))+")"
oSheet.Cells(lnRows,5) = "=SUM(E2:E"+ALLTRIM(STR(lnRows-1))+")"
oSheet.Cells(lnRows,6) = "=SUM(F2:F"+ALLTRIM(STR(lnRows-1))+")"
oSheet.Cells(lnRows,7) = "=SUM(G2:G"+ALLTRIM(STR(lnRows-1))+")"
oSheet.Cells(lnRows,8) = "=SUM(H2:H"+ALLTRIM(STR(lnRows-1))+")"
oSheet.Cells(lnRows,9) = "=SUM(I2:I"+ALLTRIM(STR(lnRows-1))+")"
*
lcPermium = "=E"+ALLTRIM(STR(lnRows))+"+H"+ALLTRIM(STR(lnRows))
lcEp = "=F"+ALLTRIM(STR(lnRows))+"+I"+ALLTRIM(STR(lnRows))
*
************************
* Adjust Case
*
SELECT adj_date, COUNT(*) AS adj_case, ;
	SUM(perm_diff) AS adj_prem, SUM(days*(perm_diff/365.25)) AS adj_ep ;
FROM (lcAdjust) ;
GROUP BY adj_date ;
ORDER BY adj_date ;
INTO CURSOR curAdjust
*	
lnRows = lnRows + 2
oSheet.Cells(lnRows,1) = "Adjust Case"
oSheet.Cells(lnRows,3) = "Receive Date" 		&& C
oSheet.Cells(lnRows,4) = "Case"  		&& D
oSheet.Cells(lnRows,5) = "Permium Re"        && E 
oSheet.Cells(lnRows,6) = "Earn Premium"     && F
*
oSheet.Columns("A:A").ColumnWidth = 20
oSheet.Columns("C:C").ColumnWidth = 10
oSheet.Columns("D:D").ColumnWidth = 10
oSheet.Columns("E:E").ColumnWidth = 10
oSheet.Columns("F:F").ColumnWidth = 10
*
oSheet.Columns("D:F").NumberFormat = "#,##0"
oSheet.Columns("E:G").NumberFormat = "#,##0.00"
oSheet.Columns("F:F").NumberFormat = "#,##0.0000"
*
lnRows = lnRows + 1
lnStart = lnRows
SELECT curAdjust
GO TOP 
SCAN 
	oSheet.Cells(lnRows,3) = adj_date   && C
	oSheet.Cells(lnRows,4) = adj_case  && D
	oSheet.Cells(lnRows,5) = adj_prem        && E 
	oSheet.Cells(lnRows,6) = adj_ep     && F
	lnRows = lnRows + 1
ENDSCAN 
*
oSheet.Cells(lnRows,4) = "=SUM(D"+ALLTRIM(STR(lnStart))+":D"+ALLTRIM(STR(lnRows-1))+")"
oSheet.Cells(lnRows,5) = "=SUM(E"+ALLTRIM(STR(lnStart))+":E"+ALLTRIM(STR(lnRows-1))+")"
oSheet.Cells(lnRows,6) = "=SUM(F"+ALLTRIM(STR(lnStart))+":F"+ALLTRIM(STR(lnRows-1))+")"
*
lcAdjPermium = "=E"+ALLTRIM(STR(lnRows))
lcAdjEp = "=F"+ALLTRIM(STR(lnRows))
*
* End Adjust Case
************************
* Less Case
*
SELECT void_date, COUNT(*) AS void_case, ;
	SUM(premium) AS void_prem, SUM(days*(premium/365.25)) AS void_ep ;
FROM (lcVoid) ;
GROUP BY void_date ;
ORDER BY void_date ;
INTO CURSOR curLess
lnRows = lnRows + 2
oSheet.Cells(lnRows,1) = "Less Case"
oSheet.Cells(lnRows,3) = "Receive Date" 		&& C
oSheet.Cells(lnRows,4) = "Case"  		&& D
oSheet.Cells(lnRows,5) = "Permium Re"        && E 
oSheet.Cells(lnRows,6) = "Earn Premium"     && F
*
oSheet.Columns("A:A").ColumnWidth = 20
oSheet.Columns("C:C").ColumnWidth = 10
oSheet.Columns("D:D").ColumnWidth = 10
oSheet.Columns("E:E").ColumnWidth = 10
oSheet.Columns("F:F").ColumnWidth = 10
*
oSheet.Columns("D:F").NumberFormat = "#,##0"
oSheet.Columns("E:G").NumberFormat = "#,##0.00"
oSheet.Columns("F:F").NumberFormat = "#,##0.0000"
*
lnRows = lnRows + 1
lnStart = lnRows
SELECT curLess
GO TOP 
SCAN 
	oSheet.Cells(lnRows,3) = void_date   && C
	oSheet.Cells(lnRows,4) = void_case  && D
	oSheet.Cells(lnRows,5) = void_prem        && E 
	oSheet.Cells(lnRows,6) = void_ep     && F
	lnRows = lnRows + 1
ENDSCAN 
*
oSheet.Cells(lnRows,4) = "=SUM(D"+ALLTRIM(STR(lnStart))+":D"+ALLTRIM(STR(lnRows-1))+")"
oSheet.Cells(lnRows,5) = "=SUM(E"+ALLTRIM(STR(lnStart))+":E"+ALLTRIM(STR(lnRows-1))+")"
oSheet.Cells(lnRows,6) = "=SUM(F"+ALLTRIM(STR(lnStart))+":F"+ALLTRIM(STR(lnRows-1))+")"
*
lcLessPermium = "=E"+ALLTRIM(STR(lnRows))
lcLessEp = "=F"+ALLTRIM(STR(lnRows))
*
lnRows = lnRows + 2
*
oSheet.Cells(lnRows,1) = "ยอดยกมา เดือน "+tMonth(gdStartDate)
oSheet.Cells(lnRows,2) = IIF(INLIST(MONTH(gdStartDate), 1, 3, 5, 7, 8, 10, 12), 31, IIF(MONTH(gdStartDate) = 2, IIF(MOD(YEAR(gdStartDate),4) = 0, 29, 28), 30))
oSheet.Cells(lnRows,5) = curSum.sum_prem
oSheet.Cells(lnRows,6) = "=(E2/365.25)*B2"

lcSumPermium = "=E"+ALLTRIM(STR(lnRows))
lcSumEp = "=F"+ALLTRIM(STR(lnRows))

lnRows = lnRows + 1
oSheet.Cells(lnRows,1) = "ADD CASE"
oSheet.Cells(lnRows,5) = lcPermium
oSheet.Cells(lnRows,6) = lcEp

lcSumPermium = lcSumPermium + "+E"+ALLTRIM(STR(lnRows))
lcSumEp = lcSumEp + "+F"+ALLTRIM(STR(lnRows))

lnRows = lnRows + 1
oSheet.Cells(lnRows,1) = "ADJUST CASE"
oSheet.Cells(lnRows,5) = lcAdjPermium
oSheet.Cells(lnRows,6) = lcAdjEp

lcSumPermium = lcSumPermium + "+E"+ALLTRIM(STR(lnRows))
lcSumEp = lcSumEp + "+F"+ALLTRIM(STR(lnRows))

lnRows = lnRows + 1
oSheet.Cells(lnRows,1) = "TOTAL"
oSheet.Cells(lnRows,5) = lcSumPermium
oSheet.Cells(lnRows,6) = lcSumEp

lcBalPermium = "=E"+ALLTRIM(STR(lnRows))
lcBalEp = "=F"+ALLTRIM(STR(lnRows))

lnRows = lnRows + 1
oSheet.Cells(lnRows,1) = "LESS CASE"
oSheet.Cells(lnRows,5) = lcLessPermium
oSheet.Cells(lnRows,6) = lcLessEp

lcBalPermium = lcBalPermium + "-E"+ALLTRIM(STR(lnRows))
lcBalEp = lcBalEp + "-F"+ALLTRIM(STR(lnRows))

lnRows = lnRows + 1
oSheet.Cells(lnRows,5) = lcBalPermium
osheet.Cells(lnRows,6) = lcBalEp

lnRows = lnRows + 1
oSheet.Cells(lnRows,6).NumberFormat = "0.00%"
oSheet.Cells(lnRows,1) = "Fee Rate"
oSheet.Cells(lnRows,6) = 0.065
lcFee = "=F"+ALLTRIM(STR(lnRows-1))+"*F"+ALLTRIM(STR(lnRows))
*
lnRows = lnRows + 1
oSheet.Cells(lnRows,1) = "HBC FEE"
oSheet.Cells(lnRows,6) = lcFee
*	
*
lcExcelCover = ADDBS(gcSaveTo)+gcFundCode+"_HC_Fee_Cover_"+ALLTRIM(CMONTH(gdStartDate))+"_"+ALLTRIM(STR(YEAR(gdStartDate)))
oWorkBook.SaveAs(lcExcelCover)
oExcel.Quit
*