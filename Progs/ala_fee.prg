#INCLUDE "include\excel9.h"

PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption
	
SET SAFETY OFF 	
gcTemp = "D:\FEE\"
********************	
gcStartDate = "From"
gcEndDate = "To"
glMonth = .T.
gcFundCode = "ALA"
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

IF USED("aladata")
	USE IN aladata
ENDIF 	
***********************
lcOldDir = SYS(5)+SYS(2003)
lcMonth = LEFT(CMONTH(gdEndDate),3)+"_"+STR(YEAR(gdEndDate),4)
lcExcelFile = ADDBS(gcSaveTo)+STR(YEAR(gdEndDate),4)+STRTRAN(STR(MONTH(gdEndDate),2), " ", "0") + "_"+gcFundCode + "_Fee_Cover_of " + lcMonth 
*************************
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()
***********
WAIT WINDOW "Last Add New" NOWAIT 
SELECT policy_no, name, surname, product As plan, TTOD(policy_date) AS pol_date, TTOD(effective) As eff_date, TTOD(expiry) AS exp_date, ;
premium, IIF((adjcancel > gdEndDate OR adjlapse > gdEndDate), "I", polstatus) AS pol_status, adddate ;
FROM cims!member ;
WHERE tpacode = gcFundCode ;
	AND adddate < gdStartDate ;
	AND TTOD(expiry) >= gdStartDate ;
	AND !EMPTY(adddate) ;
ORDER BY 10, 5 ;	
INTO CURSOR aladata	
*************************************
oSheet = oWorkBook.WorkSheets.Add()
WITH oSheet
	.Name = "Member"
	.Cells(1, 1).Value = "Fee Cover Start From"
	.Cells(1, 2).Value = gdStartDate
	.Cells(1, 3).Value = "To"
	.Cells(1, 4).Value = gdEndDate
ENDWITH 	
DO GenTitle
lnRows = 4
SELECT aladata
DO WHILE !EOF()
	WITH oSheet
		.Cells(lnRows, 1).Value = adddate
		.Cells(lnRows, 2).Value = [=TEXT("]+ALLTRIM(policy_no)+[",0)]
		.Cells(lnRows, 3).Value = plan
		.Cells(lnRows, 4).Value = name
		.Cells(lnRows, 5).Value = surname
		.Cells(lnRows, 6).Value = pol_date
		.Cells(lnRows, 7).Value = eff_date && G
		.Cells(lnRows, 8).Value = exp_date  && H
		.Cells(lnRows, 9).Value = premium  && I
		.Cells(lnRows,10).Value = pol_status && J
		.Cells(lnRows,11).Value = "=IF(A"+ALLTRIM(STR(lnRows))+" >= $B$1, F"+ALLTRIM(STR(lnRows))+", IF(F"+ALLTRIM(STR(lnRows))+" < $B$1, $B$1, F"+ALLTRIM(STR(lnRows))+"))"  && K
		.Cells(lnRows,12).Value = "=IF(H"+ALLTRIM(STR(lnRows))+" > $D$1, $D$1, H"+ALLTRIM(STR(lnRows))+")"  && L
		.Cells(lnRows,13).Value = "=IF(OR(F"+ALLTRIM(STR(lnRows))+" > $D$1, H"+ALLTRIM(STR(lnRows))+" < $B$1), 0, 1)" && M
		.Cells(lnRows,14).Value = "=IF(OR(F"+ALLTRIM(STR(lnRows))+" > $D$1, H"+ALLTRIM(STR(lnRows))+" < $B$1), 0, L"+ALLTRIM(STR(lnRows))+"-K"+ALLTRIM(STR(lnRows))+"+1)" && N
		.Cells(lnRows,15).Value = "=(I"+ALLTRIM(STR(lnRows))+"/365.25)*N"+ALLTRIM(STR(lnRows))
		.Cells(lnRows,16).Value = adddate				
	ENDWITH 
	lnRows = lnRows + 1	
	SKIP 	
ENDDO 		
*
WAIT WINDOW "Last Reinstate" NOWAIT 
SELECT policy_no, name, surname, product As plan, TTOD(policy_date) AS pol_date, TTOD(effective) As eff_date, TTOD(expiry) AS exp_date, ;
premium, polstatus AS pol_status, adjrein, adddate ;
FROM cims!member ;
WHERE tpacode = gcFundCode ;
	AND adjrein < gdStartDate ;
	AND !EMPTY(adjrein) ;
	AND ALLTRIM(polstatus) = "R" ;
ORDER BY 10, 5 ;	
INTO CURSOR aladata	

SELECT aladata
DO WHILE !EOF()
	WITH oSheet
		.Cells(lnRows, 1).Value = adjrein
		.Cells(lnRows, 2).Value = [=TEXT("]+ALLTRIM(policy_no)+[",0)]
		.Cells(lnRows, 3).Value = plan
		.Cells(lnRows, 4).Value = name
		.Cells(lnRows, 5).Value = surname
		.Cells(lnRows, 6).Value = pol_date
		.Cells(lnRows, 7).Value = eff_date && G
		.Cells(lnRows, 8).Value = exp_date  && H
		.Cells(lnRows, 9).Value = premium  && I
		.Cells(lnRows,10).Value = pol_status
		.Cells(lnRows,11).Value = "=IF(A"+ALLTRIM(STR(lnRows))+" >= $B$1, G"+ALLTRIM(STR(lnRows))+", IF(G"+ALLTRIM(STR(lnRows))+" < $B$1, $B$1, G"+ALLTRIM(STR(lnRows))+"))"  && L
		.Cells(lnRows,12).Value = "=IF(H"+ALLTRIM(STR(lnRows))+" > $D$1, $D$1, H"+ALLTRIM(STR(lnRows))+")"  && M
		.Cells(lnRows,13).Value = "=IF(H"+ALLTRIM(STR(lnRows))+" < $B$1, 0, 1)" && M
		.Cells(lnRows,14).Value = "=IF(M"+ALLTRIM(STR(lnRows))+" = 0, 0, L"+ALLTRIM(STR(lnRows))+"-K"+ALLTRIM(STR(lnRows))+"+1)" && N
		.Cells(lnRows,15).Value = "=(I"+ALLTRIM(STR(lnRows))+"/365.25)*N"+ALLTRIM(STR(lnRows))
		.Cells(lnRows,16).Value = adddate				
	ENDWITH 
	lnRows = lnRows + 1
	SKIP 	
ENDDO 		
******************************
*Add New
WAIT WINDOW "This Month New Member" NOWAIT 
SELECT policy_no, name, surname, product As plan, TTOD(policy_date) AS pol_date, TTOD(effective) As eff_date, TTOD(expiry) AS exp_date, ;
premium, IIF((adjcancel > gdEndDate OR adjlapse > gdEndDate), "", polstatus) AS pol_status, adddate ;
FROM cims!member ;
WHERE tpacode = gcFundCode ;
	AND adddate BETWEEN gdStartDate AND gdEndDate ;
	AND !ALLTRIM(IIF((adjcancel > gdEndDate OR adjlapse > gdEndDate), "", polstatus)) $ "CLR" ;
ORDER BY 10, 5 ;	
INTO CURSOR aladata	

SELECT aladata
oSheet = oWorkBook.WorkSheets(2)	
WITH oSheet
	.Name = "Add New"
	.Cells(1, 1).Value = "Fee Cover Start From"
	.Cells(1, 2).Value = gdStartDate
	.Cells(1, 3).Value = "To"
	.Cells(1, 4).Value = gdEndDate
ENDWITH 	
***********
DO GenTitle	
***********
lnRows = 4
SELECT aladata
DO WHILE !EOF()
	WITH oSheet
		.Cells(lnRows, 1).Value = adddate
		.Cells(lnRows, 2).Value = [=TEXT("]+ALLTRIM(policy_no)+[",0)]
		.Cells(lnRows, 3).Value = plan
		.Cells(lnRows, 4).Value = name
		.Cells(lnRows, 5).Value = surname
		.Cells(lnRows, 6).Value = pol_date
		.Cells(lnRows, 7).Value = eff_date && G
		.Cells(lnRows, 8).Value = exp_date  && H
		.Cells(lnRows, 9).Value = premium  && I
		.Cells(lnRows,10).Value = pol_status
		.Cells(lnRows,11).Value = "=F"+ALLTRIM(STR(lnRows))  && L
		.Cells(lnRows,12).Value = "=IF(H"+ALLTRIM(STR(lnRows))+" > $D$1, $D$1, H"+ALLTRIM(STR(lnRows))+")"  && M
		.Cells(lnRows,13).Value = "=IF(OR(F"+ALLTRIM(STR(lnRows))+" > $D$1, H"+ALLTRIM(STR(lnRows))+" < $B$1), 0, 1)" && M
		.Cells(lnRows,14).Value = "=IF(OR(F"+ALLTRIM(STR(lnRows))+" > $D$1, H"+ALLTRIM(STR(lnRows))+" < $B$1), 0, L"+ALLTRIM(STR(lnRows))+"-K"+ALLTRIM(STR(lnRows))+"+1)" && N
		.Cells(lnRows,15).Value = "=(I"+ALLTRIM(STR(lnRows))+"/365.25)*N"+ALLTRIM(STR(lnRows))
	ENDWITH 
	lnRows = lnRows + 1
	SKIP 	
ENDDO
*
WAIT WINDOW "This Month Reinstate(no lapse) Member" NOWAIT 
SELECT policy_no, name, surname, product As plan, TTOD(policy_date) AS pol_date, TTOD(effective) As eff_date, TTOD(expiry) AS exp_date, ;
premium, polstatus AS pol_status, adjrein, adddate ;
FROM cims!member ;
WHERE tpacode = gcFundCode ;
	AND adjrein BETWEEN gdStartDate AND gdEndDate ;
	AND ALLTRIM(polstatus) = "R" ;
ORDER BY 10, 5 ;	
INTO CURSOR aladata	
*********************************
DO GenTitle	
***********
SELECT aladata
DO WHILE !EOF()
	WITH oSheet
		.Cells(lnRows, 1).Value = adjrein
		.Cells(lnRows, 2).Value = [=TEXT("]+ALLTRIM(policy_no)+[",0)]
		.Cells(lnRows, 3).Value = plan
		.Cells(lnRows, 4).Value = name
		.Cells(lnRows, 5).Value = surname
		.Cells(lnRows, 6).Value = pol_date
		.Cells(lnRows, 7).Value = eff_date && G
		.Cells(lnRows, 8).Value = exp_date  && H
		.Cells(lnRows, 9).Value = premium  && I
		.Cells(lnRows,10).Value = pol_status
		.Cells(lnRows,11).Value = "=G"+ALLTRIM(STR(lnRows))  && L
		.Cells(lnRows,12).Value = "=IF(H"+ALLTRIM(STR(lnRows))+" > $D$1, $D$1, H"+ALLTRIM(STR(lnRows))+")"  && M
		.Cells(lnRows,13).Value = "=IF(OR(F"+ALLTRIM(STR(lnRows))+" > $D$1, H"+ALLTRIM(STR(lnRows))+" < $B$1), 0, 1)" && M
		.Cells(lnRows,14).Value = "=IF(OR(F"+ALLTRIM(STR(lnRows))+" > $D$1, H"+ALLTRIM(STR(lnRows))+" < $B$1), 0, L"+ALLTRIM(STR(lnRows))+"-K"+ALLTRIM(STR(lnRows))+"+1)" && N
		.Cells(lnRows,15).Value = "=(I"+ALLTRIM(STR(lnRows))+"/365.25)*N"+ALLTRIM(STR(lnRows))
		.Cells(lnRows,16).Value = adddate				
	ENDWITH 
	lnRows = lnRows + 1
	SKIP 	
ENDDO 		
*
WAIT WINDOW "This Month Reinstate Member" NOWAIT 
SELECT policy_no, name, surname, product As plan, TTOD(policy_date) AS pol_date, TTOD(effective) As eff_date, TTOD(expiry) AS exp_date, ;
premium, polstatus AS pol_status, adjrein, adddate ;
FROM cims!member ;
WHERE tpacode = gcFundCode ;
	AND adjlapse BETWEEN gdStartDate AND gdEndDate ;
	AND ALLTRIM(polstatus) = "L" ;
ORDER BY 10, 5 ;	
INTO CURSOR aladata	
*********************************
oSheet = oWorkBook.WorkSheets(3)	
WITH oSheet
	.Name = "Reinstate"
	.Cells(1, 1).Value = "Fee Cover Start From"
	.Cells(1, 2).Value = gdStartDate
	.Cells(1, 3).Value = "To"
	.Cells(1, 4).Value = gdEndDate
ENDWITH 	
***********
DO GenTitle	
***********
lnRows = 4
SELECT aladata
DO WHILE !EOF()
	WITH oSheet
		.Cells(lnRows, 1).Value = adjrein
		.Cells(lnRows, 2).Value = [=TEXT("]+ALLTRIM(policy_no)+[",0)]
		.Cells(lnRows, 3).Value = plan
		.Cells(lnRows, 4).Value = name
		.Cells(lnRows, 5).Value = surname
		.Cells(lnRows, 6).Value = pol_date
		.Cells(lnRows, 7).Value = eff_date && G
		.Cells(lnRows, 8).Value = exp_date  && H
		.Cells(lnRows, 9).Value = premium  && I
		.Cells(lnRows,10).Value = pol_status
		.Cells(lnRows,11).Value = "=G"+ALLTRIM(STR(lnRows))  && L
		.Cells(lnRows,12).Value = "=IF(H"+ALLTRIM(STR(lnRows))+" > $D$1, $D$1, H"+ALLTRIM(STR(lnRows))+")"  && M
		.Cells(lnRows,13).Value = "=IF(OR(F"+ALLTRIM(STR(lnRows))+" > $D$1, H"+ALLTRIM(STR(lnRows))+" < $B$1), 0, 1)" && M
		.Cells(lnRows,14).Value = "=IF(OR(F"+ALLTRIM(STR(lnRows))+" > $D$1, H"+ALLTRIM(STR(lnRows))+" < $B$1), 0, L"+ALLTRIM(STR(lnRows))+"-K"+ALLTRIM(STR(lnRows))+"+1)" && N
		.Cells(lnRows,15).Value = "=(I"+ALLTRIM(STR(lnRows))+"/365.25)*N"+ALLTRIM(STR(lnRows))
		.Cells(lnRows,16).Value = adddate				
	ENDWITH 
	lnRows = lnRows + 1
	SKIP 	
ENDDO 		
******************************
*Cancel & Lapse
WAIT WINDOW "This Month Cancel Member" NOWAIT 
SELECT policy_no, name, surname, product As plan, TTOD(policy_date) AS pol_date, TTOD(effective) As eff_date, TTOD(expiry) AS exp_date, ;
premium, polstatus AS pol_status, adjcancel, adddate ;
FROM cims!member ;
WHERE tpacode = gcFundCode ;
	AND adjcancel BETWEEN gdStartDate AND gdEndDate ;
	AND ALLTRIM(polstatus) $ "CSD" ;
ORDER BY 10, 5 ;	
INTO CURSOR aladata	

oSheet = oWorkBook.WorkSheets(4)
WITH oSheet
	.Name = "Expired"
	.Cells(1, 1).Value = "Fee Cover Start From"
	.Cells(1, 2).Value = gdStartDate
	.Cells(1, 3).Value = "To"
	.Cells(1, 4).Value = gdEndDate
ENDWITH 	
***********
DO GenTitle	
***********
lnRows = 4
SELECT aladata
DO WHILE !EOF()
	WITH oSheet
		.Cells(lnRows, 1).Value = adjcancel
		.Cells(lnRows, 2).Value = [=TEXT("]+ALLTRIM(policy_no)+[",0)]
		.Cells(lnRows, 3).Value = plan
		.Cells(lnRows, 4).Value = name
		.Cells(lnRows, 5).Value = surname
		.Cells(lnRows, 6).Value = pol_date && F
		.Cells(lnRows, 7).Value = eff_date && G
		.Cells(lnRows, 8).Value = exp_date  && H
		.Cells(lnRows, 9).Value = premium  && I
		.Cells(lnRows,10).Value = pol_status
		.Cells(lnRows,11).Value = "=F"+ALLTRIM(STR(lnRows))  && L
		.Cells(lnRows,12).Value = "=$B$1-1"  && M
		.Cells(lnRows,13).Value = 1 &&"=IF(H"+ALLTRIM(STR(lnRows))+" >= $B$1, 0, 1)" && M
		.Cells(lnRows,14).Value = "=IF(M"+ALLTRIM(STR(lnRows))+" = 0, 0, L"+ALLTRIM(STR(lnRows))+"-K"+ALLTRIM(STR(lnRows))+"+1)" && N
		.Cells(lnRows,15).Value = "=(I"+ALLTRIM(STR(lnRows))+"/365.25)*N"+ALLTRIM(STR(lnRows))
		.Cells(lnRows,16).Value = adddate		
	ENDWITH 
	lnRows = lnRows + 1
	SKIP 	
ENDDO
WAIT WINDOW "This Month Lapse Member" NOWAIT
SELECT policy_no, name, surname, product As plan, TTOD(policy_date) AS pol_date, TTOD(effective) As eff_date, TTOD(expiry) AS exp_date, ;
premium, polstatus AS pol_status, adjlapse, adddate ;
FROM cims!member ;
WHERE tpacode = gcFundCode ;
	AND adjlapse BETWEEN gdStartDate AND gdEndDate ;
	AND ALLTRIM(polstatus) = "L" ;
ORDER BY 10, 5 ;	
INTO CURSOR aladata	

DO WHILE !EOF()
	WITH oSheet
		.Cells(lnRows, 1).Value = adjlapse
		.Cells(lnRows, 2).Value = [=TEXT("]+ALLTRIM(policy_no)+[",0)]
		.Cells(lnRows, 3).Value = plan
		.Cells(lnRows, 4).Value = name
		.Cells(lnRows, 5).Value = surname
		.Cells(lnRows, 6).Value = pol_date
		.Cells(lnRows, 7).Value = eff_date && G
		.Cells(lnRows, 8).Value = exp_date  && H
		.Cells(lnRows, 9).Value = premium  && I
		.Cells(lnRows,10).Value = pol_status
		.Cells(lnRows,11).Value = "=H"+ALLTRIM(STR(lnRows))  && L
		.Cells(lnRows,12).Value = "=$B$1-1"  && M
		.Cells(lnRows,13).Value = 0 && "=IF(H"+ALLTRIM(STR(lnRows))+" < $B$1, 0, 1)" && M
		.Cells(lnRows,14).Value = "=IF(M"+ALLTRIM(STR(lnRows))+" = 0, 0, L"+ALLTRIM(STR(lnRows))+"-K"+ALLTRIM(STR(lnRows))+"+1)" && N
		.Cells(lnRows,15).Value = "=(I"+ALLTRIM(STR(lnRows))+"/365.25)*N"+ALLTRIM(STR(lnRows))
		.Cells(lnRows,16).Value = adddate		
	ENDWITH 
	lnRows = lnRows + 1
	SKIP 	
ENDDO 
*
ldLastDate = GOMONTH(gdStartDate, -1)
oSheet = oWorkBook.WorkSheets.Add()
WITH oSheet
	.Name = "Cover"
	.Cells(1,1).Value = "Fee Cover of "+ALLTRIM(CMONTH(gdStartDate))+" "+STR(YEAR(gdStartDate),4)
	.Cells(3,2).Value = "Amount"
	.Cells(3,3).Value = "Gross Premium"
	.Cells(3,4).Value = "Earn Premium"
	.Cells(4,1).Value = "B/F From "+LEFT(CMONTH(ldLastDate), 3)+" "+ALLTRIM(STR(YEAR(ldLastDate)))
	.Cells(4,2).Value = "=COUNT(Member!I:I)+COUNT(Expired!I:I)+COUNT(Reinstate!I:I)"	
	.Cells(4,3).Value = "=SUM(Member!I:I)+SUM(Expired!I:I)+SUM(Reinstate!I:I)"	
	.Cells(4,4).Value = "=SUM(Member!O:O)+SUM(Expired!O:O)+SUM(Reinstate!O:O)"	
	.Cells(5,1).Value = "Add New"
	.Cells(5,2).Value = "=COUNT('Add New'!I:I)"
	.Cells(5,3).Value = "=SUM('Add New'!I:I)"
	.Cells(5,4).Value = "=SUM('Add New'!O:O)"
	.Cells(6,1).Value = "Expired & Cancel"
	.Cells(6,2).Value = "=-COUNT(Expired!I:I)"
	.Cells(6,3).Value = "=-SUM(Expired!I:I)"
	.Cells(6,4).Value = "=-SUM(Expired!O:O)"
	.Range("B6:D6").Borders(xlEdgeBottom).LineStyle = xlContinuous	
	.Cells(7,2).Value = "=SUM(B4:B6)"	
	.Cells(7,3).Value = "=SUM(C4:C6)"	
	.Cells(7,4).Value = "=SUM(D4:D6)"	
	.Range("B7:C7").Borders(xlEdgeBottom).LineStyle = xlDouble
	.Cells(8,1).Value = "Fee Rate"
	.Cells(8,4).Value = 0.06
	.Range("D8:D8").Borders(xlEdgeBottom).LineStyle = xlContinuous
	.Cells(9,1).Value = "Total Fee"
	.Cells(9,4).Value = "=D7*D8"
	.Range("D9:D9").Borders(xlEdgeBottom).LineStyle = xlDouble
	.Columns("A:A").ColumnWidth = 20	
	.Columns("B:D").ColumnWidth = 15
	.Columns("B:B").NumberFormat = '#,##0;[Red]-#,##0;"-"'	
	.Columns("C:D").NumberFormat = '#,##0.00;[Red]-#,##0.00;"-"'
	.Cells(8,4).NumberFormat = "0.00%"
	.Rows("3:3").HorizontalAlignment = xlCenter
	.Rows("3:3").VerticalAlignment = xlBottom
	.Cells.RowHeight = 20	
ENDWITH 	
*xlDouble
oWorkBook.SaveAs(lcExcelFile)
oExcel.Visible = .F.
oExcel.Quit
WAIT WINDOW " Transfer Sucess ......" TIMEOUT 5
*****************************************
PROCEDURE Gentitle

WITH oSheet
	.Cells(3, 1).Value = "Trans Date"
	.Cells(3, 2).Value = "Policy No"
	.Cells(3, 3).Value = "Plan"
	.Cells(3, 4).Value = "Name"
	.Cells(3, 5).Value = "Surname"
	.Cells(3, 6).Value = "Policy Date"
	.Cells(3, 7).Value = "Eff Date"
	.Cells(3, 8).Value = "Exp Date"
	.Cells(3, 9).Value = "Premium"
	.Cells(3,10).Value = "Pol Status"
	.Cells(3,11).Value = "Start Date"
	.Cells(3,12).Value = "End Date"
	.Cells(3,13).Value = "Counts"	
	.Cells(3,14).Value = "Days"
	.Cells(3,15).Value = "Earn Premium"
	.Cells(3,16).Value = "Add Date"	
	.Columns("A:A").ColumnWidth = 10
	.Columns("B:C").ColumnWidth = 20
	.Columns("D:E").ColumnWidth = 30	
	.Columns("F:P").ColumnWidth = 15
	.Columns("M:N").ColumnWidth = 8
	.Range("F:H").NumberFormat = 'd/m/yyyy'	
	.Range("K:L").NumberFormat = 'd/m/yyyy'		
	.Range("I:I").NumberFormat = '#,##0.00;[Red]-#,##0.00;"-"'
	.Range("M:N").NumberFormat = '#,##0;[Red]-#,##0;"-"'
	.Range("O:O").NumberFormat = '#,##0.00;[Red]-#,##0.00;"-"'		
	.Rows("3:3").HorizontalAlignment = xlCenter
	.Rows("3:3").VerticalAlignment = xlBottom	
	.Cells.RowHeight = 20	
ENDWITH 	
	
	








