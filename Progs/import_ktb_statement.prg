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
CREATE TABLE (lcDbf) FREE (bdate D, descript C(30), detail C(30), chqno C(7), amounts Y, bal Y, branch C(7), tallar C(5))

lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 1 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	SELECT A
	lnFieldCounts = FCOUNT()
	SCATTER MEMVAR BLANK 
	lcTemp = laTextArray[i]
	IF i = 1
		m.descript = "B/F"
		m.bal = VAL(SUBSTR(lctemp,73,9))
		INSERT INTO (lcdbf) FROM MEMVAR 		
	ELSE 
		IF LEFT(lcTemp,1) # "H"
			m.bdate = SUBSTR(lctemp,31,8)
			m.bdate = CTOD(RIGHT(m.bdate,2)+"/"+SUBSTR(m.bdate,5,2)+"/"+LEFT(m.bdate,4))
			m.amounts = VAL(SUBSTR(lcTemp,39,14))
			m.chqno = SUBSTR(lcTemp,123,7)
			m.descript = SUBSTR(lcTemp,67,3)
			m.detail = SUBSTR(lcTemp,71,14)
			m.bal = VAL(SUBSTR(lcTemp,53,14))
			m.branch = SUBSTR(lcTemp,130,3)
			m.tallar = SUBSTR(lcTemp,133,5)
			INSERT INTO (lcdbf) FROM MEMVAR 
		ENDIF 
	ENDIF 		
ENDFOR 		
		





	