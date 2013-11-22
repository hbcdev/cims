PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption
	
SET SAFETY OFF 	
********************
lcOldDir = SYS(5)+SYS(2003)
gcStartDate = "Start Date"
gcEndDate = "End Date"
glMonth = .F.	
gcFundCode = "ACE"
gdEndDate = DATE() - DAY(DATE())
gdStartDate = gdEndDate - IIF(MOD(YEAR(gdEndDate),4) = 0, 366, 365)
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

ldOldDate = gdEndDate - IIF(INLIST(MONTH(gdEndDate), 1, 3, 5, 7, 8, 10, 12), 31, IIF(MONTH(gdEndDate) = 2, 28, 30))
lcOldFolder = ADDBS(gcTemp) + gcFundCode + "\" + STRTRAN(STR(MONTH(ldOldDate),2), " ", "0")+"_"+STR(YEAR(ldOldDate),4)
IF DIRECTORY(gcSaveTo)
	IF !DIRECTORY(lcOldFolder)
		MKDIR &lcOldFolder
	ENDIF 	
	SET DEFAULT TO (gcSaveTo)
	COPY FILE *.* To &lcOldFolder
	DELETE FILE *.*
ELSE
	MKDIR &gcSaveTo
ENDIF 	
***********************
SET DEFAULT TO (gcSaveTo)
SET TALK ON 
SET TALK WINDOW 
****************
DO q_member
DO q_claim
****************
SET TALK OFF 
SET DEFAULT TO (lcOldDir)
**************************************************************
PROCEDURE q_Member
*
SELECT Member.tpacode, Member.policy_no, Member.product AS plan, ;
	IIF(Member.product = "HB", "HB", IIF(LEFT(Member.product,1) = "I", "PA", "HS")) AS plan_type, ;
	Member.hb_limit, Member.effective, Member.expiry, Member.premium, Member.premium/365.25 AS prem_day ;
 FROM cims!Member ;
 WHERE Member.tpacode = gcFundCode ;
   AND Member.expiry >= gtStartDate ;
   AND Member.customer_type # "T" ;
 INTO CURSOR Q_member
*
SELECT tpacode, policy_no, plan, plan_type, hb_limit, effective, expiry, premium, prem_day, ;	
	IIF(effective >= gtCurDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtCurDate AND expiry >= gtCurDate, TTOD(gtCurDate), {})) AS start_month, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry >= gtCurDate AND expiry <= gtEndDate, TTOD(expiry), {})) AS end_month, ;
	IIF(effective >= gtStartDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtStartDate AND expiry >= gtStartDate, gdStartDate, {})) AS start_roll, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry <= gtEndDate, TTOD(expiry), {})) AS end_roll ;
 FROM Q_member ;
INTO CURSOR Q_memb
*
SELECT tpacode, policy_no, plan, plan_type, hb_limit, effective, expiry, premium, prem_day, ;
	start_month, end_month, IIF(EMPTY(start_month), 000, 1) AS m_nominal, ;
	IIF(EMPTY(start_month), 000, (end_month-start_month)+1) AS m_days, ;
	IIF(EMPTY(start_month), 0000.0000, ((end_month-start_month)+1)/((gdEndDate - gdCurDate)+1)) AS eqa_month, ;
	IIF(EMPTY(start_month), 0000.0000, ((end_month-start_month)+1)*prem_day) AS ep_month, ;	
	start_roll, end_roll, IIF(EMPTY(start_roll), 000, 1) AS y_nominal, ;
	IIF(EMPTY(start_roll), 000, (end_roll-start_roll)+1) AS y_days, ;	
	IIF(EMPTY(start_roll), 0000000.0000, ((end_roll-start_roll)+1)/((gdEndDate - gdStartDate)+1)) AS eqa_year, ;
	IIF(EMPTY(start_roll), 0000000.0000, ((end_roll-start_roll)+1)*prem_day) AS ep_year ;	
FROM Q_memb ;	
INTO TABLE (gcFundCode+"_member")	
*
SELECT plan, plan_type, ;
	SUM(m_nominal) AS nom_month, SUM(eqa_month) AS eqa_month, SUM(ep_month) AS ep_month, ;
	SUM(y_nominal) AS nom_year, SUM(eqa_year) AS eqa_year, SUM(ep_year) AS ep_year ;
FROM (gcFundcode+"_member") ;
GROUP BY plan ;
ORDER BY plan ;
INTO TABLE sum_Member	
*	
SELECT Dependants.fundcode, Dependants.policy_no, Dependants.plan, ;
	IIF(Dependants.plan = "HB", "HB", IIF(LEFT(Dependants.plan,1) = "I", "PA", "HS")) AS plan_type, ;
	Dependants.hb_limit, Dependants.policy_date AS effective, Dependants.expired AS expiry, ;
	Dependants.premium, Dependants.premium/365.25 AS prem_day ;
FROM cims!Dependants ;
WHERE Dependants.fundcode = gcFundCode ;
	AND Dependants.policy_date <= gtEndDate ;
INTO CURSOR Q_Client
*
SELECT fundcode, policy_no, plan, plan_type, hb_limit, effective, expiry, premium, prem_day, ;	
	IIF(effective >= gtCurDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtCurDate AND expiry >= gtCurDate, TTOD(gtCurDate), {})) AS start_month, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry >= gtCurDate AND expiry <= gtEndDate, TTOD(expiry), {})) AS end_month, ;
	IIF(effective >= gtStartDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtStartDate AND expiry >= gtStartDate, gdStartDate, {})) AS start_roll, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry <= gtEndDate, TTOD(expiry), {})) AS end_roll ;
 FROM Q_Client ;
INTO CURSOR Q_Group
*
SELECT fundcode, policy_no, plan, plan_type, hb_limit, effective, expiry, premium, prem_day, ;
	start_month, end_month, IIF(EMPTY(start_month), 000, 1) AS m_nominal, ;
	IIF(EMPTY(start_month), 000, (end_month-start_month)+1) AS m_days, ;
	IIF(EMPTY(start_month), 0000.0000, ((end_month-start_month)+1)/((gdEndDate - gdCurDate)+1)) AS eqa_month, ;
	IIF(EMPTY(start_month), 0000.0000, ((end_month-start_month)+1)*prem_day) AS ep_month, ;	
	start_roll, end_roll, IIF(EMPTY(start_roll), 0, 1) AS y_nominal, ;
	IIF(EMPTY(start_roll), 000, (end_roll-start_roll)+1) AS y_days, ;	
	IIF(EMPTY(start_roll), 00000000.0000, ((end_roll-start_roll)+1)/((gdEndDate - gdStartDate)+1)) AS eqa_year, ;
	IIF(EMPTY(start_roll), 00000000.0000, ((end_roll-start_roll)+1)*prem_day) AS ep_year ;	
FROM Q_Group ;	
INTO TABLE (gcFundCode+"_Group")	
*
SELECT policy_no, ;
	SUM(m_nominal) AS nom_month, SUM(eqa_month) AS eqa_month, SUM(ep_month) AS ep_month, ;
	SUM(y_nominal) AS nom_year, SUM(eqa_year) AS eqa_year, SUM(ep_year) AS ep_year ;
FROM (gcFundcode+"_Group") ;
GROUP BY policy_no ;
ORDER BY policy_no ;
INTO TABLE sum_Group	
*********************************************************
PROCEDURE q_Claim
*
SELECT Claim.notify_no, Claim.notify_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS serv_type, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, Claim.client_name, ;
	IIF(LEFT(Claim.policy_no,1) = "G", Claim.policy_no, Claim.plan) AS plan, ;	
	IIF(LEFT(Claim.policy_no,1) = "G", LEFT(Claim.policy_no,1), IIF(Claim.plan = "HB", "HB", IIF(LEFT(Claim.plan,1) = "I", "PA", "HS"))) AS plan_type, ;
	Claim.admis_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, ;
	IIF(EMPTY(Claim.fax_by), Claim.abenfpaid, Claim.exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid) AS paid, ;
	LEFT(result,1) AS status, Claim.result, Claim.return_date, Claim.unclean, Claim.unclean_note, ;
	LEFT(CMONTH(admis_date),3)+"-"+RIGHT(STR(YEAR(admis_date),4),2) AS admis_m, ;  
	LEFT(CMONTH(notify_date),3)+"-"+RIGHT(STR(YEAR(notify_date),4),2) AS notify_m, ;  
	((return_date-TTOD(notify_date)+1) - holidays(TTOD(notify_date), return_date)) AS workdays ;	
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.notify_date BETWEEN gtStartDate AND gtEndDate ;
	AND result # "C" ;
GROUP BY Claim.notify_no ;
INTO TABLE (gcFundCode+"_Claim")
*
SELECT plan_type+admis_m AS plan_m, ;
	SUM(paid) AS admit_paid ;
FROM (gcFundCode+"_Claim") ;
WHERE admis_date BETWEEN gtStartDate AND gtEndDate ;
	AND status = "P" ;
GROUP BY plan_type, admis_m ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_Claim_Admit")
*
SELECT plan_type+notify_m Plan_m, ;
	SUM(paid) AS notify_paid ;
FROM (gcFundCode+"_Claim") ;
WHERE notify_dat BETWEEN gtStartDate AND gtEndDate ;
	AND status = "P" ;
GROUP BY plan_type, notify_m ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_Claim_notify")
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
FROM (gcFundCode+"_Claim") ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, family_no, plan, serv_type, count(*) AS amt ;
FROM (gcFundCode+"_Claim") ;
GROUP BY policy_no, family_no, plan, serv_type ;
WHERE status $ "DP" ;
INTO CURSOR per_pol
*
SELECT plan, SUM(IIF(serv_type = "OPD", 1, 0)) AS opd_nmc, ;
	SUM(IIF(serv_type = "IPD",  1, 0)) AS ipd_nmc ;
FROM per_pol ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR nmc
*
SELECT nmc.plan, noc.opd_noc, nmc.opd_nmc, noc.d_o_noc, noc.ipd_noc, nmc.ipd_nmc, noc.d_i_noc, ;
	noc.opd_paid, noc.ipd_paid, noc.e_o_noc, noc.e_i_noc, noc.out_o_noc, noc.out_o_paid, noc.out_i_noc, noc.out_i_paid, ;
	noc.d_o_paid, noc.d_i_paid, noc.e_o_paid, noc.e_i_paid ;
FROM noc INNER JOIN nmc ;
	ON noc.plan = nmc.plan ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_incident")
*
*Query Current Month Report
*
SELECT Claim.notify_no, Claim.notify_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS serv_type, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, Claim.client_name, ;
	IIF(LEFT(Claim.policy_no,1) = "G", Claim.policy_no, Claim.plan) AS plan, ;
	IIF(LEFT(Claim.policy_no,1) = "G", LEFT(Claim.policy_no,1), IIF(Claim.plan = "HB", "HB", IIF(LEFT(Claim.plan,1) = "I", "PA", "HS"))) AS plan_type, ;
	Claim.admis_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, ;
	IIF(EMPTY(Claim.fax_by), Claim.abenfpaid, Claim.exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid, Claim.fbenfpaid) AS paid, ;
	LEFT(result,1) AS status, Claim.result, Claim.return_date, Claim.unclean, Claim.unclean_note, ;
	((return_date-TTOD(notify_date)+1) - holidays(TTOD(notify_date), return_date)) AS workdays ;	
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.notify_date BETWEEN gtCurDate AND gtEndDate ;
	AND result # "C" ;
GROUP BY Claim.notify_no ;
INTO TABLE (gcFundCode+"_Claim_Month")
**
*
SELECT plan_type, ;
	SUM(IIF(admis_date >= gtCurDate AND admis_date <= gtEndDate, paid, 0)) AS admit_paid, ;
	SUM(IIF(notify_dat >= gtCurDate AND notify_dat <= gtEndDate, paid, 0)) AS notify_paid ;
FROM (gcFundCode+"_Claim_Month") ;
WHERE LEFT(result,1) $ "P" ;
GROUP BY plan_type ;
INTO TABLE (gcFundCode+"_Claim_Sum_Month")
*
SELECT plan, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", paid, 0.00)) AS opd_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", paid, 0.00)) AS ipd_paid, ;	
	SUM(IIF(serv_type = "OPD" AND status $ "AW", 1, 0)) AS out_o_noc, ;	
	SUM(IIF( serv_type = "OPD" AND status $ "AW", paid, 0.00)) AS out_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW", 1, 0)) AS out_i_noc, ;
	SUM(IIF( serv_type = "IPD" AND status $ "AW", paid, 0.00)) AS out_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND status = "D", 1, 0)) AS d_o_noc, ;	
	SUM(IIF( serv_type = "OPD" AND status = "D", paid, 0.00)) d_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "D", 1, 0)) AS d_i_noc, ;	
	SUM(IIF( serv_type = "IPD" AND status = "D", paid, 0.00)) d_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND exgratia # 0, 1, 0)) AS e_o_noc, ;
	SUM(IIF( serv_type = "OPD", exgratia, 0.00)) AS e_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND exgratia # 0, 1, 0)) AS e_i_noc, ;
	SUM(IIF(serv_type = "IPD", exgratia, 0.00)) AS e_i_paid ;
FROM (gcFundCode+"_Claim_Month") ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc_m
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, family_no, plan, serv_type, result, status, count(*) AS amt ;
FROM (gcFundCode+"_Claim_Month") ;
GROUP BY policy_no, family_no, plan, serv_type ;
WHERE status $ "P" ;
INTO CURSOR pol_1
*
SELECT plan, SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status = "P",  1, 0)) AS ipd_nmc ;
FROM pol_1 ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR nmc_m
*
SELECT nmc_m.plan, noc_m.opd_noc, nmc_m.opd_nmc, noc_m.d_o_noc, noc_m.ipd_noc, nmc_m.ipd_nmc, noc_m.d_i_noc, ;
	noc_m.opd_paid, noc_m.ipd_paid, noc_m.e_o_noc, noc_m.e_i_noc, noc_m.out_o_noc, noc_m.out_o_paid, noc_m.out_i_noc, noc_m.out_i_paid, ;
	noc_m.d_o_paid, noc_m.d_i_paid, noc_m.e_o_paid, noc_m.e_i_paid ;
FROM noc_m INNER JOIN nmc_m ;
	ON noc_m.plan = nmc_m.plan ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_Month")
*End Query Current Month Report
*
*Query Claim by service
SELECT Claim.fundcode, Claim.notify_no, Claim.notify_date,  IIF(Claim.service_type = "IPD", "IPD", "OPD") AS serv_type, ;
  Claim.policy_no, Claim.plan, IIF(LEFT(Claim.policy_no,1) = "G", Claim.plan, IIF(Claim.plan = "HB", "HB", IIF(LEFT(Claim.plan,1) = "I", "PA", "HS"))) AS plan_type, ;
  CheckCat(Claim_line.cat_code) AS catcode, Claim_line.description, IIF(Claim_line.fcharge # 0, Claim_line.fcharge, Claim_line.scharge) AS charge, ;
  IIF(EMPTY(Claim.fax_by), Claim_line.spaid, Claim_line.fpaid) AS paid, ;
  IIF(EMPTY(Claim.fax_by), Claim_line.apaid, Claim_line.exgratia) AS exgratia, Claim.result, Claim_line.benefit ;
 FROM  cims!claim INNER JOIN cims!claim_line ;
   ON  Claim.notify_no = Claim_line.notify_no ;
 WHERE Claim.fundcode = gcFundCode ;
    AND Claim.notify_date BETWEEN gtStartDate AND gtEndDate ;
   AND Claim.service_type = "IPD" ;
   AND LEFT(Claim.plan,1) # "I" ;
   AND Claim.result = "P" ;
 INTO TABLE (gcFundCode+"_Claim_line")
*
SELECT plan_type+catcode AS plan_cat, ;
	SUM(charge) AS charge, ;
	SUM(paid) AS paid, ;
	SUM(exgratia) AS exgratia, ;
	SUM(IIF(LEFT(result,1) = "P" AND paid # 0, 1, 0)) AS noc ;
FROM (gcFundCode+"_Claim_line") ;
GROUP BY plan_type, catcode ;
ORDER BY plan_type ;
INTO TABLE (gcFundCode+"_Paidbyservice")
*
*End Query Claim by service
*
SELECT serv_type, SUM(IIF(workdays <= 1, 1, 0)) AS day_1, ;
	SUM(IIF(workdays = 2, 1, 0)) AS day_2, SUM(IIF(workdays = 3, 1, 0)) AS day_3, ;	
	SUM(IIF(workdays = 4, 1, 0)) AS day_4, SUM(IIF(workdays = 5, 1, 0)) AS day_5, ;	
	SUM(IIF(workdays = 6, 1, 0)) AS day_6, SUM(IIF(workdays >= 7 AND workdays <= 10, 1, 0)) AS day_7, ;	
	SUM(IIF(workdays > 10, 1, 0)) AS day_11 ;
FROM (gcFundCode+"_Claim_Month") ;
GROUP BY 1 ;
WHERE status $ "DP" ;
	AND EMPTY(unclean) ;	
	AND result # "P5" ;
	AND plan # "HB" ;
INTO TABLE aging
**********************************************************
PROCEDURE q_pa_rolling

lcRollingFile = gcFundCode+"_PA_Rolling"
*
CREATE TABLE (lcRollingFile) FREE (months C(6), nom Y, eqal Y, ep Y, notifys Y, admit Y, return Y, noc_notify I, noc_admit I, noc_return I)
*
ldStartDate = DATE(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate))
lnDay = ICASE(MONTH(ldStartDate) = 2, IIF(MOD(YEAR(ldStartDate),4) = 0, 29, 28), INLIST(MONTH(ldStartDate), 1,3,5,7,8,10,12), 31, 30)
ldEndDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), lnDay)

DO WHILE ldEndDate < gdEndDate
	lnDay = ICASE(MONTH(ldStartDate) = 2, IIF(MOD(YEAR(ldStartDate),4) = 0, 29, 28), INLIST(MONTH(ldStartDate), 1,3,5,7,8,10,12), 31, 30)
	ldEndDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), lnDay)
	lcFile = "R_"+STRTRAN(DTOC(ldEndDate), "/", "")
	*
	SELECT tpacode, policy_no, plan, effective, expiry, premium, prem_day, ;	
		IIF(TTOD(effective) >= ldStartDate AND TTOD(effective) <= ldEndDate, TTOD(effective), IIF(TTOD(effective) <= ldStartDate, ldStartDate, {})) AS start_month, ;
		IIF(TTOD(expiry) >= ldEndDate, ldEndDate, IIF(TTOD(expiry) >= ldStartDate AND TTOD(expiry) <= ldEndDate, TTOD(expiry), {})) AS end_month ;
	 FROM Q_member ;
	 WHERE plan_type = "PA" ;
	INTO CURSOR curRmonth
	*
	SELECT COUNT(*) AS nom, ;
		SUM((end_month-start_month)/lnDay) AS eqal, ;
		SUM(prem_day *((end_month-start_month)+1)) AS ep ;
	FROM curRMonth ;
	WHERE !EMPTY(start_month) ;
	INTO CURSOR curMonths
	SELECT curMonths
	SCATTER MEMVAR 
	***********************************************************************
	SELECT notify_no, claim_date, service_type AS service, paid, status, result ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "P" ;
	AND Claim.result # "C" ;	
	AND TTOD(claim_date) BETWEEN ldStartDate AND ldEndDate ;				
	INTO CURSOR curClaimN	
	*
	SELECT notify_no, admis_date, service_type AS service, paid, status, result ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "P" ;
	AND Claim.result # "C" ;	
	AND TTOD(admis_date) BETWEEN ldStartDate AND ldEndDate ;				
	INTO CURSOR curClaimM
	*
	SELECT notify_no, claim_date, service_type AS service, paid, result ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "P" ;
	AND Claim.result # "C" ;	
	AND return_date BETWEEN ldStartDate AND ldEndDate ;				
	INTO CURSOR curClaimR
	*	
	SELECT curClaimM
	SUM paid TO m.admit
	m.noc_admit = RECCOUNT()
	*
	SELECT curClaimN
	SUM paid TO m.notifys FOR status $ "PF"	
	m.noc_notify = RECCOUNT()
	*
	SELECT curClaimR
	SUM paid TO m.return FOR LEFT(result,1) = "P"
	m.noc_return = RECCOUNT()
	m.months = LEFT(CMONTH(ldStartDate),3)+"-"+RIGHT(STR(YEAR(ldStartDate),4),2)
	********************************
	INSERT INTO (lcRollingFile) FROM MEMVAR 
	*************************************************************************
	ldStartDate = GOMONTH(ldStartDate,1)
	ldStartDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), DAY(ldStartDate))
ENDDO 	
*******************************
PROCEDURE q_hs_rolling

lcRollingFile = gcFundCode+"_HS_Rolling"
*
CREATE TABLE (lcRollingFile) FREE (months C(6), nom Y, eqal Y, ep Y, notifys Y, admit Y, return Y, noc_notify I, noc_admit I, noc_return I)
*
ldStartDate = DATE(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate))
lnDay = ICASE(MONTH(ldStartDate) = 2, IIF(MOD(YEAR(ldStartDate),4) = 0, 29, 28), INLIST(MONTH(ldStartDate), 1,3,5,7,8,10,12), 31, 30)
ldEndDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), lnDay)

DO WHILE ldEndDate < gdEndDate
	lnDay = ICASE(MONTH(ldStartDate) = 2, IIF(MOD(YEAR(ldStartDate),4) = 0, 29, 28), INLIST(MONTH(ldStartDate), 1,3,5,7,8,10,12), 31, 30)
	ldEndDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), lnDay)
	lcFile = "R_"+STRTRAN(DTOC(ldEndDate), "/", "")
	*
	SELECT tpacode, policy_no, plan, effective, expiry, premium, prem_day, ;	
		IIF(TTOD(effective) >= ldStartDate AND TTOD(effective) <= ldEndDate, TTOD(effective), IIF(TTOD(effective) <= ldStartDate, ldStartDate, {})) AS start_month, ;
		IIF(TTOD(expiry) >= ldEndDate, ldEndDate, IIF(TTOD(expiry) >= ldStartDate AND TTOD(expiry) <= ldEndDate, TTOD(expiry), {})) AS end_month ;
	 FROM Q_member ;
	 WHERE plan_type = "HS" ;
	INTO CURSOR curRmonth
	*
	SELECT COUNT(*) AS nom, ;
		SUM((end_month-start_month)/lnDay) AS eqal, ;
		SUM(prem_day *((end_month-start_month)+1)) AS ep ;
	FROM curRMonth ;
	WHERE !EMPTY(start_month) ;
	INTO CURSOR curMonths
	SELECT curMonths
	SCATTER MEMVAR 
	***********************************************************************
	SELECT notify_no, claim_date, service_type AS service, paid, status, result ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "I" ;
	AND Claim.result # "C" ;	
	AND TTOD(claim_date) BETWEEN ldStartDate AND ldEndDate ;				
	INTO CURSOR curClaimN	
	*
	SELECT notify_no, admis_date, service_type AS service, paid, status, result ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "I" ;
	AND Claim.result # "C" ;	
	AND TTOD(admis_date) BETWEEN ldStartDate AND ldEndDate ;				
	INTO CURSOR curClaimM
	*
	SELECT notify_no, claim_date, service_type AS service, paid, result ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "I" ;
	AND Claim.result # "C" ;	
	AND return_date BETWEEN ldStartDate AND ldEndDate ;				
	INTO CURSOR curClaimR
	*	
	SELECT curClaimM
	SUM paid TO m.admit
	m.noc_admit = RECCOUNT()
	*
	SELECT curClaimN
	SUM paid TO m.notifys FOR status $ "PF"	
	m.noc_notify = RECCOUNT()
	*
	SELECT curClaimR
	SUM paid TO m.return FOR LEFT(result,1) = "P"
	m.noc_return = RECCOUNT()
	m.months = LEFT(CMONTH(ldStartDate),3)+"-"+RIGHT(STR(YEAR(ldStartDate),4),2)
	********************************
	INSERT INTO (lcRollingFile) FROM MEMVAR 
	*************************************************************************
	ldStartDate = GOMONTH(ldStartDate,1)
	ldStartDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), DAY(ldStartDate))
ENDDO 	
*******************************
PROCEDURE q_hb_rolling

lcRollingFile = gcFundCode+"_HB_Rolling"
*
CREATE TABLE (lcRollingFile) FREE (months C(6), nom Y, eqal Y, ep Y, notifys Y, admit Y, return Y, noc_notify I, noc_admit I, noc_return I)
*
ldStartDate = DATE(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate))
lnDay = ICASE(MONTH(ldStartDate) = 2, IIF(MOD(YEAR(ldStartDate),4) = 0, 29, 28), INLIST(MONTH(ldStartDate), 1,3,5,7,8,10,12), 31, 30)
ldEndDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), lnDay)

DO WHILE ldEndDate < gdEndDate
	lnDay = ICASE(MONTH(ldStartDate) = 2, IIF(MOD(YEAR(ldStartDate),4) = 0, 29, 28), INLIST(MONTH(ldStartDate), 1,3,5,7,8,10,12), 31, 30)
	ldEndDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), lnDay)
	lcFile = "R_"+STRTRAN(DTOC(ldEndDate), "/", "")
	*
	SELECT tpacode, policy_no, plan, effective, expiry, premium, prem_day, ;	
		IIF(TTOD(effective) >= ldStartDate AND TTOD(effective) <= ldEndDate, TTOD(effective), IIF(TTOD(effective) <= ldStartDate, ldStartDate, {})) AS start_month, ;
		IIF(TTOD(expiry) >= ldEndDate, ldEndDate, IIF(TTOD(expiry) >= ldStartDate AND TTOD(expiry) <= ldEndDate, TTOD(expiry), {})) AS end_month ;
	 FROM Q_member ;
	 WHERE plan_type = "HB" ;
	INTO CURSOR curRmonth
	*
	SELECT COUNT(*) AS nom, ;
		SUM((end_month-start_month)/lnDay) AS eqal, ;
		SUM(prem_day *((end_month-start_month)+1)) AS ep ;
	FROM curRMonth ;
	WHERE !EMPTY(start_month) ;
	INTO CURSOR curMonths
	SELECT curMonths
	SCATTER MEMVAR 
	***********************************************************************
	SELECT notify_no, claim_date, service_type AS service, paid, status, result ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "B" ;
	AND Claim.result # "C" ;	
	AND TTOD(claim_date) BETWEEN ldStartDate AND ldEndDate ;				
	INTO CURSOR curClaimN	
	*
	SELECT notify_no, admis_date, service_type AS service, paid, status, result ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "B" ;
	AND Claim.result # "C" ;	
	AND TTOD(admis_date) BETWEEN ldStartDate AND ldEndDate ;				
	INTO CURSOR curClaimM
	*
	SELECT notify_no, claim_date, service_type AS service, paid, result ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "B" ;
	AND Claim.result # "C" ;	
	AND return_date BETWEEN ldStartDate AND ldEndDate ;				
	INTO CURSOR curClaimR
	*	
	SELECT curClaimM
	SUM paid TO m.admit
	m.noc_admit = RECCOUNT()
	*
	SELECT curClaimN
	SUM paid TO m.notifys FOR status $ "PF"	
	m.noc_notify = RECCOUNT()
	*
	SELECT curClaimR
	SUM paid TO m.return FOR LEFT(result,1) = "P"
	m.noc_return = RECCOUNT()
	m.months = LEFT(CMONTH(ldStartDate),3)+"-"+RIGHT(STR(YEAR(ldStartDate),4),2)
	********************************
	INSERT INTO (lcRollingFile) FROM MEMVAR 
	*************************************************************************
	ldStartDate = GOMONTH(ldStartDate,1)
	ldStartDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), DAY(ldStartDate))
ENDDO 	
*******************************

