PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption
	
SET SAFETY OFF
SET DELETED ON 
SET PROCEDURE TO progs\utility
********************
gcStartDate = "Start Date"
gcEndDate = "End Date"
glMonth = .F.	
gcFundCode = "TIC"
gdEndDate = DATE() - DAY(DATE())
gdStartDate = gdEndDate - IIF(MOD(YEAR(gdEndDate),4) = 0, 365, 364)
gnOption = 1
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
*DO q_Group 
DO q_Claim
DO q_PlanbyService_Year
DO q_PlanbyService_Month
DO q_PlanbyCategory
****************
SET TALK OFF 
SET DEFAULT TO (lcOldDir)
**************************************************************
PROCEDURE q_Member
*
SELECT Member.tpacode, Member.policy_no, Member.product AS plan, ;
	IIF(Member.product = "HB", "HB", IIF(LEFT(Member.product,1) = "P", "PA", "HS")) AS plan_type, ;
	Member.hb_limit, Member.effective, Member.expiry, Member.premium, Member.premium/365.25 AS prem_day ;
 FROM cims!Member ;
 WHERE Member.tpacode = gcFundCode ;
   AND Member.expiry >= gtStartDate ;
   AND customer_type = "I" ;
 INTO CURSOR Q_member
*
IF RECCOUNT("Q_Member") = 0
	RETURN 
ENDIF 
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
INTO TABLE (gcFundCode+"_HS_member")	
*
SELECT plan, ;
	SUM(m_nominal) AS nom_month, SUM(eqa_month) AS eqa_month, SUM(ep_month) AS ep_month, ;
	SUM(y_nominal) AS nom_year, SUM(eqa_year) AS eqa_year, SUM(ep_year) AS ep_year ;
FROM (gcFundcode+"_HS_member") ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR _SumMember
*
**********************************
PROCEDURE Q_Group	
*	
SELECT Dependants.fundcode, Dependants.policy_no, Dependants.plan, ;
	IIF(Dependants.plan = "HB", "HB", IIF(LEFT(Dependants.plan,1) = "P", "PA", "HS")) AS plan_type, ;
	Dependants.hb_limit, Dependants.effective, Dependants.expired AS expiry, ;
	Dependants.premium, Dependants.premium/365.25 AS prem_day ;
FROM cims!Dependants ;
WHERE Dependants.fundcode = gcFundCode ;
	AND Dependants.effective <= gtEndDate ;
INTO CURSOR Q_Client
*
IF RECCOUNT("q_Client") = 0
	RETURN 
ENDIF 	
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
INTO TABLE (gcFundCode+"_HS_Group")	
*
SELECT plan, ;
	SUM(m_nominal) AS nom_month, SUM(eqa_month) AS eqa_month, SUM(ep_month) AS ep_month, ;
	SUM(y_nominal) AS nom_year, SUM(eqa_year) AS eqa_year, SUM(ep_year) AS ep_year ;
FROM (gcFundcode+"_Group") ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR _SumGroup	
*********************************************************
PROCEDURE q_Claim
*
SELECT Claim.notify_no, Claim.notify_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS serv_type, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, Claim.client_name, Claim.plan, IIF(Claim.claim_with = "P", "PA", "HS") AS plan_type, ;
	Claim.admis_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid,  ;
	IIF(EMPTY(Claim.fax_by), abenfpaid, exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid) AS paid, ;
	LEFT(result,1) AS status, Claim.result, Claim.return_date, Claim.unclean, Claim.unclean_note, ;
	RIGHT(STR(YEAR(admis_date),4),2)+"-"+STRTRAN(STR(MONTH(admis_date),2)," ","0") AS admis_m, ;  
	RIGHT(STR(YEAR(notify_date),4),2)+"-"+STRTRAN(STR(MONTH(notify_date),2)," ","0") AS notify_m, ;  	
	((return_date-TTOD(notify_date)) - holidays(TTOD(notify_date), return_date)) AS workdays ;	
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.claim_with = "I" ;
	AND Claim.result # "C" ;	
	AND Claim.notify_date BETWEEN gtStartDate AND gtEndDate ;
INTO TABLE (gcFundCode+"_HS_Claim")
*
SELECT plan_type,admis_m, ;
	SUM(paid) AS admit_paid ;
FROM (gcFundCode+"_HS_Claim") ;
WHERE admis_date BETWEEN gtStartDate AND gtEndDate ;
	AND status = "P" ;
GROUP BY plan_type, admis_m ;
ORDER BY 1,2 ;
INTO CURSOR claim_admit
*
DO GenTab WITH "Claim_admit", "plan_type", "admis_m", "admit_paid", gcFundCode+"_hs_claim_Admit"
*
SELECT plan_type, notify_m, ;
	SUM(paid) AS notify_paid ;
FROM (gcFundCode+"_HS_Claim") ;
WHERE notify_dat BETWEEN gtStartDate AND gtEndDate ;
	AND status = "P" ;
GROUP BY plan_type, notify_m ;
ORDER BY 1,2 ;
INTO CURSOR claim_notify
*
DO GenTab WITH "Claim_notify", "plan_type", "notify_m", "notify_paid", gcFundCode+"_hs_claim_notify"
*
*Query Current Month Report
*
SELECT Claim.notify_no, Claim.notify_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS serv_type, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, Claim.client_name, Claim.plan, IIF(Claim.claim_with = "P", "PA", "HS") AS plan_type, ;
	Claim.admis_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, ;
	IIF(EMPTY(Claim.fax_by), abenfpaid, exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid) AS paid, ;
	LEFT(result,1) AS status, Claim.result, Claim.return_date, Claim.unclean, Claim.unclean_note, ;
	((return_date-TTOD(notify_date)) - holidays(TTOD(notify_date), return_date)) AS workdays ;	
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.claim_with = "I" ;
	AND Claim.result # "C" ;
	AND Claim.notify_date BETWEEN gtCurDate AND gtEndDate ;
INTO TABLE (gcFundCode+"_HS_Claim_Month")
**
SELECT plan_type, ;
	SUM(IIF(admis_date >= gtCurDate AND admis_date <= gtEndDate, paid, 0)) AS admit_paid, ;
	SUM(IIF(notify_dat >= gtCurDate AND notify_dat <= gtEndDate, paid, 0)) AS notify_paid ;
FROM (gcFundCode+"_HS_Claim_Month") ;
WHERE status $ "P" ;
GROUP BY plan_type ;
INTO TABLE (gcFundCode+"_HS_Claim_Sum_Month")
*
*Query Claim by service
SELECT Claim.fundcode, Claim.notify_no, Claim.notify_date,  IIF(Claim.service_type = "IPD", "IPD", "OPD") AS serv_type, ;
  Claim.policy_no, Claim.plan, IIF(Claim.claim_with = "P", "PA", "HS") AS plan_type, Claim.admis_date, ;
  CheckCat(Claim_line.cat_code) AS catcode, Claim_line.description, ;
  IIF(EMPTY(Claim.fax_by), Claim_line.scharge, Claim_line.fcharge) AS charge, ;
  IIF(EMPTY(Claim.fax_by), Claim_line.spaid, Claim_line.fpaid) AS paid, ;
  IIF(EMPTY(Claim.fax_by), Claim_line.apaid, Claim_line.exgratia) AS exgratia, Claim.result, Claim_line.benefit ;
FROM  cims!claim INNER JOIN cims!claim_line ;
	ON  Claim.notify_no = Claim_line.notify_no ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.claim_with = "I" ;
	AND Claim.result # "C" ;
	AND Claim.service_type = "IPD" ;	
	AND Claim.notify_date BETWEEN gtStartDate AND gtEndDate ;
INTO TABLE (gcFundCode+"_HS_Claim_line")
*
SELECT serv_type, SUM(IIF(workdays <= 1, 1, 0)) AS day_1, ;
	SUM(IIF(workdays = 2, 1, 0)) AS day_2, SUM(IIF(workdays = 3, 1, 0)) AS day_3, ;	
	SUM(IIF(workdays = 4, 1, 0)) AS day_4, SUM(IIF(workdays = 5, 1, 0)) AS day_5, ;	
	SUM(IIF(workdays = 6, 1, 0)) AS day_6, SUM(IIF(workdays >= 7 AND workdays <= 10, 1, 0)) AS day_7, ;	
	SUM(IIF(workdays > 10, 1, 0)) AS day_11 ;
FROM (gcFundCode+"_HS_Claim_Month") ;
GROUP BY 1 ;
WHERE status $ "DP" AND result # "P5" ;
	AND EMPTY(unclean) ;
INTO TABLE aging
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
FROM (gcFundCode+"_HS_Claim_Month") ;
WHERE notify_dat BETWEEN gtCurDate AND gtEndDate ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc_m
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, family_no, plan, serv_type, status, count(*) AS amt ;
FROM (gcFundCode+"_HS_Claim_Month") ;
WHERE notify_dat BETWEEN gtCurDate AND gtEndDate ;
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
INTO TABLE (gcFundCode+"_HS_PlanbyService_Month")
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
FROM (gcFundCode+"_HS_Claim") ;
WHERE admis_date BETWEEN gtStartDate AND gtEndDate ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, family_no, plan, serv_type, status, count(*) AS amt ;
FROM (gcFundCode+"_HS_Claim") ;
WHERE admis_date BETWEEN gtStartDate AND gtEndDate ;
GROUP BY policy_no, family_no, plan, serv_type, status ;
INTO CURSOR per_pol
*
SELECT plan, SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status = "P",  1, 0)) AS ipd_nmc, ;
	SUM(IIF(status $ "AW",  1, 0)) AS w_nmc ;
FROM per_pol ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR nmc
*
SELECT nmc.plan, noc.opd_noc, nmc.opd_nmc, noc.d_o_noc, noc.ipd_noc, nmc.ipd_nmc, noc.d_i_noc, ;
	noc.opd_paid, noc.ipd_paid, noc.e_o_noc, noc.e_i_noc, noc.out_o_noc, noc.out_o_paid, noc.out_i_noc, noc.out_i_paid, ;
	noc.d_o_paid, noc.d_i_paid, noc.e_o_paid, noc.e_i_paid, nmc.w_nmc, ;	
	IIF(nmc.opd_nmc # 0 AND noc.opd_noc # 0, noc.opd_noc/nmc.opd_nmc,0) AS opd_acf, ;
	IIF(nmc.ipd_nmc # 0 AND noc.ipd_noc # 0,  noc.ipd_noc/nmc.ipd_nmc,0) AS ipd_acf, ;
	IIF(noc.opd_noc # 0 AND noc.opd_paid # 0, (noc.opd_paid+noc.e_o_paid)/noc.opd_noc, 0) AS opd_loss, ;
	IIF(noc.ipd_noc # 0 AND noc.ipd_paid # 0, (noc.ipd_paid+noc.e_i_paid)/noc.ipd_noc, 0) AS ipd_loss ;			
FROM noc INNER JOIN nmc ;
	ON noc.plan = nmc.plan ;
ORDER BY 1 ;
INTO CURSOR _SumType1
*
SELECT _SumMember.plan, _SumMember.nom_year, _SumMember.eqa_year, _SumMember.ep_year, ;
	_SumType1.opd_noc, _SumType1.opd_nmc, ;
	_SumType1.opd_acf, _SumType1.d_o_noc, ;
	_SumType1.ipd_noc, _SumType1.ipd_nmc, ;
	_SumType1.ipd_acf, _SumType1.d_i_noc, ;	
	_SumType1.opd_noc AS opd_noc1, _SumType1.opd_paid, _SumType1.e_o_paid, ;
	_SumType1.opd_loss, ;
	_SumType1.ipd_noc AS ipd_noc1, _SumType1.ipd_paid, _SumType1.e_i_paid, ;
	_SumType1.ipd_loss, ;	
	_SumType1.w_nmc, _SumType1.out_o_noc+_SumType1.out_i_noc AS w_noc, ;
	_SumType1.out_o_paid+_SumType1.out_i_paid AS w_paid, ;
	_SumType1.out_o_noc, _SumType1.out_i_noc ;	
FROM _SumType1 INNER JOIN _SumMember ;
	ON _SumType1.plan = _SumMember.plan ;
ORDER BY 1 ;		
INTO TABLE (gcFundCode+"_HS_PlanbyService_Year")
*
SELECT plan, ;
	IIF(opd_noc # 0, opd_noc/eqa_year, 0) AS o_mir, ;
	IIF(ipd_noc # 0, ipd_noc/eqa_year, 0) AS i_mir, ;
	IIF(opd_noc # 0 AND opd_nmc # 0, opd_noc/opd_nmc, 0) AS o_cir, ;
	IIF(ipd_noc # 0 AND ipd_nmc # 0, ipd_noc/ipd_nmc, 0) AS i_cir, ;
	opd_noc, ipd_noc, opd_nmc, ipd_nmc, eqa_year, out_o_noc, out_i_noc ;
FROM (gcFundCode+"_HS_PlanbyService_Year") ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_HS_Utilization")	
**********************************
PROCEDURE Q_PlanbyCategory

SELECT plan_type, catcode, ;
	SUM(charge) AS charge, ;
	SUM(paid) AS paid, ;
	SUM(exgratia) AS exgratia, ;
	SUM(IIF(LEFT(result,1) = "P" AND paid # 0, 1, 0)) AS noc ;
FROM (gcFundCode+"_HS_Claim_line") ;
WHERE LEFT(result,1) = "P" ;
GROUP BY plan_type, catcode ;
ORDER BY plan_type ;
INTO TABLE (gcFundCode+"_HS_PlanbyCategory_Year")
*
SELECT plan, catcode, ;
	SUM(charge) AS charge, ;
	SUM(paid) AS paid, ;
	SUM(exgratia) AS exgratia, ;
	SUM(IIF(paid # 0 OR exgratia # 0, 1, 0)) AS noc ;
FROM (gcFundCode+"_HS_Claim_line") ;
WHERE admis_date BETWEEN gtCurDate AND gtEndDate ;
GROUP BY plan, catcode ;
ORDER BY plan ;
INTO TABLE (gcFundCode+"_HS_PlanbyCategory_Month")
*
*End Query Claim by service