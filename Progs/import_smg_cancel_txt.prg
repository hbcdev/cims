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
CREATE DBF (lcDbf) FREE (Policy_no C(30), title V(20), name V(40), surname V(40), Eff_date T, Exp_date T, endorse C(30), reportdate D, effdate_ed T, expdate_ed T, ;
	Totalprem Y, refno C(30), personcode I, grptype C(1), lotno C(20), prodno I, locno I, itemno I, polstatus C(1), filename v(50))	
*
?DBF()
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 2 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	lnFieldCounts = FCOUNT()-2
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT(";",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(";",lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')		
		DO CASE 
		CASE INLIST(j ,5, 6, 8, 9, 10)
			laData[j] = IIF(ISNULL(laData[j]), {}, laData[j])
			IF EMPTY(laData[j])
				laData[j] = {}
			ENDIF 	
			IF TYPE("laData[j]") = "C"
				laData[j] = CTOD(laData[j])
			ENDIF 				
			IF EMPTY(laData[j])
				laData[j] = {}
			ELSE 
				IF j # 9	
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 16, 00)
				ENDIF 	
			ENDIF 	
		CASE INLIST(j ,11,13,16,17,18)
			laData[j] = VAL(STRTRAN(laData[j], ",", ""))
		ENDCASE  	
		*
		IF AT(";",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	laData[19] = IIF(RIGHT(ALLTRIM(laData[7]),1)= "A", "A", "C")
	laData[20] = JUSTFNAME(lcSourceFile)
	*
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 
BROWSE 
USE 
