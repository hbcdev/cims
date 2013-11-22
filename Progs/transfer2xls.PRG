PARAMETERS tcTable
IF PARAMETERS() = 0
	tcTable = GETFILE("DBF", "Enter Table To Covert")
ENDIF
USE (tctable) ALIAS clm

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.WorkBooks.Add
oWorkSheet = oExcel.WorkSheets.Add
