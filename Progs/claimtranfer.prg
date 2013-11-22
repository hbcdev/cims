LPARAMETER tcTpaCode, tdStart, tdEnd, tcPath
IF PARAMETER() < 4
	RETURN
ENDIF

INCLUDE include\cims.h
LOCAL lcClmHead,;
	lcPath
PRIVATE pcClmIpd
*********************
lcPath = ADDBS(tcPath)
lnMonthStart = MONTH(tdStart)
lnMonthEnd = MONTH(tdEnd)	
lcClmHead = tcTpaCode+"_Clmhead"+STRTRAN(STR(lnMonthStart,2), " ", "0")+STR(YEAR(tdStart),4)
pcClmIpd = STRTRAN(lcClmHead, "head", "ipd")
**************************************
CREATE DBF (lcPath+lcClmHead) FREE ;
	(not_no C(10), not_date T,;
	bro_no C(10), clm_no C(10),;
	pol_no C(30), app_no C(10),;
	title C(10), name C(30), surname C(30),;
	eff_date T, exp_date T, plan C(10),;
	type_clm I, clm_type I, admit T, disc T,;
	hosp_amt Y, benf_covr Y, benf_paid Y,;
	over_benf Y, hosp_code C(10), hosp_name C(30),;
	ill_code C(10), ill_name C(50), icd_10 C(10),;
	clm_pstat C(8), ret_date D, remark M)
**********************************************
CREATE DBF (lcPath+pcClmIPD) FREE ;
	(not_no C(10), not_date T,;
	bro_no C(10), clm_no C(10),;
	pol_no C(30), app_no C(10),;
	title C(10), name C(30), surname C(30),;
	eff_date T, exp_date T, plan C(10),;
	type_clm I, clm_type I, admit T, disc T,;
	hosp_amt Y, benf_covr Y, benf_paid Y,;
	over_benf Y, hosp_code C(10), hosp_name C(30),;
	ill_code C(10), ill_name C(50), icd_10 C(10),;
	no_r_b N(3), a_r_b Y, o_r_b Y, p_r_b Y, c_r_b Y,;
	a_icu Y, o_icu Y, p_icu Y, c_icu Y,;
	a_ss_sa Y, o_ss_sa Y, p_ss_sa Y, c_ss_sa Y,;
	a_ghe Y, o_ghe Y, p_ghe Y, c_ghe Y,;
	no_doct N(3), a_doct_fee Y, o_doct_fee Y, p_doct_fee Y, c_doct_fee Y,;
	a_consult Y, o_consult Y, p_consult Y, c_consult Y,;
	a_aet Y, o_aet Y, p_aet Y, c_aet Y,;
	a_hb Y, o_hb Y, p_hb Y, c_hb Y,;
	misc Y, remark M)
***********************************
IF !USED(lcClmHead)
	USE (lcPath+lcClmHead) IN 0
ENDIF
*****
IF !USED(pcClmIPD)
	USE (lcPath+pcClmIPD) IN 0
ENDIF
IF !USED("claim_line")
	USE cims!claim_line ORDER claim_id IN 0
ENDIF
******
SELECT claim.notify_no, claim.notify_date, claim.refno, claim.policy_no, claim.client_name,;
	claim.effective, claim.expried, claim.plan, claim.claim_type, claim.type_claim,;
	claim.admis_date, claim.disc_date, claim.prov_id, provider.name AS prov_name,;
	claim.illness1, claim.result, claim.fcharge, claim.fbenfpaid, claim.fremain, claim.fnote,;
	claim.scharge, claim.sbenfpaid, claim.sremain, claim.snote, claim.return_date, claim.claim_id;
FROM cims!claim INNER JOIN cims!provider;
	ON claim.prov_id = provider.prov_id;
WHERE LEFT(claim.customer_id,3) = tcTpacode AND TTOD(claim.notify_date) >= tdStart;
	 AND TTOD(claim.notify_date) >= tdEnd;
ORDER BY claim.notify_date;
INTO CURSOR curClaimList
IF _TALLY = 0
	=MESSAGEBOX("ไม่พบรายการเคลม ในช่วงวันที่ "+DTOC(tdStart)+" ถึง "+DTOC(tdEnd), MB_OK, "Claim Tranfer")
	RETURN
ENDIF
SELECT curClaimList
GO TOP
SCAN
	SELECT (lcClmHead)
	APPEND BLANK
	REPLACE not_no WITH curClaimList.notify_no,;
	not_date WITH curClaimList.notify_date,;
	bro_no  WITH curClaimList.refno,;
	pol_no WITH curClaimList.policy_no,;
	name WITH LEFT(curClaimList.client_name, AT(" ",curClaimList.client_name)-1),; 
	surname WITH SUBSTR(curClaimList.client_name, AT(" ",curClaimList.client_name)+1),; 
	eff_date WITH curClaimList.effective,;
	exp_date WITH curClaimList.expried,;
	plan WITH curClaimList.plan,;
	type_clm WITH curClaimList.type_claim,;
	admit WITH curClaimList.admis_date,;
	disc WITH curClaimList.disc_date,;
	hosp_amt WITH curClaimList.scharge,;
	benf_paid WITH curClaimList.sbenfpaid,;
	over_benf WITH curClaimList.sremain,;
	hosp_code WITH curClaimList.prov_id,;
	hosp_name WITH curClaimList.prov_name,;
	icd_10 WITH curClaimList.illness1,;
	clm_type WITH IIF(curClaimList.claim_type = 1, "OPD", "IPD"),;
	clm_pstat WITH curClaimList.result,;
	ret_date WITH curClaimList.return_date,;
	remark WITH curClaimList.sNote
	**********************************
	IF INLIST(curClaimList.claim_type, 2,3)
		DO TranIPD IN claimtranfer	
	ENDIF 
	SELECT curClaimList
ENDSCAN	
*************************************
PROC TranIPD

SELECT (pcClmIpd)
SCATTER MEMVAR MEMO
*******************
SELECT claim_line
IF SEEK(curClaimList.claim_id)
	DO WHILE claim_id = curClaimList.claim_id AND !EOF()
		DO CASE
		CASE cat_code = "RB05"
			m.a_r_b = scharge
			m.o_r_b = benf_cover
			m.p_r_b = spaid
			m.c_r_b = sremain
			m.no_r_b = sadmis
		CASE cat_code = "ICU05"
			m.a_icu = scharge
			m.o_icu = benf_cover
			m.p_icu = spaid
			m.c_icu = sremain
		CASE cat_code = "GHS05"
			m.a_ghe = scharge
			m.o_ghe = benf_cover
			m.p_ghe = spaid
			m.c_ghe = sremain
		CASE cat_code = "AS05"
		CASE cat_code = "SG05"
			m.a_ss_sa = scharge
			m.o_ss_sa = benf_cover
			m.p_ss_sa = spaid
			m.c_ss_sa = sremain
		CASE cat_code = "DSS05"
			m.a_consult = scharge
			m.o_consult = benf_cover
			m.p_consult = spaid
			m.c_consult = sremain
		CASE cat_code = "DGS05"
			m.a_doct_fee = scharge
			m.o_doct_fee = benf_cover
			m.p_doct_fee = spaid
			m.c_doct_fee = sremain
			m.no_doct_fee = sadmis 
		CASE cat_code = "ER05"
			m.a_aet = scharge
			m.o_aet = benf_cover
			m.p_aet = spaid
			m.c_aet = sremain
		CASE cat_code = "OPD05"
		CASE LEFT(cat_code,4) = "XXXX"
			m.other = m.other+scharge		
		ENDCASE
		m.remark = m.remark+snote+CRLF
		SKIP
	ENDDO
	SELECT (pcClmIpd)
	APPEND BLANK
	GATHER MEMVAR MEMO
	********************
	REPLACE not_no WITH curClaimList.notify_no,;
	not_date WITH curClaimList.notify_date,;
	bro_no  WITH curClaimList.refno,;
	pol_no WITH curClaimList.policy_no,;
	name WITH LEFT(curClaimList.client_name, AT(" ",curClaimList.client_name)-1),; 
	surname WITH SUBSTR(curClaimList.client_name, AT(" ",curClaimList.client_name)+1),; 
	eff_date WITH curClaimList.effective,;
	exp_date WITH curClaimList.expried,;
	plan WITH curClaimList.plan,;
	type_clm WITH curClaimList.type_claim,;
	admit WITH curClaimList.admis_date,;
	disc WITH curClaimList.disc_date,;
	hosp_amt WITH curClaimList.scharge,;
	benf_paid WITH curClaimList.sbenfpaid,;
	over_benf WITH curClaimList.sremain,;
	hosp_code WITH curClaimList.prov_id,;
	hosp_name WITH curClaimList.prov_name,;
	icd_10 WITH curClaimList.illness1,;
	clm_type WITH IIF(curClaimList.claim_type = 1, "OPD", "IPD")
ENDIF