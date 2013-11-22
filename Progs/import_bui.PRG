SET PROCEDURE TO progs\utility
lcSourceFile = GETFILE("TXT")
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
*************************************
IF EMPTY(lcSourceFile) AND EMPTY(lcDbf)
	RETURN 
ENDIF 
*	
IF FILE(lcDbf)
	=MESSAGEBOX(lcDbf+" is exist")
*	RETURN 
ENDIF 
*	
SELECT 0

CREATE TABLE (lcDbf) FREE (policy_no C(30), endorseno C(10), type_endor C(10), n_no I, plan C(20), cust_id C(20), fullname C(70), sex C(1), ;
	age I, address_1 C(70), address_2 c(70), pol_date D, eff_date D, exp_date D, agency C(40), ;	
	adj_date D, renew I, pol_status C(1), old_pol C(30), insure C(50), empname C(50), client_no C(10))
*
?DBF()
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
?lnlines
FOR i = 2 TO lnLines
	WAIT WINDOW TRANSFORM(i, "@Z 99,999") NOWAIT 
	lnFieldCounts = FCOUNT()-3
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = ALLTRIM(STRTRAN(IIF(AT("|",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT("|",lcTemp)-1)),'|',''))
		IF INLIST(j ,12,13,14,16)
			IF !EMPTY(laData[j])
				laData[j] = CTOD(RIGHT(laData[j],2)+"/"+SUBSTR(laData[j],3,2)+"/20"+LEFT(laData[j],2))
			ENDIF 	
		ENDIF 	
		IF INLIST(j ,4,9,17)
			laData[j] = VAL(laData[j])
		ENDIF 	
		lcTemp = SUBSTR(lcTemp,AT("|",lcTemp)+1)
	ENDFOR 
	laData[j] = LEFT(laData[7], AT("/", laData[7])-1)
	laData[j+1] = ALLTRIM(SUBSTR(laData[7],  AT("/", laData[7])+1))
	laData[j+2] = RIGHT(ALLTRIM(laData[7]), 5)
	*
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR
BROWSE 
USE