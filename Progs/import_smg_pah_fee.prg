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
CREATE DBF (lcDbf) FREE (Policy_no C(30), subclass C(10), Eff_date T, Exp_date T, insure C(60), ;
	cover_y N(1), projcode C(20), suminsure Y, netpremium Y, poltax Y, polduty Y, totalprem Y, ;
	reportdate D, tpacode C(3), grptype C(1))
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
		CASE INLIST(j , 3, 4, 13)
			laData[j] = IIF(ISNULL(laData[j]), {}, laData[j])
			IF EMPTY(laData[j])
				laData[j] = {}
			ENDIF 	
			IF TYPE("laData[j]") = "C"
				laData[j] = CTOD(laData[j])
			ENDIF 				
			IF INLIST(j, 3, 4)
				IF EMPTY(laData[j])
					laData[j] = {}
				ELSE 	
					IF laData[7] = "PADEBIT"					
						laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 12, 00)
					ELSE 
						laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 16, 00)
					ENDIF 	
				ENDIF 	
			ENDIF 	
		CASE INLIST(j, 6, 8, 9, 10, 11, 12)
			laData[j] = VAL(STRTRAN(laData[j], ",", ""))
		ENDCASE
		IF AT(";",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 
BROWSE
