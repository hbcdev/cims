CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "SMG Adj Data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
IF AT("ADJ", UPPER(lcDataFile)) = 0
	=MESSAGEBOX("àÅ×Í¡ä¿Åì·ÕèãªéÍÑ¾à´·¼Ô´", 0)
	RETURN 
ENDIF 

lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
CREATE DBF (lcDbf) FREE (adjdate D, oldcard C(30), newcard C(30), saledate D, importd D)


oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
	*
oSheet = oWorkBook.worksheets(1)
	
?DBF()
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
***************************************************
lnFieldCount = 5
lnRow = 2
DIMENSION laData[5]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 2).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE INLIST(i, 1, 4, 5)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			IF EMPTY(laData[i])
				laData[i] = {}
			ENDIF 	
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF 	
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 	
		ENDCASE 
	ENDFOR
	IF !EMPTY(laData[2])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
USE 
=MESSAGEBOX("Finished.....")
oExcel.quit 
************************************************
*
* Update To Member Table
*
USE (lcDbf) IN 0 ALIAS smgadj
IF !USED("members")
	USE cims!members IN 0
ENDIF 

SELECT smgadj
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 99,999") NOWAIT 
	IF SEEK("SMG"+oldcard, "members", "policy_no")
		?oldcard + " ===> " + newcard
		REPLACE members.old_policyno WITH members.policy_no, ;
			members.cardno WITH newcard, ;
			members.policy_no WITH newcard, ;
			members.l_submit WITH importd, ;
			members.adj_plan_date WITH adjdate
		********************************************
		IF SEEK("SMG"+oldcard, "claim", "policy_no")
			DO AdjClaim WITH oldcard, newcard
		ENDIF 	
		********************************************	
	ENDIF 
ENDSCAN

USE IN smgadj 

PROCEDURE AdjClaim
PARAMETERS tcOldCard, tcNewCard

IF EMPTY(tcOldCard) AND EMPTY(tcNewCard)
	RETURN 
ENDIF 

?? " Update new card to claim"
lnSelect = SELECT()
IF SEEK("SMG"+tcOldCard, "claim", "policy_no")
	?? " Update new card to claim"
	UPDATE cims!claim ;
	SET claim.policy_no = tcNewCard, ;
		claim.cardno = tcNewCard ;
	WHERE claim.fundcode = "SMG" ;
	AND claim.policy_no = tcOldCard  
	*
	IF SEEK("SMG"+tcOldCard, "notify", "policy_no")
		UPDATE cims!notify ;
		SET notify.policy_no = tcNewCard, ;
			notify.cardno = tcNewCard ;
		WHERE notify.fundcode = "SMG" ;
		AND notify.policy_no = tcOldCard  
	ENDIF 	
	*
	IF SEEK("SMG"+tcOldCard, "notify_log", "policy_no")
		UPDATE cims!notify_log ;
		SET notify_log.policy_no = tcNewCard, ;
			notify_log.cardno = tcNewCard ;
		WHERE notify_log.fundcode = "SMG" ;
		AND notify_log.policy_no = tcOldCard  
	ENDIF 	
	*
	IF SEEK("SMG"+tcOldCard, "notify_period", "policy_no")
		UPDATE cims!notify_period ;
		SET notify_period.policy_no = tcNewCard ;
		WHERE notify_period.fundcode = "SMG" ;
		AND notify_period.policy_no = tcOldCard  
	ENDIF 	
ENDIF 	
*

