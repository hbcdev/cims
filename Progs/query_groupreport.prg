#INCLUDE "include\excel9.h"

gcFundCode = "PIT"
gdStartDate = {^2008-10-01}
gdEndDate = {^2008-10-31}
gcSaveTo = "F:\Report\PIT\"+ALLTRIM(STR(YEAR(gdEndDate)))+"-"+STRTRAN(STR(MONTH(gdEndDate),2), " ", "0")+"-"+STRTRAN(STR(DAY(gdEndDate),2), " ", "0")
IF !DIRECTORY(gcSaveTo)
	MD (gcSaveTo)
ENDIF 	
gcSaveTo = ADDBS(gcSaveTo) + "School"
IF !DIRECTORY(gcSaveTo)
	MD (gcSaveTo)
ENDIF 	

*
SELECT claim.policy_no, claim.client_name, claim.service_type, claim.acc_date, ;
claim.fcharge, claim.fbenfpaid, IIF(EMPTY(claim.fax_by), claim.scharge, 0) AS scharge, ;
IIF(EMPTY(claim.fax_by), claim.sbenfpaid, 0) AS sbenfpaid, ;
claim.indication_admit, claim.result, claim.return_date, claim.policy_holder ;
FROM cims!claim ;
WHERE claim.fundcode = gcFundCode ;
	AND claim.return_date BETWEEN gdStartDate AND gdEndDate ;
	AND claim.result LIKE "P%" ;
ORDER BY claim.policy_no ;
INTO CURSOR curClaim
*******************
IF RECCOUNT("curClaim") < 0
	RETURN 
ENDIF 	
oExcel = CREATEOBJECT("Excel.Application")

SELECT curClaim
DO WHILE !EOF()
	WAIT WINDOW policy_holder NOWAIT 
	oWorkBook = oExcel.Workbooks.Add()
	oSheet = oWorkBook.WorkSheets("Sheet1")
	WITH oSheet
		.PageSetup.Orientation = xlLandscape
		.PageSetup.Zoom = 100
		.PageSetup.LeftMargin = 1.2
		.PageSetup.RightMargin = 0.5
		.Cells(1,1).Value = "สรุปการเรียกร้องสินไหมของโรงเรียน "+ALLTRIM(policy_holder)
		.Cells(1,4).Value = "ตั้งแต่วันที่ "+DTOC(gdStartDate)+" ถึง วันที่ "+DTOC(gdEndDate)
		.Cells(3,1).Value = "ลำดับที่"
		.Cells(3,2).Value = "ชื่อ-นามสกุล"
		.Cells(3,3).Value = "ประเภท"
		.Cells(3,4).Value = "วันที่เกิดเหตุ"
		.Cells(3,5).Value = "Fax Claim"
		.Cells(3,7).Value = "Reimbursement"	
		.Cells(4,5).Value = "โรงพยาบาลเรียกเก็บ"
		.Cells(4,6).Value = "ค่าสินไหมจ่าย"
		.Cells(4,7).Value = "โรงพยาบาลเรียกเก็บ"
		.Cells(4,8).Value = "ค่าสินไหมจ่าย"
		.Range("A1:C1").MergeCells = .T.			
		.Range("D1:F1").MergeCells = .T.							
		.Range("A3:A4").MergeCells = .T.
		.Range("B3:B4").MergeCells = .T.
		.Range("C3:C4").MergeCells = .T.
		.Range("D3:D4").MergeCells = .T.
		.Range("E3:F3").MergeCells = .T.	
		.Range("G3:H3").MergeCells = .T.			
		.Rows("3:4").HorizontalAlignment = xlCenter
		.Rows("3:4").VerticalAlignment = xlBottom
		.Rows("3:4").WrapText = .T.
		.Range("E:H").NumberFormat = '#,##0.00;[Red](#,##0.00);""'
		.Columns("A:A").ColumnWidth = 10
		.Columns("B:B").ColumnWidth = 50
		.Columns("C:C").ColumnWidth = 8
		.Columns("D:H").ColumnWidth = 12
		.Cells.RowHeight = 20
		.Rows("4:4").RowHeight = 33		
	ENDWITH 	
	lnNo = 1
	lnRow = 5
	lcPolicyNo = policy_no	
	lcPolHolder = policy_holder
	DO WHILE policy_no = lcPolicyNo AND !EOF()
		WITH oSheet
			.Cells(lnRow,1).Value = lnNo
			.Cells(lnRow,2).Value = client_name
			.Cells(lnRow,3).Value = service_type
			.Cells(lnRow,4).Value = acc_date
			.Cells(lnRow,5).Value = IIF(service_type = "OPD" AND result = "P5", scharge, fcharge)
			.Cells(lnRow,6).Value = IIF(service_type = "OPD" AND result = "P5", sbenfpaid, fbenfpaid)
			.Cells(lnRow,7).Value = IIF(service_type = "OPD" AND result = "P5", 0, scharge)
			.Cells(lnRow,8).Value = IIF(service_type = "OPD" AND result = "P5", 0, sbenfpaid)
		ENDWITH 
		lnNo = lnNo + 1
		lnRow  = lnRow + 1
		SKIP 	
	ENDDO
	WITH oSheet
		.Cells(lnRow,4).Value = "ยอดรวม"
		.Cells(lnRow,4).HorizontalAlignment = xlRight		
		.Cells(lnRow,5).Value = "=SUM(E5:E"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,6).Value = "=SUM(F5:F"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,7).Value = "=SUM(G5:G"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,8).Value = "=SUM(H5:H"+ALLTRIM(STR(lnRow-1))+")"
	ENDWITH 	
	**	
	DO SetLine WITH 5, lnRow
	**
	lcFile = ADDBS(gcSaveTo)+STRTRAN(ALLTRIM(lcPolicyNo), "/","-")+IIF(EMPTY(lcPolHolder), "", "("+ALLTRIM(lcPolHolder)+")_")+CMONTH(gdEndDate)+"_"+ALLTRIM(STR(YEAR(gdEndDate)))
	lcFile = STRTRAN(lcFile, '"', "")
	oWorkBook.Saveas(lcFile)
ENDDO
oExcel.Quit

PROCEDURE SetLine
PARAMETERS tnStart, tnEnd

IF EMPTY(tnStart) OR EMPTY(tnEnd)
	RETURN 
ENDIF 	

lcColExp = ["A3:H4"]
oSheet.Range(&lcColExp).Borders(xlEdgeTop).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlEdgeBottom).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlEdgeLeft).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlEdgeRight).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlInsideVertical).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlInsideHorizontal).LineStyle = xlContinuous
*
lcColExp = ["A]+ALLTRIM(STR(tnStart)) + [:H] + ALLTRIM(STR(tnEnd)) + ["]
oSheet.Range(&lcColExp).Borders(xlEdgeTop).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlEdgeBottom).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlEdgeLeft).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlEdgeRight).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlInsideVertical).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlInsideHorizontal).Weight = xlHairline
oSheet.Range(&lcColExp).Borders(xlInsideHorizontal).LineStyle = xlContinuous

lcColExp = ["A]+ALLTRIM(STR(tnEnd)) + [:H] + ALLTRIM(STR(tnEnd)) + ["]
oSheet.Range(&lcColExp).Borders(xlEdgeTop).Weight = xlThin
oSheet.Range(&lcColExp).Borders(xlEdgeTop).LineStyle = xlContinuous
oSheet.Range(&lcColExp).Borders(xlInsideVertical).LineStyle = xlNone