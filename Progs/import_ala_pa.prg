CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Select ALA member data file", "Select")
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
CREATE DBF (lcDbf) FREE (policy_no C(30), plan C(20), cust_id C(20), title C(20), name C(40), surname C(40), ;
	sex C(1), dob D, pol_date T, eff_date T, exp_date T, premium Y, prem_m Y, pol_status C(20), medical Y, opd_cr Y, due D, mop C(1), tremdate D, transdate D, datadate D, polstatus C(1))
***************************************************
lnFieldCount = 21
lnRow = 2
DIMENSION laData[22]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 1).Value)
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value	
		DO CASE 
		CASE INLIST(i, 4, 5, 6, 7, 14, 18)
			laData[i] = ALLTRIM(laData[i])
		CASE INLIST(i, 8, 9, 10, 11, 19, 20, 21)
			laData[i] = STR(laData[i],8)
			IF ALLTRIM(laData[i]) # "0" 
				laData[i] = CTOD(RIGHT(laData[i],2)+"/"+SUBSTR(laData[i],5,2)+"/"+STR(VAL(LEFT(laData[i],4))-543,4))
				*IF !EMPTY(laData[i])
				*	laData[i] = DATE(YEAR(laData[i])-543, MONTH(laData[i]), DAY(laData[i]))
				*ENDIF 
				IF INLIST(i, 9, 10, 11)
					laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 12, 00)
				ENDIF 	
			ENDIF 	
		OTHERWISE 
			laData[i] = IIF(ISNULL(laData[i]), 0, laData[i])
		ENDCASE 
	ENDFOR 
	IF !EMPTY(laData[1])
		laData[22] = ICASE(laData[14] = "Re-instate", "R", laData[14] = "Rescind", "S",  LEFT(laData[14], 1))
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
=MESSAGEBOX("Finished.....")
USE 
oExcel.quit