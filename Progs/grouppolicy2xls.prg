SET SAFETY OFF 	
SET PROCEDURE TO progs\utility
********************	
gcStartDate = "From"
gcEndDate = "To"
glMonth = .T.
gcFundCode = "PIT"
gdStartDate = DATE(YEAR(GOMONTH(DATE(),-1)), MONTH(GOMONTH(DATE(),-1)),1)
gdEndDate = DATE(YEAR(gdStartDate), MONTH(gdStartDate),IIF(INLIST(MONTH(gdStartDate), 1,3,5,7,8,10,12),31,IIF(MONTH(gdStartDate) = 2, 28,30)))
gnOption = 1
gcSaveTo = "F:\Report\"
DO FORM form\dateentry
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF

IF !DIRECTORY(gcSaveTo)
	MKDIR gcSaveTo
ENDIF 	

IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN
ENDIF 
**********
SET NOTIFY ON
SET TALK ON
*
SELECT Claim.policy_no, Member.policy_name, ; 
 SUM(IIF(EMPTY(Claim.fax_by),Claim.scharge,Claim.fcharge)) AS charge, ;
 SUM(IIF(EMPTY(Claim.fax_by),Claim.sbenfpaid,Claim.fbenfpaid)) AS paid ;
FROM  cims!claim LEFT JOIN cims!member ;
	ON Claim.policy_no = Member.policy_no ;
WHERE Claim.fundcode = gcfundcode;
  	AND INLIST(Claim.claim_with, "A", "P") ;
	AND TTOD(Claim.notify_date) BETWEEN gdStartDate AND gdEndDate ;
	AND Claim.result LIKE "P%" ;
GROUP BY 1, 2 ;  
ORDER BY Claim.policy_no ;
INTO CURSOR curAgent
IF _TALLY = 0
	=MESSAGEBOX("ไม่มีข้อมูลที่เกิดขึ้นในช่วงวันที่ "+DTOC(gdStartDate)+" ถึง "+DTOC(gdEndDate),0,"Agent to excel")
	RETURN
ENDIF
oXls = CREATEOBJECT("EXcel.Application")
oBook = oxls.workbooks.Add
oSheet =oBook.WorkSheets("Sheet1")
oSheet.name = "Claim Loss Ratio"
*******************************************
* กำหนดค่า Page setup
WITH oSheet.PageSetup
	.PrintTitleRows = "$1:$4"
	.PrintTitleColumns = "$A:$A"
	.PaperSize = 5
	.Orientation = 1
	.Zoom = 95
ENDWITH	
********
WITH oSheet
	.Cells(1,1) = "รายงานสรุปการจ่ายสินไหมทดแทนผลประโยชน์ค่ารักษาพยาบาล"
	.Cells(2,1) = "ประจำเดือน "+TMONTH(gdStartDate)
	.Cells(3,1) = "ค่าสินไหมทดแทน"
	**************************
	.Cells(4,1) = "เลขที่กรมธรรม์"
	.Cells(4,2) = "โรงเรียน"
	.Cells(4,3) = "ค่าใช้จ่ายจริง"	
	.Cells(4,4) = "ค่าทดแทนตามกรมธรรม์"	
 	********************
 	.Range("A1:D1").Merge
 	.Range("A2:D2").Merge
 	.Range("A3:D3").Merge
 	.Range("A1:D4").HorizontalAlignment = 3
 	.Columns("A:D").Autofit
 	*******************************
 	.Columns("A:A").ColumnWidth = 15
 	.Columns("B:B").ColumnWidth = 40
 	.Columns("C:C").ColumnWidth = 20
 	.Columns("D:D").ColumnWidth = 20
 	.Columns("C:C").NumberFormat = "#,##0.00"
 	.Columns("D:D").NumberFormat = "#,##0.00"
 	**********************************
ENDWITH 	
*End Page setup
******************************************
lnRow = 5
SELECT curAgent
SCAN
	WITH oSheet
		.Cells(lnRow,1) = ALLTRIM(policy_no)
		.Cells(lnRow,2) = ALLTRIM(policy_name)
		.Cells(lnRow,3) = charge
		.Cells(lnRow,4) = paid
	ENDWITH
	lnRow = lnRow + 1
ENDSCAN
WITH oSheet
	.Cells(lnRow,2) = "ยอดรวมทั้งสิ้น"
 	.Cells(lnRow,2).HorizontalAlignment = 4
	.Cells(lnRow	,3) = "=SUM(C5:C"+ALLTRIM(STR(lnRow-1))+")"
	.Cells(lnRow	,4) = "=SUM(D5:D"+ALLTRIM(STR(lnRow-1))+")"
ENDWITH
***********
lcCol = ["A1:D]+ALLTRIM(STR(lnRow))+["]
oSheet.Range(&lcCol).RowHeight = 20
*
oXls.WorkSheets("Sheet2").Delete
oXls.WorkSheets("Sheet3").Delete
*
DO SetBorder WITH lcCol
***********
lcFile = ADDBS(gcSaveTo)+"Policy Summary Report as of "+CMONTH(gdEndDate)+" "+STR(YEAR(gdEndDate),4)
oBook.SaveAs(lcFile)
oXls.Quit
****************************
PROCEDURE SetBorder
PARAMETERS tcRange

IF EMPTY(tcRange)
	RETURN 
ENDIF 	

WITH oSheet
	.Range(&tcRange).Borders(7).LineStyle = 1
	.Range(&tcRange).Borders(7).Weight = 2
	.Range(&tcRange).Borders(7).ColorIndex = -4105
	.Range(&tcRange).Borders(8).LineStyle = 1
	.Range(&tcRange).Borders(8).Weight = 2
	.Range(&tcRange).Borders(8).ColorIndex = -4105
	.Range(&tcRange).Borders(9).LineStyle = 1
	.Range(&tcRange).Borders(9).Weight = 2
	.Range(&tcRange).Borders(9).ColorIndex = -4105
	.Range(&tcRange).Borders(10).LineStyle = 1
	.Range(&tcRange).Borders(10).Weight = 2
	.Range(&tcRange).Borders(10).ColorIndex = -4105
	.Range(&tcRange).Borders(11).LineStyle = 1
	.Range(&tcRange).Borders(11).Weight = 2
	.Range(&tcRange).Borders(11).ColorIndex = -4105
	.Range(&tcRange).Borders(12).LineStyle = 1
	.Range(&tcRange).Borders(12).Weight = 2
	.Range(&tcRange).Borders(12).ColorIndex = -4105
	.Range("A1").Select
ENDWITH 	
