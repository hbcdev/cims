PARAMETERS gcFundCode, gdStartDate, gdEndDate

CLEAR 
CLOSE ALL
*SET PROCEDURE TO progs\utility
*
USE cims!item IN 0
USE cims!policy2items IN 0 ALIAS CO
USE cims!member IN 0 ALIAS EL
USE d:\hips\data\cig_icd10 IN 0 ALIAS icd10
*
SELECT claim.fundcode, claim.notify_no, claim.ref_date, claim.policy_no, claim.customer_id AS natid, claim.plan, claim.client_name, claim.return_date, ;
	claim.cause_type, claim.admis_date, claim.prov_id, claim.prov_name, claim.illness1, claim.result, ;
	claim.payment_type, claim.tr_acno, claim.tr_name, claim.bank, claim.tr_banch, claim.note2ins, ;
	claim_line.cat_code, claim_line.description AS cat_desc, claim_line.scharge, claim_line.spaid, ;
	claim_items.item_code, claim_items.std_desc, claim_items.charge, claim_items.benf_paid ;
FROM cims!claim INNER JOIN cims!claim_line ;
	ON claim.notify_no = claim_line.notify_no ;
	INNER JOIN cims!claim_items ;	
	ON claim_line.notify_no = claim_items.notify_no ;
		AND claim_line.cat_id = claim_items.cat_id ;
WHERE claim.fundcode = gcFundCode ;
	AND claim.return_date Between gdStartDate AND gdEndDate ;
	AND claim.result = "P5" ;
	AND claim_line.scharge # 0 ;
	AND claim_items.charge # 0 ;
	AND claim_items.item_code IN ("SL", "FL", "FT", "WR", "RC", "ET") ;
ORDER BY claim.notify_no ;	
INTO CURSOR curClaim
*
IF _TALLY = 0
	RETURN 
ENDIF 
lcDbf = "hbc_claim_return_"+DTOS(gdStartDate)
CREATE DBF ("D:\report\cig\"+lcDbf) FREE (claim_no C(30), policy_no C(30), prodcode C(16), covercode C(30), name C(60), natid C(20), client_rel C(60), ;
	paiddate D, claim_amt Y, pay_amt Y, delay_int Y, total_amt Y, summitted D, eventdate D, category C(16), class1 C(40), class2 C(68), class3 C(57), ;
	hospID C(13), hospname C(60), diagnosis C(60), clmstatus C(10), pay_type C(15), b_accno C(10), b_code C(3), b_branch C(20), payee C(60), ;
	rej_date D, sus_reason C(100), sup_comp_d D, remark C(200))
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
		IF SEEK(curClaim.item_code, "item", "item_grp")
			m.category = item.category
			m.class1 = item.class1
			m.class2 = item.class2
			m.class3 = item.class3
		ELSE 
			m.category = "Dental"
			m.class1 = curClaim.cat_desc
			m.class2 = curClaim.item_code
			m.class3 = curClaim.std_desc
		ENDIF 		
		*
		IF SEEK(curClaim.illness1, "icd10", "code")
			m.diagnosis = icd10.nameeng
		ELSE 
			m.diagnosis = curClaim.illness1		
		ENDIF 	
		*
		m.covercode = curClaim.cat_code
		m.natid = STRTRAN(curClaim.natid, "CIG", "")	
		m.policy_no = curClaim.policy_no
		m.name = curClaim.client_name
		m.client_rel = "self"
		m.paiddate = {}
		m.summitted = TTOD(curClaim.ref_date)
		m.eventdate = TTOD(curClaim.admis_date)
		m.hospid = "Others"
		m.hospname = curClaim.prov_name
		m.clmstatus = "New"
		*m.clmstatus = IIF(INLIST(LEFT(curClaim.result,2), "W5", "W6"), "New", ICASE(LEFT(curClaim.result,1) = "P", "Payment", LEFT(curClaim.result,1) = "W", "Suspend", LEFT(curClaim.result,1) = "D", "Reject", LEFT(curClaim.result,1) = "C", "Cancel", ""))
		m.pay_type = ICASE(curClaim.payment_type = 1, "Cash", curClaim.payment_type = 2, "Cheque", curClaim.payment_type = 3, "Direct Credit", iif(curClaimList.fundcode = "CIG", "Direct Credit",""))
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
		m.claim_amt = curClaim.charge 
		m.pay_amt = curClaim.benf_paid 
		m.delay_int = 0
		m.total_amt = IIF(m.clmstatus = "Payment", curClaim.benf_paid, 0)
		*******************************************
		INSERT INTO (lcDbf) FROM MEMVAR 
		********************************************
		lnSeqNo = lnSeqNo + 1
		*******************************
		SELECT curClaim
		SKIP 
	ENDDO 	
ENDDO 
