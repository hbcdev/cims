SET SAFETY OFF 	
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
SELECT Member.agentcy, Member.agency_name, Member.agent, Member.agent_name,;
 Claim.policy_no, Claim.client_name, Claim.plan, Claim.notify_date,;
 IIF(EMPTY(Claim.fax_by),Claim.scharge,Claim.fcharge) AS charge,;
 IIF(EMPTY(Claim.fax_by),Claim.sbenfpaid,Claim.fbenfpaid) AS paid,;
 Claim.paid_date, Claim.exgratia, Claim.result, Claim.notify_no;
FROM  cims!claim LEFT JOIN cims!Member ;
 ON  Claim.fundcode = Member.tpacode;
 	AND Claim.policy_no  = Member.policy_no;
 	AND Claim.plan = Member.product;
WHERE Claim.fundcode = gcfundcode;
  AND TTOD(Claim.notify_date) BETWEEN gdStartDate AND gdEndDate;
ORDER BY Member.agentcy;
INTO CURSOR curAgent
IF _TALLY = 0
	=MESSAGEBOX("ไม่มีข้อมูลที่เกิดขึ้นในช่วงวันที่ "+DTOC(gdStartDate)+" ถึง "+DTOC(gdEndDate),0,"Agent to excel")
	RETURN
ENDIF
oXls = CREATEOBJECT("EXcel.Application")
oBook = oxls.workbooks.Add
oSheet =oBook.WorkSheets("Sheet1")
oSheet.name = "Agent"
*******************************************
* กำหนดค่า Page setup
WITH oSheet.PageSetup
	.PrintTitleRows = "$1:$4"
	.PrintTitleColumns = "$A:$A"
	.PaperSize = 5
	.Orientation = 2
	.Zoom = 75
ENDWITH	
********
WITH oSheet
	.Cells(1,4) = "รายงานสรุปการจ่ายสินไหมทดแทนผลประโยชน์ค่ารักษาพยาบาล"
	.Cells(2,4) = "ตั้งแต่วันที่ " + dTOc(gdStartDate)+" ถึง "+ dTOc(gdEndDate) &&"ประจำเดือน "+TMONTH(gdStartDate)
	.Cells(3,7) = "ค่าสินไหมทดแทน"
	**************************
	.Cells(4,1) = "รหัสตัวแทน"
	.Cells(4,2) = "ชื่อตัวแทน"
	.Cells(4,3) = "หน่วย"
	.Cells(4,4) = "เลขที่กรมธรรม์"
	.Cells(4,5) = "ชื่อผู้เอาประกัน"	
	.Cells(4,6) = "ประเภทความคุ้มครอง"	
	.Cells(4,7) = "วันที่เรียกร้อง"
	.Cells(4,8) = "ค่าใช้จ่ายจริง"	
	.Cells(4,9) = "ค่าทดแทนตามกรมธรรม์"	
	.Cells(4,10) = "วันที่จ่ายสินไหม"	
 	.Cells(4,11) = "หมายเหตุ"	
 	********************
 	.Range("D1:G1").Merge
 	.Range("D2:G2").Merge
 	.Range("G3:J3").Merge
 	.Range("A:K").HorizontalAlignment = 3
 	.Range("H:I").HorizontalAlignment = 1
 	.Columns("A:K").Autofit
 	*******************************
 	.Columns("A:A").ColumnWidth = 15
 	.Columns("B:B").ColumnWidth = 30
 	.Columns("C:C").ColumnWidth = 30
 	.Columns("D:D").ColumnWidth = 20
 	.Columns("E:E").ColumnWidth = 30
 	.Columns("K:K").ColumnWidth = 40
 	.Columns("H:H").NumberFormat = "#,##0.00"
 	.Columns("I:I").NumberFormat = "#,##0.00"
 	**********************************
ENDWITH 	
*End Page setup
******************************************
lnRow = 5
SELECT curAgent
SCAN
	lcAgent = agentcy
	STORE 0 TO lnCharge, lnPaid
	DO WHILE agentcy = lcAgent AND !EOF()
		WAIT WINDOW lcAgent+" Record "+TRANSFORM(RECNO(),"@Z 99,999") NOWAIT AT 20,25
		DO CASE 
		CASE result = "W2"
			lcNote = "รอเอกสารทางการแพทย์"
		CASE result = "W5"
			lcNote = "รอวางบิลจากทางโรงพยาบาล"
		CASE result = "W6"
			lcNote = "อยู่ระหว่างการพิจารณาค่าสินไหม"
		CASE result = "A1"
			lcNote = "อยู่ระหว่างการออกเช็คจ่าย"
		OTHERWISE 
			lcNote = ""	
		ENDCASE 
		*********************
		WITH oSheet
			.Cells(lnRow,1) = ALLTRIM(agentcy)
			.Cells(lnRow,2) = ALLTRIM(agency_name)
			.Cells(lnRow,3) = ALLTRIM(agent_name)
			.Cells(lnRow,4) = ALLTRIM(policy_no)
			.Cells(lnRow,5) = ALLTRIM(client_name)
			.Cells(lnRow,6) = ALLTRIM(plan)
			.Cells(lnRow,7) = IIF(EMPTY(notify_date), "", TTOD(notify_date))
			.Cells(lnRow,8) = charge
			.Cells(lnRow,9) = IIF(LEFT(result,1) = "P", paid, 0)
			.Cells(lnRow,10) = IIF(EMPTY(paid_date), "", paid_date)
			.Cells(lnRow,11) = lcNote
			.Cells(lnrow,12) = result
			.Cells(lnrow,13) = notify_no
		ENDWITH
		***************
		lnCharge = lnCharge + charge
		lnPaid = lnPaid + IIF(LEFT(result,1) = "P", paid, 0)
		lnRow = lnRow + 1
		SKIP 
	ENDDO
	WITH oSheet
		.Cells(lnRow	,8) = lnCharge
		.Cells(lnRow	,9) = lnPaid
		lnRow = lnRow + 1
		****
		.Cells(lnRow,1).Select
		.HPageBreaks.Add(oXls.ActiveCell)
	ENDWITH
ENDSCAN
lcFile = PUTFILE("Save Agent report To", "Agent "+CMONTH(gdStartDate)+","+STR(YEAR(gdStartDate),4), "XLS") 
oBook.SaveAs(lcFile)
oXls.Quit
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
oSheet.Range("A1").Select
