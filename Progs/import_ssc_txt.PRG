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
CREATE DBF (lcDbf) FREE (Policy_no C(30), Plan_type C(10), Plan C(8), Cust_id C(15), Title C(20), Name C(60), Surname C(60), ;
	sex C(1), dob D, pol_date T, Eff_date T, Exp_Date T)
*
?DBF()
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 1 TO lnLines
	WAIT WINDOW TRANSFORM(i, "@Z 999,999") NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT(CHR(9),lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(CHR(9),lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')	
		laData[j] = IIF(laData[j] = "NULL", "", laData[j])	
		DO CASE 
		CASE INLIST(j ,13, 17)
			laData[j] = SUBSTR(laData[j], 9,2)+"/"+SUBSTR(laData[j], 6, 2)+"/"+LEFT(laData[j], 4)			
			laData[j] = CTOD(laData[j])
			IF !EMPTY(laData[j])
				laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 12, 00)	
			ENDIF
		CASE INLIST(j, 14, 16)
			laData[j] = IIF(laData[j]="", 0, laData[j])	
		ENDCASE  	
		*
		IF AT(CHR(9),lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(CHR(9),lcTemp)+1)
		ENDIF 	
	ENDFOR 
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 
BROWSE 
USE 