CLEAR 
CLOSE ALL 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "AVIVA data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
USE cims!member IN 0

lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
CREATE DBF (lcDbf) FREE (groupno C(30), empid C(30), policy_no C(30), provname C(40), assigncode C(1), benftype C(2), icd10 C(20), admit T, discharge T, ;
	charge Y, paid Y, deduc Y, copayment Y, claimtype C(2), noncover Y, mcdays I, diagcode C(30), currencyc C(3), clientname C(40), remarks C(50), prov_id C(10), ;
	pol_holder C(50), cust_id C(20), plan C(20), plan_id C(10), effective T, expiry T, deductible Y)
***************************************************
lnFieldCount = 20
lnRow = 2
DIMENSION laData[28]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 19).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE i = 1
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			laData[i] = IIF(TYPE("laData[i]") = "N", STR(laData[i],10), laData[i])
		CASE i = 3
			laData[i] =  IIF(ISNULL(laData[i]), laData[2], laData[i])
		CASE INLIST(i, 8,9)
			laData[i] = ALLTRIM(STR(laData[i]))
			laData[i] =  CTOD(RIGHT(laData[i],2)+"/"+SUBSTR(laData[i], 5,2)+"/"+LEFT(laData[i],4))
		OTHERWISE 
			laData[i] =  IIF(ISNULL(laData[i]), "", laData[i])
		ENDCASE 	
	ENDFOR 
	IF !EMPTY(laData[19])
		IF SEEK(LEFT(laData[3],30), "member", "policy")
			SCATTER FIELDS member.policy_name, member.customer_id, member.product, member.plan_id, member.effective, member.expiry, member.insure TO laMember
		ELSE 
			SCATTER FIELDS member.policy_name, member.customer_id, member.product, member.plan_id, member.effective, member.expiry, member.insure BLANK TO laMember
		ENDIF 	
		laData[22] = laMember[1]
		laData[23] = laMember[2]
		laData[24] = laMember[3]
		laData[25] = laMember[4]
		laData[26] = laMember[5]
		laData[27] = laMember[6]
		laData[28] = laMember[7]		
		laData[19] = UPPER(laData[19])
		laData[21] = ""
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
