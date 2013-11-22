SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("TXT", "SMG data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
*
llBlclosed = .F.
IF FILE(ADDBS(DATAPATH)+"smg_blacklist.dbf")
	IF !USED("smb_blacklist")
		llBlClosed = .T.	
		USE (ADDBS(DATAPATH)+"smg_blacklist") IN 0 
	ENDIF 	
ENDIF 	
*
CLEAR 
?lcDataFile
********************
llPah = "PAH" $ lcDataFile
lcDate = RIGHT(JUSTFNAME(lcDataFile),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
***************************************************
DIMENSION laData[25]
lnFieldCounts = 18
lnLines = ALINES(laTextArray,FILETOSTR(lcDataFile))
FOR j = 2 TO lnLines
	WAIT WINDOW TRANSFORM(j-1, "999,999") NOWAIT 
	lcTemp = laTextArray[j]
	FOR i = 1 TO lnFieldCounts - 1
		laData[i] = STRTRAN(IIF(AT(";",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(";",lcTemp)-1)),'"','')
		laData[i] = STRTRAN(laData[i], '"','')		
		DO CASE 
		CASE i = 8
			IF llPAH
				laData[19] = ICASE(laData[i] = "A", 50000, laData[i] = "B", 100000, laData[i] = "C", 300000, laData[i] = "D", 300000, 0)
				laData[20] = ICASE(laData[i] = "A", "SMG1440", laData[i] = "B", "SMG1441", laData[i] = "C", "SMG1442", laData[i] = "D", "SMG1443", 0)
				laData[i] = ICASE(laData[i] = "A", "PaHappyPlus5แสน", laData[i] = "B", "PaHappyPlus1ล้าน", laData[i] = "C", "PaHappyPlus3ล้าน", laData[i] = "D", "PaHappyPlus5ล้าน", "PaHappyPlus")
			ELSE 	
				laData[19] = ICASE(laData[i] = "S", 5000, laData[i] = "G", 25000, 0)		
				laData[20] = ICASE(laData[i] = "S", "SMG1050", laData[i] = "G", "SMG1051", "")					
				laData[i] = ICASE(laData[i] = "S", "PADebit1แสน", laData[i] = "G", "PADebit5แสน", laData[i])
			ENDIF 
		CASE INLIST(i, 4, 6, 7, 14)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			IF EMPTY(laData[i])
				laData[i] = {}
			ENDIF 	
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF 	
			
			IF INLIST(i, 6, 7)
				IF EMPTY(laData[i])
					laData[i] = {}
				ELSE 	
					IF llPAH
						laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 16, 00)
					ELSE 
						laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 12, 00)
					ENDIF 	
				ENDIF 	
			ENDIF 	
			laData[21] = laData[6]
		CASE i = 11
			laData[i] = ICASE(VAL(laData[i]) = 260, 258, VAL(laData[i]) = 900, 896, VAL(laData[i]))
		CASE i = 16
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])	
			laData[23] = laData[i]
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 	
		ENDCASE 
		IF AT(";",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF 			
	ENDFOR
	*check pa life
	IF llPAH
		DO CASE 
		CASE INLIST(laData[11], 1400, 4000, 6370)
			laData[19] = 15000
			laData[20] = "SMG1498"
			laData[8] =  "PA Happy Life 3 แสน"
		CASE INLIST(laData[11], 1900, 5440, 8650)
			laData[19] = 50000
			laData[20] = "SMG1499"
			laData[8] =  "PA Happy Life 5 แสน"
		CASE INLIST(laData[11], 3200, 9150, 14560)
			laData[19] = 100000
			laData[20] = "SMG1750"
			laData[8] =  "PA Happy Life 1 ล้าน"
		CASE INLIST(laData[11], 8000, 22880, 36400)
			laData[19] = 300000
			laData[20] = "SMG1751"
			laData[8] =  "PA Happy Life 3 ล้าน"
		CASE INLIST(laData[11], 10900, 31180, 49600)
			laData[19] = 300000
			laData[20] = "SMG1752"
			laData[8] =  "PA Happy Life 5 ล้าน"
		ENDCASE 
		laData[12] = IIF(ISNULL(laData[12]) OR EMPTY(laData[12]), laData[10], laData[12])	
	ELSE 
		laData[12] = IIF(ISNULL(laData[12]) OR EMPTY(laData[12]), laData[9], laData[12])			
	ENDIF 	 
	*
	laData[13] = ""
	laData[24] = ""
	laData[25] = JUSTFNAME(lcDataFile)
	IF USED("smg_blacklist")
		SELECT subclass ;
		FROM smg_blacklist ;
		WHERE idcardno = ALLTRIM(laData[16]) ;
			AND name = ALLTRIM(laData[2]) ;
			AND surname = ALLTRIM(laData[3]) ;
		INTO ARRAY aBlackList
		IF _TALLY <> 0
			? laData[9]+" Blacklist" 
			laData[13] = "C"
			laData[24] = "SCSMG Blacklist"
		ENDIF
	ENDIF 	
	laData[22] = ALLTRIM(laData[2])+" "+ALLTRIM(laData[3])
	INSERT INTO cims!member_scb FROM ARRAY laData
	*
	=insertToSQL()
ENDFOR 
*
IF llBlClosed
	USE IN smg_blacklist
ENDIF 	

*******************************
function insertToSQL


if gnConn <= 0
	return
endif

lcSql = "{call sp_insertMemberSCB(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}"
lnSuscess = sqlexec(gnConn, lcSql)
return lnSuscess
