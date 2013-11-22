lcSourceFile = GETFILE("TXT", "Open")
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
lcMainDbf = ADDBS(DataPath)+"Bki_073_payment.Dbf"
IF !FILE(lcMainDbf)
	CREATE TABLE (lcMainDbf) FREE (policy_no C(30), insure C(120), period I, duedate D, paiddate D, premium Y, adddate D, filename C(50))
ENDIF 	
*
CREATE CURSOR bkiPayment (policy_no C(30), insure C(120), period I, duedate D, paiddate D, premium Y, adddate D, filename C(50))
DO ConvertToDbf WITH lcSourceFile
*
*!*	SET DEFAULT TO ?
*!*	lnAmountFiles = ADIR(laBki, "*.TXT")
*!*	FOR lnFile = 1 TO lnAmountFiles
*!*		DO ConvertToDbf WITH laBki[lnFile, 1]
*!*	ENDFOR 		
*
PROCEDURE convertToDbf
PARAMETERS tcSourceFile
IF EMPTY(tcSourceFile)
	RETURN 
ENDIF 	

?tcSourceFile
lcDate = SUBSTR(JUSTFNAME(tcSourceFile),11,8)
ldDate = CTOD(RIGHT(lcDate,2)+"/"+SUBSTR(lcDate,5,2)+"/"+LEFT(lcDate,4))
*
lnFieldAmt = 6
lnLines = ALINES(laTextArray,FILETOSTR(tcSourceFile))
DIMENSION laFieldWidth[lnFieldAmt]
laFieldWidth[1] = 30
laFieldWidth[2] = 120
laFieldWidth[3] = 3
laFieldWidth[4] = 8
laFieldWidth[5] = 8
laFieldWidth[6] = 12
*
SELECT bkipayment
FOR i = 1 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldAmt
		laData[j] = ALLTRIM(LEFT(lcTemp, laFieldWidth[j]))
		IF INLIST(j ,4,5)
			IF EMPTY(ALLTRIM(laData[j]))
				laData[j] = {}	
			ELSE 			
				laData[j] = CTOD(LEFT(laData[j],2)+"/"+SUBSTR(laData[j],3,2)+"/"+SUBSTR(laData[j], 5,4))
			ENDIF 	
		ENDIF 	
		IF INLIST(j ,3,6)
			laData[j] = IIF(TYPE("laData[j]") = "C", VAL(laData[j]), laData[j])
		ENDIF 	
		*
		lcTemp = SUBSTR(lcTemp, laFieldWidth[j]+1)
	ENDFOR 
	laData[7] = ldDate
	laData[8] = JUSTFNAME(tcSourceFile)
	*
	INSERT INTO bkiPayment FROM ARRAY laData
	************************************************************
	lcPolNo = LEFT(laData[1], 30)
	lnPeriod = laData[3]
	SELECT policy_no ;
	FROM (lcMainDbf) ;
	WHERE policy_no = lcPolNo ;
		AND period = lnPeriod ;
	INTO ARRAY laPay
	IF _TALLY = 0
		INSERT INTO (lcMaindbf) FROM ARRAY laData
	ELSE 
		? laPay[1]
		UPDATE (lcMainDbf) SET paiddate = laData[5], ;
			adddate = laData[7], ;
			filename = laData[8] ;
		WHERE policy_no = lcPolNo ;
			AND period = lnPeriod
	ENDIF 			
ENDFOR 		
SELECT bkiPayment
BROWSE 
IF MESSAGEBOX("ต้องการอัพเดทเข้าระบบหรือไม่ ",4+32+256,"Comfrim") = 7
	RETURN 
ENDIF 	
*	
llUseMember = .T.
IF !USED("member")
	USE cims!member IN 0
	llUseMember = .T.
ENDIF 	
IF FILE("bki_error.txt")
	DELETE FILE bki_error.txt
ENDIF 	
*
CLEAR 
SELECT bkiPayment
GO TOP 
IF RECCOUNT() = 0
	RETURN 
ENDIF 		
llError = .F.
lnRecNo = 0
DO WHILE !EOF()
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	lcPayMode = ""
	IF SEEK("BKI"+policy_no, "member", "policy_no")
		lcPolNo = policy_no
		DO WHILE policy_no = lcPolNo AND !EOF()
			lcPayMode = STR(period,1)
			IF !EMPTY(paiddate)
				IF VAL(member.pay_fr) < period
					REPLACE member.pay_fr WITH STR(period,1), ;
						member.lastpaid WITH paiddate
				ENDIF 		
				lnRecNo = lnRecNo + 1						
			ENDIF
			SKIP 
		ENDDO 
		REPLACE member.pay_mode WITH lcPayMode
	ELSE 
		llError = .T.
		=STRTOFILE(ALLTRIM(policy_no)+CHR(13), "bki_error.txt",.T.)
		SKIP 
	ENDIF 	
ENDDO 
lcUpdate = "Payment : " + STR(lnRecNo)+"/"+STR(RECCOUNT())
=MESSAGEBOX(lcUpdate,0)
USE IN bkiPayment
IF llError
	MODIFY FILE bki_error.txt NOEDIT 
ENDIF