CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Select ALA member data file", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
CREATE DBF (lcDbf) FREE (lapsedate D, policy_no C(30), poltype C(10), sumins Y, polstatus C(2), plan C(20)) 
*
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)	
***************************************************
lnFieldCount = 5
lnRow = 2
DIMENSION laData[6]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 1).Value)
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value	
		DO CASE 
		CASE INLIST(i, 2, 3, 4, 5)
			IF TYPE("laData[i]") = "N"
				laData[i] = ALLTRIM(STR(laData[i],10))
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
	laData[6] = ICASE(LEFT(laData[3],2) = "HS", laData[4], LEFT(laData[3],2) = "HN", laData[4], LEFT(laData[3],2) = "HB", "HB", laData[3])
	IF !EMPTY(laData[1])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
oExcel.quit
BROWSE 
**********************
*
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
		IF lapsedate > member.policy_end
			?member.policy_no+member.product
			REPLACE member.policy_end WITH lapsedate, ;
				member.expried_y WITH lapsedate, ;
				member.polstatus WITH "LA", ;
				member.pay_status WITH "LA"
			?? " Lapse date "
			?? member.policy_end		
			*********************************
			m.fundcode = member.tpacode
			m.policy_no = member.policy_no
			m.plan = member.product
			m.plan_id = member.plan_id
			m.lapsedate = member.policy_end
			m.l_update = DATETIME()
			m.l_users = "VACHARA"
			m.filename = lcDataFile
			m.polstatus = polstatus			
			INSERT INTO cims!reinstate FROM MEMVAR 
			*********************************
		ENDIF 	
	ENDIF 
ENDSCAN 
SELECT (lnArea)
USE 		
=MESSAGEBOX("Finished.....")

