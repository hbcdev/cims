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
CREATE DBF (lcDbf) FREE (Policy_no C(30), Eff_date T, Exp_date T, endosno C(30), reportdate D, edeffdate T, edexpdate T, premium Y)
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
		CASE INLIST(j , 2, 3, 5, 6, 7)
			laData[j] = IIF(ISNULL(laData[j]), {}, laData[j])
			IF EMPTY(laData[j])
				laData[j] = {}
			ENDIF 	
			IF TYPE("laData[j]") = "C"
				laData[j] = CTOD(laData[j])
			ENDIF 				
			IF INLIST(j, 2, 3, 6, 7)
				IF EMPTY(laData[j])
					laData[j] = {}
				ELSE 	
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 12, 00)
				ENDIF 	
			ENDIF 	
		CASE j = 11
			laData[j] = VAL(STRTRAN(laData[j], ",", ""))
		ENDCASE
		IF AT(";",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	*
	INSERT INTO (lcdbf) FROM ARRAY laData
	*
ENDFOR 
BROWSE
************************
PROCEDURE aa
IF MESSAGEBOX("ต้องการอัพเดทข้อมูลเข้าระบบ หรือไม่",4+32+256,"Comfrim") = 7
	RETURN 
ENDIF 
*	
SELECT (lnSelect)
GO TOP 
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	IF SEEK(LEFT(policy_no, 20), "members", "policy_gro")
		lcPolNo = LEFT(policy_no, 20)
		lcPersonCode = ALLTRIM(personcode)
		SELECT members
		DO WHILE policy_group = lcPolNo AND !EOF()
			IF ALLTRIM(members.quotation) = lcPersonCode
				REPLACE members.polstatus WITH "C" , ;
					members.policy_end = members.effective, ;
					members.adjcancel WITH ldReportDate, ;
					members.l_update WITH DATETIME()
			ENDIF 
			SKIP 
		ENDDO 
	ENDIF 
	SELECT (lnSelect)
ENDSCAN 					
		