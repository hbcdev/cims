CLEAR 
SET SAFETY OFF 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Renew data", "Select",0,'Falcon Data Upload')
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
IF !FILE(lcDbf)
	*DO Xls2Dbf
else 
	use (lcDbf) in 0 alias fniexp	
ENDIF 	

SELECT fniExp
scan 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	SCATTER MEMVAR 
	select expiry from cims!member where tpacode = 'FAL' and policy_no = m.policy_no and natid = m.natid into array laMem
	if _TALLY = 0
		delete 
	else
		if m.expdate <= laMem[1]	
			delete 
		endif	
	endif 
endscan 




*DO UpdateData
***************************************
PROCEDURE xls2dbf

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
CREATE DBF (lcDbf) FREE (Policy_no V(30), payer V(60), expdate T, quotation V(50), natid V(13), adjdate D)
*
lcDate = LEFT(RIGHT(DBF(), 12), 8)
if isdigit(lcDate)
	ldDate = CTOD(LEFT(lcDate,2)+"/"+SUBSTR(lcDate,3,2)+"/"+RIGHT(lcDate,4))
else
	ldDate = date()	
endif	
************************************************************
lnFieldCount = 5
lnRow = 2
DIMENSION laData[6]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 4).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE i = 3
			IF EMPTY(laData[i])
				laData[i] = {}
			ELSE 	
				laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 12, 00)
			ENDIF 	
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 	
		ENDCASE 
	ENDFOR
	IF !EMPTY(laData[4])
		laData[6] = ldDate
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
USE 
=MESSAGEBOX("Finished.....")
oExcel.quit
************************************
PROCEDURE UpdateData

? "Update Data to Member system"

SET MULTILOCKS ON 
lcErrorFile = "Falcon_Exp.txt"
STORE 0 TO lnUpdate, lnNoUpdate

USE (lcDbf) IN 0 ALIAS fniExp
IF !USED("member")
	USE cims!member ORDER quotation IN 0
else 
	set order to quotation in member	
ENDIF 	
*=CURSORSETPROP("Buffering", 5, "member")
************************************
SELECT fniExp

DO WHILE !EOF()
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	SCATTER MEMVAR 
	IF !EMPTY(fniexp.quotation)		
		lcPolNo = fniexp.quotation
		IF SEEK(lcPolNo, "member", "quotation")
			lnUpdate = lnUpdate + 1					
			DO WHILE member.quotation = lcPolNo AND !EOF("member")
				IF fniexp.expdate > member.expiry
					REPLACE member.oldexpiry WITH member.expiry, ;					
					member.expiry WITH fniexp.expdate, ;
					member.adj_plan_date WITH fniexp.adjdate
					* update to sql
					if !updateFniSql("R", "FAL", member.policy_no, member.natid, fniexp.quotation, fniexp.expdate, fniexp.adjdate, "A", null)
						lcError = fniexp.quotation+" not update to sql server"+chr(13)
						=strtofile(lcError, "fni_error.txt",1)
					endif
					DO UpdateLog				
				ENDIF 	
				IF !EMPTY(m.policy_no)
					IF member.policy_no # m.policy_no
						IF AT("/", m.quotation) # 0
							m.policy_no = ALLTRIM(m.policy_no)+RIGHT(ALLTRIM(m.quotation),2)
						ENDIF 
						*						
						REPLACE member.policy_group WITH IIF(EMPTY(fniexp.policy_no), member.policy_no, ALLTRIM(fniexp.policy_no)), ;
							member.policy_no WITH IIF(EMPTY(m.policy_no), member.policy_no, ALLTRIM(m.policy_no)), ;
							member.payee WITH fniexp.payer, ;
							member.l_update WITH DATETIME()
						DO updateClaim WITH LEFT(lcPolNo, 30), member.policy_no, ALLTRIM(member.name)+" "+ALLTRIM(member.surname), fniexp.quotation
					ENDIF 
				ENDIF 		
				SKIP IN member
			ENDDO 
		ELSE 
			DO UpdateExp
		ENDIF 	
	ELSE 
		DO UpdateExp
	ENDIF 
	SELECT fniexp	
	SKIP 			
ENDDO 	
SELECT fniexp
lcMessage = "Total: "+TRANSFORM(RECCOUNT(), "@Z 999,999")+CHR(13)+;
			 "Total Update: "+TRANSFORM(lnUpdate, "@Z 999,999")+CHR(13)+;
			 "Total No Update: "+TRANSFORM(lnNoUpdate, "@Z 999,999")
=MESSAGEBOX(lcMessage)
IF lnNoUpdate > 0
	MODIFY FILE lcErrorFile NOEDIT 
ENDIF 	
USE IN fniexp
*******************************************
PROCEDURE UpdateExp	
			
** Replace by policy_group
lcPolNo = fniexp.policy_no
IF SEEK(lcPolNo, "member", "policy_gro")
	lnUpdate = lnUpdate + 1		
	SET ORDER TO policy_gro IN member
	DO WHILE member.tpacode = "FAL" AND member.policy_group = lcPolNo AND !EOF("member")
		?member.quotation
		?? ALLTRIM(member.name)+" "+ALLTRIM(member.surname)
		IF fniexp.expdate > member.expiry
			REPLACE member.oldexpiry WITH member.expiry, member.expiry WITH fniexp.expdate, ;
				member.adj_plan_date WITH fniexp.adjdate
			DO UpdateLog		
		ENDIF 
		REPLACE member.payee WITH fniexp.payer, ;				
				member.l_update WITH DATETIME()
		SKIP IN member
	ENDDO 
ELSE 
	lnNoUpdate = lnNoUpdate + 1		
	lcText = m.quotation+"|"+m.policy_no+"|"+m.payer+CHR(10)+CHR(13)
	=STRTOFILE(lcText, lcErrorFile, 1)					
ENDIF 	
*******************************
PROCEDURE UpdateLog

SCATTER FIELDS member.tpacode, member.customer_id, member.policy_no, member.name, member.surname, ;
	member.product, member.plan_id, member.effective, member.expiry MEMVAR
INSERT INTO cims!member_rider (fundcode, customer_id, policy_no, name, surname, plan_id, plan, effective, expiry) ;
	VALUES ("FAL", m.customer_id, m.policy_no, m.name, m.surname, m.plan_id, m.product, m.effective, m.expiry)
*********************************
PROCEDURE UpdateClaim
PARAMETERS tcPolNo, tcPolicyNo, tcName, tcQuotation
IF EMPTY(tcPolNo) AND EMPTY(tcPolicyNo)
	RETURN 
ENDIF 
	
UPDATE cims!claim SET policy_no = tcPolicyNo, ;
		quotation = tcQuotation ;		
	WHERE fundcode = "FAL" AND policy_no = tcPolNo AND client_name = tcName

UPDATE cims!notify SET policy_no = tcPolicyNo, ;
		quotation = tcQuotation ;		
	WHERE fundcode = "FAL" AND policy_no = tcPolNo AND client_name = tcName
	
UPDATE cims!notify_log SET policy_no = tcPolicyNo, ;
		quotation = tcQuotation ;		
	WHERE fundcode = "FAL" AND policy_no = tcPolNo AND client_name = tcName
	
UPDATE cims!notify_period SET policy_no = tcPolicyNo, ;
		quotation = tcQuotation ;
	WHERE fundcode = "FAL" AND policy_no = tcPolNo
