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
SELECT A
CREATE TABLE (lcDbf) FREE (no C(4), branch_cod C(20), province c(40), policy_no c(30), policy_hol C(40), ;
	plan C(20), first_year D, eff_date D, exp_date D, cust_id C(20), natid C(20), title C(20), name C(40), middle C(40), ;
	surname c(40), sex C(1), dob D, age I, address1 C(40), address2 c(40), address3 C(40), address4 C(40), postcode C(5), premium Y, medical Y, renew I, ;
	exclusion C(40), pay_mode C(10), old_plan c(20), old_prem Y, adjust_dat D, adjust_pre Y, payer C(40), agent_code C(40), agency_nam c(40), ;
	agent_addr C(40), agency C(40), agency_na1 c(40), agency_add c(40), card C(1), credit Y)
*
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 2 TO lnLines-2
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	SELECT A
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(LEFT(lcTemp,AT(",",lcTemp)-1),'"','')
		IF INLIST(j ,7,8,9,17,31,32)
			laData[j] = CTOD(laData[j])
		ENDIF 	
		IF INLIST(j ,18,24,25,26,41)
			laData[j] = VAL(laData[j])
		ENDIF 	
		*
		lcTemp = SUBSTR(lcTemp,AT(",",lcTemp)+1)
	ENDFOR 
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 		
		





	