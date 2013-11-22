IF EMPTY(gcFundCode) AND EMPTY(gdStartNo) AND EMPTY(gdEndNo)
	RETURN 
ENDIF

gcSaveTo = "\\DRAGON1\ACCOUNT\"

SELECT *;
FROM cims!wt;
WHERE wt_no BETWEEN gcStartNo AND gcEndNo;
	AND total <> 0;
	AND tax <> 0;
ORDER BY wt_no;
INTO CURSOR wtReport1
SELECT wt_no, wt_date, fund_taxid, paid_to, address, prov_taxid, total, wt, tax, ;
	IIF(MOD(RECNO(),10) = 0, INT(RECNO()/10), INT(RECNO()/10)+1) as page ;
FROM wtreport1 ;
INTO CURSOR curWT

SELECT curWT
IF _TALLY <= 0
	RETURN 
ENDIF 

oExcel = CREATEOBJECT("Excel.Application")
oBook = oExcel.workBooks.Add()
oSheet = oBook.Worksheets(1)
oSheet.name = "PND53"
WITH oSheet
	.Columns("D:D").ColumnWidth = 40
	.Columns("E:E").ColumnWidth = 60
	.Range("H:H").NumberFormat = "#"	
	.Range("I:J").NumberFormat = '#,##0.00;[Red](#,##0.00);""'
ENDWITH 
*
lnRow = 1
WITH oSheet
	.Cells(lnRow,1).Value = "No."	
	.Cells(lnRow,2).Value = "Tax ID."
	.Cells(lnRow,3).Value = "Prefix"
	.Cells(lnRow,4).Value = "Vendor Name"
	.Cells(lnRow,5).Value = "Address"
	.Cells(lnRow,6).Value = "Paid Date"	
	.Cells(lnRow,7).Value = "Tax Type"
	.Cells(lnRow,8).Value = "Tax Rate"
	.Cells(lnRow,9).Value = "Paid Amt."
	.Cells(lnRow,10).Value = "Tax Amt."
	.Cells(lnRow,11).Value = "Condition"
ENDWITH 
*
lnRow = 2
SELECT curWT
DO WHILE !EOF()
	WAIT WINDOW TRANSFORM(RECNO(), "@Z99,999") NOWAIT 
	WITH oSheet
		.Cells(lnRow,1).Value = RECNO()
		.Cells(lnRow,2).Value = prov_taxid
		.Cells(lnRow,3).Value = ""
		.Cells(lnRow,4).Value = paid_to
		.Cells(lnRow,5).Value = STRTRAN(STRTRAN(address, CHR(13), " "), CHR(10), " ")
		.Cells(lnRow,6).Value = wt_date
		.Cells(lnRow,7).Value = "ค่าบริการ"
		.Cells(lnRow,8).Value = wt
		.Cells(lnRow,9).Value = total
		.Cells(lnRow,10).Value = tax
		.Cells(lnRow,11).Value = "1"	
	ENDWITH 
	lnRow = lnRow + 1
	SKIP 
ENDDO 
lcExcelCover = ADDBS(gcSaveTo)+ALLTRIM(STR(YEAR(gdStartDate)))+"-"+STRTRAN(STR(MONTH(gdStartDate),2), " ", "0")+" "+gcFundCode+"_WT53_Cover_"+ALLTRIM(CMONTH(gdStartDate))+"_"+ALLTRIM(STR(YEAR(gdStartDate)))
oBook.SaveAs(lcExcelCover)
oExcel.Quit

USE IN wtreport1
USE IN curWT