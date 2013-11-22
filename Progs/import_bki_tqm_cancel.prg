lcSourceFile = GETFILE("TXT", "Open")
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
llCovert = .T.
IF FILE(lcDbf)
	llCovert = MESSAGEBOX("want to convert again.",4+32+256,"Comfrim") = 6
ENDIF 	
*
IF llCovert
	SELECT 0
	CREATE TABLE (lcDbf) FREE (policy_no C(30), plan C(20), cust_id C(20), title C(20), fullname C(120), sex C(1), dob D, age I, ;
		address1 C(40), address2 C(40), address3 C(40), address4 C(40), country C(40), postcode C(5), phone C(20), contact_p C(30), contact_t C(20), ;
		effdate T, expdate T, premium Y, exclusion C(200), channel C(20), agent_code C(40), paymode C(1), old_pol C(30), pol_status C(1), renew_time I, endos C(30), end_type C(2), ;
		fleet_seq I, fam_seq N(5), sub_seq N(2), payor C(10), cus_code C(8), cus_name C(120), unique_no C(20), sts_flag C(1), cancel_flg C(1), fam_sts C(1), pricipleid C(20), package C(20), paiddate D, ;
		name C(60), surname C(60), suminsure Y, payfreq I, adjcancel D, planid C(10))
	ldDate = SUBSTR(JUSTFNAME(DBF()), 16, 2)+"/"+SUBSTR(JUSTFNAME(DBF()), 14, 2)+"/"+SUBSTR(JUSTFNAME(DBF()), 10, 4)	
	lcAlias = ALIAS()
	*
	IF !USED("bki_premium")
		IF FILE("d:\hips\data\bki_premium.dbf")
			USE d:\hips\data\bki_premium IN 0
		ELSE
			USE (ADDBS(DATAPATH)+"bki_premium") IN 0
		ENDIF
	ENDIF
	*
	lnFieldAmt = 42
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
			IF INLIST(j ,7,18,19)
				IF EMPTY(ALLTRIM(laData[j]))
					laData[j] = {}	
				ELSE 			
					laData[j] = CTOD(LEFT(laData[j],2)+"/"+SUBSTR(laData[j],3,2)+"/"+SUBSTR(laData[j], 5,4))
					IF j = 18
						laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 00, 01)
					ENDIF 					
					IF j = 19
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
		laData[43] = ALLTRIM(LEFT(laData[5], AT(" ", laData[5])))
		laData[44] = ALLTRIM(SUBSTR(laData[5], AT(" ", laData[5])))
		laData[45] = ICASE(laData[2] = "1", 30000, laData[2] = "2", 50000, 0)
		laData[47] = ldDate
		laData[48] = ICASE(laData[2] = "1", "BKI1678", laData[2] = "2", "BKI1679", "")	
		INSERT INTO (lcdbf) FROM ARRAY laData
	ENDFOR 		
	BROWSE 
	USE 
ENDIF 
************************************************************************************	
llUseMember = .T.

IF USED("bkicancel")
	SELECT bkicancel
ELSE 
	SELECT 0
ENDIF 		
USE (lcDbf) ALIAS bkicancel

IF !USED("member")
	USE cims!member IN 0
	llUseMember = .T.
ENDIF 	
IF RECCOUNT() = 0
	RETURN 
ENDIF 		
*
IF FILE("bki_error.txt")
	DELETE FILE bki_error.txt
ENDIF 	
*
llError = .F.
lnRecNo = 0
SELECT bkicancel
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	scatter memvar
	IF SEEK("BKI"+policy_no, "member", "policy_no")
		REPLACE member.expiry WITH bkicancel.expdate, ;
			member.polstatus WITH bkicancel.cancel_flg, ;
			member.adjcancel WITH bkicancel.adjcancel, ;
			member.l_user with gcUserName, ;
			member.l_update with datetime()
		lnRecNo = lnRecNo + 1			
		if !updateCancelMember("BKI", m.policy_no, fleet_seq, m.planid, m.expdate, m.cancel_flg, m.adjcancel, m.effdate, gcUserName, datetime())
			llError = .T.
			=STRTOFILE("SQL Error: "+ALLTRIM(policy_no)+" cannot update to SQL"+CHR(13), "bki_error.txt",.T.)
		endif 			
	ELSE 
		llError = .T.
		=STRTOFILE("Data Error : "+ALLTRIM(policy_no)+" is not found"+CHR(13), "bki_error.txt",.T.)
	ENDIF 	
ENDSCAN 			
**************************************************************
lcUpdate = "Cancel : " + STR(lnRecNo)+"/"+STR(RECCOUNT())
=MESSAGEBOX(lcUpdate,0)
USE in bkicancel 

IF llError
	MODIFY FILE bki_error.txt NOEDIT 
ENDIF 	