*!*	lcSourceFile = GETFILE("TXT")
*!*	lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
*!*	*************************************
*!*	IF EMPTY(lcSourceFile)
*!*		RETURN 
*!*	ENDIF 
*!*	*	
*!*	IF FILE(lcDbf)
*!*		=MESSAGEBOX(lcDbf+" is exist")
*!*	*	RETURN 
*!*	ENDIF 
*	
SET DEFAULT TO ?

lnAmountFiles = ADIR(laBki, "*.TXT")
FOR lnFile = 1 TO lnAmountFiles
	DO ConvertToDbf WITH laBki[lnFile, 1]
ENDFOR 		
*
******************************
PROCEDURE ConvertToDbf
PARAMETERS tcTextFile

lcSourceFile = tcTextFile
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
*************************************
*	
*IF FILE(lcDbf)
	=MESSAGEBOX(lcDbf+" is exist")
*	RETURN 
*ENDIF 
?lcSourceFile
*************************************
SELECT A
CREATE TABLE (lcDbf) FREE (policy_no C(30), plan C(20), cust_id C(20), title C(20), fullname C(120), sex C(1), dob D, age I, ;
	address1 C(40), address2 C(40), address3 C(40), address4 C(40), country C(40), postcode C(5), phone C(20), contact_p C(30), contact_t C(20), ;
	effdate T, expdate T, premium Y, exclusion C(200), channel C(20), agent_code C(40), paymode C(1), old_pol C(30), pol_status C(1), renew_time I, endos C(30), end_type C(2), ;
	fleet_seq I, fam_seq N(5), sub_seq N(2), payor C(10), cus_code C(8), cus_name C(120), unique_no C(20), sts_flag C(1), cancel_flg C(1), fam_sts C(1), pricipleid C(20), name C(60), surname C(60), ;
	acno C(10), acname C(50), bankcode C(3), bankname C(30), br_code C(3), br_name C(40), p_addr1 C(50), p_addr2 C(60), jw_code C(2), zipcode C(5), p_phone C(30))
*
lnFieldAmt = 40
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
*
FOR i = 1 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	SELECT A
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
	laData[41] = ALLTRIM(LEFT(laData[5], AT(" ", laData[5])))
	laData[42] = ALLTRIM(SUBSTR(laData[5], AT(" ", laData[5])))
	laData[43] = "2080051515"
	laData[44] = "สหกรณ์ออมทรัพย์การไฟฟ้าฝ่ายผลิตแห่งประเทศไทย จำกัด"
	laData[45] = "002"
	laData[46] = "ธนาคารกรุงเทพ จำกัด(มหาชน) "
	laData[47] = "208"
	laData[49] = "การไฟฟ้าฝ่ายผลิตแห่งประเทศไทย จำกัด"
	laData[50] = "53 หมู่ 2 ถนนจรัญสนิทวงศ์ ตำบลบางกรวย อำเภอเมือง นนทบุรี    "
	laData[51] = "23"
	laData[52] = "11130"
	laData[53] = "024365911"
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 		
*
PROCEDURE aa 
SELECT A
GO TOP 
DO WHILE !EOF()
	lnCount = 0
	lcCustID = cust_id
	DO WHILE cust_id = lcCustID AND !EOF()
		REPLACE cust_id WITH ALLTRIM(cust_id) + IIF(lnCount = 0, "", "-"+STRTRAN(STR(lncount, 2), " ", "0"))
		lnCount = lncount + 1
		SKIP 
	ENDDO 
ENDDO 		