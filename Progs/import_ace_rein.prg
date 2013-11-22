CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Select ALA member data file", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
CREATE DBF (lcDbf) FREE (reindate D, policy_no C(30), name C(40), surname C(40), poltype C(10), sumins Y, plan C(20)) 
*
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)	
***************************************************
lnFieldCount = 6
lnRow = 2
DIMENSION laData[7]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 1).Value)
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value	
		DO CASE 
		CASE INLIST(i, 2, 3, 4, 5)
			IF TYPE("laData[i]") = "N"
				laData[i] = STR(laData[i],10)
			ENDIF 	
			laData[i] = ALLTRIM(laData[i])
		CASE i = 1
			laData[i] = STR(laData[i],8)
			laData[i] = CTOD(RIGHT(laData[i],2)+"/"+SUBSTR(laData[i],5,2)+"/"+LEFT(laData[i],4))
			IF !EMPTY(laData[i])
				laData[i] = DATE(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]))
			ENDIF 
		OTHERWISE 
			laData[i] = IIF(ISNULL(laData[i]), 0, laData[i])
		ENDCASE 
	ENDFOR 
	laData[7] = ICASE(LEFT(laData[5],2) = "HS", ALLTRIM(STR(laData[6])), LEFT(laData[5],2) = "HN", ALLTRIM(STR(laData[6])), LEFT(laData[5],2) = "HB", "HB", laData[5])
	IF !EMPTY(laData[1])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
oExcel.quit
**********************
*SET MULTILOCKS ON 
lnArea = SELECT()
SELECT (lnArea)
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
		IF reindate > member.reindate
			?member.policy_no+member.product
			REPLACE member.end_serial WITH 4, member.reindate WITH reindate
			?? "MT code "
			?? member.end_serial
			?? " Reindate "
			?? member.reindate		
			*********************************
			m.fundcode = member.tpacode
			m.policy_no = member.policy_no
			m.plan = member.product
			m.plan_id = member.plan_id
			m.reindate = member.reindate
			m.l_update = DATETIME()
			m.l_users = gcUserName
			m.filename = lcDataFile
			INSERT INTO cims!reinstate FROM MEMVAR 
			*********************************
		ENDIF 	
	ENDIF 
ENDSCAN 
SELECT (lnArea)
USE 		
=MESSAGEBOX("Finished.....")

