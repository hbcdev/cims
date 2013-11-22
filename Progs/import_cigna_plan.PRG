CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Cigna Plan data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")

CREATE DBF (lcDbf) FREE (prodcode C(10), prodtype C(2), cover_code C(10), cover_desc C(80), billtype C(2), sum_ins Y, g_prem_m Y, n_prem_m Y, g_prem_q Y, n_prem_q Y, ;
		g_prem_s Y, n_prem_s Y, g_prem_a Y, n_prem_a Y, plancode C(20), cover_thai C(50))

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
	*
oSheet = oWorkBook.worksheets(1)
	
?DBF()
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
***************************************************
lnFieldCount = 14
lnRow = 3
DIMENSION laData[16]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 1).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
		IF TYPE("laData[i]") = "N"
			laData[i] = LTRIM(STR(laData[i]))
		ENDIF 	
	ENDFOR
	laData[15] = ALLTRIM(laData[1])+"-"+ALLTRIM(laData[2])
	IF SEEK(SUBSTR(laData[3], 3, 3), "category", "item_grp")
		laData[16] = category.description
	ELSE 
		laData[16] = ""
	ENDIF 		
	IF !EMPTY(laData[1])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
USE 
=MESSAGEBOX("Finished.....")
oExcel.quit 