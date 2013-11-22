CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "ACE Group data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
CREATE DBF (lcDbf) FREE (policy_no C(30), plan C(20), id_no C(20), cert_no C(20), title C(30), name C(40), surname C(40), sex C(1), dob D, policy_iss D, pol_exp D, ;
	member_eff D, member_exp D, prem_ipd Y, prem_opd Y, pay_mode C(1), employee C(10), status C(10), terminate D, remark C(80), adddate D, old_pol C(30))
?DBF()
*************************************************************
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)
oExcel.ActiveWindow.Activate
lnAmountSheet = oWorkBook.Worksheets.Count
*
lnFieldCount = 20
DIMENSION laData[22]

FOR j = 1 TO lnAmountSheet
	oSheet = oWorkBook.worksheets(j)
	?oSheet.name
	oExcel.ActiveWindow.FreezePanes = .F.
	*
	ldAddDate = oSheet.Cells(4,12).Value
	ldDate = IIF(EMPTY(ldAddDate), ldDate, ldAddDate)
	lnRow = IIF(j = 5, 5, 6)
	*
	DO CovertDbf
ENDFOR 
BROWSE 
USE 
=MESSAGEBOX("Finished.....")
oExcel.quit 
**********************************************
PROCEDURE CovertDbf
*
DO WHILE !ISNULL(oSheet.Cells(lnRow, 1).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value		
		DO CASE 
		CASE INLIST(i, 2, 4)
			laData[i] = IIF(ISNULL(laData[i]), 0, laData[i]) 		
			IF TYPE("laData[i]") = "N"
				laData[i] = ALLTRIM(STR(laData[i]))
			ENDIF 	
		CASE INLIST(i, 9, 10, 11, 12, 13)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			IF EMPTY(laData[i])
				laData[i] = {}
			ENDIF 	
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF 	
			IF !EMPTY(laData[i])
				laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 00, 00)
			ENDIF 	
		OTHERWISE 
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
		ENDCASE 
	ENDFOR
	laData[2] = IIF(ISALPHA(laData[2]), laData[2], ALLTRIM(STR(VAL(laData[2]))))
	laData[3] = IIF(EMPTY(laData[3]), "", STR(laData[3], 13))
	laData[21] = ldDate
	laData[22] = ICASE(laData[1] = "G0000001-00", "G0000001", laData[1] = "G0000001-01", "G0000101", laData[1] = "G0000001-02", "G0000103", laData[1] = "G0000001-03", "G0000102", laData[1])
	IF !EMPTY(laData[1])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
