PARAMETERS gcFundCode, gdStartDate, gdEndDate

IF EMPTY(gcFundCode) AND EMPTY(gdStartDate)
	RETURN 
ENDIF 

IF EMPTY(gdEndDate)
	gdEndDate = gdStartDate
ENDIF 		
*
IF !USED("item")
	USE cims!item IN 0
ENDIF 
*
IF !USED("provider")
	USE cims!provider IN 0
ENDIF 
	
IF !USED("cig_icd10")	
	USE (ADDBS(datapath)+"cig_icd10") IN 0 ALIAS cig_icd10
ENDIF 	
*
SELECT claim.fundcode, claim.notify_no, claim.ref_date, claim.policy_no, claim.customer_id AS natid, claim.plan, claim.client_name, claim.return_date, ;
	claim.cause_type, claim.admis_date, claim.disc_date, claim.prov_id, claim.prov_name, claim.illness1, claim.result, ;
	claim.payment_type, claim.tr_acno, claim.tr_name, claim.bank, claim.tr_banch, claim.note2ins, ;
	SUBSTR(claim_line.cat_code, 3, 2) AS catType, claim_line.cat_code, claim_line.description AS cat_desc, ;
	claim_line.scharge-claim_line.sdiscount AS scharge, claim_line.spaid, ;
	ALLTRIM(member.h_addr1)+" "+ALLTRIM(member.h_addr2)+" "+ALLTRIM(member.h_city)+" "+ALLTRIM(member.h_province) AS address, ;
	member.h_postcode ;
FROM cims!claim_line INNER JOIN cims!claim ;
	ON claim_line.notify_no = claim.notify_no ;	
	LEFT JOIN cims!member ;
		ON claim.fundcode + claim.policy_no = member.tpacode + member.policy_no ;
WHERE claim.fundcode = gcFundCode ;
	AND claim.return_date Between gdStartDate AND gdEndDate ;
	AND INLIST(SUBSTR(claim_line.cat_code, 3, 2), "SF", "ET", "AC", "RC", "WR", "SL") ;
	AND claim_line.scharge # 0 ;		
ORDER BY claim.result, claim.notify_no ;
INTO CURSOR curClaim

IF _TALLY = 0
	RETURN 
ENDIF 

*!*	lcPath = "D:\report\cig\uat\"
*!*	lcDbf = "UAT_Claim"

CREATE DBF (ADDBS(lcPath)+lcDbf) FREE (claim_no C(30), policy_no C(30), prodcode C(16), covercode C(30), name C(60), natid C(20), client_rel C(60), ;
	paiddate D, claim_amt Y, pay_amt Y, delay_int Y, total_amt Y, summitted D, eventdate D, category C(16), class1 C(40), class2 C(68), class3 C(57), ;
	hospID C(13), hospname C(60), diagnosis C(60), clmstatus C(10), rej_date D, sus_reason C(100), sup_comp_d D, remark C(200), result C(3), ;
	diags2 C(20), diags3 C(10), proc1 C(10), proc2 C(10), proc3 C(10), ;
	payee C(60), payee_addr C(200), payee_post C(5), pay_type C(15), b_code C(3), b_branch C(20), b_accno C(15), payee_t C(2))
****************************************
SELECT (lcDbf)
SCATTER MEMVAR
****************************************
SELECT curClaim
DO WHILE !EOF()
	lnSeqNo = 1
	lcNotifyNo = curClaim.notify_no	
	DO WHILE notify_no = lcNotifyNo AND !EOF()
		m.claim_no = ALLTRIM(curClaim.notify_no)+STRTRAN(STR(lnSeqNo,2), " ", "0")
		m.prodcode = LEFT(curClaim.plan,6)
		m.prodrate = RIGHT(ALLTRIM(m.prodcode),1)
		IF SEEK(curClaim.cattype, "item", "item_grp")
			m.category = item.category
			m.class1 = item.class1
			m.class2 = item.class2
			m.class3 = item.class3
			m.proc1 = item.proc1
			m.proc2 = item.proc2
			m.proc3 = item.proc3
		ELSE 
			m.category = "Dental"
			m.class1 = curClaim.cat_desc
			m.class2 = curClaim.cat_code
			m.class3 = ""
			m.proc1 = ""
			m.proc2 = ""
			m.proc3 = ""
		ENDIF 		
		*
		lcIcd10 = IIF(LEN(ALLTRIM(curClaim.illness1)) > 3, STUFF(ALLTRIM(curClaim.illness1), 4, 0, "."), ALLTRIM(curClaim.illness1))
		m.diagnosis = lcIcd10	
		m.covercode = IIF(ISALPHA(RIGHT(ALLTRIM(curClaim.cat_code),1)), ALLTRIM(curClaim.cat_code)+m.prodrate, curClaim.cat_code)
		m.natid = STRTRAN(curClaim.natid, "CIG", "")	
		m.policy_no = curClaim.policy_no
		m.name = curClaim.client_name
		m.client_rel = "self"
		m.paiddate = {}
		m.summitted = IIF(TTOD(curClaim.ref_date) < DATE(YEAR(DATE()), MONTH(DATE()), 1), DATE(YEAR(DATE()), MONTH(DATE()), 1), TTOD(curClaim.ref_date))
		m.eventdate = TTOD(curClaim.admis_date)
		m.hospid = "Others"
		m.hospname = curClaim.prov_name
		m.clmstatus = ICASE(LEFT(curClaim.result,1) = "P", "Payment", LEFT(curClaim.result,1) = "W", "Suspend", LEFT(curClaim.result,1) = "D", "Reject", LEFT(curClaim.result,1) = "C", "Cancel", "")
		m.pay_type = ICASE(curClaim.payment_type = 1, "Cash", curClaim.payment_type = 2, "Check", curClaim.payment_type = 3, "Direct Credit", "Direct Credit")
		*
		DO CASE 
		CASE curClaim.result = "P1"
			m.b_accno = curClaim.tr_acno
			m.b_code = curClaim.bank
			m.b_branch = "0"+LEFT(curClaim.tr_acno,3)
			m.payee = curClaim.tr_name
			m.payee_addr = curClaim.address
			m.payee_post = curClaim.h_postcode
			m.total_amt = curClaim.spaid
		CASE curClaim.result = "P5"
			IF SEEK(curClaim.prov_id, "provider", "prov_id")
				m.b_accno = provider.account_no
				m.b_code = provider.bankcode
				m.b_branch = "0"+LEFT(provider.account_no,3)
				m.payee = provider.acc_name
				m.payee_addr = ALLTRIM(provider.addr_1)+" "+ALLTRIM(provider.addr_2)+" "+ALLTRIM(provider.province)+" "+ALLTRIM(provider.city)
				m.payee_post = provider.postcode
				m.total_amt = curClaim.spaid				
			ENDIF
		ENDCASE
		m.rej_date = IIF(curClaim.result = "D", curClaim.return_date, {})
		m.sus_reason = ""
		m.sup_comp_d = {}
		m.remark  = ALLTRIM(curClaim.note2ins)
		m.plan = curClaim.plan
		m.cat_code = curClaim.cat_code	
		m.claim_amt = curClaim.scharge 
		m.pay_amt = curClaim.spaid 
		m.delay_int = 0
		m.result = curClaim.result
		m.payee_t = ICASE(curClaim.result = "P1", "01", curClaim.result = "P5", "02", "  ")
		*******************************************
		INSERT INTO (lcDbf) FROM MEMVAR 
		********************************************
		lnSeqNo = lnSeqNo + 1
		*******************************
		SELECT curClaim
		SKIP 
	ENDDO 	
ENDDO 
*
SELECT (lcDbf)
GO TOP 
*
DO CovertToText
*
=MESSAGEBOX("Transfer Data Finish")
*
USE IN (lcDbf)
USE IN cig_icd10
USE IN curClaim
*
*********************************************************************************
PROCEDURE CovertToText

#DEFINE CRLF CHR(13)+CHR(10)

*lcPath = ADDBS(JUSTPATH(DBF("uat")))
lcDate = ChangeDateFormat(DATE())
lcTime = ChangeTimeFormat(DATETIME())
STORE 0 TO lnNew, lnP1, lnP5, lnD
*
DO genTypeNew
DO genText
*
=MESSAGEBOX("Claim Upload is:"+CHR(13) +;
		"P1 = "+TRANSFORM(lnP1, "@Z 9,999")+CHR(13)+;
		"P5 = "+TRANSFORM(lnP5, "@Z 9,999")+CHR(13)+;
		"D = "+TRANSFORM(lnD, "@Z 9,999")+CHR(13)+;
		"Total = "+TRANSFORM(lnNew, "@Z 9,999")+CHR(13),0+64,"Infomation")
*USE IN curUat
******************************
*
PROCEDURE genText

lcFileName1 = "CLAIM_PAYMENT_"+TTOC(DATETIME(),1)+".TXT"
lcFileName = ADDBS(lcPath) + lcFileName1
*Start
=STRTOFILE("01" + ReplaceBlank(lcFileName1, 20) + ReplaceBlank(lcDate, 10) +ReplaceBlank(lcTime, 10) + CRLF, lcFileName, 0)
*
STORE 0 TO lnReccount, lnTransation
*
GO TOP 
SCAN
	DO CASE 
	CASE clmstatus = "Payment"
		lcStr1 = "02" + ReplaceBlank(clmstatus, 10) + ReplaceBlank(claim_no, 30) + LEFT(policy_no, 17) + ReplaceBlank(ALLTRIM(LEFT(name,AT(" ",name))), 60)		
		lcStr2 = ReplaceBlank(ALLTRIM(SUBSTR(name,AT(" ",name))),60) + ReplaceBlank(natid, 20) + ReplaceBlank("Self", 60) 
		lcStr3 = ChangeDateFormat(summitted) + ChangeDateFormat(eventdate) + category + class1 + class2 + class3
		lcStr4 = ReplaceBlank(hospid, 32) + ReplaceBlank(hospname, 100) + ReplaceBlank(diagnosis, 60) + ReplaceBlank(remark, 510) + ReplaceBlank(total_amt, 17) + ReplaceBlank(delay_int, 17)
		lcStr5 = SPACE(10) + SPACE(4) + SPACE(2) + SPACE(6) + SPACE(10) + ReplaceBlank("HBC", 200)				
		lcStr026 = ReplaceBlank(diags2, 20) + ReplaceBlank(diags2, 10) + ReplaceBlank(proc1, 10)+ ReplaceBlank(proc2, 10)+ ReplaceBlank(proc3, 10) + CRLF		
		lcStr6 = "03" + ReplaceBlank(prodcode, 16) + ReplaceBlank(covercode, 30) + ReplaceBlank(natid, 30) + ReplaceBlank(claim_amt, 17) + SPACE(23) + ReplaceBlank(total_amt, 17) + CRLF
		lcStr7 = "04" + ReplaceBlank(payee, 60) + ReplaceBlank(natid, 30) + ;
			ReplaceBlank(payee_addr, 200) + ReplaceBlank(payee_post, 10) + ReplaceBlank(pay_type, 15) + ;
			ReplaceBlank(b_code, 40) + ReplaceBlank(b_branch, 200) + ReplaceBlank(total_amt, 17) + ReplaceBlank(b_accno, 15) + ;
			ReplaceBlank(payee_t, 2) + CRLF
		lcStr8 = "08" + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + CRLF
		*
		=STRTOFILE(lcStr1 + lcStr2 + lcStr3 + lcStr4 + lcStr5 + lcStr026 + lcStr6 + lcStr7 + lcStr8, lcFileName, 1)
		* 		
		lnTransation = lnTransation + 4
	OTHERWISE 
		lcStr1 = "02" + ReplaceBlank(clmstatus, 10) + ReplaceBlank(claim_no, 30) + LEFT(policy_no, 17) + ReplaceBlank(ALLTRIM(LEFT(name,AT(" ",name))), 60)		
		lcStr2 = ReplaceBlank(ALLTRIM(SUBSTR(name,AT(" ",name))),60) + ReplaceBlank(natid, 20) + ReplaceBlank("Self", 60) 
		lcStr3 = ChangeDateFormat(summitted) + ChangeDateFormat(eventdate) + category + class1 + class2 + class3
		lcStr4 = ReplaceBlank(hospid, 32) + ReplaceBlank(hospname, 100) + ReplaceBlank(diagnosis, 60) + ReplaceBlank(remark, 510) + ReplaceBlank(total_amt, 17) + ReplaceBlank(delay_int, 17)
		DO CASE 
		CASE clmstatus = "Reject"
			lcStr5 = ChangeDateFormat(rej_date) + LEFT(sus_reason,4) + SPACE(2) + SPACE(6) + SPACE(10) + ReplaceBlank("HBC", 200)		
		CASE clmstatus = "Suspend"
			lcStr5 = SPACE(10) + SPACE(4) + "01" + LEFT(sus_reason,6) + SPACE(10) + ReplaceBlank("HBC", 200)		
		ENDCASE 
		lcStr026 = ReplaceBlank(diags2, 20) + ReplaceBlank(diags2, 10) + ReplaceBlank(proc1, 10)+ ReplaceBlank(proc2, 10)+ ReplaceBlank(proc3, 10) + CRLF
		lcStr6 = "03" + ReplaceBlank(prodcode, 16) + ReplaceBlank(covercode, 30) + ReplaceBlank(natid, 30) + ReplaceBlank(claim_amt, 17) + CRLF
		lcStr8 = "08" + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + ReplaceBlank("0", 20) + CRLF
		=STRTOFILE(lcStr1 + lcStr2 + lcStr3 + lcStr4 + lcStr5 + lcStr026 + lcStr6 + lcStr8 , lcFileName, 1)		
		* 		
		lnTransation = lnTransation + 3
	ENDCASE 
	lnP1 = lnP1 + IIF(result = "P1", 1, 0)
	lnP5 = lnP5 + IIF(result = "P5", 1, 0)
	lnD = lnD + IIF(result = "D", 1, 0)	
ENDSCAN 
=STRTOFILE("09" + ReplaceBlank(lnTransation, 20, 0) + ReplaceBlank(RECCOUNT(), 20, 0), lcFileName, 1)
=MESSAGEBOX("Transfer Claim Payment Data Finish")
***************************************************
PROCEDURE genTypeNew


lcFileName1 = "CLAIM_NEW_"+TTOC(DATETIME(),1)+".TXT"
lcFileName = ADDBS(lcPath) + lcFileName1
=STRTOFILE("01" + ReplaceBlank(lcFileName1, 20) + ReplaceBlank(lcDate, 10) +ReplaceBlank(lcTime, 10) + CRLF, lcFileName, 0)
STORE 0 TO lnReccount, lnTransation

GO TOP 
SCAN
	lcStr1 = "02" + ReplaceBlank("New", 10) + ReplaceBlank(claim_no, 30) + LEFT(policy_no, 17) + ReplaceBlank(ALLTRIM(LEFT(name,AT(" ",name))), 60)		
	lcStr2 = ReplaceBlank(ALLTRIM(SUBSTR(name,AT(" ",name))),60) + ReplaceBlank(natid, 20) + ReplaceBlank("Self", 60) 
	lcStr3 = ChangeDateFormat(summitted) + ChangeDateFormat(eventdate) + category + class1 + class2 + class3
	lcStr4 = ReplaceBlank(hospid, 32) + ReplaceBlank(hospname, 100) + ReplaceBlank(diagnosis, 60) + ReplaceBlank(remark, 510) + ReplaceBlank(total_amt, 17) + ReplaceBlank(delay_int, 17)
	lcStr5 = SPACE(10) + SPACE(4) + SPACE(2) + SPACE(6) + SPACE(10) + ReplaceBlank("HBC", 200)		
	lcStr026 = ReplaceBlank(diags2, 20) + ReplaceBlank(diags2, 10) + ReplaceBlank(proc1, 10)+ ReplaceBlank(proc2, 10)+ ReplaceBlank(proc3, 10) + CRLF
	*
	lcStr6 = "03" + ReplaceBlank(prodcode, 16) + ReplaceBlank(covercode, 30) + ReplaceBlank(natid, 30) + ReplaceBlank(claim_amt, 17) + ;
		ReplaceBlank(" ", 10) + ReplaceBlank(" ", 10) + ReplaceBlank(" ", 3) + CRLF
	lcStr7 = "08" + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + ReplaceBlank("0", 20) + CRLF
	*
	=STRTOFILE(lcStr1 + lcStr2 + lcStr3 + lcStr4 + lcStr5 + lcStr026 + lcStr6 + lcStr7 , lcFileName, 1)
	*		
	lnNew = lnNew + 1
	lnTransation = lnTransation + 3	
ENDSCAN 
=STRTOFILE("09" + ReplaceBlank(lnTransation, 20, 0) + ReplaceBlank(RECCOUNT(), 20, 0), lcFileName, 1)
=MESSAGEBOX("Transfer Claim New Data Finished")
ENDPROC 
********************************************************
FUNCTION ChangeDateFormat(tdDate)
	IF EMPTY(tdDate)
		RETURN SPACE(10)
	ELSE 	
		RETURN  STR(YEAR(tdDate),4)+"-"+STRTRAN(STR(MONTH(tdDate),2), " ", "0")+"-"+STRTRAN(STR(DAY(tdDate),2), " ", "0")
	ENDIF 	
ENDFUNC 
*
FUNCTION ChangeTimeFormat(tdDateTime)
	IF EMPTY(tdDateTime)
		RETURN SPACE(10)
	ELSE 	
		RETURN STRTRAN(STR(HOUR(tdDateTime),2)," ","0")+"-"+STRTRAN(STR(MINUTE(tdDateTime),2)," ","0")+"-"+STRTRAN(STR(SEC(tdDateTime),2)," ","0")
	ENDIF 	
ENDFUNC 
*
FUNCTION ReplaceBlank(tcText, tnSize, tnDecimal)
	IF PARAMETERS() = 2
		tnDecimal = 2
	ENDIF 	
	lcRetValue = SPACE(tnSize)
	DO CASE 
	CASE TYPE("tcText") $ "NYI"	
		lcRetValue = ALLTRIM(STR(tcText, tnSize, tnDecimal))
		lcRetValue = lcRetValue + REPLICATE(" ", tnSize-LEN(lcRetValue))
	CASE TYPE("tcText") = "C"
		lcRetValue = ALLTRIM(tcText)
		IF LEN(lcRetValue) > tnSize
			lcRetValue = LEFT(lcRetValue, tnSize)
		ELSE 			
			lcRetValue = lcRetValue + REPLICATE(" ", tnSize-LEN(lcRetValue))
		ENDIF 	
	ENDCASE 
	RETURN lcRetValue
ENDFUNC 