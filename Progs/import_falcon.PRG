lcSourceFile = GETFILE("DAT;TXT")
lcDbf = STRTRAN(lcSourceFile, ".DAT", ".DBF")
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
CREATE TABLE (lcDbf) FREE (policyno C(30), plan C(20), cust_id C(20), title C(20), name C(80), middle C(40), surname C(40), ;
	sex C(1), dob D, age I, address1 C(80), address2 C(40), address3 C(40), address4 C(40), address5 C(40), postcode C(5), ;
	telephone C(25), contact_p C(20), contact_t C(20), pol_date T, eff_date T, exp_date T, premium Y, exclusion C(40), agent C(40), agency C(40), ;
	pay_mode C(10), occ_code C(8), occ_class c(8), adj_date D, renew I, pol_status C(2), ;
	employee C(2), payer C(40),  hb_limit Y, medical Y)
*
?DBF()
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 2 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT("|",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT("|",lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')		
		DO CASE 
		CASE INLIST(j ,9,20,21,22)
			DO CASE 
			CASE j = 9
				IF LEN(laData[j]) = 7
					laData[j] = LEFT(laData[j],2)+"/0"+SUBSTR(laData[j], 3,1)+"/"+SUBSTR(laData[j],4, 4)
				ELSE 	
					laData[j] = LEFT(laData[j],2)+"/"+SUBSTR(laData[j], 3,2)+"/"+SUBSTR(laData[j],5, 4)
				ENDIF 					
				laData[j] = CTOD(laData[j])							
				IF !EMPTY(laData[j])
					laData[j] = DATE(YEAR(laData[j])-543, MONTH(laData[j]), DAY(laData[j]))
				ENDIF 	
			CASE  INLIST(j ,20,21,22)
				laData[j] = LEFT(laData[j],2)+"/"+SUBSTR(laData[j], 3,2)+"/"+SUBSTR(laData[j],5, 4)			
				laData[j] = CTOD(laData[j])			
				laData[j] = DATETIME(YEAR(laData[j])-543, MONTH(laData[j]), DAY(laData[j]), 12, 00)	
			ENDCASE  			
		CASE INLIST(j ,10,23,31,35,36)
			laData[j] = VAL(laData[j])
		ENDCASE  	
		*
		IF AT("|",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT("|",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 
*
GO TOP 
DO WHILE !EOF()
	PolNo = policyno
	no = 1
	DO WHILE PolNo = policyno AND !EOF()
		IF "GP" $ policyno
			REPLACE policyno WITH ALLTRIM(policyno)+"-"+STRTRAN(STR(no,2), " ", "0")
		ENDIF 	
		no = no + 1
		SKIP 
	ENDDO 
ENDDO 
*		
BROWSE 
USE 