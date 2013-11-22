CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Select AII member data file", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
IF !USED("member")
	USE cims!member ORDER policy IN 0
ENDIF 	
*
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
CREATE DBF (lcDbf) FREE (person_no I, title C(20), name C(40), surname C(40), sumins Y, medical Y, payer C(50), policy_no C(30), title1 C(20), insured C(40), plan C(20), effdate T, expdate T)
***************************************************
lnFieldCount = 13
lnRow = 6
DIMENSION laData[lnFieldCount]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 1).Value)
	FOR i = 1 TO 7
		laData[i] = oSheet.Cells(lnRow,i).Value	
	ENDFOR 
	laData[8] = ALLTRIM(SUBSTR(oSheet.Cells(2,1).Value,52,20))		
	laData[9] = ALLTRIM(SUBSTR(oSheet.Cells(3,1).Value,23,8))	
	laData[10] = ALLTRIM(SUBSTR(oSheet.Cells(3,1).Value,31,40))				
	laData[11] = ALLTRIM(SUBSTR(oSheet.Cells(4,1).Value,17,20))	
	IF SEEK(laData[8], "member", "policy")
		laData[9] = member.title
		laData[10] = IIF(LEN(ALLTRIM(laData[10])) > LEN(ALLTRIM(member.name)), laData[10], member.name)
		laData[12] = member.effective
		laData[13] = member.expiry
	ENDIF 	
	IF !EMPTY(laData[1])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
=MESSAGEBOX("Finished ....")
BROWSE 
USE 
oExcel.quit