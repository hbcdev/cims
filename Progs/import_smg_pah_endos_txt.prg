CLEAR 
lcSourceFile = GETFILE("TXT")
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
*************************************
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
*	
IF FILE(lcDbf)
	=MESSAGEBOX(lcDbf+" is exist")
*	RETURN 
ENDIF 
*	
IF !USED("members")
	USE cims!members IN 0 
ENDIF 
*	
SELECT 0	
lnSelect = SELECT()
CREATE DBF (lcDbf) FREE (Policy_no C(30), Title C(20), Name C(40), Surname C(40), ;
	Effdate T, Expdate T, endosno C(30), reportdate D, edeffdate T, edexpdate T, premium Y, ;
	refno C(30), personcode I, grptype C(20), lotno C(20), polstatus C(1))
	*
?DBF()
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 2 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT(";",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(";",lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')		
		DO CASE 
		CASE INLIST(j , 5, 6, 8, 9, 10)
			laData[j] = IIF(ISNULL(laData[j]), {}, laData[j])
			IF EMPTY(laData[j])
				laData[j] = {}
			ENDIF 	
			IF TYPE("laData[j]") = "C"
				laData[j] = CTOD(laData[j])
			ENDIF 				
			IF INLIST(j, 5, 6, 9, 10)
				IF EMPTY(laData[j])
					laData[j] = {}
				ELSE 	
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 16, 00)
				ENDIF 	
			ENDIF 	
		CASE j = 11
			laData[j] = VAL(STRTRAN(laData[j], ",", ""))
		ENDCASE
		IF AT(";",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	laData[16] = RIGHT(ALLTRIM(laData[7]), 1)
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 
BROWSE
************************
IF MESSAGEBOX("ต้องการอัพเดทข้อมูลเข้าระบบ หรือไม่",4+32+256,"Comfrim") = 7
	RETURN 
ENDIF 
*	
lnUpdate = 0
IF FILE("smg_endos_error.txt")
	DELETE FILE "smg_endos_error.txt"
ENDIF 	
SELECT (lnSelect)
GO TOP 
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	SCATTER MEMVAR 
	?m.refno
	UPDATE cims!members SET ;
		members.polstatus = "C" , ;
		members.expiry = m.edeffdate, ;
		members.oldeffective = m.effdate, ;
		members.oldexpiry = m.expdate, ;
		members.adjcancel = m.reportdate, ;
		members.canceldate = m.edeffdate, ;
		members.l_user = gcUserName, ;
		members.l_update = DATETIME() ;
	WHERE members.policy_no = m.refno ;
		AND members.family_no = m.personcode ;
		AND members.name = m.name ;
		AND members.surname = m.surname
	IF _TALLY = 0
		lcError = ALLTRIM(m.policy_no)+" "+ALLTRIM(m.name)+" "+ALLTRIM(m.surname)+" "+ALLTRIM(STR(m.personcode))+CHR(13)
		=STRTOFILE(lcError, "smg_endos_error.txt", .T.)		
	ELSE 
		lnUpdate = lnUpdate + _TALLY			
	ENDIF
ENDSCAN
lcError = "Update: "+TRANSFORM(lnUpdate, "@Z 99,999"+"/"+TRANSFORM(RECCOUNT(), "@Z 999,999")+" Records"
=MESSAGEBOX(lcError, 0, "SMG Endos")

MODIFY FILE "smg_endos_error.txt" NOEDIT  
