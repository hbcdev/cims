#INCLUDE "include\excel9.h"

SET DELETED ON 
SET PROCEDURE TO progs\utility

PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption

CLEAR 	
SET SAFETY OFF 	
OPEN DATABASE cims
gcTemp = "D:\"
llRun = .F.
********************	
gcFundCode = "BKI"
*******************************
gcStartDate = "From"
gcEndDate = "To"
glMonth = .T.
gdStartDate = DATE(YEAR(GOMONTH(DATE(),-1)), MONTH(GOMONTH(DATE(),-1)),1)
gdEndDate = GOMONTH(gdStartDate, 1) -1
gnOption = 1
gcSaveTo = LEFT(gcTemp,3)+"REPORT\"
cAgent = "MC"
*
DO FORM form\dateentry
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
*************************
IF !DIRECTORY(gcSaveTo)
	MKDIR &gcSaveTo
ENDIF 	
*************************
*			
? "BKI Report From "+DTOC(gdStartDate)+" To "+DTOC(gdEndDate) 
***********************
lcOldDir = SYS(5)+SYS(2003)
lcExcelFile = ADDBS(gcSaveTo)+gcFundCode + "_"+cAgent+"_Cliam_of " +  STRTRAN(DTOC(gdStartDate), "/", "")+"_"+STRTRAN(DTOC(gdEndDate), "/", "")
******************************************************
USE cims!claimbyadmitdate
*
IF RECCOUNT("claimbyadmitdate") = 0
	RETURN 
ENDIF 
*	
lcDate = "Admit Date ตั้งแต่ "+tlongdate(gdStartDate)+"-"+tlongdate(gdEndDate)

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()
oSheet = oWorkBook.WorkSheets(1)
WITH oSheet.PageSetup
	.CenterHeader = "ประวัติการเรียกร้องสินไหม"+CHR(10)+lcDate
	.RightHeader = "พิมพ์เมื่อ"+tlongdate(DATE())
       .PrintGridlines = .F.
        .Orientation = xlLandscape
        .PaperSize = xlPaperA4
        .FirstPageNumber = xlAutomatic
        .Zoom = 90
ENDWITH

WITH oSheet
	.Columns("A:A").ColumnWidth = 10
	.Columns("B:B").ColumnWidth = 20
	.Columns("C:C").ColumnWidth = 10
	.Columns("D:D").ColumnWidth = 10
	.Columns("E:E").ColumnWidth = 12
	.Columns("F:F").ColumnWidth = 12
	.Columns("G:G").ColumnWidth = 10
	.Columns("H:H").ColumnWidth = 20
	.Columns("I:I").ColumnWidth = 30	
	.Columns("E:F").NumberFormat = '#,##0.00;[Red](#,##0.00);""'	
ENDWITH 
***********
lnRow = 1
SELECT claimbyadmitdate
GO TOP 
DO WHILE !EOF()
	lcPolNo = policy_no
	STORE "" TO lcCntC, lcSumC, lcSumE, lcSumF
	lcRange = ["A]+ALLTRIM(STR(lnRow+1))+":I"+ALLTRIM(STR(lnRow+1))+["]
	WITH oSheet
		.Range(&lcRange).Borders( xlEdgeTop).LineStyle = 1
		.Range(&lcRange).Borders( xlEdgeTop).Weight = 2
		.Range(&lcRange).Borders( xlEdgeTop).ColorIndex = -4105
		.Cells(lnRow, 1).Value = policy_name
		.Cells(lnRow+1,1).Value = "เลขที่สินไหม"
		.Cells(lnRow+1,2).Value = "วันที่รักษา"
		.Cells(lnRow+1,3).Value = "จำนวนวัน"
		.Cells(lnRow+1,4).Value = "ผลประโยชน์"
		.Cells(lnRow+1,5).Value = "เรียกร้อง"
		.Cells(lnRow+1,6).Value = "สินไหมจ่าย"
		.Cells(lnRow+1,7).Value = "จ่ายโดย"
		.Cells(lnRow+1,8).Value = "สถานพยาบาล"
		.Cells(lnRow+1,9).Value = "โรค"
		.Range(&lcRange).Borders(xlEdgeBottom).LineStyle = 1
		.Range(&lcRange).Borders(xlEdgeBottom).Weight = 2
		.Range(&lcRange).Borders(xlEdgeBottom).ColorIndex = -4105
	ENDWITH
	lnRow = lnRow + 3
	DO WHILE policy_no = lcPolNo AND !EOF()
		lcName = client_name		
		WITH oSheet
			.Cells(lnRow, 1).Value = "ผู้รับความคุ้มครอง "+client_name
			.Cells(lnRow, 7).Value = "En. No. "+client_no
			.Cells(lnRow,9).Value = "แผน "+plan
		ENDWITH		 	
		lnRow = lnRow + 1	
		lnOldRow = lnRow
		DO WHILE policy_no = lcPolNo AND client_name = lcName AND !EOF() 	
			WITH oSheet
				.Cells(lnRow,1).Value = notify_no
				.Cells(lnRow,2).Value = DTOC(admis_date)+"-"+DTOC(disc_date)
				.Cells(lnRow,3).Value = TTOD(disc_date)-TTOD(admis_date)+1
				.Cells(lnRow,4).Value = service_type
				.Cells(lnRow,5).Value = scharge
				.Cells(lnRow,6).Value = sbenfpaid
				.Cells(lnRow,7).Value = ICASE(result = "P1", "Cash", result = "P5", "Credit", "D")
				.Cells(lnRow,8).Value = prov_name
				.Cells(lnRow,9).Value = thainame
			ENDWITH 
			lnRow = lnRow + 1
			SKIP 
		ENDDO 
		lcRange = ["B]+ALLTRIM(STR(lnRow))+":F"+ALLTRIM(STR(lnRow))+["]
		WITH oSheet
			.Range(&lcRange).Borders( xlEdgeTop).LineStyle = 1
			.Range(&lcRange).Borders( xlEdgeTop).Weight = 2
			.Range(&lcRange).Borders( xlEdgeTop).ColorIndex = -4105
			
			.Cells(lnRow, 1).Value = "รวม:"
			.Cells(lnRow, 2).Value = "=COUNT(C"+ALLTRIM(STR(lnOldRow))+":C"+ALLTRIM(STR(lnRow-1))+")"
			.Cells(lnRow, 3).Value = "=SUM(C"+ALLTRIM(STR(lnOldRow))+":C"+ALLTRIM(STR(lnRow-1))+")"
			.Cells(lnRow, 5).Value = "=SUM(E"+ALLTRIM(STR(lnOldRow))+":E"+ALLTRIM(STR(lnRow-1))+")"
			.Cells(lnRow, 6).Value = "=SUM(F"+ALLTRIM(STR(lnOldRow))+":F"+ALLTRIM(STR(lnRow-1))+")"
			
			.Range(&lcRange).Borders(xlEdgeBottom).LineStyle = 1
			.Range(&lcRange).Borders(xlEdgeBottom).Weight = 2
			.Range(&lcRange).Borders(xlEdgeBottom).ColorIndex = -4105
		ENDWITH 	
		lcCntC = lcCntC+"C"+ALLTRIM(STR(lnRow))+"+"
		lcSumC = lcSumC+"C"+ALLTRIM(STR(lnRow))+"+"
		lcSumE = lcSumE+"E"+ALLTRIM(STR(lnRow))+"+"
		lcSumF = lcSumF+"F"+ALLTRIM(STR(lnRow))+"+"
		lnRow = lnRow + 2		
	ENDDO 
	oSheet.Cells(lnRow, 1).Value = "รวมทั้งหมด:"
	oSheet.Cells(lnRow, 2).Value = "="+LEFT(lcCntC, LEN(lcCntC)-1)
	oSheet.Cells(lnRow, 3).Value = "="+LEFT(lcSumC, LEN(lcSumC)-1)
	oSheet.Cells(lnRow, 5).Value = "="+LEFT(lcSumE, LEN(lcSumE)-1)
	oSheet.Cells(lnRow, 6).Value = "="+LEFT(lcSumF, LEN(lcSumF)-1)
	
	lcRange = ["B]+ALLTRIM(STR(lnRow))+":F"+ALLTRIM(STR(lnRow))+["]	
	oSheet.Range(&lcRange).Borders(xlEdgeBottom).LineStyle = 1
	oSheet.Range(&lcRange).Borders(xlEdgeBottom).Weight = 2
	oSheet.Range(&lcRange).Borders(xlEdgeBottom).ColorIndex = -4105			
	
	lnRow = lnRow + 2			
ENDDO   	
oSheet.Cells.RowHeight = 20
*
WITH oExcel
	.WorkSheets("Sheet2").Delete
	.WorkSheets("Sheet3").Delete
	.ActiveWindow.DisplayGridlines
ENDWITH 
*
lcExcelFile = ADDBS(gcSaveTo)+gcFundCode + "_"+cAgent+"_Cliam_of_" +  STRTRAN(DTOC(gdStartDate), "/", "")+"_"+STRTRAN(DTOC(gdEndDate), "/", "")
oWorkBook.saveas(lcExcelFile)