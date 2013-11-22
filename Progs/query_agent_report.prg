#INCLUDE "include\excel9.h"

gcFundCode = "PIT"
gdStartDate = {^2008-03-01}
gdEndDate = {^2009-02-28}
gcSaveTo = "F:\Report\PIT\"+ALLTRIM(STR(YEAR(gdEndDate)))+"-"+STRTRAN(STR(MONTH(gdEndDate),2), " ", "0")+"-"+STRTRAN(STR(DAY(gdEndDate),2), " ", "0")
IF !DIRECTORY(gcSaveTo)
	MD (gcSaveTo)
ENDIF 	
gcSaveTo = ADDBS(gcSaveTo) + "Agent"
IF !DIRECTORY(gcSaveTo)
	MD (gcSaveTo)
ENDIF 	
*********************
SELECT member.agent, member.policy_no, member.policy_name, member.premium, ;
	SUM(IIF(claim.service_type # "IPD", 1, 0)) AS opd_noc, ;
	SUM(IIF(claim.service_type # "IPD", IIF(EMPTY(claim.fax_by), claim.scharge, claim.fcharge), 0)) AS opd_charge, ;
	SUM(IIF(claim.service_type # "IPD" AND result = "P", IIF(EMPTY(claim.fax_by), claim.sbenfpaid, claim.fbenfpaid), 0)) AS opd_paid, ;	
	SUM(IIF(claim.service_type # "IPD" AND result = "D", IIF(EMPTY(claim.fax_by), claim.scharge, claim.fcharge), 0)) AS opd_denied, ;	
	SUM(IIF(claim.service_type # "IPD" AND result = "W", IIF(EMPTY(claim.fax_by), claim.sbenfpaid, claim.fbenfpaid), 0)) AS opd_wait, ;		
	SUM(IIF(claim.service_type = "IPD", 1, 0)) AS ipd_noc, ;	
	SUM(IIF(claim.service_type = "IPD", IIF(EMPTY(claim.fax_by), claim.scharge, claim.fcharge), 0)) AS ipd_charge, ;
	SUM(IIF(claim.service_type = "IPD" AND result = "P", IIF(EMPTY(claim.fax_by), claim.sbenfpaid, claim.fbenfpaid), 0)) AS ipd_paid, ;
	SUM(IIF(claim.service_type = "IPD" AND result = "D", IIF(EMPTY(claim.fax_by), claim.scharge, claim.fcharge), 0)) AS ipd_denied, ;
	SUM(IIF(claim.service_type = "IPD" AND result = "W", IIF(EMPTY(claim.fax_by), claim.sbenfpaid, claim.fbenfpaid), 0)) AS ipd_wait ;	
FROM cims!member LEFT JOIN cims!claim ;
	ON member.tpacode = claim.fundcode ;
	AND member.policy_no = claim.policy_no ;
WHERE member.tpacode = gcFundCode ;
	AND TTOD(notify_date) <= gdEndDate ;
GROUP BY 1, 2, 3, 4 ;
ORDER BY 1, 2 ;
INTO CURSOR curAgent

SELECT curAgent
IF RECCOUNT() = 0
	RETURN 
ENDIF 	

oExcel = CREATEOBJECT("Excel.Application")

SELECT curAgent
DO WHILE !EOF()
	WAIT WINDOW policy_no NOWAIT 
	oWorkBook = oExcel.Workbooks.Add()
	oSheet = oWorkBook.WorkSheets("Sheet1")		
	WITH oSheet
		.PageSetup.Orientation = xlLandscape
		.PageSetup.Zoom = 65
		.PageSetup.LeftMargin = 0.5
		.PageSetup.RightMargin = 0.5
		.Cells(1,1).Value = "สรุปการเรียกร้องสินไหมของโรงเรียนในการดูแลของ "+ALLTRIM(agent)
		.Range("A1:C1").MergeCells = .T.			
		.Cells(1,4).Value = "ตั้งแต่เริ่มต้นกรมธรรม์จนถึงวันที่ "+DTOC(gdEndDate)
		.Range("D1:F1").MergeCells = .T.					
		.Cells(3,1).Value = "ลำดับที่"
		.Cells(3,2).Value = "เลขที่กรมธรรม์"
		.Cells(3,3).Value = "ชื่อโรงเรียน"
		.Cells(3,4).Value = "เบี้ยประกันสุทธิุ"
		.Cells(3,5).Value = "OPD"
		.Cells(4,5).Value = "จำนวนเคลม"		
		.Cells(4,6).Value = "โรงพยาบาลเรียกเก็บ"
		.Cells(4,7).Value = "ยอดสินไหมจ่าย"
		.Cells(4,8).Value = "ยอดปฏิเสธการจ่าย"		
		.Cells(4,9).Value = "ยอดรอการทำจ่าย"
		.Cells(3,10).Value = "IPD"			
		.Cells(4,10).Value = "จำนวนเคลม"		
		.Cells(4,11).Value = "โรงพยาบาลเรียกเก็บ"
		.Cells(4,12).Value = "ยอดสินไหมจ่าย"
		.Cells(4,13).Value = "ยอดปฏิเสธการจ่าย"		
		.Cells(4,14).Value = "ยอดรอการทำจ่าย"
		.Cells(3,15).Value = "ยอดจ่ายรวม"
		.Cells(3,16).Value = "Claim Ratio"
		.Range("A3:A4").MergeCells = .T.
		.Range("B3:B4").MergeCells = .T.
		.Range("C3:C4").MergeCells = .T.
		.Range("D3:D4").MergeCells = .T.
		.Range("O3:O4").MergeCells = .T.
		.Range("P3:P4").MergeCells = .T.
		.Range("E3:I3").MergeCells = .T.	
		.Range("J3:N3").MergeCells = .T.
		.Rows("3:4").HorizontalAlignment = xlCenter
		.Rows("3:4").VerticalAlignment = xlBottom
		.Rows("3:4").WrapText = .T.
		.Range("D:O").NumberFormat = '#,##0.00;[Red](#,##0.00);"-"'
		.Range("E:E").NumberFormat = '#,##0;[Red](#,##0);"-"'
		.Range("J:J").NumberFormat = '#,##0;[Red](#,##0);"-"'		
		.Range("P:P").NumberFormat = "0.00%"
		.Columns("A:A").ColumnWidth = 10
		.Columns("B:B").ColumnWidth = 12
		.Columns("C:C").ColumnWidth = 40
		.Columns("D:P").ColumnWidth = 12
		.Columns("E:E").ColumnWidth = 10
		.Columns("J:J").ColumnWidth = 10		
		.Cells.RowHeight = 20
	ENDWITH 	
	lnRow = 5
	lnNo = 0
	lcPlus = "+"
	lcAgent = agent
	DO WHILE agent = lcAgent AND !EOF()
		lnNo = lnNo + 1
		WITH oSheet
			.Cells(lnRow,1).Value = lnNo
			.Cells(lnRow,2).Value = policy_no
			.Cells(lnRow,3).Value = policy_name
			.Cells(lnRow,4).Value = premium
			.Cells(lnRow,5).Value = opd_noc
			.Cells(lnRow,6).Value = opd_charge
			.Cells(lnRow,7).Value = opd_paid
			.Cells(lnRow,8).Value = opd_denied
			.Cells(lnRow,9).Value = opd_wait
			.Cells(lnRow,10).Value = ipd_noc
			.Cells(lnRow,11).Value = ipd_charge
			.Cells(lnRow,12).Value = ipd_paid
			.Cells(lnRow,13).Value = ipd_denied
			.Cells(lnRow,14).Value = ipd_wait
			.Cells(lnRow,15).Value = "=G" + ALLTRIM(STR(lnRow)) + " + I" + ALLTRIM(STR(lnRow))+ "+ L" + ALLTRIM(STR(lnRow)) + " + N" + ALLTRIM(STR(lnRow))
			.Cells(lnRow,16).Value = "=O" + ALLTRIM(STR(lnRow)) + "/D" + ALLTRIM(STR(lnRow))
		ENDWITH 
		lnRow = lnRow + 1
		SKIP 
	ENDDO 		
	WITH oSheet
		.Cells(lnRow,3).Value = "ยอดรวม"	
		.Cells(lnRow,3).HorizontalAlignment = xlRight
		.Cells(lnRow,4).Value = "=SUM(D5:D"+ALLTRIM(STR(lnRow-1))+")"		
		.Cells(lnRow,5).Value = "=SUM(E5:E"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,6).Value = "=SUM(F5:F"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,7).Value = "=SUM(G5:G"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,8).Value = "=SUM(H5:H"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,9).Value = "=SUM(I5:I"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,10).Value = "=SUM(J5:J"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,11).Value = "=SUM(K5:K"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,12).Value = "=SUM(L5:L"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,13).Value = "=SUM(M5:M"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,14).Value = "=SUM(N5:N"+ALLTRIM(STR(lnRow-1))+")"				
		.Cells(lnRow,15).Value = "=SUM(O5:O"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,16).Value = "=O" + ALLTRIM(STR(lnRow)) + "/D" + ALLTRIM(STR(lnRow))
	ENDWITH 	
	*
	DO SetLine WITH 5, lnRow
	*
	lcFile = ADDBS(gcSaveTo)+ALLTRIM(lcAgent)+"_"+CMONTH(gdEndDate)+"_"+ALLTRIM(STR(YEAR(gdEndDate)))
	oWorkBook.Saveas(lcFile)
ENDDO
oExcel.Quit

PROCEDURE SetLine
PARAMETERS tnStart, tnEnd

IF EMPTY(tnStart) OR EMPTY(tnEnd)
	RETURN 
ENDIF 	

lcColExp = ["A3:P4"]
oSheet.Range(&lcColExp).Borders(xlEdgeTop).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlEdgeBottom).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlEdgeLeft).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlEdgeRight).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlInsideVertical).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlInsideHorizontal).LineStyle = xlContinuous
*
lcColExp = ["A]+ALLTRIM(STR(tnStart)) + [:P] + ALLTRIM(STR(tnEnd)) + ["]
oSheet.Range(&lcColExp).Borders(xlEdgeTop).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlEdgeBottom).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlEdgeLeft).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlEdgeRight).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlInsideVertical).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlInsideHorizontal).Weight = xlHairline
oSheet.Range(&lcColExp).Borders(xlInsideHorizontal).LineStyle = xlContinuous

lcColExp = ["A]+ALLTRIM(STR(tnEnd)) + [:P] + ALLTRIM(STR(tnEnd)) + ["]
oSheet.Range(&lcColExp).Borders(xlEdgeTop).Weight = xlThin
oSheet.Range(&lcColExp).Borders(xlEdgeTop).LineStyle = xlContinuous
