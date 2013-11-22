SET PROCEDURE TO progs\utility
SET SAFETY ON 
*****************************
gcFundCode = "PIT"
gdStartDate = {^2008-03-01}
gdEndDate = {^2008-12-31}
gcSaveTo = "F:\Report\PIT\"+ALLTRIM(STR(YEAR(gdEndDate)))+"-"+STRTRAN(STR(MONTH(gdEndDate),2), " ", "0")+"-"+STRTRAN(STR(DAY(gdEndDate),2), " ", "0")
IF !DIRECTORY(gcSaveTo)
	MD (gcSaveTo)
ENDIF 	
*
SELECT claim.policy_no, member.policy_name, claim.client_name, claim.service_type, claim.acc_date, ;
claim.fcharge, claim.fbenfpaid, IIF(EMPTY(claim.fax_by), claim.scharge, 0) AS scharge, ;
IIF(EMPTY(claim.fax_by), claim.sbenfpaid, 0) AS sbenfpaid, ;
claim.indication_admit, claim.result, claim.return_date, claim.policy_holder ;
FROM cims!claim LEFT JOIN cims!member ;
	ON claim.policy_no = member.policy_no ;
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
		.Name = "Claim Detail"
		.Cells(1,1).Value = "สรุปการเรียกร้องสินไหมของโรงเรียน "+ALLTRIM(policy_name)+"("+ALLTRIM(policy_no)+")"
		.Range("A1:H1").MergeCells = .T.			
		.Cells(2,1).Value = "ตั้งแต่วันที่ "+DTOC(gdStartDate)+" ถึง วันที่ "+DTOC(gdEndDate)
		.Range("A2:H2").MergeCells = .T.					
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
		.Range("A3:A4").MergeCells = .T.
		.Range("B3:B4").MergeCells = .T.
		.Range("C3:C4").MergeCells = .T.		
		.Range("D3:D4").MergeCells = .T.				
		.Range("E3:F3").MergeCells = .T.	
		.Range("G3:H3").MergeCells = .T.	
	 	.Range("A1:H4").HorizontalAlignment = 3				
		.Range("E:H").NumberFormat = '#,##0.00;[Red](#,##0.00);""'
		.Columns("A:A").ColumnWidth = 8
		.Columns("B:B").ColumnWidth = 40
		.Columns("C:C").ColumnWidth = 10
		.Columns("D:D").ColumnWidth = 15
		.Columns("E:E").ColumnWidth = 20
		.Columns("F:F").ColumnWidth = 20
		.Columns("G:G").ColumnWidth = 20
		.Columns("H:H").ColumnWidth = 20
		.Cells.RowHeight = 20
	ENDWITH 	
	lnNo = 1
	lnRow = 5
	lcPolicyNo = policy_no	
	lcPolHolder = policy_name
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
		.Cells(lnRow,5).Value = "=SUM(E5:E"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,6).Value = "=SUM(F5:F"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,7).Value = "=SUM(G5:G"+ALLTRIM(STR(lnRow-1))+")"
		.Cells(lnRow,8).Value = "=SUM(F5:F"+ALLTRIM(STR(lnRow-1))+")"
	ENDWITH 	
	**	
	lcCol = ["A1:H]+ALLTRIM(STR(lnRow))+["]
	*
	DO SetBorder WITH lcCol	
	**
	oWorkBook.WorkSheets("Sheet2").Delete
	oWorkBook.WorkSheets("Sheet3").Delete
	**	
	lcPolHolder = STRTRAN(lcPolHolder, ["], [-])
	lcFile = ADDBS(gcSaveTo)+STRTRAN(ALLTRIM(lcPolicyNo), "/","-")+IIF(EMPTY(lcPolHolder), "", "("+ALLTRIM(lcPolHolder)+")_")+CMONTH(gdEndDate)+"_"+ALLTRIM(STR(YEAR(gdEndDate)))
	oWorkBook.Saveas(lcFile)
ENDDO
oExcel.Quit
*******************************************************
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
