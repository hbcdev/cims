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
CREATE DBF (lcDbf) FREE (Policy_no C(30), Plan C(20), Cust_id C(20), Title C(20), Name C(40), MidName C(40), Surname C(40), ;
	Sex C(1), Dob D, Age I, Address1 C(40), Address2 C(40), Address3 C(40), Address4 C(40), Country C(40), Postcode C(5), Telephone C(30), ContactPer C(40), ContactTel C(30), ;
	pol_date T, Eff_date T, Exp_date T, Premium Y, Exclusion C(100), Agent C(20), Agency C(20), Pay_mode C(1), OccuCode C(20), OccuClass C(10), AdjDate D, Renew I, PolStatus C(1), ;
	Employee C(1), Payer C(40), HB_Limit Y, Medical Y)
*
?DBF()
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 1 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT("|",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT("|",lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')		
		DO CASE 
		CASE INLIST(j ,9, 20, 21, 22, 30)
			laData[j] = STRTRAN(laData[j], "-", "/")
			laData[j] = CTOD(laData[j])
			IF YEAR(laData[j]) > 2500
				laData[j] = DATE(YEAR(laData[j])-543, MONTH(laData[j]), DAY(laData[j]))	
			ENDIF 			
			IF INLIST(j ,20, 21, 22)
				IF !EMPTY(laData[j])
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 12, 00)	
				ENDIF 	
			ENDIF
		CASE INLIST(j ,10,23,31,35,36)
			laData[j] = VAL(STRTRAN(laData[j], ",", ""))
		ENDCASE  	
		*
		IF AT("|",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT("|",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 
BROWSE 
USE 