CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Select ACE Summit data file", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
CREATE DBF (lcDbf) FREE (paiddate D, policy_no C(30), name C(40), surname C(40), poltype C(10), duedate D, sumins Y, plan C(20))

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)
oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
***************************************************
lnFieldCount = 7
lnRow = 2
DIMENSION laData[8]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 1).Value)
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value	
		DO CASE 
		CASE INLIST(i, 2, 3, 4, 5)
			laData[i] = ALLTRIM(laData[i])
		CASE INLIST(i, 1, 6)
			laData[i] = STR(laData[i],8)
			laData[i] = CTOD(RIGHT(laData[i],2)+"/"+SUBSTR(laData[i],5,2)+"/"+LEFT(laData[i],4))
			IF !EMPTY(laData[i])
				laData[i] = DATE(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]))
			ENDIF 
		OTHERWISE 
			laData[i] = IIF(ISNULL(laData[i]), 0, laData[i])
		ENDCASE 
	ENDFOR 
	laData[8] = ICASE(LEFT(laData[5],2) = "HS", ALLTRIM(STR(laData[7])), LEFT(laData[5],2) = "HB", "HB", laData[5])
	IF !EMPTY(laData[1])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
oExcel.quit
**********************
lnArea = SELECT()
SELECT (lnArea)
BROWSE 
*
GO TOP 
IF RECCOUNT() = 0
	RETURN 
ENDIF 	
IF !USED("member")
	USE cims!member IN 0 ORDER policy
ENDIF 	
SELECT (lnArea)
SCAN 
	IF SEEK("ACE"+policy_no+plan, "member", "pol_plan")
		?member.policy_no
		??member.product
		REPLACE member.lastpaid WITH paiddate, ;
			member.oldexpiry WITH duedate
		?? "Last Paid "
		?? member.lastpaid
		*********************************
		m.fundcode = member.tpacode
		m.policy_no = member.policy_no
		m.plan = member.product
		m.plan_id = member.plan_id
		m.lastpaid = member.lastpaid
		m.duedate = member.oldexpiry
		m.l_update = DATETIME()
		m.l_users = gcUserName	
		m.filename = lcDataFile
		INSERT INTO cims!reinstate FROM MEMVAR 
		*********************************
	ENDIF 
ENDSCAN 
SELECT (lnArea)
USE 		
=MESSAGEBOX("Finished.....")

