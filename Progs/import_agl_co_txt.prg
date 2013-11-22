lcSourceFile = GETFILE("TXT")
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
ldDate = CTOD(SUBSTR(JUSTFNAME(lcDbf), 9,2)+"/"+SUBSTR(JUSTFNAME(lcDbf),6,2)+"/"+SUBSTR(JUSTFNAME(lcDbf),1, 4))
ldDate = IIF(EMPTY(ldDate), DATE(), ldDate)
?lcSourceFile
**************************************
SET HOURS TO 24
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
*
SELECT 0
CREATE DBF (lcDbf) FREE (Benfcode C(30),  lak2bht Y, usd2bht Y, seqno C(1), desctext C(30), daycover I, per C(1), benfcover Y, ;
	policy_no C(30), plan C(20), catcode C(10), catid C(7),  curr_t C(3), service I,  adddate D, benf_th Y)	
lnSelect = SELECT()	
*
?DBF()
lnError = 0
lcErrFile = STRTRAN(lcDbf, "DBF", "ERR")
lnFieldCounts = 8
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 1 TO lnLines
	llError = .F.
	WAIT WINDOW TRANSFORM(i, "@Z 999,999") NOWAIT 
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT("|",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT("|",lcTemp)-1)),"|","")
		laData[j] = STRTRAN(laData[j], '"','')	
		laData[j] = IIF(laData[j] = "NULL", "", laData[j])
		*	
		DO CASE 
		CASE INLIST(j, 2, 3, 6, 8)
			IF TYPE("laData[j]") = "C"
				laData[j] = VAL(laData[j])
			ENDIF 
		ENDCASE 
		*		
		IF AT("|",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT("|",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	*
	laData[6] = IIF(laData[6] = 0, 1, laData[6])	
	laData[7] = ICASE(laData[4] = "A", "D", laData[4] = "B", "D", laData[4] = "C", "M", ;
		laData[4] = "D", "M", laData[4] = "E", "M", laData[4] = "F", "M", laData[4] = "G", "D", ;
		laData[4] = "H", "M", laData[4] = "I", "M", laData[4] = "J", "D", laData[4] = "Z", "Y", "")		
		
	SELECT product FROM cims!member WHERE quotation = laData[1] INTO ARRAY aProduct
	IF _TALLY > 0
		laData[10] = aProduct[1]
		laData[13] = iif(RIGHT(ALLTRIM(laData[10]),1) = "L", "LAK", "USD")
		laData[16] = IIF(laData[13] = "LAK", laData[8] / laData[2], laData[8] * laData[3])
	else 	
		llError = .T.
		lcError = benfcode	+"|"+catcode+CHR(13)
		=STRTOFILE(lcError, lcErrFile, 1)	
	ENDIF 
	*
	laData[9] = LEFT(laData[1], 9)
	laData[11] = ICASE(laData[4] = "A", "RB90D", laData[4] = "B", "ICU7D", laData[4] = "C", "GHS90", ;
		laData[4] = "D", "SG90", laData[4] = "E", "SGR90", laData[4] = "F", "ANES90", laData[4] = "G", "DGS90D", ;
		laData[4] = "H", "LAB90", laData[4] = "I", "ER24HR", laData[4] = "J", "OPD30D", laData[4] = "Z", "ALL", "")
	laData[12] = ICASE(laData[4] = "A", "0000813", laData[4] = "B", "0000814", laData[4] = "C", "0000815", ;
			laData[4] = "D", "0000816", laData[4] = "E", "0000817", laData[4] = "F", "0000818", laData[4] = "G", "0000819", ;
			laData[4] = "H", "0000821", laData[4] = "I", "0000820", laData[4] = "J", "0000822", laData[4] = "Z", "9999999", "")
	laData[14] = ICASE("ALL" $ laData[11], 9, "OPD30D" $ laData[11], 1, "ER24HR" $ laData[11], 3, "LAB90" $ laData[11], 6, 2)
	laData[15] = ldDate
	*
	INSERT INTO (lcdbf) FROM ARRAY laData
	if llError
		lnError = lnError + 1
		delete 
	endif 	
ENDFOR 
*
if lnError > 0
	=MESSAGEBOX("พบมีข้อผิดพลาดในข้อมูล กรุณาตรวจสอบก่อนจะนำเข้าระบบ ",0,"Error")
	BROWSE 
	return 
else 
	browse 	
endif 	
*	
SELECT adddate, COUNT(*) FROM cims!member WHERE tpacode = "AGL" AND adddate = ldDate GROUP BY 1 INTO ARRAY laUpdate
IF _TALLY = 0
	=MESSAGEBOX("กรุณานำเข้าข้อมูลผู้เอาประกันของวันที่ "+DTOC(ldDate)+" เข้าก่อนจะนำเข้าข้อมูลตารางผลประโยชน์",0,"Error")
	RETURN 
ENDIF 	
*
IF MESSAGEBOX("ต้องการให้โอนเข้าฐานข้อมูล หรือไม่",4+32+256,"Confrim") = 7
	RETURN 
ENDIF 	
*********************************
SELECT (lnSelect)
GO TOP 
IF !USED("policy2items")
	USE cims!policy2items IN 0
ENDIF 
IF !USED("member")	
	USE cims!member IN 0
ENDIF 
	
lnNew = 0
**********************************
IF FILE(lcErrFile)
	DELETE FILE (lcErrFile)
ENDIF 	
**********************************
STORE 0 TO lnNew, lnUpdate, lnNoUpdate, lnDele
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	if empty(plan) and empty(benf_th)
		llError = .T.
		lnDele = lnDele + 1
		lcError = benfcode	+"|"+catcode+CHR(13)
		=STRTOFILE(lcError, lcErrFile, 1)	
	else 	
		IF SEEK(ALLTRIM(benfcode), "member", "quotation")
			m.effdate = member.effective
			m.expdate = member.expiry
		ELSE 
			m.effdate = {}
			m.expdate = {}
			*************************************
			llError = .T.
			lnDele = lnDele + 1
			lcError = benfcode	+"|"+catcode+CHR(13)
			=STRTOFILE(lcError, lcErrFile, 1)	
		ENDIF 	
		****************************************
		m.fundcode = "AGL"
		m.policy_no = policy_no
		m.plan = plan	
		m.trailer = service
		m.cat_id = catid
		m.catcode = catcode
		m.catdesc = desctext
		m.rate = 0
		m.benefit = benfcover
		m.itemcode = ""
		m.l_user = gcUserName
		m.l_update = DATETIME()		
		m.adddate = adddate
		m.per = per
		m.currency_type = curr_t
		m.daycover = daycover
		m.benefitcode = benfcode	
		m.fxrate = IIF(curr_t = "LAK", lak2bht, usd2bht)
		m.remark = ""
		m.benefit_th = benf_th 
		*****************************************************
		SELECT benefitcode ;
		FROM cims!policy2items ;
		WHERE fundcode = "AGL" ;
			AND benefitcode = m.benefitcode ;
			AND catcode = m.catcode ;
		INTO ARRAY laAgl
		IF _TALLY = 0
			lnNew = lnNew + 1			
			INSERT INTO cims!policy2items FROM MEMVAR
			=insertPolicy2ItemsSQL("policy2items", gnConn)
		ELSE 
			UPDATE cims!policy2items SET ;
				fundcode = m.fundcode, ;
				benefitcode = m.benefitcode, ;
				plan = m.plan, ;
				policy_no = m.policy_no, ;
				effdate = m.effdate, ;
				expdate = m.expdate, ;
				per = m.per, ;
				cat_id = m.cat_id, ;
				daycover = m.daycover, ;
				catcode = m.catcode, ;
				catdesc = m.catdesc, ;
				benefit = m.benefit, ;
				benefit_th = m.benefit_th, ;
				fxrate = m.fxrate, ;
				currency_type = m.currency_type, ;
				trailer = m.trailer, ;
				l_user = m.l_user, ;
				l_update = m.l_update ;
			WHERE fundcode = "AGL" ;
				AND benefitcode = m.benefitcode ;
				AND catcode = m.catcode
			IF _TALLY = 0
				=updatePolicy2ItemsSQL("policy2items", gnConn)
				lnNoUpdate = lnNoUpdate + 1
			ELSE 
				lnUpdate = lnUpdate + 1
			ENDIF
		ENDIF 
		IF catcode = "OPD"
			lcPlanId = getAglPlanID()
			IF !EMPTY(lcPlanId)
				IF SEEK(benfcode, "member", "quotation")
					lcBenfCode = ALLTRIM(benfcode)
					SELECT member
					DO WHILE ALLTRIM(quotation) = lcBenfCode
						REPLACE plan_id WITH lcPlanID
						SKIP 
					ENDDO 
				ENDIF 	
			ENDIF 
		ENDIF 
		****************
		do updateToSql
		
		
	endif 	
	SELECT (lnSelect)
ENDSCAN
IF llError
	MODIFY FILE (lcErrFile)
ENDIF 	
=MESSAGEBOX("New Data: " + TRANSFORM(lnNew, "@Z 999,999")+CHR(13)+;
	"Update:      "+TRANSFORM(lnUpdate, "@Z 999,999")+CHR(13)+;
	"No Update: "+TRANSFORM(lnNoUpdate, "@Z 999,999")+CHR(13)+;	
	"Not Found: "+TRANSFORM(lnDele, "@Z 999,999"), 0)
*********************************************
FUNCTION getAglPlanID

lcPlanId = ""
DO CASE 
CASE SUBSTR(benfcode,11,4) = "HSB0"
	DO CASE 
	CASE benfcover = 10 OR benfcover = 86000 OR benfcover = 87000
		lcPlanID = "AGL1653"
	CASE benfcover = 20 OR benfcover = 173000
		lcPlanID = "AGL1654"		
	CASE benfcover = 30 OR benfcover = 260000
		lcPlanID = "AGL1655"		
	CASE benfcover = 40 OR benfcover = 346000
		lcPlanID = "AGL1656"		
	CASE benfcover = 50 OR benfcover = 430000
		lcPlanID = "AGL1657"		
	ENDCASE 
CASE SUBSTR(benfcode,11,4) = "HSB1"
	DO CASE 
	CASE benfcover = 10 OR benfcover = 86000 OR benfcover = 87000
		lcPlanID = "AGL1658"
	CASE benfcover = 20 OR benfcover = 173000
		lcPlanID = "AGL1659"		
	CASE benfcover = 30 OR benfcover = 260000
		lcPlanID = "AGL1660"		
	CASE benfcover = 40 OR benfcover = 346000
		lcPlanID = "AGL1661"		
	CASE benfcover = 50 OR benfcover = 430000
		lcPlanID = "AGL1662"		
	ENDCASE 
CASE SUBSTR(benfcode,11,4) = "HSB2"
	DO CASE 
	CASE benfcover = 10 OR benfcover = 86000 OR benfcover = 87000
		lcPlanID = "AGL1663"
	CASE benfcover = 20 OR benfcover = 173000
		lcPlanID = "AGL1664"		
	CASE benfcover = 30 OR benfcover = 260000
		lcPlanID = "AGL1665"		
	CASE benfcover = 40 OR benfcover = 346000
		lcPlanID = "AGL1666"		
	CASE benfcover = 50 OR benfcover = 430000
		lcPlanID = "AGL1667"		
	ENDCASE 
CASE SUBSTR(benfcode,11,4) = "HSB3"
	DO CASE 
	CASE benfcover = 10 OR benfcover = 86000 OR benfcover = 87000
		lcPlanID = "AGL1668"
	CASE benfcover = 20 OR benfcover = 173000
		lcPlanID = "AGL1669"		
	CASE benfcover = 30 OR benfcover = 260000
		lcPlanID = "AGL1670"		
	CASE benfcover = 40 OR benfcover = 346000
		lcPlanID = "AGL1671"		
	CASE benfcover = 50 OR benfcover = 430000
		lcPlanID = "AGL1672"		
	ENDCASE 
CASE SUBSTR(benfcode,11,4) = "HSB4"
	DO CASE 
	CASE benfcover = 10 OR benfcover = 86000 OR benfcover = 87000
		lcPlanID = "AGL1673"
	CASE benfcover = 20 OR benfcover = 173000
		lcPlanID = "AGL1674"		
	CASE benfcover = 30 OR benfcover = 260000
		lcPlanID = "AGL1675"		
	CASE benfcover = 40 OR benfcover = 346000
		lcPlanID = "AGL1676"		
	CASE benfcover = 50 OR benfcover = 430000
		lcPlanID = "AGL1677"		
	ENDCASE 		
ENDCASE 	
RETURN lcPlanID
***************************************
procedure updateToSql


lcSql = "{call sp_insertPolicy2Items(?m.fundcode,?m.policy_no,?m.plan,?m.effdate,?m.expdate,?m.trailer,?m.cat_id,?m.catcode,?m.catdesc,"+;
	"?m.rate,?m.benefit,?m.itemcode,?m.l_user,?m.l_update,?m.adddate,?m.per,?m.currency_type,?m.daycover,?m.benefitcode,?m.fxrate,?m.remark,?m.benefit_th)}"
if sqlexec(gnConn, lcSql) < 0
	=saveError(program()+" SQL Connection Error")
endif 
