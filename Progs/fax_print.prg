PARAMETERS tcClaimID, tnPrintTo
#INCLUDE "include\cims.h"
IF PARAMETERS()= 0
	RETURN
ENDIF
***********************
DO Query_claim IN fax_print
IF USED("curPvList")
	IF RECCOUNT("curPvList") = 0
		RETURN
	ENDIF
ELSE
	RETURN 		
ENDIF
***********************
DO Create_Cursor IN fax_print
IF !USED("faxprint")
	=MESSAGEBOX("ไม่สามารถสร้างแฟ้มข้อมูล กรุณาตรวจสอบกับผู้ดูแลระบบก่อน", MB_OK, "คำเตือน")
	RETURN
ENDIF	
DO Transfer IN fax_print
********************************
SELECT faxprint
GO TOP
IF RECCOUNT() > 0
	IF tnPrintTo= 3
		RETURN 
	ELSE
		gcPvTable = "faxprint"
		SELECT faxprint
		IF INLIST(claim_with, "P", "A")  && PA
			IF tnPrintTo= 1
				REPORT FORM (gcReportPath+"pa") NOCONSOLE PREVIEW
			ELSE
				REPORT FORM (gcReportPath+"pa") TO PRINTER NOCONSOLE
				REPORT FORM (gcReportPath+"pa_copy") TO PRINTER NOCONSOLE
			ENDIF	
		ELSE	
			IF INLIST(claim_type, 1, 3, 4, 6)  && OPD ER MIN
				IF tnPrintTo= 1
					REPORT FORM (gcReportPath+"opd") NOCONSOLE PREVIEW
				ELSE
					REPORT FORM (gcReportPath+"opd") TO PRINTER NOCONSOLE
					REPORT FORM (gcReportPath+"opd_copy") TO PRINTER NOCONSOLE
				ENDIF	
			ELSE
				DO CASE
				CASE claim_type = 2 OR claim_type = 5	
					IF tnPrintTo= 1
						REPORT FORM (gcReportPath+"ipd")  NOCONSOLE PREVIEW
					ELSE
						REPORT FORM (gcReportPath+"ipd")TO PRINTER NOCONSOLE
						REPORT FORM (gcReportPath+"ipd_copy") TO PRINTER NOCONSOLE
					ENDIF	
				CASE claim_type = 10
					IF tnPrintTo= 1
						REPORT FORM (gcReportPath+"hb")  NOCONSOLE PREVIEW
					ELSE
						REPORT FORM (gcReportPath+"hb") TO PRINTER NOCONSOLE
						REPORT FORM (gcReportPath+"hb_copy") TO PRINTER NOCONSOLE
					ENDIF
				ENDCASE
			ENDIF	
		ENDIF	
	ENDIF	
ELSE
	=MESSAGEBOX("ไม่มี faxclaim ที่ต้องการพิมพ์", MB_OK, TITLE_LOC)	
ENDIF
USE IN faxprint

****************************
PROCEDURE transfer
****************************
SELECT faxprint
SCATTER MEMVAR MEMO BLANK
**********************
SELECT curPvList
m.pv_no = curPvList.notify_no
m.pv_date = TLongDate(curPvList.disc_date)
m.policy_no = curPvList.policy_no
m.name = curPvList.client_name
m.claim_type = curPvList.claim_type
m.claim_with = curPvList.claim_with
m.send = ALLTRIM(curPvList.prov_name)
m.chqno = "HN No "+ALLTRIM(curPvList.hn_no)+" AN No "+ALLTRIM(curpvList.an_no)
m.chqdate = "เข้ารักษาเมื่อ "+TLongDate(curPvList.admis_date)+" ถึง "+TLongDate(curPvList.disc_date)
m.total = curPvList.fbenfpaid
m.mail_addr = ""
IF USED("member")
	IF SEEK(curPvList.fundcode+curPvList.policy_no, "member", "policy_no")
		m.mail_addr = member.mail_address
	ENDIF
ENDIF
*********************
DO WHILE  !EOF()
	DO CASE
	CASE curPvList.claim_type = 1
		m.no_opd = ALLTRIM(m.no_opd)+IIF(EMPTY(m.no_opd), "", ", ")+ALLTRIM(curPvList.year_visit)
		m.a_opd = m.a_opd + curPvList.fcharge
		m.o_opd = m.o_opd + curPvList.benf_cover
		m.p_opd = m.p_opd + curPvList.fpaid
		m.c_opd = m.c_opd + curPvList.fremain+curPvList.nopaid
	CASE curPvList.claim_type = 3 OR curPvList.claim_type = 6
		m.a_er = m.a_er + curPvList.fcharge
		m.o_er = m.o_er + curPvList.benf_cover
		m.p_er = m.p_er + curPvList.fpaid
		m.c_er = m.c_er + curPvList.fremain+curPvList.nopaid
	CASE curPvList.claim_type = 4
		m.a_mn = m.a_mn + curPvList.fcharge
		m.o_mn = m.o_mn + curPvList.benf_cover
		m.p_mn = m.p_mn + curPvList.fpaid
		m.c_mn = m.c_mn + curPvList.fremain+curPvList.nopaid
	CASE curPvList.claim_type =  2
		lcCatCode = GetCatCode(curPvList.cat_code)
		DO CASE
		CASE lcCatCode = "RB"
			m.a_r_b = curPvList.fcharge
			m.o_r_b = curPvList.benf_cover
			m.p_r_b = curPvList.fpaid
			m.c_r_b = curPvList.fremain+curPvList.nopaid
			m.no_r_b = curPvList.fadmis
		CASE lcCatCode = "ICU"
			m.a_icu = curPvList.fcharge
			m.o_icu = curPvList.benf_cover
			m.p_icu = curPvList.fpaid
			m.c_icu = curPvList.fremain+curPvList.nopaid
			m.no_icu = curPvList.fadmis
		CASE lcCatCode = "SGR"
			m.a_oper = curPvList.fcharge
			m.o_oper = curPvList.benf_cover
			m.p_oper = curPvList.fpaid
			m.c_oper = curPvList.fremain+curPvList.nopaid
		CASE lcCatCode = "ANE"
			m.a_anes = curPvList.fcharge
			m.o_anes = curPvList.benf_cover
			m.p_anes = curPvList.fpaid
			m.c_anes = curPvList.fremain+curPvList.nopaid
		CASE lcCatCode = "GHS"
			m.a_ghe = curPvList.fcharge
			m.o_ghe = curPvList.benf_cover
			m.p_ghe = curPvList.fpaid
			m.c_ghe = curPvList.fremain+curPvList.nopaid
		CASE lcCatCode = "PH"
			m.a_med = curPvList.fcharge
			m.o_med = curPvList.benf_cover
			m.p_med = curPvList.fpaid
			m.c_med = curPvList.fremain+curPvList.nopaid
		CASE lcCatCode = "AS"
		CASE lcCatCode = "SG"
			m.a_ss_sa = fcharge
			m.o_ss_sa = benf_cover
			m.p_ss_sa = fpaid
			m.c_ss_sa = fremain+curPvList.nopaid
		CASE lcCatCode = "LAB"
			m.a_lab = curPvList.fcharge
			m.o_lab = curPvList.benf_cover
			m.p_lab = curPvList.fpaid
			m.c_lab = curPvList.fremain+curPvList.nopaid
		CASE lcCatCode = "DSS"
			m.a_consult = curPvList.fcharge
			m.o_consult = curPvList.benf_cover
			m.p_consult = curPvList.fpaid
			m.c_consult = curPvList.fremain+curPvList.nopaid
			m.no_consult = curPvList.fadmis
		CASE lcCatCode = "DGS"
			m.a_doct_fee = curPvList.fcharge
			m.o_doct_fee = curPvList.benf_cover
			m.p_doct_fee = curPvList.fpaid
			m.c_doct_fee = curPvList.fremain+curPvList.nopaid
			m.no_doct = curPvList.fadmis
		ENDCASE
	CASE curPvList.claim_type =  5
		m.a_fw = m.a_fw + curPvList.fcharge
		m.o_fw = m.o_fw + curPvList.benf_cover
		m.p_fw = m.p_fw + curPvList.fpaid
		m.c_fw = m.c_fw + curPvList.fremain+curPvList.nopaid
	CASE curPvList.claim_type =  10 && HB
		m.a_hb = m.a_hb + curPvList.fcharge
		m.o_hb = m.o_hb + curPvList.benf_cover
		m.p_hb = m.p_hb + curPvList.fpaid
		m.c_hb = m.c_hb + curPvList.fremain+curPvList.nopaid
	ENDCASE
	m.nocover = m.nocover+CRLF+ALLTRIM(curPvList.fnote)
	SELECT curPvList
	SKIP
ENDDO
SELECT faxprint
APPEND BLANK
GATHER MEMVAR MEMO
*******************************************
PROCEDURE query_claim
SELECT Claim.notify_no, Claim.claim_id, Claim.claim_type, Claim.claim_with, Claim.fundcode,;
 Claim.policy_no, Claim.client_name, Claim.plan, Claim.effective, Claim.expried, Claim.fax_by,;
 Claim.prov_name, Claim.an_no, Claim.hn_no, Claim.admis_date, Claim.disc_date, Claim.fbenfpaid,;
 Claim_line.cat_code, Claim_line.description, Claim_line.service_type, ;
 Claim_line.serv_cover, Claim_line.benf_cover,;
 Claim_line.fadmis, Claim_line.fcharge, Claim_line.fdiscount, Claim_line.fnote,;
 Claim_line.fpaid, Claim_line.fremain, Claim_line.exgratia, Claim_line.nopaid;
 FROM  cims!Claim LEFT JOIN cims!claim_line ;
   ON  Claim.notify_no = Claim_line.notify_no;
 WHERE Claim.notify_no = tcclaimID;
INTO CURSOR curPvList
SET TALK OFF
***************************

PROCEDURE Create_Cursor
CREATE CURSOR faxprint ;
	(pv_no C(10) NULL, pv_date C(30) NULL, policy_no C(30) NULL, name C(120) NULL,;
	claim_type I NULL, claim_with C(1) NULL,;
	send C(60) NULL, chqno C(10) NULL, chqdate C(30) NULL, total Y NULL, notify_no C(10) NULL,;
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
	other Y, nocover M, fundname C(60), mail_addr M)
	