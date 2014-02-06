lcSourceFile = GETFILE("TXT")
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
ldDate = CTOD(SUBSTR(JUSTFNAME(lcDbf), 9,2)+"/"+SUBSTR(JUSTFNAME(lcDbf),6,2)+"/"+SUBSTR(JUSTFNAME(lcDbf),1, 4))
*************************************
SET HOURS TO 24
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
*	
IF FILE(lcDbf)
	=MESSAGEBOX(lcDbf+" is exist")
ENDIF 
*	
SELECT 0
CREATE DBF (lcDbf) FREE (Policy_grp C(30), Plan_type C(3), plan_agl C(20), policy_no C(30), Name C(40), Surname C(40), Sex C(1), Dob D, ;
	Pol_date T, Eff_date T, Exp_date T, Exclusion C(200), paymode C(1), curcy C(3), polstatus C(1), renew I, benfcode C(20), plan C(20), ;
	plan_id C(10), cardno C(25), insure C(80), adddate D, access_lvl C(1), family_no I)
*
?DBF()
lnFieldCounts = 17
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 1 TO lnLines
	WAIT WINDOW TRANSFORM(i, "@Z 999,999") NOWAIT 
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT("|",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT("|",lcTemp)-1)),"|","")
		laData[j] = STRTRAN(laData[j], '"','')	
		laData[j] = IIF(laData[j] = "NULL", "", laData[j])	
		DO CASE 
		CASE INLIST(j ,5, 6)
			laData[j] = UPPER(ALLTRIM(laData[j]))
		CASE INLIST(j ,8, 9, 10, 11)
			laData[j] = SUBSTR(laData[j], 1,2)+"/"+SUBSTR(laData[j], 3, 2)+"/"+RIGHT(laData[j], 4)
			laData[j] = CTOD(laData[j])
			IF !EMPTY(laData[j])
				IF INLIST(j, 9, 10)
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 00, 00)	
				ELSE 
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 23, 59)
				ENDIF 	
			ENDIF
		ENDCASE  	
		*	
		IF AT("|",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT("|",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	laData[18] = ALLTRIM(SUBSTR(laData[17], 11))+LEFT(laData[14],1)
	laData[19] = ICASE(laData[3] = "HSB0", "AGL1685", laData[3] = "HSB1", "AGL1686", laData[3] = "HSB2", "AGL1687", laData[3] = "HSB3", "AGL1688", ;
		laData[3] = "HSB4", "AGL1689", laData[3] = "HSBS", "AGL1690", "")
	laData[20] = STRTRAN(laData[4], "-", "")
	laData[21] = ALLTRIM(laData[5])+" "+ALLTRIM(laData[6])
	laData[22] = IIF(EMPTY(ldDate), DATE(), ldDate)
	laData[23] = IIF(laData[13] = "Q", "R", "")
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 
BROWSE 
USE 