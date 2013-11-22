PARAMETERS tcClaimID
LOCAL lnArea

lnArea = SELECT()
SELECT 0
CREATE CURSOR faxclm;
	policy_no C(30) NULL, name C(60) NULL,;
	year_visit C(120) NULL, claim_type I NULL, claim_with C(1) NULL,;
	send C(60) NULL, chqno C(10) NULL, chqdate C(30) NULL, total Y NULL,;
	no_opd C(120) NULL, a_opd Y NULL, o_opd Y NULL,  p_opd Y NULL, c_opd Y NULL,;  && Opd
	no_er C(20) NULL, a_er Y NULL, o_er Y NULL, p_er Y NULL, c_er Y NULL,;  && Opd emergecy
	no_mn C(20), a_mn Y, o_mn Y,  p_mn Y, c_mn Y,;  && Minor surgery
	no_r_b N(3), a_r_b Y, o_r_b Y, p_r_b Y, c_r_b Y,;  && ค่าห้อง
	no_icu Y, a_icu Y, o_icu Y, p_icu Y, c_icu Y,;  && ค่าห้อง ไอซียู
	a_ss_sa Y, o_ss_sa Y, p_ss_sa Y, c_ss_sa Y,; && ค่าศัลยกรรม
	a_oper Y, o_oper Y, p_oper Y, c_oper Y,;  && ค่าห้องผ่าตัด
	a_anes Y, o_anes Y, p_anes Y, c_anes Y,; && ค่าวางยาสลบ
	a_ghe Y, o_ghe Y, p_ghe Y, c_ghe Y,;  && ค่ารักษาพยาบาลอื่นๆ
	a_med Y, o_med Y, p_med Y, c_med Y,; && ค่ายา
	a_lab Y, o_lab Y, p_lab Y, c_lab Y,; && ค่าห้องปฎิบัติการ
	no_doct N(3), a_doct_fee Y, o_doct_fee Y, p_doct_fee Y, c_doct_fee Y,; && ค่าหมอทั่วไป
	no_consult Y, a_consult Y, o_consult Y, p_consult Y, c_consult Y,; && ค่าหมอพิเศษ
	a_aet Y, o_aet Y, p_aet Y, c_aet Y,; && อุบัติเหตุ
	a_hb Y, o_hb Y, p_hb Y, c_hb Y,; && ชดเชยรายได้
	a_fw Y, o_fw Y, p_fw Y, c_fw Y,; && FollowUp
	other Y, fundname C(60), mail_addr M)
*************************************
SELECT claim.notify_no, claim.notify_date, claim.claim_no, claim.refno, claim.policy_no, claim.client_name,;
	claim.effective, claim.expried, claim.plan, claim.claim_type, claim.type_claim,claim.plan_id, claim.acc_date,;
	claim.admis_date, claim.disc_date, claim.prov_id, claim.prov_name, prov_class,;
	claim.illness1, claim.result, claim.benf_cover,	claim.fcharge, claim.fbenfpaid, claim.fremain, claim.fnote,;
	claim.ref_date, claim.doc_date, claim.return_date, claim.claim_id, claim.claim_with, claim.note2ins,;
	member.l_addr1, member.l_addr2, member.province, member.city, member.postcode;
FROM cims!claim LEFT JOIN cims!member;
	ON claim.fundcode = member.tpacode AND claim.policy_no = member.policy_no;
WHERE claim.claim_id = tcClaimID;
INTO CURSOR curPvList
IF _TALLY = 0
	=MESSAGEBOX("ไม่พบรายการเคลม รับเข้า วันที่ "+DTOC(ldStart), MB_OK, "Claim Tranfer")
	RETURN
ENDIF

SELECT clmipd
SCATTER MEMVAR MEMO BLANK
****************************
SELECT curPvList
GO TOP
ThisForm.Olecontrol1.Max = RECCOUNT()
DO WHILE !EOF()
	m.policy_no = curPvList.policy_no
	m.name = curPvList.client_name
	m.claim_type = curPvList.claim_type
	m.claim_with = curPvList.claim_with
	m.chqno = ""
	m.chqdate = TLongDate(curPvList.disc_date)
	m.send = "ค่าสินไหมทดแทนที่ได้ชำระให้กัย "+ALLTRIM(curPvlist.prov-name)+"เมื่อ "
	m.total = curPvList.total
	m.mail_addr = curPvList.mail_address
	m.fundname = thisform.cFundName
	m.year_visit = ALLTRIM(m.year_visit)+" "+IIF(EMPTY(m.year_visit), "", ", ")+ALLTRIM(curPvList.year_visit)
	*************************************************
	IF INLIST(curPvList.claim_with, "A", "P")
		ThisForm.Olecontrol1.Value = RECNO()
		SKIP
	ELSE
		DO WHILE curPvList.pv_no = m.pv_no AND !EOF()
			ThisForm.Olecontrol1.Value = RECNO()
			DO CASE
			CASE curPvList.claim_type = 1
				m.no_opd = ALLTRIM(m.no_opd)+IIF(EMPTY(m.no_opd), "", ", ")+ALLTRIM(curPvList.year_visit)
				m.a_opd = m.a_opd + curPvList.scharge
				m.o_opd = m.o_opd + curPvList.benf_cover
				m.p_opd = m.p_opd + curPvList.spaid
				m.c_opd = m.c_opd + curPvList.sremain
			CASE curPvList.claim_type = 3 OR curPvList.claim_type = 6
				m.a_er = m.a_er + curPvList.scharge
				m.o_er = m.o_er + curPvList.benf_cover
				m.p_er = m.p_er + curPvList.spaid
				m.c_er = m.c_er + curPvList.sremain
			CASE curPvList.claim_type = 4
				m.a_mn = m.a_mn + curPvList.scharge
				m.o_mn = m.o_mn + curPvList.benf_cover
				m.p_mn = m.p_mn + curPvList.spaid
				m.c_mn = m.c_mn + curPvList.sremain
			CASE curPvList.claim_type =  2
				lcCatCode = GetCatCode(cat_code)
				DO CASE
				CASE lcCatCode = "RB"
					m.a_r_b = scharge
					m.o_r_b = benf_cover
					m.p_r_b = spaid
					m.c_r_b = sremain
					m.no_r_b = sadmis
				CASE lcCatCode = "ICU"
					m.a_icu = scharge
					m.o_icu = benf_cover
					m.p_icu = spaid
					m.c_icu = sremain
					m.no_icu = sadmis
				CASE lcCatCode = "SGR"
					m.a_oper = scharge
					m.o_oper = benf_cover
					m.p_oper = spaid
					m.c_oper = sremain
				CASE lcCatCode = "ANE"
					m.a_anes = scharge
					m.o_anes = benf_cover
					m.p_anes = spaid
					m.c_anes = sremain
				CASE lcCatCode = "GHS"
					m.a_ghe = scharge
					m.o_ghe = benf_cover
					m.p_ghe = spaid
					m.c_ghe = sremain
				CASE lcCatCode = "PH"
					m.a_med = scharge
					m.o_med = benf_cover
					m.p_med = spaid
					m.c_med = sremain
				CASE lcCatCode = "AS"
				CASE lcCatCode = "SG"
					m.a_ss_sa = scharge
					m.o_ss_sa = benf_cover
					m.p_ss_sa = spaid
					m.c_ss_sa = sremain
				CASE lcCatCode = "LAB"
					m.a_lab = scharge
					m.o_lab = benf_cover
					m.p_lab = spaid
					m.c_lab = sremain
				CASE lcCatCode = "DSS"
					m.a_consult = scharge
					m.o_consult = benf_cover
					m.p_consult = spaid
					m.c_consult = sremain
					m.no_consult = sadmis
				CASE lcCatCode = "DGS"
					m.a_doct_fee = scharge
					m.o_doct_fee = benf_cover
					m.p_doct_fee = spaid
					m.c_doct_fee = sremain
					m.no_doct = sadmis
				ENDCASE
			CASE curPvList.claim_type =  5
				m.a_fw = m.a_fw + curPvList.scharge
				m.o_fw = m.o_fw + curPvList.benf_cover
				m.p_fw = m.p_fw + curPvList.spaid
				m.c_fw = m.c_fw + curPvList.sremain
			CASE curPvList.claim_type =  10 && HB
				m.a_hb = m.a_hb + curPvList.scharge
				m.o_hb = m.o_hb + curPvList.benf_cover
				m.p_hb = m.p_hb + curPvList.spaid
				m.c_hb = m.c_hb + curPvList.sremain
			ENDCASE
			SKIP
		ENDDO
	ENDIF
	SELECT (lcClmHead)
	APPEND BLANK
	GATHER MEMVAR MEMO
	*****************
	SCATTER MEMVAR MEMO BLANK
	SELECT curPvList
ENDDO
IF ThisForm.opgDeviceTo.Value = 2
	SET PRINTER TO NAME GETPRINTER()
ENDIF	
***********************************
SELECT (lcClmHead)
GO TOP
IF RECCOUNT() > 0
	PUBLIC gcPvNo,;
		gcPvTable
	gcPvNo = ""	
	gcPvTable = This.cClmHead
	*IF MESSAGEBOX("ต้องการให้ทำการพิมพ์ ใบสรุปค่าสินไหมทดแทน หรือไม่", MB_ICONQUESTION+MB_YESNO, "PV Print") = IDNO
	*	RETURN
	*ENDIF	
	IF ThisForm.opgDeviceTo.Value = 3
		EXPORT TO (lcClmHead) TYPE XL5
	ELSE
		DO WHILE !EOF()
			gcPvNo = pv_no
			*
			DO progs\pvprint WITH ThisForm.cboFundName.Value, pv_no
			*
			IF INLIST(claim_with, "P", "A")  && PA
				IF ThisForm.opgDeviceTo.Value = 1
					REPORT FORM report\pa_form NOCONSOLE PREVIEW
				ELSE
					REPORT FORM report\pa_form TO PRINTER NOCONSOLE
					REPORT FORM report\pa_form_copy TO PRINTER NOCONSOLE
				ENDIF	
			ELSE	
				IF INLIST(claim_type, 1, 3, 4, 6)  && OPD ER MIN
					IF ThisForm.opgDeviceTo.Value = 1
						REPORT FORM report\opd_form NOCONSOLE PREVIEW
					ELSE
						REPORT FORM report\opd_form TO PRINTER NOCONSOLE
						REPORT FORM report\opd_form_copy TO PRINTER NOCONSOLE
					ENDIF	
				ELSE
					DO CASE
					CASE claim_type = 2 OR claim_type = 5	
						IF ThisForm.opgDeviceTo.Value = 1
							REPORT FORM report\ipd_form  NOCONSOLE PREVIEW
						ELSE
							REPORT FORM report\ipd_form TO PRINTER NOCONSOLE
							REPORT FORM report\ipd_form_copy TO PRINTER NOCONSOLE
						ENDIF	
					CASE claim_type = 10
						IF ThisForm.opgDeviceTo.Value = 1
							REPORT FORM (gcReportPath+"hb_form")  NOCONSOLE PREVIEW
						ELSE
							REPORT FORM (gcReportPath+"hb_form") TO PRINTER NOCONSOLE
							REPORT FORM (gcReportPath+"hb_form_copy") TO PRINTER NOCONSOLE
						ENDIF
					ENDCASE
				ENDIF	
			ENDIF	
			SELECT (lcClmhead)
			DO WHILE  pv_no = gcPvNo AND !EOF()
				SKIP
			ENDDO	
		ENDDO
	ENDIF	
ELSE
	=MESSAGEBOX("ไม่พบ pv ที่ต้องการพิมพ์", MB_OK, TITLE_LOC)	
ENDIF
USE IN (lcClmHead)
ThisForm.cmdRun.Command2.SetFocus


SELECT claim_line
IF SEEK(curClaimList.claim_id,"claim_line", "claim_id")
	IF SEEK(curClaimList.illness1, "icd10", "code")
		lcIllname = icd10.description
	ENDIF	
	**************************
	m.remark = curClaimList.fNote+CRLF+curClaimList.sNote
	DO WHILE claim_id = curClaimList.claim_id AND !EOF()
		lcCatCode = GetCatCode(cat_code)
		DO CASE
		CASE lcCatCode = "RB"
			m.a_r_b = scharge
			m.d_r_b  = sdiscount
			m.o_r_b = benf_cover
			m.p_r_b = spaid
			m.c_r_b = sremain
			m.no_r_b = sadmis
		CASE lcCatCode = "ICU"
			m.a_icu = scharge
			m.d_icu  = sdiscount
			m.o_icu = benf_cover
			m.p_icu = spaid
			m.c_icu = sremain
			m.no_icu = sadmis
		CASE lcCatCode = "SGR"
			m.a_oper = scharge
			m.d_oper = sdiscount
			m.o_oper = benf_cover
			m.p_oper = spaid
			m.c_oper = sremain
		CASE lcCatCode = "ANE"
			m.a_anes = scharge
			m.d_anes  = sdiscount
			m.o_anes = benf_cover
			m.p_anes = spaid
			m.c_anes = sremain
		CASE lcCatCode = "GHS"
			m.a_ghe = scharge
			m.d_ghe  = sdiscount
			m.o_ghe = benf_cover
			m.p_ghe = spaid
			m.c_ghe = sremain
		CASE lcCatCode = "PH"
			m.a_med = scharge
			m.d_med  = sdiscount
			m.o_med = benf_cover
			m.p_med = spaid
			m.c_med = sremain
		CASE lcCatCode = "AS"
		CASE INLIST(lcCatCode, "SG", "MSG")
			m.f_ss_sa = total_fee
			m.a_ss_sa = scharge
			m.d_ss_sa  = sdiscount
			m.o_ss_sa = benf_cover
			m.p_ss_sa = spaid
			m.c_ss_sa = sremain
		CASE lcCatCode = "LAB"
			m.a_lab = scharge
			m.d_lab  = sdiscount
			m.o_lab = benf_cover
			m.p_lab = spaid
			m.c_lab = sremain
		CASE lcCatCode = "DSS"
			m.a_consult = scharge
			m.d_consult  = sdiscount
			m.o_consult = benf_cover
			m.p_consult = spaid
			m.c_consult = sremain
		CASE lcCatCode = "DGS"
			m.a_doct_fee = scharge
			m.d_doct_fee  = sdiscount
			m.o_doct_fee = benf_cover
			m.p_doct_fee = spaid
			m.c_doct_fee = sremain
			m.no_doct = sadmis
		CASE lcCatCode = "ER"
			m.a_aet = scharge
			m.d_aet  = sdiscount
			m.o_aet = benf_cover
			m.p_aet = spaid
			m.c_aet = sremain
		CASE lcCatCode = "OPD"
		CASE lcCatCode = "OTHER"
			m.other = m.other+scharge
		ENDCASE
		m.remark = m.remark+snote+CRLF
		SKIP
	ENDDO
	******************
	SELECT clmipd
	APPEND BLANK
	GATHER MEMVAR MEMO
	***********************************
	REPLACE not_no WITH curClaimList.notify_no,;
	not_date WITH curClaimList.notify_date,;
	bro_no  WITH curClaimList.refno,;
	pol_no WITH curClaimList.policy_no,;
	name WITH LEFT(curClaimList.client_name, AT(" ",curClaimList.client_name)-1),; 
	surname WITH SUBSTR(curClaimList.client_name, AT(" ",curClaimList.client_name)+1),; 
	eff_date WITH curClaimList.effective,;
	exp_date WITH curClaimList.expried,;
	plan WITH curClaimList.plan,;
	type_clm WITH lcTypeClm,;
	acc_date WITH curClaimList.acc_date,;
	admit WITH curClaimList.admis_date,;
	disc WITH curClaimList.disc_date,;
	hosp_amt WITH curClaimList.scharge,;
	benf_paid WITH curClaimList.sbenfpaid,;
	over_benf WITH curClaimList.sremain,;
	hosp_code WITH curClaimList.prov_id,;
	hosp_name WITH curClaimList.prov_name,;
	icd_10 WITH curClaimList.illness1,;
	ill_name WITH lcIllname,;
	clm_type WITH curClaimList.service_type
ENDIF
