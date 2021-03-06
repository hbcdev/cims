PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption
	
SET SAFETY OFF 	
SET PROCEDURE TO progs\utility
********************
gcStartDate = "Start Date"
gcEndDate = "End Date"
glMonth = .F.	
gcFundCode = "SSL"
gdEndDate = DATE() - DAY(DATE())
gdStartDate = gdEndDate - IIF(MOD(YEAR(gdEndDate),4) = 0, 366, 365)+1
gnOption = 1
gnType = 1
gnRolling = 12
gcSaveTo = gcTemp
DO FORM form\Rollingentry
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
gdCurDate = DATE(YEAR(gdEndDate), MONTH(gdEndDate), 1)
gtCurDate = DATETIME(YEAR(gdEndDate), MONTH(gdEndDate), 1, 00, 00)
gtStartDate = DATETIME(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate), 00, 00)
gtEndDate = DATETIME(YEAR(gdEndDate), MONTH(gdEndDate), DAY(gdEndDate), 00, 00)
gcSaveTo = IIF(EMPTY(gcSaveTo), gcTemp, gcSaveTo)

IF !DIRECTORY(gcSaveTo)
	MKDIR (gcSaveTo)
ENDIF 	
***********************
lcOldDir = SYS(5)+SYS(2003)
SET DEFAULT TO (gcSaveTo)
SET TALK ON 
SET TALK WINDOW 
****************
DO q_Member
DO q_Claim
DO q_PlanbyService_Year
DO q_PlanbyService_Month
DO q_PlanbyCategory_Month
DO q_rolling
****************
SET TALK OFF 
SET DEFAULT TO (lcOldDir)
**************************************************************
PROCEDURE q_Member
*
SELECT Member.tpacode, Member.policy_no, Member.product AS plan, ;
	LEFT(Member.product,2) AS plan_type, VAL(cause1) AS prem_i, VAL(cause2) AS prem_o, ;	
	Member.hb_limit, Member.effective, Member.expiry, Member.premium, Member.premium/365.25 AS prem_day ;
 FROM cims!Member ;
 WHERE Member.tpacode = gcFundCode ;
   AND Member.expiry >= gtStartDate ;
   AND INLIST(customer_type, "I", "D", "H") ;
 INTO CURSOR Q_member
*
IF RECCOUNT("Q_Member") = 0
	RETURN 
ENDIF 
*	
SELECT tpacode, policy_no, plan, plan_type, hb_limit, effective, expiry, premium, prem_day, ;
	IIF(prem_i = 0, premium, prem_i) AS prem_i, prem_o, ;
	IIF(effective >= gtCurDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtCurDate AND expiry >= gtCurDate, TTOD(gtCurDate), {})) AS start_month, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry >= gtCurDate AND expiry <= gtEndDate, TTOD(expiry), {})) AS end_month, ;
	IIF(effective >= gtStartDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtStartDate AND expiry >= gtStartDate, gdStartDate, {})) AS start_roll, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry <= gtEndDate, TTOD(expiry), {})) AS end_roll ;
 FROM Q_member ;
INTO CURSOR Q_memb
*
SELECT tpacode, policy_no, plan, plan_type, hb_limit, effective, expiry, premium, prem_day, prem_i, prem_o, ;
	start_month, end_month, IIF(EMPTY(start_month), 000, 1) AS m_nominal, ;
	IIF(EMPTY(start_month), 000, (end_month-start_month)+1) AS m_days, ;
	IIF(EMPTY(start_month), 0000000.0000, ((end_month-start_month)+1)/((gdEndDate - gdCurDate)+1)) AS eqa_month, ;
	IIF(EMPTY(start_month), 0000000.0000, ((end_month-start_month)+1)*prem_day) AS ep_month, ;	
	IIF(EMPTY(start_month), 0000000.0000, ((end_month-start_month)+1)*(prem_i/365.25)) AS iep_month, ;
	IIF(EMPTY(start_month), 0000000.0000, ((end_month-start_month)+1)*(prem_o/365.25)) AS oep_month, ;				
	start_roll, end_roll, IIF(EMPTY(start_roll), 000, 1) AS y_nominal, ;
	IIF(EMPTY(start_roll), 000, (end_roll-start_roll)+1) AS y_days, ;	
	IIF(EMPTY(start_roll), 0000000.0000, ((end_roll-start_roll)+1)/((gdEndDate - gdStartDate)+1)) AS eqa_year, ;
	IIF(EMPTY(start_roll), 0000000.0000, ((end_roll-start_roll)+1)*prem_day) AS ep_year, ;
	IIF(EMPTY(start_roll), 0000000.0000, ((end_roll-start_roll)+1)*(prem_i/365.25)) AS iep_year, ;
	IIF(EMPTY(start_roll), 0000000.0000, ((end_roll-start_roll)+1)*(prem_o/365.25)) AS oep_year ;	
FROM Q_memb ;	
INTO TABLE (gcFundCode+"_HC_member")	
*
SELECT plan, ;
	SUM(m_nominal) AS nom_month, SUM(eqa_month) AS eqa_month, SUM(ep_month) AS ep_month, ;
	SUM(y_nominal) AS nom_year, SUM(eqa_year) AS eqa_year, SUM(ep_year) AS ep_year, ;
	SUM(iep_month) AS iep_month, SUM(oep_month) AS oep_month, SUM(iep_year) AS iep_year, SUM(oep_year) AS oep_year ; 
FROM (gcFundcode+"_HC_member") ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR _SumMember
*
*********************************************************
*
PROCEDURE q_Claim
*
SELECT Claim.notify_no, Claim.notify_date, IIF(Claim.service_type = "OPD", "OPD", "IPD") AS serv_type, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, Claim.client_name, Claim.plan, LEFT(Claim.plan,2) AS plan_type, ;
	Claim.admis_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, ;
	IIF(EMPTY(Claim.fax_by), Claim.abenfpaid, Claim.exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid, Claim.fbenfpaid) AS paid, ;
	LEFT(result,1) AS status, Claim.result, Claim.return_date, Claim.unclean, Claim.unclean_note, ;
	RIGHT(STR(YEAR(admis_date),4),2)+ "-"+STRTRAN(STR(MONTH(admis_date),2)," ","0") AS admis_m, ;  
	RIGHT(STR(YEAR(notify_date),4),2)+ "-"+STRTRAN(STR(MONTH(notify_date),2)," ","0") AS notify_m, ;  		
	((return_date-TTOD(notify_date)) - holidays(TTOD(notify_date), return_date)) AS workdays ;	
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND INLIST(Claim.claim_with, "I", "T", "H") ;
	AND Claim.result # "C" ;	
	AND Claim.admis_date BETWEEN gtStartDate AND gtEndDate ;	
INTO TABLE (gcFundCode+"_HC_Claim")
**
*Query Current Month Report
*
SELECT Claim.notify_no, Claim.notify_date, IIF(Claim.service_type = "OPD", "OPD", "IPD") AS serv_type, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, Claim.client_name, Claim.plan, LEFT(Claim.plan,2) AS plan_type, ;
	Claim.admis_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, Claim.fax_by, ;
	IIF(EMPTY(Claim.fax_by), Claim.abenfpaid, Claim.exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid, Claim.fbenfpaid) AS paid, ;
	LEFT(result,1) AS status, Claim.result, Claim.return_date, Claim.unclean, Claim.unclean_note, ;
	((return_date-TTOD(notify_date)) - holidays(TTOD(notify_date), return_date)) AS workdays ;	
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND INLIST(Claim.claim_with, "I", "T", "H") ;
	AND Claim.result # "C" ;
	AND Claim.notify_date BETWEEN gtCurDate AND gtEndDate ;
INTO TABLE (gcFundCode+"_HC_Claim_Month")
***
*Query Claim by service
SELECT A.fundcode, A.notify_no, A.notify_dat,  A.serv_type,  A.policy_no, A.plan, A.plan_type, ;
  A.plan+Claim_line.cat_code AS plan_cat, Claim_line.cat_code, Claim_line.description, Claim_line.benefit, ;
  IIF(EMPTY(A.fax_by), Claim_line.scharge, Claim_line.fcharge) AS charge, ;
  IIF(EMPTY(A.fax_by), Claim_line.spaid, Claim_line.fpaid) AS paid, ;
  IIF(EMPTY(A.fax_by), Claim_line.apaid, Claim_line.exgratia) AS exgratia, A.result, A.status ;  
FROM (gcFundCode+"_HC_Claim_Month") A INNER JOIN cims!claim_line ;
	ON  A.notify_no = Claim_line.notify_no ;
WHERE A.serv_type = "IPD" ;
	AND A.status = "P" ;	
INTO TABLE (gcFundCode+"_HC_Claimline")
*
SELECT serv_type, SUM(IIF(workdays <= 1, 1, 0)) AS day_1, ;
	SUM(IIF(workdays = 2, 1, 0)) AS day_2, SUM(IIF(workdays = 3, 1, 0)) AS day_3, ;	
	SUM(IIF(workdays = 4, 1, 0)) AS day_4, SUM(IIF(workdays = 5, 1, 0)) AS day_5, ;	
	SUM(IIF(workdays = 6, 1, 0)) AS day_6, SUM(IIF(workdays >= 7 AND workdays <= 10, 1, 0)) AS day_7, ;	
	SUM(IIF(workdays > 10, 1, 0)) AS day_11 ;
FROM (gcFundCode+"_HC_Claim_Month") ;
GROUP BY 1 ;
WHERE INLIST(status, "D", "P") ;
	AND EMPTY(unclean) ;
	AND result # "P5" ;
INTO TABLE (gcFundCode+"_HC_Aging")
*
**********************************
PROCEDURE q_PlanbyService_Month
*
SELECT plan, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", paid, 0)) AS opd_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", paid, 0)) AS ipd_paid, ;	
	SUM(IIF(serv_type = "OPD" AND status $ "AW", 1, 0)) AS out_o_noc, ;	
	SUM(IIF( serv_type = "OPD" AND status $ "AW", paid, 0)) AS out_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW", 1, 0)) AS out_i_noc, ;
	SUM(IIF( serv_type = "IPD" AND status $ "AW", paid, 0)) AS out_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND status = "D", 1, 0)) AS d_o_noc, ;	
	SUM(IIF( serv_type = "OPD" AND status = "D", paid, 0)) d_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "D", 1, 0)) AS d_i_noc, ;	
	SUM(IIF( serv_type = "IPD" AND status = "D", paid, 0)) d_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND exgratia # 0, 1, 0)) AS e_o_noc, ;
	SUM(IIF( serv_type = "OPD", exgratia, 0)) AS e_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND exgratia # 0, 1, 0)) AS e_i_noc, ;
	SUM(IIF( serv_type = "IPD", exgratia, 0)) AS e_i_paid ;
FROM (gcFundCode+"_HC_Claim_Month") ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc_m
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, family_no, plan, serv_type, status, count(*) AS amt ;
FROM (gcFundCode+"_HC_Claim_Month") ;
GROUP BY policy_no, family_no, plan, serv_type, status ;
INTO CURSOR pol_1
*
SELECT plan, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_nmc, ;
	SUM(IIF(serv_type = "OPD" AND status = "W", 1, 0)) AS w_opd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status = "P",  1, 0)) AS ipd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status = "W",  1, 0)) AS w_ipd_nmc ;	
FROM pol_1 ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR nmc_m
*
SELECT nmc_m.plan, noc_m.opd_noc, nmc_m.opd_nmc, noc_m.d_o_noc, noc_m.ipd_noc, nmc_m.ipd_nmc, noc_m.d_i_noc, ;
	noc_m.opd_paid, noc_m.ipd_paid, noc_m.e_o_noc, noc_m.e_i_noc, noc_m.out_o_noc, noc_m.out_o_paid, noc_m.out_i_noc, noc_m.out_i_paid, ;
	noc_m.d_o_paid, noc_m.d_i_paid, noc_m.e_o_paid, noc_m.e_i_paid, w_opd_nmc, w_ipd_nmc ;
FROM noc_m INNER JOIN nmc_m ;
	ON noc_m.plan = nmc_m.plan ;
ORDER BY 1 ;
INTO CURSOR _SumType
*
SELECT _SumMember.plan, _SumMember.nom_month, _SumMember.eqa_month, _SumMember.ep_month, ;
	_SumType.opd_nmc, _SumType.opd_noc, _SumType.opd_paid, _SumType.e_o_paid, _SumType.d_o_noc, ;
	_SumType.ipd_nmc, _SumType.ipd_noc, _SumType.ipd_paid, _SumType.e_i_paid, _SumType.d_i_noc, ;
	_SumType.w_opd_nmc+_SumType.w_ipd_nmc AS w_nmc, _SumType.out_o_noc+_sumType.out_i_noc AS w_noc, ;
	_SumType.out_o_paid+_Sumtype.out_i_paid As w_paid ;
FROM _SumType RIGHT JOIN _SumMember ;
	ON _SumType.plan = _SumMember.plan ;
ORDER BY 1 ;		
INTO TABLE (gcFundCode+"_HC_PlanbyService_Month")
*End Query Current Month Report
*
**********************************
PROCEDURE Q_PlanbyService_Year

SELECT plan, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", paid, 0)) AS opd_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", paid, 0)) AS ipd_paid, ;	
	SUM(IIF(serv_type = "OPD" AND status $ "AW", 1, 0)) AS out_o_noc, ;	
	SUM(IIF( serv_type = "OPD" AND status $ "AW", paid, 0)) AS out_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW", 1, 0)) AS out_i_noc, ;
	SUM(IIF( serv_type = "IPD" AND status $ "AW", paid, 0)) AS out_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND status = "D", 1, 0)) AS d_o_noc, ;	
	SUM(IIF( serv_type = "OPD" AND status = "D", paid, 0)) d_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "D", 1, 0)) AS d_i_noc, ;	
	SUM(IIF( serv_type = "IPD" AND status = "D", paid, 0)) d_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND exgratia # 0, 1, 0)) AS e_o_noc, ;
	SUM(IIF( serv_type = "OPD", exgratia, 0)) AS e_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND exgratia # 0, 1, 0)) AS e_i_noc, ;
	SUM(IIF( serv_type = "IPD", exgratia, 0)) AS e_i_paid ;
FROM (gcFundCode+"_HC_Claim") ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, family_no, plan, serv_type, status, count(*) AS amt ;
FROM (gcFundCode+"_HC_Claim") ;
GROUP BY policy_no, family_no, plan, serv_type, status ;
INTO CURSOR per_pol
*
SELECT plan, SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status = "P",  1, 0)) AS ipd_nmc, ;
	SUM(IIF(serv_type = "OPD" AND status $ "AW",  1, 0)) AS w_opd_nmc, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW",  1, 0)) AS w_ipd_nmc ;	
FROM per_pol ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR nmc
*
SELECT nmc.plan, noc.opd_noc, nmc.opd_nmc, noc.d_o_noc, noc.ipd_noc, nmc.ipd_nmc, noc.d_i_noc, ;
	noc.opd_paid, noc.ipd_paid, noc.e_o_noc, noc.e_i_noc, noc.out_o_noc, noc.out_o_paid, noc.out_i_noc, noc.out_i_paid, ;
	noc.d_o_paid, noc.d_i_paid, noc.e_o_paid, noc.e_i_paid, nmc.w_opd_nmc, nmc.w_ipd_nmc ;
FROM noc INNER JOIN nmc ;
	ON noc.plan = nmc.plan ;
ORDER BY 1 ;
INTO CURSOR _SumType
*
SELECT _SumMember.plan, _SumMember.nom_year, ;
	_SumMember.eqa_year, _SumMember.ep_year, ;
	_SumType.opd_noc, _SumType.opd_nmc, ;
	IIF(_SumType.opd_noc = 0 OR _sumtype.opd_nmc = 0, 0, _SumType.opd_noc/_SumType.opd_nmc) AS opd_acf, ;
	_SumType.d_o_noc, _SumType.ipd_noc, _SumType.ipd_nmc, ;		
	IIF(_SumType.ipd_noc = 0 OR _Sumtype.ipd_nmc = 0, 0, _SumType.ipd_noc/_SumType.opd_nmc) AS ipd_acf, ;
	_SumType.d_i_noc, _SumType.opd_noc, _SumType.opd_paid, _SumType.e_o_paid, ;
	IIF(_SumType.opd_paid = 0 OR _SumType.opd_noc = 0, 0, (_SumType.opd_paid+_SumType.e_o_paid)/_SumType.opd_noc) AS opd_loss, ;
	_SumType.ipd_noc, _SumType.ipd_paid, _SumType.e_i_paid, ;
	IIF(_Sumtype.ipd_paid = 0 OR _sumType.ipd_noc = 0, 0, (_SumType.ipd_paid+_SumType.e_i_paid)/_SumType.ipd_noc) AS ipd_loss, ;	
	_SumType.w_opd_nmc, _sumtype.w_ipd_nmc, ;
	_SumType.out_o_noc+_SumType.out_i_noc AS w_noc, _SumType.out_o_paid+_SumType.out_i_paid AS w_paid ;	
FROM _SumType RIGHT JOIN _SumMember ;
	ON _SumType.plan = _SumMember.plan ;
ORDER BY 1 ;		
INTO TABLE (gcFundCode+"_HC_PlanbyService_Year")
*
**********************************
PROCEDURE Q_PlanbyCategory_Month

SELECT plan, descriptio, benefit, ;
	SUM(charge) AS charge, ;
	SUM(paid) AS paid, ;
	SUM(exgratia) AS exgratia, ;
	SUM(IIF(status = "P" AND paid # 0, 1, 0)) AS noc ;
FROM (gcFundCode+"_HC_Claimline") ;
GROUP BY plan, descriptio, benefit ;
ORDER BY plan ;
INTO TABLE (gcFundCode+"_HC_PlanbyCategory_Month")
*
*End Query Claim by service
*
**********************************************************
PROCEDURE q_rolling

lcRollingFile = gcFundCode+"_HC_Rolling"
*
CREATE TABLE (lcRollingFile) FREE (months C(6), nom Y, eqal Y, ep Y, notifys Y, admit Y, iep Y, inotify Y, iadmit Y, oep Y, onotify Y, oadmit Y)
*
ldStartDate = DATE(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate))
lnDay = ICASE(MONTH(ldStartDate) = 2, IIF(MOD(YEAR(ldStartDate),4) = 0, 29, 28), INLIST(MONTH(ldStartDate), 1,3,5,7,8,10,12), 31, 30)
ldEndDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), lnDay)

DO WHILE ldEndDate < gdEndDate
	lnDay = ICASE(MONTH(ldStartDate) = 2, IIF(MOD(YEAR(ldStartDate),4) = 0, 29, 28), INLIST(MONTH(ldStartDate), 1,3,5,7,8,10,12), 31, 30)
	ldEndDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), lnDay)
	lcFile = "R_"+STRTRAN(DTOC(ldEndDate), "/", "")
	*
	SELECT tpacode, policy_no, plan, effective, expiry, premium, prem_day, prem_i, prem_o, ;	
		IIF(TTOD(effective) >= ldStartDate AND TTOD(effective) <= ldEndDate, ;
		TTOD(effective), IIF(TTOD(effective) <= ldStartDate, ldStartDate, {})) AS start_month, ;
		IIF(TTOD(expiry) >= ldEndDate, ldEndDate, IIF(TTOD(expiry) >= ldStartDate AND TTOD(expiry) <= ldEndDate, ;
		TTOD(expiry), {})) AS end_month ;
	 FROM Q_member ;
	INTO CURSOR curRmonth
	*
	SELECT COUNT(*) AS nom, ;
		SUM((end_month-start_month)/lnDay) AS eqal, ;
		SUM(prem_day *((end_month-start_month)+1)) AS ep, ;
		SUM((prem_i/365.25) *((end_month-start_month)+1)) AS iep, ;
		SUM((prem_o/365.25) *((end_month-start_month)+1)) AS oep ;		
	FROM curRMonth ;
	WHERE !EMPTY(start_month) ;
	INTO CURSOR curMonths
	SELECT curMonths
	SCATTER MEMVAR 
	***********************************************************************
	SELECT YEAR(notify_date) AS yy, MONTH(notify_date) AS mm, SUM(IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid)) AS paid, ;
		SUM(IIF(Claim.service_type <> "OPD", IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid), 0)) AS ipaid, ;
		SUM(IIF(Claim.service_type = "OPD", IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid), 0)) AS opaid ;	
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND INLIST(Claim.claim_with,  "I", "T", "H") ;
	AND Claim.result = "P" ;
	AND TTOD(Claim.notify_date) BETWEEN ldStartDate AND ldEndDate ;
	GROUP BY 1, 2 ;
	INTO CURSOR curClaimN	
	*
	SELECT YEAR(admis_date) AS yy, MONTH(admis_date) AS mm, SUM(IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid)) AS paid, ;
		SUM(IIF(Claim.service_type <> "OPD", IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid), 0)) AS ipaid, ;
		SUM(IIF(Claim.service_type = "OPD", IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid), 0)) AS opaid ;	
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND INLIST(Claim.claim_with,  "I", "T",  "H") ;
	AND Claim.result = "P" ;
	AND TTOD(Claim.admis_date) BETWEEN ldStartDate AND ldEndDate ;
	GROUP BY 1, 2 ;
	INTO CURSOR curClaimM	
	*
	m.admit = curClaimM.paid
	m.iadmit= curClaimM.ipaid
	m.oadmit= curClaimM.opaid	
	m.notifys = curClaimN.paid
	m.inotify = curClaimN.ipaid
	m.inotify = curClaimN.opaid	
	m.months = LEFT(CMONTH(ldStartDate),3)+"-"+RIGHT(STR(YEAR(ldStartDate),4),2)
	********************************
	INSERT INTO (lcRollingFile) FROM MEMVAR 
	********************************
	ldStartDate = GOMONTH(ldStartDate,1)
	ldStartDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), DAY(ldStartDate))
ENDDO 	