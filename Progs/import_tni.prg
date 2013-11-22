CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Select TNI member data file", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
lcAlias = ""
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
IF !FILE(lcDbf)
	DO GetData
ENDIF 

IF EMPTY(lcAlias)
	SELECT 0
	USE ?
	lcAlias = ALIAS()
ENDIF 
USE cims!member IN 0	
SELECT (lcAlias)
GO TOP 
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	IF SEEK("TNI"+policy_no, "member", "policy_no")
		IF EMPTY(member.customer_id)
			REPLACE member.customer_id WITH NEWID("member", "TNI")
		ENDIF 	
	ELSE 
		SCATTER MEMVAR 
		INSERT INTO cims!member (fund_id, tpacode, customer_type, policy_no, cause10, effective, expiry, premium, product, plan_id, overall_limit, name, surname) ;
			VALUES (17, "TNI", "P", m.policy_no, m.package, DATETIME(YEAR(m.effdate), MONTH(m.effdate), DAY(m.effdate), 12,00), ;
				DATETIME(YEAR(m.expdate), MONTH(m.expdate),DAY(m.expdate),12,00), m.premium, m.plan, m.plan_id, m.medical, m.name, m.surname)
	ENDIF 		
ENDSCAN 	

USE 
=MESSAGEBOX("Finished.....")
******************
PROCEDURE GetData

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
CREATE DBF (lcDbf) FREE (policy_no C(30), package C(10), effdate D, expdate D, premium Y, plan C(20), plan_id C(10), medical Y, name C(40), surname C(40))
***************************************************
lcAlias = ALIAS()
lnFieldCount = 10
lnRow = 2
DIMENSION laData[lnFieldCount]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 1).Value)
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value	
		IF INLIST(i, 9, 10)
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
		ENDIF 			
	ENDFOR 
	IF !EMPTY(laData[1])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
oExcel.quit