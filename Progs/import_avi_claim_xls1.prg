CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Claim data", "Select")
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
CREATE DBF (lcDbf) FREE (policy_no C(30), claimant C(30), nric C(30), admit T, discharge T, ctype C(2), claimno C(10), charge Y, paid Y, ;
	pol_holder C(60), cust_id C(20), plan C(20), plan_id C(10), effective T, expiry T, deductible Y)
***************************************************
lnFieldCount = 9
lnRow = 2
DIMENSION laData[16]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 3).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE i = 1
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			laData[i] = IIF(TYPE("laData[i]") = "N", STR(laData[i],10), laData[i])
		CASE i = 3
			laData[i] =  IIF(ISNULL(laData[i]), laData[2], laData[i])
		CASE INLIST(i, 4,5)
			laData[i] = ALLTRIM(STR(laData[i]))
			laData[i] =  CTOD(RIGHT(laData[i],2)+"/"+SUBSTR(laData[i], 5,2)+"/"+LEFT(laData[i],4))
		OTHERWISE 
			laData[i] =  IIF(ISNULL(laData[i]), "", laData[i])
		ENDCASE 	
	ENDFOR 
	IF !EMPTY(laData[3])
		SELECT policy_name, customer_id, product, plan_id, effective, expiry, insure ;
		FROM cims!member ;
		WHERE tpacode = "AVI" AND policy_no = laData[3] ;
		INTO ARRAY laMember
		IF _TALLY > 0
			laData[10] = laMember[1]
			laData[11] = laMember[2]
			laData[12] = laMember[3]
			laData[13] = laMember[4]
			laData[14] = laMember[5]
			laData[15] = laMember[6]
			laData[16] = laMember[7]
		ELSE 
			SELECT policy_name, customer_id, product, plan_id, effective, expiry, insure ;
			FROM cims!member ;
			WHERE tpacode = "AVI" AND policy_group = laData[1] ;
			INTO ARRAY laMember
			IF _TALLY > 0
				laData[10] = laMember[1]
			ELSE 
				laData[10] = ""
				laData[11] = ""
				laData[12] = ""
				laData[13] = ""
				laData[14] = {}
				laData[15] = {}
				laData[16] = 0
			ENDIF 
		ENDIF 		
		**********	
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
=MESSAGEBOX("Finished.....")
USE 
oExcel.quit


FUNCTION chgMonth(tcMonth)

DIMENSION laMonth[12]
laMonth[1] = "JAN"
laMonth[2] = "FEB"
laMonth[3] = "MAR"
laMonth[4] = "APR"
laMonth[5] = "MAY"
laMonth[6] = "JUN"
laMonth[7] = "JUL"
laMonth[8] = "AUG"
laMonth[9] = "SEP"
laMonth[10] = "OCT"
laMonth[11] = "NOV"
laMonth[12] = "DEC"

RETURN STR(ASCAN(laMonth, UPPER(tcMonth)),2)
