lcSourceFile = GETFILE("TXT", "BKI NEW & ADJ")
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
IF !USED("bki_premium")
	IF FILE(ADDBS(DATAPATH)+"bki_premium.dbf")
		USE (ADDBS(DATAPATH)+"bki_premium") IN 0
	ELSE 
		=MESSAGEBOX("ไม่พบตารางเบี้ยประกัน กรุณาแจ้ง Admin",0+16,"Error")
		RETURN 			
	ENDIF 
ENDIF
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
SELECT 0
CREATE TABLE (lcDbf) FREE (policy_no C(30), plan C(20), cust_id C(20), title C(20), fullname C(120), sex C(1), dob D, age I, ;
	address1 C(40), address2 C(40), address3 C(40), address4 C(40), country C(40), postcode C(5), phone C(20), contact_p C(30), contact_t C(20), ;
	effdate T, expdate T, premium Y, exclusion C(200), channel C(20), agent_code C(40), paymode C(1), old_pol C(30), pol_status C(1), renew_time I, endos C(30), end_type C(2), ;
	fleet_seq I, fam_seq N(5), sub_seq N(2), payor C(10), cus_code C(8), cus_name C(120), unique_no C(20), sts_flag C(1), cancel_flg C(1), fam_sts C(1), pricipleid C(20), ;
	package C(30), paiddate D, address C(250), oldeffdate T, expiry T, name C(60), surname C(60), suminsure Y, payfreq I, adddate D, planid C(10))	
	
IF "BKINEW" $ UPPER(dbf())		
	ldDate = SUBSTR(JUSTFNAME(DBF()), 13, 2)+"/"+SUBSTR(JUSTFNAME(DBF()), 11, 2)+"/"+SUBSTR(JUSTFNAME(DBF()), 7, 4)
ELSE 
	ldDate = SUBSTR(JUSTFNAME(DBF()), 16, 2)+"/"+SUBSTR(JUSTFNAME(DBF()), 14, 2)+"/"+SUBSTR(JUSTFNAME(DBF()), 10, 4)
ENDIF 	
lcAlias = ALIAS()
**
lnFieldAmt = 45
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
DIMENSION laFieldWidth[lnFieldAmt]
laFieldWidth[1] = 30
laFieldWidth[2] = 8
laFieldWidth[3] = 15
laFieldWidth[4] = 60
laFieldWidth[5] = 120
laFieldWidth[6] = 1
laFieldWidth[7] = 8
laFieldWidth[8] = 2
laFieldWidth[9] = 60
laFieldWidth[10] = 60
laFieldWidth[11] = 1
laFieldWidth[12] = 1
laFieldWidth[13] = 1
laFieldWidth[14] = 5
laFieldWidth[15] = 50
laFieldWidth[16] = 1
laFieldWidth[17] = 1
laFieldWidth[18] = 8
laFieldWidth[19] = 8
laFieldWidth[20] = 12
laFieldWidth[21] = 200
laFieldWidth[22] = 15
laFieldWidth[23] = 15
laFieldWidth[24] = 1
laFieldWidth[25] = 30
laFieldWidth[26] = 2
laFieldWidth[27] = 2
laFieldWidth[28] = 30
laFieldWidth[29] = 2
laFieldWidth[30] = 5
laFieldWidth[31] = 5
laFieldWidth[32] = 2
laFieldWidth[33] = 10
laFieldWidth[34] = 8
laFieldWidth[35] = 120
laFieldWidth[36] = 20
laFieldWidth[37] = 1
laFieldWidth[38] = 1
laFieldWidth[39] = 1
laFieldWidth[40] = 20
laFieldWidth[41] = 20
laFieldWidth[42] = 8
laFieldWidth[43] = 250
laFieldWidth[44] = 10
laFieldWidth[45] = 10
*
SELECT (lcAlias)
FOR i = 1 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldAmt
		laData[j] = ALLTRIM(LEFT(lcTemp, laFieldWidth[j]))
		IF INLIST(j, 7, 8)
			IF j = 7
				IF LEN(laData[j]) < 8
					lcAge = laData[j]
					laData[j] = ""					
				ENDIF 	
			ENDIF 
			IF j = 8
				IF EMPTY(laData[j])
					laData[j] = lcAge
				ENDIF 
			ENDIF 			
		ENDIF 
		*
		IF INLIST(j ,7,18,19, 44, 45)
			IF EMPTY(ALLTRIM(laData[j]))
				laData[j] = {}	
			ELSE 			
				laData[j] = CTOD(LEFT(laData[j],2)+"/"+SUBSTR(laData[j],3,2)+"/"+SUBSTR(laData[j], 5,4))
				IF inlist(j, 18, 19, 44, 45)
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 00, 01)
				ENDIF 					
			ENDIF 	
		ENDIF 	
		IF INLIST(j ,8,20,27)
			laData[j] = VAL(laData[j])
		ENDIF 	
		*
		lcTemp = SUBSTR(lcTemp, laFieldWidth[j]+1)
	ENDFOR 
	*
	laData[20] = getBkiPremium("BKI", laData[41],laData[2],laData[8])
	laData[46] = ALLTRIM(LEFT(laData[5], AT(" ", laData[5])))
	laData[47] = ALLTRIM(SUBSTR(laData[5], AT(" ", laData[5])))
	laData[50] = ldDate	
	*
	DO CASE 
	CASE SUBSTR(laData[1], 9, 1) = "7"
		laData[48] = ICASE(laData[2] = "1", 30000, laData[2] = "2", 50000, 0)
		laData[51] = ICASE(laData[2] = "1", "BKI1678", laData[2] = "2", "BKI1679", "")	
	CASE SUBSTR(laData[1], 9, 1) = "9"
		laData[48] = ICASE(laData[2] = "1", 20000, laData[2] = "2", 30000, laData[2] = "3", 40000, laData[2] = "4", 60000, 0)
		laData[51] = ICASE(laData[2] = "1", "BKI1693", laData[2] = "2", "BKI1694", laData[2] = "3", "BKI1695", laData[2] = "4", "BKI1696", "")	
	ENDCASE 		
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 		
*
lcError = ""
llError = .F.

SELECT (lcAlias)
GO TOP 
SCAN 
	SCATTER MEMVAR 
	REPLACE premium WITH getBkiPremium("BKI", m.package,m.plan,m.age)
	*
	IF EMPTY(policy_no) AND EMPTY(plan) AND EMPTY(name) AND EMPTY(surname) AND EMPTY(plan_id) AND EMPTY(effdate) AND EMPTY(expdate) AND EMPTY(premium)
		llError = .T.
		lcError = alltrim(package)+" "+ALLTRIM(policy_no)+"|"+ALLTRIM(plan)+"|"+ALLTRIM(name)+"|"+ALLTRIM(surname)+"|"+TTOC(effdate)+"|"+TTOC(expdate)+CHR(13)
		=STRTOFILE(lcError, "bki_new_error.txt",.t.)
	ENDIF 
ENDSCAN 
*
GO TOP 
BROWSE 
USE 
*
IF llError
	MODIFY FILE bki_new_error.txt NOEDIT 
ENDIF 	

*******************
function getOldEffective(tcPolicyNo)

ldEff = {}
select effective from cims!member where policy_no = tcPolicyNo into array laEff
if _TALLY = 1
	ldEff = laEff[1]
endif
return ldEff
