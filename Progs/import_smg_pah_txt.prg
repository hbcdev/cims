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
USE (DATAPATH+"smg_policy") IN 0
*
SELECT 0	
lnSelect = SELECT()
CREATE TABLE (lcDbf) FREE (Policy_no C(30), Plan C(20), Cust_id C(20), Title C(20), Name C(40), Surname C(40), sex C(1), dob D, age I, ;
	address1 C(40), address2 C(40), address3 C(40), address4 C(40), country C(40), postcode C(5), telephone C(30), ;
	pol_date T, Eff_date T, Exp_date T, agent C(20), agency C(20), medical Y, netpremium Y, refno C(30), ;
	reportdate D, projcode C(20), personcode C(20), projgrp C(20), sellbr C(4), selldate D, lotno C(20), ;
	subclass C(20), personno C(20), idno C(20), creditcard C(20), datato C(20), insured C(60), grouptype C(1), ;
	prodno I, locno I, itemno I, plan_id C(8), cardid C(25), filename C(40), quono C(30), l_update T)
*
?DBF()
STORE 0 TO lnNew, lnUpdate
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 2 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 999,999")+"/"+TRANSFORM(lnLines, "@Z 999,999") AT 25, 45 NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts - 1
		laData[j] = STRTRAN(IIF(AT(";",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(";",lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')		
		DO CASE 
		CASE INLIST(j , 8, 17, 18, 19, 25, 30)
			laData[j] = IIF(ISNULL(laData[j]), {}, laData[j])
			IF EMPTY(laData[j])
				laData[j] = {}
			ENDIF 	
			IF TYPE("laData[j]") = "C"
				laData[j] = CTOD(laData[j])
			ENDIF 				
			IF INLIST(j, 17, 18, 19)
				IF EMPTY(laData[j])
					laData[j] = {}
				ELSE 	
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 16, 00)
				ENDIF 	
			ENDIF 	
		CASE INLIST(j ,9, 22, 23)
			laData[j] = VAL(STRTRAN(laData[j], ",", ""))
		CASE j = 28
			IF laData[28] = "PADEBIT"
				laData[17] = DATETIME(YEAR(laData[17]), MONTH(laData[17]), DAY(laData[17]), 12, 00)
				laData[18] = DATETIME(YEAR(laData[18]), MONTH(laData[18]), DAY(laData[18]), 12, 00)
				laData[19] = DATETIME(YEAR(laData[19]), MONTH(laData[19]), DAY(laData[19]), 12, 00)
			ENDIF
		CASE j = 33	
			IF EMPTY(laData[26])
				laData[24] = ALLTRIM(laData[24])+"-"+STRTRAN(STR(VAL(laData[33]), 4), " ", "0")
			ENDIF 
		ENDCASE
		IF AT(";",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	*
	DO CASE 
	CASE laData[28] = "PADEBIT"
		laData[17] = DATETIME(YEAR(laData[17]), MONTH(laData[17]), DAY(laData[17]), 12, 00)
		laData[18] = DATETIME(YEAR(laData[18]), MONTH(laData[18]), DAY(laData[18]), 12, 00)
		laData[19] = DATETIME(YEAR(laData[19]), MONTH(laData[19]), DAY(laData[19]), 12, 00)
		***************************	
		DO CASE 
		CASE laData[22] = 5000
			laData[42] = "SMG1050" 	
		CASE laData[22] = 25000
			laData[42] = "SMG1051" 	
		OTHERWISE 
			laData[42] = "SMG1050"
		ENDCASE	
		laData[43] = laData[35]
		laData[45] = laData[35]
	CASE laData[28] = "PAH"
		DO CASE 
		CASE laData[22] = 50000
			laData[42] = "SMG1440" 	
		CASE laData[22] = 100000
			laData[42] = "SMG1441" 	
		CASE laData[22] = 300000
			IF "3" $ laData[2]
				laData[42] = "SMG1442" 	
			ELSE 	
				laData[42] = "SMG1443" 	
			ENDIF
		OTHERWISE 
			laData[42] = "SMG1440"
		ENDCASE
		laData[43] = STRTRAN(ALLTRIM(laData[24]), "-", "")
		laData[45] = laData[24]
	CASE laData[28] = "PA กลุ่ม"	
		laData[42] = "SMG1444"	
		laData[43] = STRTRAN(ALLTRIM(laData[24]), "-", "")
		laData[45] = laData[24]		
	CASE UPPER(laData[28]) = "MYFAMILYPA"
		IF laData[2] = "MyFamilyPAChild"
			laData[42] = "SMG1679"
		ELSE 
			laData[42] = "SMG1678"		
		ENDIF 		
		laData[43] = STRTRAN(ALLTRIM(laData[24]), "-", "")
		laData[45] = laData[24]		
	OTHERWISE 
		laData[42] = "SMG1444"
		laData[43] = STRTRAN(ALLTRIM(laData[24]), "-", "")
		laData[45] = laData[24]		
	ENDCASE 
	laData[2] = IIF(AT("/", laData[2]) <> 0, LEFT(laData[2], AT("/", laData[2])-3), laData[2])
	laData[44] = JUSTFNAME(DBF())
	laData[46] = DATETIME()
	lcPolIdNo = IIF(LEN(laData[1]) > 30, LEFT(laData[1],30), laData[1]+REPLICATE(" ", 30-LEN(laData[1]))+LEFT(laData[34],20))
	lcRefPers = IIF(LEN(laData[24]) > 30, LEFT(laData[24],30), laData[24]+REPLICATE(" ", 30-LEN(laData[24]))+LEFT(laData[27],20))	
	IF SEEK(lcRefPers, "smg_policy", "ref_pers")
		lnUpdate = lnUpdate+1
		SELECT smg_policy
		GATHER FROM laData
		SELECT (lnSelect)
	ELSE 
		lnNew = lnNew+1
		INSERT INTO (DATAPATH+"smg_policy") FROM ARRAY laData		
	ENDIF
	laData[37] = IIF(laData[28] = "PADEBIT", ALLTRIM(laData[5])+" "+ALLTRIM(laData[6]), laData[37])
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR
lcMessage = "Update: "+TRANSFORM(lnUpdate, "@Z 999,999") +CHR(13)+;
	"New: "+TRANSFORM(lnNew, "@Z 999,9999") +CHR(13)+;
	"Total: "+TRANSFORM(RECCOUNT(lnSelect), "@Z 999,999") +CHR(13)	
=MESSAGEBOX(lcMessage,0,"SMG Convert")	
*
USE IN smg_policy
SELECT (lnSelect)
BROWSE
lcHp = STUFF(STUFF(DBF(), AT("PAH", DBF()), 4, ""), AT("PADEBIT", STUFF(DBF(), AT("PAH", DBF()), 4, "")), 8, "")
lcPaDebit = STUFF(STUFF(DBF(), AT("PAH", DBF()), 4, ""), AT("HP", STUFF(DBF(), AT("PAH", DBF()), 4, "")), 3, "")
lcPah = STUFF(STUFF(DBF(), AT("PADEBIT", DBF()), 8, ""), AT("HP", STUFF(DBF(), AT("PADEBIT", DBF()), 8, "")), 3, "")
lcOther = STUFF(lcPah, AT("PAH", lcPah), 3, "OTH")
lcPag = STUFF(lcPah, AT("PAH", lcPah), 3, "PAG")
*
COPY TO (lcOther) FOR !INLIST(projgrp , "PAH", "PADEBIT", "PHP", "PA กลุ่ม")
COPY TO (lcPag) FOR projgrp = "PA กลุ่ม"
COPY TO (lcPah) FOR projgrp = "PAH"
COPY TO (lcPaDebit) FOR projgrp = "PADEBIT"
COPY TO (lcHp) FOR projgrp = "PHP"
* 