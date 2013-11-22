CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Falcon data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
CREATE DBF (lcDbf) FREE (Policy_no C(30), title1 C(20), insured C(30), person_no I, client_no c(20), title C(20), name C(40), surname C(40), plan C(20), Effdate T, Expdate T, medical Y)
***************************************************
lnFieldCount = 12
lnRow = 2
DIMENSION laData[lnFieldCount]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 1).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE i = 5
			IF TYPE("laData[i]") = "N"		
				laData[i] = ALLTRIM(STR(laData[i]))
			ELSE 
				laData[i] = IIF(ISNULL(laData[i]), "", laData[i])	
			ENDIF 	
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
		ENDCASE 
	ENDFOR 
	IF !EMPTY(laData[1])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
=MESSAGEBOX("Finished.....")
USE 
oExcel.quit