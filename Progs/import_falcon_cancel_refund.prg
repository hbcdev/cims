CLEAR 
SET PROCEDURE TO progs\utility
lnArea = 0
lcDataFile = GETFILE("XLS", "Falcon data", "Select")
IF EMPTY(lcDataFile) AND !USED("eff") AND !USED("exp")
	RETURN 
ENDIF 
********************
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
IF !FILE(lcDbf)
	DO Xls2Dbf
ENDIF 	
DO UpdateData
****************************************************
PROCEDURE Xls2Dbf

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
CREATE DBF (lcDbf) FREE (Quotation C(50), Policy_no C(30), name C(60), surname C(60), canceldate D, types C(1), expdate D, resson C(200), adjdate D)
***************************************************
lcDate = LEFT(RIGHT(DBF(), 12), 8)
ldDate = CTOD(LEFT(lcDate,2)+"/"+SUBSTR(lcDate,3,2)+"/"+RIGHT(lcDate,4))
***************
lnFieldCounts = 9
lnRow = 2
DIMENSION laData[lnFieldCounts]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 1).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCounts
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE INLIST(i, 5, 7)
			IF EMPTY(laData[i]) OR ISNULL(laData[i])
				laData[i] = {}
			ELSE 	
				IF TYPE("laData[i]") = "C"
					*IF i = 5
						*laData[i] = SUBSTR(laData[i], 3, 3)+"0"+LEFT(ladata[i],2)+SUBSTR(ladata[i], 6, 4)					
					*ENDIF 
					laData[i] = CTOD(laData[i])
				ENDIF
				IF YEAR(laData[i]) > 2500 				
					laData[i] = DATE(YEAR(laData[i])-543, MONTH(laData[i]), DAY(laData[i]))
				ENDIF 					
			ENDIF 	
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 	
		ENDCASE 
	ENDFOR
	laData[9] = ldDate
	IF !EMPTY(laData[1])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
USE 
=MESSAGEBOX("Finished.....")
oExcel.quit
****************************
PROCEDURE UpdateData

? "Update Data in Member Table"
USE (lcDbf) ALIAS fniCancel
IF !USED("member")
	USE cims!member ORDER quotation IN 0
ENDIF 	

lcErrorFile = "Falcon_Cancel.txt"
STORE 0 TO lnUpdate, lnNoUpdate

SELECT fniCancel
DO WHILE !EOF()
	WAIT WINDOW "Update by Quotation Record "+TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	SCATTER MEMVAR 
	*******************
	lcQuoName = "FAL"+m.quotation+ALLTRIM(m.name)+ALLTRIM(m.surname)
	IF SEEK(lcQuoName, "member", "quo_name")		
		? "Update With Quotation "+m.quotation
		DO CASE 
		CASE m.types = "C"
			lnUpdate = lnUpdate + 1
			REPLACE member.expiry WITH m.expdate, ;
				member.notation WITH ALLTRIM(m.resson)+CHR(10)+CHR(13)+ALLTRIM(member.notation), ;			
				member.canceldate WITH m.canceldate, ;
				member.adjcancel WITH m.canceldate, ;
				member.status WITH "C", ;
				member.polstatus  WITH m.types
		CASE m.types = "R"
			lnUpdate = lnUpdate + 1		
			REPLACE member.cancelexp WITH IIF(member.polstatus = "C", member.expiry, expdate), ;
				member.expiry WITH m.expdate, ;
				member.notation WITH ALLTRIM(m.resson)+CHR(10)+CHR(13)+ALLTRIM(member.notation), ;			
				member.refunddate WITH m.canceldate, ;
				member.adjrefund WITH m.canceldate, ;
				member.status WITH "C", ;
				member.polstatus  WITH m.types
		OTHERWISE 
			lnNoUpdate = lnNoUpdate + 1		
			lcText = m.quotation+"|"+m.policy_no+"|"+m.name+"|"+m.surname+CHR(10)+CHR(13)
			=STRTOFILE(lcText, lcErrorFile, 1)			
			DELETE
		ENDCASE
		**********************************************************
		IF !EMPTY(m.policy_no)
			IF member.policy_no # m.policy_no
				lcOldPolNo = member.policy_no
				REPLACE member.policy_group WITH m.policy_no, ;
					member.policy_no WITH m.policy_no, ;
					member.cardno with STRTRAN(STRTRAN(m.policy_no, "-", ""), "/", "")
				DO updateClaim WITH lcOldPolNo, m.policy_no, ALLTRIM(member.name)+" "+ALLTRIM(member.surname), fnicancel.quotation				
			ENDIF 		
		ENDIF
	ELSE 
		lnNoUpdate = lnNoUpdate + 1
		lcText = m.quotation+"|"+m.policy_no+"|"+m.name+"|"+m.surname+CHR(10)+CHR(13)
		=STRTOFILE(lcText, lcErrorFile, 1)					
		DELETE
	ENDIF 
	SKIP
ENDDO 	
SELECT fniCancel
lcMessage = "Total Update: "+TRANSFORM(lnUpdate, "@Z 999,999")+CHR(13)+;
			 "Total Update: "+TRANSFORM(lnUpdate, "@Z 999,999")+CHR(13)+;
			 "Total No Update: "+TRANSFORM(lnNoUpdate, "@Z 999,999")
=MESSAGEBOX(lcMessage)
IF lnNoUpdate > 0
	MODIFY FILE lcErrorFile NOEDIT 
ENDIF 	
USE IN fniCancel
****************************************
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

