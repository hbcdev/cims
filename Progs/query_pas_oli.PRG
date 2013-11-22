PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption
	
SET SAFETY OFF 	
********************
gcStartDate = "Start Date"
gcEndDate = "End Date"
glMonth = .F.	
gcFundCode = "OLI"
gdEndDate = DATE() - DAY(DATE())
gdStartDate = gdEndDate - IIF(MOD(YEAR(gdEndDate),4) = 0, 366, 365)+1
gdStartDate = IIF(gdStartDate < {^2004-9-16}, {^2004-9-16}, gdStartDate)
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
DO q_member
DO q_claim
DO q_Planbyservice_Month
DO q_planbycause_month
DO q_planbycause_year
DO q_provincebycause_month
DO q_provincebycause_year
DO query_rolling
*************************
SET TALK OFF 
SET DEFAULT TO (lcOldDir)
*************************
PROCEDURE q_Member
*
SELECT Member.tpacode, Member.policy_no, Member.product AS plan, IIF(Member.customer_type = "P", "PA", "HS") AS plan_type, ;
	Member.effective, Member.expiry, Member.premium, Member.premium/(365.25*5) AS prem_day, ;
	Member.branch_code, Member.l_city AS province ;
 FROM cims!Member ;
 WHERE Member.tpacode = gcFundCode ;
   AND Member.expiry >= gtStartDate ;
   AND customer_type = "P" ;
   AND RIGHT(ALLTRIM(product),1) = "S" ;
 INTO CURSOR Q_member
*
SELECT tpacode, policy_no, plan, effective, expiry, premium, prem_day, branch_code, province, ;	
	IIF(effective >= gtCurDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtCurDate AND expiry >= gtCurDate, TTOD(gtCurDate), {})) AS start_month, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry >= gtCurDate AND expiry <= gtEndDate, TTOD(expiry), {})) AS end_month, ;
	IIF(effective >= gtStartDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtStartDate AND expiry >= gtStartDate, gdStartDate, {})) AS start_roll, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry <= gtEndDate, TTOD(expiry), {})) AS end_roll, ;
	((gdEndDate - gdStartDate)+1) AS p_year ;
 FROM Q_member ;
INTO CURSOR Q_memb
*
SELECT tpacode, policy_no, plan, effective, expiry, premium, prem_day, branch_code, province, p_year, ;
	start_month, end_month, IIF(EMPTY(start_month), 000, 1) AS m_nominal, ;
	IIF(EMPTY(start_month), 000, (end_month-start_month)+1) AS m_days, ;
	IIF(EMPTY(start_month), 0000.0000, ((end_month-start_month)+1)/((gdEndDate - gdCurDate)+1)) AS eqa_month, ;
	IIF(EMPTY(start_month), 0000.0000, ((end_month-start_month)+1)*prem_day) AS ep_month, ;	
	start_roll, end_roll, IIF(EMPTY(start_roll), 000, 1) AS y_nominal, ;
	IIF(EMPTY(start_roll), 000, (end_roll-start_roll)+1) AS y_days, ;	
	IIF(EMPTY(start_roll), 0000000.0000, (((end_roll-start_roll)+1)/p_year)) AS eqa_year, ;
	IIF(EMPTY(start_roll), 0000000.0000, ((end_roll-start_roll)+1)*prem_day) AS ep_year ;	
FROM Q_memb ;	
INTO TABLE (gcFundCode+"_PAS_member")	
*
SELECT plan, ;
	SUM(m_nominal) AS nom_month, SUM(eqa_month) AS eqa_month, SUM(ep_month) AS ep_month, ;
	SUM(y_nominal) AS nom_year, SUM(eqa_year) AS eqa_year, SUM(ep_year) AS ep_year ;
FROM (gcFundcode+"_PAS_member") ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR _SumbyPlan	
*	
SELECT province, ;
	SUM(m_nominal) AS nom_month, SUM(eqa_month) AS eqa_month, SUM(ep_month) AS ep_month, ;
	SUM(y_nominal) AS nom_year, SUM(eqa_year) AS eqa_year, SUM(ep_year) AS ep_year ;
FROM (gcFundcode+"_PAS_member") ;
GROUP BY province ;
ORDER BY province ;
INTO CURSOR _SumbyProv
*********************************************************
*
PROCEDURE q_Claim
*
SELECT Claim.notify_no, Claim.notify_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS serv_type, Claim.cause_type, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, Claim.client_name, Claim.plan, IIF(Claim.claim_with = "P", "PA", "HS") AS plan_type, ;
	Claim.admis_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, ;
	IIF(EMPTY(Claim.fax_by), abenfpaid, exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid) AS paid, ;
	LEFT(result,1) AS status, Claim.result, Claim.return_date, Claim.unclean, Claim.unclean_note, Claim.branch, Claim.agent_province AS province, ;
	RIGHT(STR(YEAR(admis_date),4),2)+ "-"+STRTRAN(STR(MONTH(admis_date),2)," ","0") AS admis_m, ;  
	RIGHT(STR(YEAR(notify_date),4),2)+ "-"+STRTRAN(STR(MONTH(notify_date),2)," ","0") AS notify_m, ;  	
	((return_date-TTOD(notify_date)) - holidays(TTOD(notify_date), return_date))-1 AS workdays ;	
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.claim_with = "P" ;
	AND RIGHT(ALLTRIM(Claim.plan),1) = "S" ;	
	AND Claim.notify_date BETWEEN gtStartDate AND gtEndDate ;
	AND Claim.result # "C" ;
INTO TABLE (gcFundCode+"_PAS_claim")
*
SELECT plan_type, admis_m, ;
	SUM(paid) AS admit_paid ;
FROM (gcFundCode+"_PAS_claim") ;
WHERE admis_date BETWEEN gtStartDate AND gtEndDate ;
	AND status = "P" ;
GROUP BY admis_m ;
ORDER BY 1 ;
INTO CURSOR paclaim_admit &&TABLE (gcFundCode+"_PAclaim_Admit")
*
DO GenTab WITH "PAClaim_admit", "plan_type", "admis_m", "admit_paid", gcFundCode+"_PASclaim_Admit"
*
SELECT plan_type, notify_m, ;
	SUM(paid) AS notify_paid ;
FROM (gcFundCode+"_PAS_claim") ;
WHERE notify_dat BETWEEN gtStartDate AND gtEndDate ;
	AND status = "P" ;
GROUP BY notify_m ;
ORDER BY 1 ;
INTO CURSOR paclaim_not

DO GenTab WITH "PAClaim_not", "plan_type", "notify_m", "notify_paid", gcFundCode+"_PASclaim_notify"
*
*****************************************************************
*Query Current Month Report
*
SELECT Claim.notify_no, Claim.notify_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS serv_type, Claim.cause_type, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, Claim.client_name, Claim.plan, ;
	Claim.admis_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, ;
	IIF(EMPTY(Claim.fax_by), abenfpaid, exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid) AS paid, ;
	LEFT(result,1) AS status, Claim.result, Claim.return_date, Claim.unclean, Claim.unclean_note, Claim.branch, ;
	Claim.agent_province AS province, ((return_date-TTOD(notify_date)) - holidays(TTOD(notify_date), return_date))-1 AS workdays ;	
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.claim_with = "P" ;	
	AND RIGHT(ALLTRIM(Claim.plan),1) = "S" ;		
	AND Claim.notify_date BETWEEN gtCurDate AND gtEndDate ;
	AND LEFT(claim.result,1) # "C" ;
INTO TABLE (gcFundCode+"_PAS_claimMonth")
**
SELECT plan, ;
	SUM(IIF(admis_date >= gtCurDate AND admis_date <= gtEndDate, paid, 0)) AS admit_paid, ;
	SUM(IIF(notify_dat >= gtCurDate AND notify_dat <= gtEndDate, paid, 0)) AS notify_paid ;
FROM (gcFundCode+"_PAS_claimMonth") ;
WHERE status = "P" ;
GROUP BY plan ;
INTO TABLE (gcFundCode+"_PAS_claim_Sum_Month")
*
SELECT serv_type, SUM(IIF(workdays <= 1, 1, 0)) AS day_1, ;
	SUM(IIF(workdays = 2, 1, 0)) AS day_2, SUM(IIF(workdays = 3, 1, 0)) AS day_3, ;	
	SUM(IIF(workdays = 4, 1, 0)) AS day_4, SUM(IIF(workdays = 5, 1, 0)) AS day_5, ;	
	SUM(IIF(workdays = 6, 1, 0)) AS day_6, SUM(IIF(workdays >= 7 AND workdays <= 10, 1, 0)) AS day_7, ;	
	SUM(IIF(workdays > 10, 1, 0)) AS day_11 ;
FROM (gcFundCode+"_PAS_claimMonth") ;
GROUP BY 1 ;
WHERE status $ "DP" ;
	AND result # "P5" ;
	AND EMPTY(unclean) ;
INTO TABLE PAS_aging
********************************
PROCEDURE Q_PlanbyCause_Month

SELECT plan, ;
	SUM(IIF(cause_type = "ME" AND status = "P", 1, 0)) AS me_p_noc, ;
	SUM(IIF(cause_type = "ME" AND status = "P", paid, 0)) AS me_p_paid, ;
	SUM(IIF(cause_type = "MC" AND status = "P", 1, 0)) AS mc_p_noc, ;
	SUM(IIF(cause_type = "MC" AND status = "P", paid, 0)) AS mc_p_paid, ;
	SUM(IIF(cause_type = "PMC" AND status = "P", 1, 0)) AS pmc_p_noc, ;
	SUM(IIF(cause_type = "PMC" AND status = "P", paid, 0)) AS pmc_p_paid, ;	
	SUM(IIF(cause_type = "PMR" AND status = "P", 1, 0)) AS pmr_p_noc, ;
	SUM(IIF(cause_type = "PMR" AND status = "P", paid, 0)) AS pmr_p_paid, ;
	SUM(IIF(cause_type = "PMW" AND status = "P", 1, 0)) AS pmw_p_noc, ;
	SUM(IIF(cause_type = "PMW" AND status = "P", paid, 0)) AS pmw_p_paid, ;
	SUM(IIF(cause_type = "PMA" AND status = "P", 1, 0)) AS pma_p_noc, ;
	SUM(IIF(cause_type = "PMA" AND status = "P", paid, 0)) AS pma_p_paid, ;
	SUM(IIF(cause_type = "PMS" AND status = "P", 1, 0)) AS pms_p_noc, ;
	SUM(IIF(cause_type = "PMS" AND status = "P", paid, 0)) AS pms_p_paid, ;
	SUM(IIF(cause_type = "PMK" AND status = "P", 1, 0)) AS pmk_p_noc, ;
	SUM(IIF(cause_type = "PMK" AND status = "P", paid, 0)) AS pmk_p_paid, ;
	SUM(IIF(cause_type = "MA" AND status = "P", 1, 0)) AS ma_p_noc, ;
	SUM(IIF(cause_type = "MA" AND status = "P", paid, 0)) AS ma_p_paid, ;
	SUM(IIF(cause_type = "PWA" AND status = "P", 1, 0)) AS pwa_p_noc, ;
	SUM(IIF(cause_type = "PWA" AND status = "P", paid, 0)) AS pwa_p_paid, ;
	SUM(IIF(status $ "AW", 1, 0)) AS w_noc ;
FROM (gcFundCode+"_PAS_claimMonth") ;
WHERE notify_dat BETWEEN gtCurDate AND gtEndDate ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR _planbycause
*
SELECT _SumbyPlan.plan, _Sumbyplan.nom_month, _SumbyPlan.eqa_month, _SumbyPlan.ep_month, ;
	_planbycause.me_p_noc, _planbycause.me_p_paid, _planbycause.mc_p_noc, _planbycause.mc_p_paid, _planbycause.pmc_p_noc, _planbycause.pmc_p_paid, ;	
	_planbycause.pmr_p_noc, _planbycause.pmr_p_paid, _planbycause.pmw_p_noc, _planbycause.pmw_p_paid, _planbycause.pma_p_noc, _planbycause.pma_p_paid, ;
	_planbycause.pms_p_noc, _planbycause.pms_p_paid, _planbycause.pmk_p_noc, _planbycause.pmk_p_paid, _planbycause.ma_p_noc, _planbycause.ma_p_paid, ;
	_planbycause.pwa_p_noc, pwa_p_paid, ;
	_planbycause.me_p_noc+_planbycause.mc_p_noc+_planbycause.pmc_p_noc+_planbycause.pmr_p_noc+_planbycause.pmw_p_noc+;
	_planbycause.pma_p_noc+_planbycause.pms_p_noc+_planbycause.pmk_p_noc+_planbycause.ma_p_noc+_planbycause.pwa_p_noc AS total_case, ;	
	_planbycause.me_p_paid+_planbycause.mc_p_paid+_planbycause.pmc_p_paid+_planbycause.pmr_p_paid+_planbycause.pmw_p_paid+;
	_planbycause.pma_p_paid+_planbycause.pms_p_paid+_planbycause.pmk_p_paid+_planbycause.ma_p_paid+_planbycause.pwa_p_paid AS total_paid, ;	
	w_noc ;
FROM _planbycause RIGHT JOIN _SumbyPlan ;
	ON _planbycause.plan = _SumbyPlan.plan ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_PlanByCause_Months")
*
**********************************************************************
PROCEDURE Q_PlanbyCause_Year
*
SELECT plan, ;
	SUM(IIF(cause_type = "ME" AND status = "P", 1, 0)) AS me_p_noc, ;
	SUM(IIF(cause_type = "ME" AND status = "P", paid, 0)) AS me_p_paid, ;
	SUM(IIF(cause_type = "MC" AND status = "P", 1, 0)) AS mc_p_noc, ;
	SUM(IIF(cause_type = "MC" AND status = "P", paid, 0)) AS mc_p_paid, ;
	SUM(IIF(cause_type = "PMC" AND status = "P", 1, 0)) AS pmc_p_noc, ;
	SUM(IIF(cause_type = "PMC" AND status = "P", paid, 0)) AS pmc_p_paid, ;	
	SUM(IIF(cause_type = "PMR" AND status = "P", 1, 0)) AS pmr_p_noc, ;
	SUM(IIF(cause_type = "PMR" AND status = "P", paid, 0)) AS pmr_p_paid, ;
	SUM(IIF(cause_type = "PMW" AND status = "P", 1, 0)) AS pmw_p_noc, ;
	SUM(IIF(cause_type = "PMW" AND status = "P", paid, 0)) AS pmw_p_paid, ;
	SUM(IIF(cause_type = "PMA" AND status = "P", 1, 0)) AS pma_p_noc, ;
	SUM(IIF(cause_type = "PMA" AND status = "P", paid, 0)) AS pma_p_paid, ;
	SUM(IIF(cause_type = "PMS" AND status = "P", 1, 0)) AS pms_p_noc, ;
	SUM(IIF(cause_type = "PMS" AND status = "P", paid, 0)) AS pms_p_paid, ;
	SUM(IIF(cause_type = "PMK" AND status = "P", 1, 0)) AS pmk_p_noc, ;
	SUM(IIF(cause_type = "PMK" AND status = "P", paid, 0)) AS pmk_p_paid, ;
	SUM(IIF(cause_type = "MA" AND status = "P", 1, 0)) AS ma_p_noc, ;
	SUM(IIF(cause_type = "MA" AND status = "P", paid, 0)) AS ma_p_paid, ;
	SUM(IIF(cause_type = "PWA" AND status = "P", 1, 0)) AS pwa_p_noc, ;
	SUM(IIF(cause_type = "PWA" AND status = "P", paid, 0)) AS pwa_p_paid, ;
	SUM(IIF(status $ "AW", 1, 0)) AS w_noc ;
FROM (gcFundCode+"_PAS_claim") ;
WHERE admis_date BETWEEN gtStartDate AND gtEndDate ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR _planbycause
*
SELECT _Sumbyplan.plan, _Sumbyplan.nom_year, _SumbyPlan.eqa_year, _SumbyPlan.ep_year, ;
	_planbycause.me_p_noc, _planbycause.me_p_paid, _planbycause.mc_p_noc, _planbycause.mc_p_paid, _planbycause.pmc_p_noc, _planbycause.pmc_p_paid, ;	
	_planbycause.pmr_p_noc, _planbycause.pmr_p_paid, _planbycause.pmw_p_noc, _planbycause.pmw_p_paid, _planbycause.pma_p_noc, _planbycause.pma_p_paid, ;
	_planbycause.pms_p_noc, _planbycause.pms_p_paid, _planbycause.pmk_p_noc, _planbycause.pmk_p_paid, _planbycause.ma_p_noc, _planbycause.ma_p_paid, ;
	_planbycause.pwa_p_noc, pwa_p_paid, ;
	_planbycause.me_p_noc+_planbycause.mc_p_noc+_planbycause.pmc_p_noc+_planbycause.pmr_p_noc+_planbycause.pmw_p_noc+;
	_planbycause.pma_p_noc+_planbycause.pms_p_noc+_planbycause.pmk_p_noc+_planbycause.ma_p_noc+_planbycause.pwa_p_noc AS total_case, ;
	_planbycause.me_p_paid+_planbycause.mc_p_paid+_planbycause.pmc_p_paid+_planbycause.pmr_p_paid+_planbycause.pmw_p_paid+;
	_planbycause.pma_p_paid+_planbycause.pms_p_paid+_planbycause.pmk_p_paid+_planbycause.ma_p_paid+_planbycause.pwa_p_paid AS total_paid, ;	
	_planbycause.w_noc ;
FROM _planbycause RIGHT JOIN _SumbyPlan ;
	ON _planbycause.plan = _SumbyPlan.plan ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_PlanByCause_Years")
**
*************************************************
PROCEDURE Q_PlanbyService_Month
*************Query plan By service 
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
FROM (gcFundCode+"_PAS_claimMonth") ;
WHERE notify_dat BETWEEN gtCurDate AND gtEndDate ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc_m
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, family_no, plan, serv_type, status, count(*) AS amt ;
FROM (gcFundCode+"_PAS_claimMonth") ;
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
	noc_m.d_o_paid, noc_m.d_i_paid, noc_m.e_o_paid, noc_m.e_i_paid, nmc_m.w_opd_nmc, nmc_m.w_ipd_nmc ;
FROM noc_m INNER JOIN nmc_m ;
	ON noc_m.plan = nmc_m.plan ;
ORDER BY 1 ;
INTO CURSOR _SumType
*
SELECT _Sumbyplan.plan, _Sumbyplan.nom_month, _SumbyPlan.eqa_month, _SumbyPlan.ep_month, ;
	_SumType.opd_nmc, _SumType.opd_noc, _SumType.opd_paid, _SumType.e_o_paid, _SumType.d_o_noc, ;
	_SumType.ipd_nmc, _SumType.ipd_noc, _SumType.ipd_paid, _SumType.e_i_paid, _SumType.d_i_noc, ;
	_SumType.w_opd_nmc+_SumType.w_ipd_nmc AS w_nmc, _SumType.out_o_noc+_SumType.out_i_noc AS w_noc, ;
	_SumType.out_o_paid+_Sumtype.out_i_paid AS w_paid ;
FROM _SumType RIGHT JOIN _SumbyPlan ;
	ON _SumType.plan = _SumbyPlan.plan ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_PAS_Planbyservice_Months")	
*****************************************
*End Query Current Month Report

*******************************************
PROCEDURE Q_ProvincebyCause_Month
*
* Query By accident date for this month
SELECT province, ; 
	SUM(IIF(cause_type = "ME" AND status = "P", 1, 0)) AS me_p_noc, ;
	SUM(IIF(cause_type = "ME" AND status = "P", paid, 0)) AS me_p_paid, ;
	SUM(IIF(cause_type = "MC" AND status = "P", 1, 0)) AS mc_p_noc, ;
	SUM(IIF(cause_type = "MC" AND status = "P", paid, 0)) AS mc_p_paid, ;
	SUM(IIF(cause_type = "PMC" AND status = "P", 1, 0)) AS pmc_p_noc, ;
	SUM(IIF(cause_type = "PMC" AND status = "P", paid, 0)) AS pmc_p_paid, ;	
	SUM(IIF(cause_type = "PMR" AND status = "P", 1, 0)) AS pmr_p_noc, ;
	SUM(IIF(cause_type = "PMR" AND status = "P", paid, 0)) AS pmr_p_paid, ;
	SUM(IIF(cause_type = "PMW" AND status = "P", 1, 0)) AS pmw_p_noc, ;
	SUM(IIF(cause_type = "PMW" AND status = "P", paid, 0)) AS pmw_p_paid, ;
	SUM(IIF(cause_type = "PMA" AND status = "P", 1, 0)) AS pma_p_noc, ;
	SUM(IIF(cause_type = "PMA" AND status = "P", paid, 0)) AS pma_p_paid, ;
	SUM(IIF(cause_type = "PMS" AND status = "P", 1, 0)) AS pms_p_noc, ;
	SUM(IIF(cause_type = "PMS" AND status = "P", paid, 0)) AS pms_p_paid, ;
	SUM(IIF(cause_type = "PMK" AND status = "P", 1, 0)) AS pmk_p_noc, ;
	SUM(IIF(cause_type = "PMK" AND status = "P", paid, 0)) AS pmk_p_paid, ;
	SUM(IIF(cause_type = "MA" AND status = "P", 1, 0)) AS ma_p_noc, ;
	SUM(IIF(cause_type = "MA" AND status = "P", paid, 0)) AS ma_p_paid, ;
	SUM(IIF(cause_type = "PWA" AND status = "P", 1, 0)) AS pwa_p_noc, ;
	SUM(IIF(cause_type = "PWA" AND status = "P", paid, 0)) AS pwa_p_paid, ;
	SUM(IIF(status $ "AW", 1, 0)) AS w_noc ;
FROM (gcFundCode+"_PAS_claimMonth") ;
WHERE notify_dat BETWEEN gtCurDate AND gtEndDate ;
GROUP BY province ;
ORDER BY province ;
INTO CURSOR _provbycause
*
SELECT _Sumbyprov.province, _Sumbyprov.nom_month, _SumbyProv.eqa_month, _SumbyProv.ep_month, ;
	_provbycause.me_p_noc, _provbycause.me_p_paid, _provbycause.mc_p_noc, _provbycause.mc_p_paid, _provbycause.pmc_p_noc, _provbycause.pmc_p_paid, ;	
	_provbycause.pmr_p_noc, _provbycause.pmr_p_paid, _provbycause.pmw_p_noc, _provbycause.pmw_p_paid, _provbycause.pma_p_noc, _provbycause.pma_p_paid, ;
	_provbycause.pms_p_noc, _provbycause.pms_p_paid, _provbycause.pmk_p_noc, _provbycause.pmk_p_paid, _provbycause.ma_p_noc, _provbycause.ma_p_paid, ;
	_provbycause.pwa_p_noc, pwa_p_paid, ;
	_provbycause.me_p_noc+_provbycause.mc_p_noc+_provbycause.pmc_p_noc+_provbycause.pmr_p_noc+_provbycause.pmw_p_noc+;
	_provbycause.pma_p_noc+_provbycause.pms_p_noc+_provbycause.pmk_p_noc+_provbycause.ma_p_noc+_provbycause.pwa_p_noc AS total_case, ;
	_provbycause.me_p_paid+_provbycause.mc_p_paid+_provbycause.pmc_p_paid+_provbycause.pmr_p_paid+_provbycause.pmw_p_paid+;
	_provbycause.pma_p_paid+_provbycause.pms_p_paid+_provbycause.pmk_p_paid+_provbycause.ma_p_paid+_provbycause.pwa_p_paid AS total_paid, ;	
	w_noc ;
FROM _provbycause RIGHT JOIN _SumbyProv ;
	ON _provbycause.province = _SumbyProv.province ;
ORDER BY 1 ;
INTO CURSOR _SumProvbyCause
*
SELECT province, nom_month, eqa_month, ep_month, ;
	me_p_noc, me_p_paid, mc_p_noc, mc_p_paid, pmc_p_noc, pmc_p_paid, ;	
	pmr_p_noc, pmr_p_paid, pmw_p_noc, pmw_p_paid, pma_p_noc, pma_p_paid, ;
	pms_p_noc, pms_p_paid, pmk_p_noc, pmk_p_paid, ma_p_noc, ma_p_paid, ;
	pwa_p_noc, pwa_p_paid, total_case, total_paid, w_noc, total_paid/ep_month AS loss_ratio ;
FROM _Sumprovbycause ;
WHERE me_p_noc # 0 OR mc_p_noc # 0 OR pmc_p_noc # 0 OR pmr_p_noc # 0 OR pmw_p_noc # 0 ;
	OR pma_p_noc # 0 OR pms_p_noc # 0 OR pmk_p_noc # 0 OR ma_p_noc # 0 ; 
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_PAS_ProvinceByCause_months")
*
*********************************************************************
PROCEDURE Q_ProvincebyCause_Year
*
SELECT province, ; 
	SUM(IIF(cause_type = "ME" AND status = "P", 1, 0)) AS me_p_noc, ;
	SUM(IIF(cause_type = "ME" AND status = "P", paid, 0)) AS me_p_paid, ;
	SUM(IIF(cause_type = "MC" AND status = "P", 1, 0)) AS mc_p_noc, ;
	SUM(IIF(cause_type = "MC" AND status = "P", paid, 0)) AS mc_p_paid, ;
	SUM(IIF(cause_type = "PMC" AND status = "P", 1, 0)) AS pmc_p_noc, ;
	SUM(IIF(cause_type = "PMC" AND status = "P", paid, 0)) AS pmc_p_paid, ;	
	SUM(IIF(cause_type = "PMR" AND status = "P", 1, 0)) AS pmr_p_noc, ;
	SUM(IIF(cause_type = "PMR" AND status = "P", paid, 0)) AS pmr_p_paid, ;
	SUM(IIF(cause_type = "PMW" AND status = "P", 1, 0)) AS pmw_p_noc, ;
	SUM(IIF(cause_type = "PMW" AND status = "P", paid, 0)) AS pmw_p_paid, ;
	SUM(IIF(cause_type = "PMA" AND status = "P", 1, 0)) AS pma_p_noc, ;
	SUM(IIF(cause_type = "PMA" AND status = "P", paid, 0)) AS pma_p_paid, ;
	SUM(IIF(cause_type = "PMS" AND status = "P", 1, 0)) AS pms_p_noc, ;
	SUM(IIF(cause_type = "PMS" AND status = "P", paid, 0)) AS pms_p_paid, ;
	SUM(IIF(cause_type = "PMK" AND status = "P", 1, 0)) AS pmk_p_noc, ;
	SUM(IIF(cause_type = "PMK" AND status = "P", paid, 0)) AS pmk_p_paid, ;
	SUM(IIF(cause_type = "MA" AND status = "P", 1, 0)) AS ma_p_noc, ;
	SUM(IIF(cause_type = "MA" AND status = "P", paid, 0)) AS ma_p_paid, ;
	SUM(IIF(cause_type = "PWA" AND status = "P", 1, 0)) AS pwa_p_noc, ;
	SUM(IIF(cause_type = "PWA" AND status = "P", paid, 0)) AS pwa_p_paid, ;
	SUM(IIF(status $ "AW", 1, 0)) AS w_noc ;
FROM (gcFundCode+"_PAS_claim") ;
WHERE admis_date BETWEEN gtStartDate AND gtEndDate ;
	AND status = "P" ;
GROUP BY province ;
ORDER BY province ;
INTO CURSOR _provbycause
*
SELECT _Sumbyprov.province, _Sumbyprov.nom_year, _SumbyProv.eqa_year, _SumbyProv.ep_year, ;
	_provbycause.me_p_noc, _provbycause.me_p_paid, _provbycause.mc_p_noc, _provbycause.mc_p_paid, _provbycause.pmc_p_noc, _provbycause.pmc_p_paid, ;	
	_provbycause.pmr_p_noc, _provbycause.pmr_p_paid, _provbycause.pmw_p_noc, _provbycause.pmw_p_paid, _provbycause.pma_p_noc, _provbycause.pma_p_paid, ;
	_provbycause.pms_p_noc, _provbycause.pms_p_paid, _provbycause.pmk_p_noc, _provbycause.pmk_p_paid, _provbycause.ma_p_noc, _provbycause.ma_p_paid, ;
	_provbycause.pwa_p_noc, pwa_p_paid, ;	
	_provbycause.me_p_noc+_provbycause.mc_p_noc+_provbycause.pmc_p_noc+_provbycause.pmr_p_noc+_provbycause.pmw_p_noc+;
	_provbycause.pma_p_noc+_provbycause.pms_p_noc+_provbycause.pmk_p_noc+_provbycause.ma_p_noc+_provbycause.pwa_p_noc AS total_case, ;
	_provbycause.me_p_paid+_provbycause.mc_p_paid+_provbycause.pmc_p_paid+_provbycause.pmr_p_paid+_provbycause.pmw_p_paid+;
	_provbycause.pma_p_paid+_provbycause.pms_p_paid+_provbycause.pmk_p_paid+_provbycause.ma_p_paid+_provbycause.pwa_p_paid AS total_paid, ;	
	_provbycause.w_noc ;
FROM _provbycause RIGHT JOIN _SumbyProv ;
	ON _provbycause.province = _SumbyProv.province ;
ORDER BY 1 ;
INTO CURSOR _SumProvbyCause
*
SELECT province, nom_year, eqa_year, ep_year, ;
	me_p_noc, me_p_paid, mc_p_noc, mc_p_paid, pmc_p_noc, pmc_p_paid, ;	
	pmr_p_noc, pmr_p_paid, pmw_p_noc, pmw_p_paid, pma_p_noc, pma_p_paid, ;
	pms_p_noc, pms_p_paid, pmk_p_noc, pmk_p_paid, ma_p_noc, ma_p_paid, ;
	pwa_p_noc, pwa_p_paid, total_case, total_paid, total_paid/ep_year AS loss_ratio, ;
	w_noc ;
FROM _Sumprovbycause ;
WHERE me_p_noc # 0 OR mc_p_noc # 0 OR pmc_p_noc # 0 OR pmr_p_noc # 0 OR pmw_p_noc # 0 ;
	OR pma_p_noc # 0 OR pms_p_noc # 0 OR pmk_p_noc # 0 OR ma_p_noc # 0 ; 
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_PAS_ProvinceByCause_years")
*
**********************************************************
PROCEDURE Query_rolling

CREATE TABLE (gcFundCode+"_PAS_Rolling") FREE (months C(6), nom Y, eqal Y, ep Y, notifys Y, admit Y)
*
ldStartDate = DATE(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate))
lnDay = ICASE(MONTH(ldStartDate) = 2, IIF(MOD(YEAR(ldStartDate),4) = 0, 29, 28), INLIST(MONTH(ldStartDate), 1,3,5,7,8,10,12), 31, 30)
ldEndDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), lnDay)

DO WHILE ldEndDate < gdEndDate
	lnDay = ICASE(MONTH(ldStartDate) = 2, IIF(MOD(YEAR(ldStartDate),4) = 0, 29, 28), INLIST(MONTH(ldStartDate), 1,3,5,7,8,10,12), 31, 30)
	ldEndDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), lnDay)
	lcFile = "R_"+STRTRAN(DTOC(ldEndDate), "/", "")
	*
	SELECT tpacode, policy_no, plan, effective, expiry, premium, prem_day, branch_code, province, ;	
		IIF(TTOD(effective) >= ldStartDate AND TTOD(effective) <= ldEndDate, TTOD(effective), IIF(TTOD(effective) <= ldStartDate, ldStartDate, {})) AS start_month, ;
		IIF(TTOD(expiry) >= ldEndDate, ldEndDate, IIF(TTOD(expiry) >= ldStartDate AND TTOD(expiry) <= ldEndDate, TTOD(expiry), {})) AS end_month ;
	 FROM Q_member ;
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
	SELECT notify_no, notify_date, IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid) AS paid ;		
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.claim_with = "P" ;
	AND Claim.result = "P" ;
	AND RIGHT(ALLTRIM(plan),1) = "S" ;
	AND TTOD(Claim.notify_date) BETWEEN ldStartDate AND ldEndDate ;			
	INTO CURSOR curClaimN	
	*
	SELECT notify_no, admis_date, IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid) AS paid ;	
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.claim_with = "P" ;
	AND Claim.result = "P" ;
	AND RIGHT(ALLTRIM(plan),1) = "S" ;
	AND TTOD(Claim.admis_date) BETWEEN ldStartDate AND ldEndDate ;				
	INTO CURSOR curClaimM	
	*
	SELECT curClaimM
	SUM paid TO m.admit
	*
	SELECT curClaimN
	SUM paid TO m.notifys	
	m.months = LEFT(CMONTH(ldStartDate),3)+"-"+RIGHT(STR(YEAR(ldStartDate),4),2)
	********************************
	INSERT INTO (gcFundCode+"_PAS_Rolling") FROM MEMVAR 
	*************************************************************************
	ldStartDate = GOMONTH(ldStartDate,1)
	ldStartDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), DAY(ldStartDate))
ENDDO 	
*******************************
*
PROCEDURE Gentab
PARAMETERS tcAlias, tcRow, tcColumn, tcData, tcOutFile
Local oXtab, res

SELECT(tcAlias)

starttime = Seconds()
oXtab = NewObject("FastXtab", "g:\hips_src\progs\FastXtab.prg")
oXtab.cOutFile = tcOutFile
oXtab.nPageField = 0
oXtab.nRowField = tcRow
oXtab.nColField = tcColumn
oXtab.nDataField = tcData

oXtab.lCursorOnly = .F.
oXtab.lDisplayNulls = .F.
oXtab.lBrowseAfter = .F.

oXtab.lCloseTable = .F.
oXtab.RunXtab()
