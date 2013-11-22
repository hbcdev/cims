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
lnFieldCounts = 92
CREATE TABLE (lcDbf) FREE (policy_grp C(20), policyno C(30), plan C(20), cust_id C(20), title C(20), name C(80), surname C(40), ;
	sex C(1), dob D, pol_date T, eff_date T, exp_date T, medical Y, polstatus C(1), pol_name C(80), natid C(13), adddate D, mode N(1))
*
?DBF()
lcDate = RIGHT(JUSTFNAME(DBF()),16)
ldDate = CTOD(SUBSTR(lcDate, 7,2)+"/"+SUBSTR(lcDate,5,2)+"/"+IIF(LEFT(LEFT(lcDate, 4), 2) = "20", LEFT(lcDate, 4), STR(VAL(LEFT(lcDate, 4))-543, 4)))
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 1 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		lcData = STRTRAN(IIF(AT("|",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT("|",lcTemp)-1)),'"','')
		lcData = STRTRAN(lcData, '"','')	
		DO CASE 
		CASE j = 1
			laData[18] = lcData
			laData[14] =  ICASE(lcData = "1", "A", lcData = "3", "C", lcData = "4", "R", "A")
		CASE j = 4
			laData[2] = lcData
		CASE j = 6
			laData[4] = lcData			
		CASE j = 15
			laData[1] = lcData
		CASE j = 26
			STORE "" TO m.title, m.name, m.surname
			*lcData = STRCONV(lcData, 11)
			laData[15] = deltitle(lcData)
			laData[5] = m.title	
			laData[6] = m.name
			laData[7] = 	m.surname	
		CASE j = 37
			laData[16] = lcData			
		CASE j = 43
			laData[8] = lcData
		CASE j = 45
			laData[3] = lcData
		CASE j = 58
			*laData[14] = ICASE(laData[1] = "1", "I", laData[1] = "3", "C", "I")
		CASE INLIST(j ,18, 19, 42)
			lcData = SUBSTR(lcData, 7, 2)+"/"+SUBSTR(lcData, 5,2)+"/"+LEFT(lcData,4)
			lcData = CTOD(lcData)
			DO CASE 
			CASE j = 18
				laData[10] = DATETIME(YEAR(lcData), MONTH(lcData), DAY(lcData), 12, 00)
				laData[11] = laData[10]
			CASE j = 19
				laData[12] = DATETIME(YEAR(lcData), MONTH(lcData), DAY(lcData), 12, 00)
			CASE j = 42
				laData[9] = lcData
			ENDCASE  			
		CASE INLIST(j ,92)
			laData[13] = VAL(lcData)
		ENDCASE  	
		*
		IF AT("|",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT("|",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	laData[17] = ldDate
	laData[12] = IIF(laData[14] = "C", ldDate, laData[12])	
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 
*		
BROWSE 
*
lcPa = LEFT(DBF(),LEN(DBF())-4)+"_PA"
lcHs = LEFT(DBF(),LEN(DBF())-4)+"_HEACARE1"
COPY TO (lcHs) FOR plan = "HEACARE1"
COPY TO (lcPa) FOR plan <> "HEACARE1"
*
USE 