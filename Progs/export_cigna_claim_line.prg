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
USE (ADDBS(datapath)+"cig_icd10") IN 0 ALIAS cig_icd10
*
SELECT claim.fundcode, claim.notify_no, claim.ref_date, claim.policy_no, claim.customer_id AS natid, claim.plan, claim.client_name, claim.return_date, ;
	claim.cause_type, claim.admis_date, claim.prov_id, claim.prov_name, claim.illness1, claim.result, ;
	claim.payment_type, claim.tr_acno, claim.tr_name, claim.bank, claim.tr_banch, claim.note2ins, ;
	SUBSTR(claim_line.cat_code, 3, 2) AS catType, claim_line.cat_code, claim_line.description AS cat_desc, ;
	claim_line.scharge-claim_line.sdiscount AS scharge, claim_line.spaid ;
FROM cims!claim INNER JOIN cims!claim_line ;
	ON claim.notify_no = claim_line.notify_no ;
WHERE claim.fundcode = gcFundCode ;
	AND claim.return_date Between gdStartDate AND gdEndDate ;
	AND INLIST(SUBSTR(claim_line.cat_code, 3, 2), "SF", "ET", "AC", "RC", "WR", "SL") ;
	AND claim_line.scharge # 0 ;
ORDER BY claim.result, claim.notify_no ;
INTO CURSOR curClaim
*
IF _TALLY = 0
	RETURN 
ENDIF 
CREATE DBF (ADDBS(lcPath)+lcDbf) FREE (claim_no C(30), policy_no C(30), prodcode C(16), covercode C(30), name C(60), natid C(20), client_rel C(60), ;
	paiddate D, claim_amt Y, pay_amt Y, delay_int Y, total_amt Y, summitted D, eventdate D, category C(16), class1 C(40), class2 C(68), class3 C(57), ;
	hospID C(13), hospname C(60), diagnosis C(60), clmstatus C(10), pay_type C(15), b_accno C(10), b_code C(3), b_branch C(20), payee C(60), ;
	rej_date D, sus_reason C(100), sup_comp_d D, remark C(200), result C(3))
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
		ELSE 
			m.category = "Dental"
			m.class1 = curClaim.cat_desc
			m.class2 = curClaim.cat_code
			m.class3 = ""
		ENDIF 		
		*
		lcIcd10 = IIF(LEN(ALLTRIM(curClaim.illness1)) > 3, STUFF(ALLTRIM(curClaim.illness1), 4, 0, "."), ALLTRIM(curClaim.illness1))
		IF SEEK(lcIcd10, "cig_icd10", "code")
			m.diagnosis = cig_icd10.nameeng
		ELSE 
			m.diagnosis = curClaim.illness1		
		ENDIF 
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
		m.clmstatus = "New"
		*m.clmstatus = IIF(INLIST(LEFT(curClaim.result,2), "W5", "W6"), "New", ICASE(LEFT(curClaim.result,1) = "P", "Payment", LEFT(curClaim.result,1) = "W", "Suspend", LEFT(curClaim.result,1) = "D", "Reject", LEFT(curClaim.result,1) = "C", "Cancel", ""))
		m.pay_type = ICASE(curClaim.payment_type = 1, "Cash", curClaim.payment_type = 2, "Check", curClaim.payment_type = 3, "Direct Credit", "")
		m.b_accno = curClaim.tr_acno
		m.b_code = curClaim.bank
		m.b_branch = curClaim.tr_banch
		m.payee = curClaim.tr_name
		m.rej_date = curClaim.return_date
		m.sus_reason = ""
		m.sup_comp_d = {}
		m.remark  = ALLTRIM(curClaim.note2ins)
		m.plan = curClaim.plan
		m.cat_code = curClaim.cat_code	
		m.claim_amt = curClaim.scharge 
		m.pay_amt = curClaim.spaid 
		m.delay_int = 0
		m.total_amt = IIF(m.clmstatus = "Payment", curClaim.benf_paid, 0)
		m.result = curClaim.result
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

SET SAFETY OFF 
SET DELETED ON 
*
SELECT result, COUNT(*) FROM (lcDbf) GROUP BY 1 INTO CURSOR curUat
*
SELECT curUat
SCAN 
	DO genText WITH curUat.result
ENDSCAN
*USE IN curUat
******************************
*
PROCEDURE genText

PARAMETERS tcResult

IF EMPTY(tcResult)
	RETURN 
ENDIF 	

SELECT (lcDbf)
tcResult = ALLTRIM(IIF(INLIST(LEFT(tcResult, 1), "D", "R"), LEFT(tcResult,1), tcResult))

lcPath = ADDBS(JUSTPATH(DBF(lcDbf)))
lcFileName = STRTRAN(JUSTFNAME(DBF(lcDbf)), "_", "")
lcNewFile = lcPath+STRTRAN(STRTRAN(STRTRAN(JUSTFNAME(DBF(lcDbf)), "_", ""), "RETURN",tcResult), "DBF", "TXT")
lcFileName = ReplaceBlank(JUSTFNAME(lcNewFile), 20)
lcPayFileName = "hbcpaymentclaim.txt"
lcPayFileName = ReplaceBlank(lcPayFileName, 20)

lcDate = ChangeDateFormat(DATE())
lcTime = ChangeTimeFormat(DATETIME())

*Start
=STRTOFILE("01" + ReplaceBlank(lcFileName, 20) + ReplaceBlank(lcdate, 10) +ReplaceBlank(lctime, 10) + CRLF, lcNewFile, 0)
*
=STRTOFILE("01" + ReplaceBlank(lcPayFileName, 20) + ReplaceBlank(lcdate, 10) +ReplaceBlank(lctime, 10) + CRLF, lcPayFileName, 0)
*
STORE 0 TO lnReccount, lnTransation, lnPayRecCount, lnPayTransation
*
SELECT (lcDbf)
SCAN FOR result = tcResult
	IF clmstatus <> "New"
		***********************************
		lcStr1 = "02" + ReplaceBlank(clmstatus, 10) + ReplaceBlank(claim_no, 30) + LEFT(policy_no, 17) + ReplaceBlank(ALLTRIM(LEFT(name,AT(" ",name))), 60)		
		lcStr2 = ReplaceBlank(ALLTRIM(SUBSTR(name,AT(" ",name))),60) + ReplaceBlank(natid, 20) + ReplaceBlank("Self", 60) 
		lcStr3 = ChangeDateFormat(summitted) + ChangeDateFormat(eventdate) + category + class1 + class2 + class3
		lcStr4 = ReplaceBlank(hospid, 32) + ReplaceBlank(hospname, 100) + ReplaceBlank(diagnosis, 60) + ReplaceBlank(remark, 20) + SPACE(17) + ReplaceBlank(delay_int, 17)
		*
		DO CASE 
		CASE clmstatus = "Reject"
			lcStr5 = ChangeDateFormat(rej_date) + LEFT(sus_reason,4) + SPACE(2) + SPACE(6) + SPACE(10) + ReplaceBlank("HBC", 200)		
		CASE clmstatus = "Suspend"
			lcStr5 = SPACE(10) + SPACE(4) + "01" + LEFT(sus_reason,6) + SPACE(10) + ReplaceBlank("HBC", 200)		
		CASE clmstatus = "Payment"
			lcStr5 = SPACE(10) + SPACE(4) + SPACE(2) + SPACE(6) + SPACE(10) + ReplaceBlank("HBC", 200)		
		ENDCASE 
		*
		=STRTOFILE(lcStr1 + lcStr2 + lcStr3 + lcStr4 + lcStr5 + CRLF, lcPayFileName, 1)
		*		
		lcStr6 = "03" + ReplaceBlank(prodcode, 16) + ReplaceBlank(covercode, 30) + ReplaceBlank(natid, 30) + ReplaceBlank(claim_amt, 17) + CRLF
		*
		IF clmstatus = "Payment"
			lcStr7 = "04" + ReplaceBlank(payee, 60) + ReplaceBlank(natid, 30) + SPACE(200) + SPACE(10) + ReplaceBlank(pay_type, 15) + ;
				ReplaceBlank(b_code, 40) + ReplaceBlank(b_branch, 200) + ReplaceBlank(total_amt, 17) + ReplaceBlank(b_accno, 15) + CRLF
			lcStr8 = "08" + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + CRLF
			=STRTOFILE(lcStr6 + lcStr7 + lcStr8, lcPayFileName, 1)		
		ELSE 
			lcStr8 = "08" + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + ReplaceBlank("0", 20) + CRLF				
			=STRTOFILE(lcStr6 + lcStr8, lcPayFileName, 1)			
		ENDIF
		* 		
		lnPayTransation = lnPayTransation + 1
		lnPayRecCount = lnPayRecCount + 1	
	ELSE 
		lcStr1 = "02" + ReplaceBlank(clmstatus, 10) + ReplaceBlank(claim_no, 30) + LEFT(policy_no, 17) + ReplaceBlank(ALLTRIM(LEFT(name,AT(" ",name))), 60)		
		lcStr2 = ReplaceBlank(ALLTRIM(SUBSTR(name, AT(" ",name))),60) + ReplaceBlank(natid, 20) + ReplaceBlank("Self", 60) 
		lcStr3 = ChangeDateFormat(summitted) + ChangeDateFormat(eventdate) + category + class1 + class2 + class3
		lcStr4 = ReplaceBlank(hospid, 32) + ReplaceBlank(hospname, 100) + ReplaceBlank(diagnosis, 60) + ReplaceBlank(remark, 20) + ReplaceBlank(total_amt, 17) + ReplaceBlank(delay_int, 17)
		lcStr5 = ChangeDateFormat(rej_date) + SPACE(4) + SPACE(2) + LEFT(sus_reason,6) + ChangeDateFormat(sup_comp_d) + ReplaceBlank("HBC", 200)
		*
		=STRTOFILE(lcStr1 + lcStr2 + lcStr3 + lcStr4 + lcStr5 + CRLF, lcNewFile, 1)
		*		
		lcStr6 = "03" + ReplaceBlank(prodcode, 16) + ReplaceBlank(covercode, 30) + ReplaceBlank(natid, 30) + ReplaceBlank(claim_amt, 17) + CRLF
		lcStr7 = "08" + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + ReplaceBlank("0", 20) + CRLF
		*
		=STRTOFILE(lcStr6 + lcStr7, lcNewFile, 1)
		*		
		lnTransation = lnTransation + 1
		lnReccount = lnReccount + 1
	ENDIF 
ENDSCAN 
lnReccount = (lnReccount * 3) + 2
=STRTOFILE("09" + ReplaceBlank(lnReccount, 20, 0) + ReplaceBlank(lnTransation, 20, 0), lcNewFile, 1)
*
lnPayReccount = (lnPayReccount * 3) + 2
=STRTOFILE("09" + ReplaceBlank(lnPayReccount, 20, 0) + ReplaceBlank(lnPayTransation, 20, 0), lcPayFileName, 1)
=MESSAGEBOX("Transfer Result <"+tcResult+">Data Finish")
*****************************************************************
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
******************************************************************
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
***************************************************************