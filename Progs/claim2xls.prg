SET SAFETY OFF 	
********************	
gcStartDate = "From"
gcEndDate = "To"
glMonth = .T.
gcFundCode = "BKI"
*gdStartDate = DATE(YEAR(GOMONTH(DATE(),-1)), MONTH(GOMONTH(DATE(),-1)),1)
*gdEndDate = DATE(YEAR(gdStartDate), MONTH(gdStartDate),IIF(INLIST(MONTH(gdStartDate), 1,3,5,7,8,10,12),31,IIF(MONTH(gdStartDate) = 2, 28,30)))
gdStartDate = {^2008-11-01}
gdEndDate = {^2009-01-31}
gnOption = 1
gcSaveTo = "F:\Report\"
gcPolicyNo = "608010873"
*DO FORM form\rollingentry1
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF

IF !DIRECTORY(gcSaveTo)
	MKDIR gcSaveTo
ENDIF 	

IF EMPTY(gcFundCode) AND EMPTY(gcPolicyNo) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN
ENDIF 
**********
SET NOTIFY ON
SET TALK ON
*
oXls = CREATEOBJECT("Excel.Application")
oBook = oxls.workbooks.Add
*
SELECT Claim.notify_no, Claim.notify_date, Claim.client_name, Claim.plan, Claim.service_type, Claim.prov_name, Claim.admis_date, Claim.disc_date, ;
	Claim.illness1, Claim.illness2, Claim.illness3, Claim.scharge AS charge, Claim.sbenfpaid AS paid, Claim.snopaid AS nopaid, Claim.abenfpaid AS exgratia, ;
	Claim.sremain AS clientpaid,  Claim.ref_date AS rcvdate, Claim.indication_admit AS remark ;
FROM  cims!claim  ;
WHERE Claim.fundcode = gcfundcode;
	AND Claim.policy_no = gcPolicyNo ;
	AND Claim.result = "P1" ;
	AND Claim.return_date BETWEEN gdStartDate AND gdEndDate;
INTO CURSOR curClaim
IF _TALLY = 0
	=MESSAGEBOX("ไม่มีข้อมูลที่เกิดขึ้นในช่วงวันที่ "+DTOC(gdStartDate)+" ถึง "+DTOC(gdEndDate),0,"Agent to excel")
	RETURN	
ENDIF
DO genReport WITH "จ่ายให้กับผู้เอาประกัน", "sheet1"
***********************************
SELECT Claim.notify_no, Claim.client_name, Claim.plan, Claim.service_type, Claim.prov_name, Claim.admis_date, Claim.disc_date, ;
	Claim.illness1, Claim.illness2, Claim.illness3, Claim.fcharge AS charge, Claim.fbenfpaid AS paid, Claim.fnopaid AS nopaid, Claim.exgratia AS exgratia, ;
	Claim.fremain AS clientpaid, TTOD(Claim.notify_date) AS rcvdate, Claim.indication_admit AS remark ;
FROM  cims!claim  ;
WHERE Claim.fundcode = gcfundcode;
	AND Claim.policy_no = gcPolicyNo ;
	AND Claim.result = "P5" ;
	AND Claim.return_date BETWEEN gdStartDate AND gdEndDate;
INTO CURSOR curClaim
IF _TALLY = 0
	=MESSAGEBOX("ไม่มีข้อมูลที่เกิดขึ้นในช่วงวันที่ "+DTOC(gdStartDate)+" ถึง "+DTOC(gdEndDate),0,"Agent to excel")
	RETURN	
ENDIF
DO genReport WITH "จ่ายให้กับโรงพยาบาล", "sheet2"
**************************************
*
SELECT Claim.notify_no, Claim.client_name, Claim.plan, Claim.service_type, Claim.prov_name, Claim.admis_date, Claim.disc_date, ;
	Claim.illness1, Claim.illness2, Claim.illness3, ;
	IIF(EMPTY(Claim.fax_by), Claim.ref_date, TTOD(Claim.notify_date)) AS rcvdate, Claim.indication_admit AS remark, ;
	IIF(EMPTY(Claim.fax_by), Claim.scharge, Claim.fcharge) AS charge, ;
	IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid, Claim.fbenfpaid) AS paid, ;
	IIF(EMPTY(Claim.fax_by), Claim.snopaid, Claim.fnopaid) AS nopaid, ;
	IIF(EMPTY(Claim.fax_by), Claim.abenfpaid, Claim.exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), Claim.sremain, Claim.fremain) AS clientpaid ;
FROM  cims!claim  ;
WHERE Claim.fundcode = gcfundcode;
	AND Claim.policy_no = gcPolicyNo ;
	AND Claim.result = "W" ;
INTO CURSOR curClaim
IF _TALLY = 0
	=MESSAGEBOX("ไม่มีข้อมูลที่เกิดขึ้นในช่วงวันที่ "+DTOC(gdStartDate)+" ถึง "+DTOC(gdEndDate),0,"Agent to excel")
	RETURN	
ENDIF
DO genReport WITH "Outstanding Claim", "sheet3"
**************************************
*
lcFile = PUTFILE("Save Claim report To", "Claim Report "+CMONTH(gdStartDate)+","+STR(YEAR(gdStartDate),4), "XLS") 
oBook.SaveAs(lcFile)
oXls.Quit
*
**********************************
*
PROCEDURE genReport
PARAMETERS tcTitle, tcSheet

DO CASE 
CASE UPPER(tcSheet) = "SHEET1"
	oSheet =oBook.WorkSheets("Sheet1")
CASE UPPER(tcSheet) = "SHEET2"
	oSheet =oBook.WorkSheets("Sheet2")
CASE UPPER(tcSheet) = "SHEET3"
	oSheet =oBook.WorkSheets("Sheet3")	
OTHERWISE 
	oSheet =oBook.WorkSheets.add	
ENDCASE 	
oSheet.name = tcTitle
*******************************************
* กำหนดค่า Page setup
WITH oSheet.PageSetup
	.PrintTitleRows = "$1:$4"
	.PrintTitleColumns = "$A:$A"
	.PaperSize = 5
	.Orientation = 2
	.Zoom = 70
ENDWITH	
********
WITH oSheet
	.Cells(1,4) = "รายงานสรุปการจ่ายสินไหมทดแทนผลประโยชน์ค่ารักษาพยาบาล"
	.Cells(2,4) = "ตั้งแต่วันที่ " + dTOc(gdStartDate)+" ถึง "+ dTOc(gdEndDate) &&"ประจำเดือน "+TMONTH(gdStartDate)
	**************************
	.Cells(4,1) = "Notify No."
	.Cells(4,2) = "วันที่รับเอกสาร"
	.Cells(4,3) = "ชื่อผู้เอาประกัน"	
	.Cells(4,4) = "แผน"
	.Cells(4,5) = "ประเภทความคุ้มครอง"
	.Cells(4,6) = "โรงพยาบาล"	
	.Cells(4,7) = "วันที่เข้ารักษา"
	.Cells(4,8) = "วันที่ออก"
	.Cells(4,9) = "ICD 10 #1"
	.Cells(4,10) = "ICD 10 #2"
	.Cells(4,11) = "ICD 10 #3"		
	.Cells(4,12) = "โรงพยาบาลเรียกเก็บ"	
	.Cells(4,13) = "ยอดเงินไม่คุ้มครอง"	
	.Cells(4,14) = "ยอดเงินจ่าย"	
	.Cells(4,15) = "ยอดอนุโลมจ่าย"
	.Cells(4,16) = "ส่วนเกินผู้เอาประกันจ่าย"
 	.Cells(4,17) = "หมายเหตุ"	
 	********************
 	.Range("D1:G1").Merge
 	.Range("D2:G2").Merge
 	.Columns("A:P").Autofit
 	*******************************
 	.Columns("A:A").ColumnWidth = 13
 	.Columns("B:B").ColumnWidth = 14
 	.Columns("C:C").ColumnWidth = 30
 	.Columns("D:D").ColumnWidth = 10 	
 	.Columns("E:P").ColumnWidth = 12
 	.Columns("F:G").ColumnWidth = 10
 	.Columns("I:K").ColumnWidth = 10
 	.Columns("L:P").NumberFormat = "#,##0.00"
 	.Columns("Q:Q").ColumnWidth = 100
 	**********************************
ENDWITH 	
*End Page setup
*************************************
lnRow = 5
SELECT curClaim
SCAN
	WAIT WINDOW tcSheet+" Record "+TRANSFORM(RECNO(),"@Z 99,999") NOWAIT AT 20,25
	WITH oSheet
		.Cells(lnRow,1) = notify_no
		.Cells(lnRow,2) = IIF(EMPTY(rcvdate), "", rcvdate)
		.Cells(lnRow,3) = ALLTRIM(client_name)
		.Cells(lnRow,4) = ALLTRIM(plan)
		.Cells(lnRow,5) = ALLTRIM(service_type)
		.Cells(lnRow,6) = ALLTRIM(prov_name)
		.Cells(lnRow,7) = TTOD(admis_date)
		.Cells(lnRow,8) = TTOD(disc_date)
		.Cells(lnRow,9) = illness1
		.Cells(lnRow,10) = illness2
		.Cells(lnRow,11) = illness3
		.Cells(lnrow,12) = charge
		.Cells(lnrow,13) = nopaid
		.Cells(lnrow,14) = paid
		.Cells(lnrow,15) = exgratia
		.Cells(lnrow,16) =clientpaid
		.Cells(lnrow,17) = ALLTRIM(remark)
	ENDWITH
	lnRow = lnRow + 1
ENDSCAN
DO setLine
****************************
PROCEDURE SetLine

osheet.Cells.Borders(7).LineStyle = 1
osheet.Cells.Borders(7).Weight = 2
osheet.Cells.Borders(7).ColorIndex = -4105
osheet.Cells.Borders(8).LineStyle = 1
osheet.Cells.Borders(8).Weight = 2
osheet.Cells.Borders(8).ColorIndex = -4105
osheet.Cells.Borders(9).LineStyle = 1
osheet.Cells.Borders(9).Weight = 2
osheet.Cells.Borders(9).ColorIndex = -4105
osheet.Cells.Borders(10).LineStyle = 1
osheet.Cells.Borders(10).Weight = 2
osheet.Cells.Borders(10).ColorIndex = -4105
osheet.Cells.Borders(11).LineStyle = 1
osheet.Cells.Borders(11).Weight = 2
osheet.Cells.Borders(11).ColorIndex = -4105
osheet.Cells.Borders(12).LineStyle = 1
osheet.Cells.Borders(12).Weight = 2
osheet.Cells.Borders(12).ColorIndex = -4105
*oSheet.Range("A1").Select