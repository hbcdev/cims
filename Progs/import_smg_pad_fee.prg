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
SELECT 0	
lnSelect = SELECT()
CREATE DBF (lcDbf) FREE (Policy_no C(30), Cust_id C(20), Reportdate D, Name C(40), Surname C(40), Projcode C(20), ;
	Eff_date T, Exp_date T, Grossprem Y, Poltax Y, Polduty Y, Totalprem Y, idcardno C(20), personcode C(20), plan C(20), medical Y)		
*
?DBF()
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 2 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 9,999,999") NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT(";",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(";",lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')		
		DO CASE 
		CASE INLIST(j ,3, 7, 8)
			laData[j] = IIF(ISNULL(laData[j]), {}, laData[j])
			IF EMPTY(laData[j])
				laData[j] = {}
			ENDIF 	
			IF TYPE("laData[j]") = "C"
				laData[j] = CTOD(laData[j])
			ENDIF 				
			IF INLIST(j, 7, 8)
				IF EMPTY(laData[j])
					laData[j] = {}
				ELSE 	
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 12, 00)
				ENDIF 	
			ENDIF 	
		CASE INLIST(j ,9, 10, 11, 12)
			laData[j] = VAL(STRTRAN(laData[j], ",", ""))
		ENDCASE  	
		*
		IF AT(";",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF 	
	ENDFOR 	
	laData[15] = IIF(laData[9] <= 258, "Sliver", "Gold")
	laData[16] = IIF(laData[9] <= 258, 5000, 25000)
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 
BROWSE 
******************************
PROCEDURE updateMember


USE cims!member IN 0

SELECT (lnSelect)
GO TOP 
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	IF SEEK("SMG"+cust_id, "member", "policy_no")
		REPLACE member.policy_group WITH policy_no, ;
				member.customer_id with idcardno, ;
				member.natid WITH idcardno, ;
				member.cardno WITH cust_id
		IF member.policy_no # cust_id
			REPLACE member.old_policyno WITH member.policy_no, ;
					member.policy_no WITH cust_id			
		ENDIF 								
	ENDIF 
ENDSCAN 			


















PROCEDURE Old_Format

SELECT 0	
CREATE DBF (lcDbf) FREE (Policy_no C(30), Plan C(20), Cust_id C(20), Title C(20), Name C(40), Surname C(40), ;
	Sex C(1), Dob D, Age I, Address1 C(40), Address2 C(40), Address3 C(40), Address4 C(40), Country C(40), Postcode C(5), Telephone C(30), ;
	Pol_date T, Eff_date T, Exp_date T, Premium Y, Agent C(20), Agency C(20), Medical Y, Netprem Y, Referance C(15), Reportdate D, ;
	Projcode C(10), Personcode C(10),  Pol_group C(20), Pol_name C(60), Adddate D)
	
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
		CASE j = 1
			laData[29] = laData[j] 
		CASE j = 2
			laData[2] = UPPER(laData[j])	
		CASE j = 6
			laData[30] = ALLTRIM(laData[5])+" "+ALLTRIM(laData[6])			
		CASE INLIST(j ,8, 17, 18, 19, 26)
			laData[j] = IIF(ISNULL(laData[j]), {}, laData[j])
			IF EMPTY(laData[j])
				laData[j] = {}
			ENDIF 	
			IF TYPE("laData[j]") = "C"
				laData[j] = CTOD(laData[j])
			ENDIF 				
			IF INLIST(j, 17, 18, 19)
				IF EMPTY(laData[j])
					laData[j] = {}
				ELSE 	
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 12, 00)
				ENDIF 	
			ENDIF 	
		CASE INLIST(j ,9, 20, 23, 24)
			laData[j] = VAL(STRTRAN(laData[j], ",", ""))
		CASE j = 31
			laData[31] = ldDate			
		ENDCASE  	
		*
		IF AT(";",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 
BROWSE 
USE 


