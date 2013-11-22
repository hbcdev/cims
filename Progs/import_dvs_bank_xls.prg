CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS;XLSX", "SMG data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
lcAlias = ""
lcDbf = FORCEEXT(lcDataFile, ".DBF")
*
CREATE DBF (lcDbf) FREE (Policy_no C(30), EmpID C(20), NameT C(40), SnameT C(40), BankName C(40), BrName C(40), Account C(20), Natid C(13))
lcAlias = ALIAS()

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
	*
oSheet = oWorkBook.worksheets(1)
	
?DBF()
***************************************************
lnFieldCount = 8
lnRow = 2
DIMENSION laData[8]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 2).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
		IF TYPE("laData[i]") = "N"
			laData[i] = ALLTRIM(STR(laData[i]))
		ENDIF 	
	ENDFOR
	INSERT INTO (lcDbf) FROM ARRAY laData
	lnRow = lnRow + 1
ENDDO
BROWSE 
oExcel.quit 