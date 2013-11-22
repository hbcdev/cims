PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnRolling, ;
	gnOption
	
SET SAFETY OFF 
SET NULL ON 	
SET PROCEDURE TO progs\utility
*******************************
lnConn = SQLCONNECT("CimsDB")
IF lnConn <=0
	=MESSAGEBOX("Cannot connect to SQL Server Please Contact Database Administrator",0)
	RETURN 
ENDIF
*******************************
gcCaption = "PA Monthly Report"
gnAll = 1
gnCover = 1
gnData = 0
gnType = 1
gcStartDate = "Start Date"
gcEndDate = "End Date"
glMonth = .F.	
gcFundCode = "SMG"
gdEndDate = DATE() - DAY(DATE())
gdStartDate = getstartroll(gdEndDate, 12)
gnOption = 1
gnType = 1
gnRolling = 12
gcSaveTo = ADDBS(gcMonthlyReportPath)
DO FORM form\Rollingentry
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
lnDayInRoll = gnRolling*(365.25/12)
gdStartDate = getstartroll(gdEndDate, gnRolling)
gdCurDate = DATE(YEAR(gdEndDate), MONTH(gdEndDate), 1)
gtCurDate = DATETIME(YEAR(gdEndDate), MONTH(gdEndDate), 1, 00, 00)
gtStartDate = DATETIME(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate), 00, 00)
gtEndDate = DATETIME(YEAR(gdEndDate), MONTH(gdEndDate), DAY(gdEndDate), 23, 59)
gcSaveTo = IIF(EMPTY(gcSaveTo), gcTemp, gcSaveTo)
*
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
DO Q_PlanbyCause_Month
DO Q_PlanbyCause_Year
DO Q_ProvincebyCause_Month
DO Q_ProvincebyCause_Year
DO Q_Hospital_Month
DO Q_Hospital_Year
DO q_rolling
DO q_claimrolling
****************
SET TALK OFF 
SET NULL OFF 
SET DEFAULT TO (lcOldDir)
**************************************************************
PROCEDURE q_Member
*
lcSQL = "SELECT [fundcode], [policy_no], [package] AS 'plan', [customer_type], [effective], [expiry], [premium], [branch_code], [agent_name], [agent] "+;
	"FROM [cimsdb].[dbo].[member] WHERE [fundcode] = ?gcFundCode AND [expiry] >= ?gtStartDate AND [polstatus] <> 'C' "
lnSucess = SQLEXEC(lnConn, lcSQL, "curMember")
IF lnSucess = -1
	=MESSAGEBOX("Query Error",0)
	RETURN 
ENDIF 	
*
IF !USED("curMember")
	RETURN 
ENDIF 	
IF RECCOUNT("curMember") = 0
	=MESSAGEBOX("No data query",0)
	RETURN 
ENDIF 	
*		
SELECT fundcode AS tpacode, policy_no, plan, IIF(INLIST(customer_type, "P", "S", "G"), "PA", "HS") AS plan_type, ;
	effective, expiry, premium, YEAR(expiry) - YEAR(effective) AS y_cover, ;
	branch_code, ALLTRIM(agent_name)+"/"+ALLTRIM(agent) AS province ;
FROM curMember ;
INTO CURSOR Q_member
*
lnCurDay = ICASE(MONTH(gdEndDate) = 2, IIF(MOD(YEAR(gdEndDate),4) = 0, 29, 28), INLIST(MONTH(gdEndDate), 1,3,5,7,8,10,12), 31, 30)

SELECT tpacode, policy_no, plan, effective, expiry,  y_cover, branch_code, province,  premium AS gpremium, ;
	IIF(y_cover = 0, 0, premium/y_cover) AS premium, ;	
	IIF(effective >= gtCurDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtCurDate AND expiry >= gtCurDate, TTOD(gtCurDate), {})) AS start_month, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry >= gtCurDate AND expiry <= gtEndDate, TTOD(expiry), {})) AS end_month, ;
	IIF(effective >= gtStartDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtStartDate AND expiry >= gtStartDate, gdStartDate, {})) AS start_roll, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry <= gtEndDate, TTOD(expiry), {})) AS end_roll ;
FROM Q_member ;
INTO CURSOR Q_memb
*
SELECT tpacode, policy_no, plan, effective, expiry, gpremium, premium, y_cover, premium/lnDayInRoll AS prem_day, ;
	branch_code, province, start_month, end_month, IIF(EMPTY(start_month), 000, 1) AS m_nominal, ;
	IIF(EMPTY(start_month), 000, (end_month-start_month)+1) AS m_days, ;
	IIF(EMPTY(start_month), 0000.0000, ((end_month-start_month)+1)/lnCurDay) AS eqa_month, ;
	IIF(EMPTY(start_month), 0000.0000, ((end_month-start_month)+1)*(premium/lnDayInRoll)) AS ep_month, ;	
	start_roll, end_roll, IIF(EMPTY(start_roll), 000, 1) AS y_nominal, ;
	IIF(EMPTY(start_roll), 000, (end_roll-start_roll)+1) AS y_days, ;	
	IIF(EMPTY(start_roll), 0000000.0000, ((end_roll-start_roll)+1)/((gdEndDate - gdStartDate)+1)) AS eqa_year, ;	
	IIF(EMPTY(start_roll), 0000000.0000, ((end_roll-start_roll)+1)*(premium/lnDayInRoll)) AS ep_year ;	
FROM Q_memb ;	
INTO TABLE (gcFundCode+"_PAmember")	
*
SELECT plan, ;
	SUM(m_nominal) AS nom_month, ;
	SUM(IIF(m_nominal = 1, premium, 0)) AS m_premium, ;
	SUM(eqa_month) AS eqa_month, SUM(ep_month) AS ep_month, ;
	SUM(y_nominal) AS nom_year, ;
	SUM(IIF(y_nominal = 1, premium, 0)) AS y_premium, ;	
	SUM(eqa_year) AS eqa_year, SUM(ep_year) AS ep_year ;
FROM (gcFundcode+"_PAmember") ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR _SumMember
*
SELECT plan, ;
	SUM(m_nominal) AS nom_month, ;
	SUM(eqa_month) AS eqa_month, ;
	SUM(IIF(m_nominal = 1, premium, 0)) AS m_premium, ;	
	SUM(ep_month) AS ep_month, ;
	SUM(y_nominal) AS nom_year, ;
	SUM(eqa_year) AS eqa_year, ;
	SUM(IIF(y_nominal = 1, premium, 0)) AS y_premium, ;		
	SUM(ep_year) AS ep_year ;
FROM (gcFundcode+"_PAmember") ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR _SumbyPlan	
*	
SELECT province, ;
	SUM(m_nominal) AS nom_month, SUM(eqa_month) AS eqa_month, SUM(ep_month) AS ep_month, ;
	SUM(y_nominal) AS nom_year, SUM(eqa_year) AS eqa_year, SUM(ep_year) AS ep_year ;
FROM (gcFundcode+"_PAmember") ;
GROUP BY province ;
ORDER BY province ;
INTO CURSOR _SumbyProv
*
*********************************************************
*
PROCEDURE q_Claim
*
SELECT Claim.notify_no, Claim.notify_date, Claim.followup, Claim.claim_date, IIF(inlist(Claim.service_type, "IPD", "IFO"), "IPD", "OPD") AS serv_type, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, SUBSTR(Claim.customer_id,4) AS client_no, Claim.client_name, Claim.cause_type, ;
	app_no AS plan, LEFT(Claim.plan,2) AS plan_type, Claim.admis_date, Claim.acc_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, ;
	IIF(EMPTY(Claim.fax_by), Claim.abenfpaid, Claim.exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), Claim.scharge, Claim.fcharge) AS charge, ;	
	IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid+Claim.over_respond, Claim.fbenfpaid+Claim.deduc) AS paid, ;
	IIF(EMPTY(Claim.fax_by), Claim.sremain, Claim.fremain) AS remain, ;				
	ALLTRIM(Claim.agent)+"/"+ALLTRIM(Claim.agent_code) AS province, ;	
	IIF(empty(Claim.fax_by), LEFT(result,1), "F") AS status, ;	
	Claim.result, Claim.return_date, Claim.unclean, Claim.unclean_note, Claim.prov_name, ;
	((return_date-TTOD(notify_date)) - holidays(TTOD(notify_date), return_date)) AS workdays, ;	
	Claim.disc_date, Claim.illness1, Claim.illness2, Claim.illness3 ;	
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.result # "C" ;	
	AND Claim.acc_date BETWEEN gtStartDate AND gtEndDate ;	
INTO TABLE (gcFundCode+"_PA_Claim")
**
*Query Current Month Report
*
SELECT Claim.notify_no, Claim.notify_date, Claim.followup, Claim.claim_date, IIF(inlist(Claim.service_type, "IPD", "IFO"), "IPD", "OPD") AS serv_type, Claim.cause_type, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, SUBSTR(Claim.customer_id,4) AS client_no, Claim.client_name, LEFT(Claim.plan,2) AS plan_type, ;
	app_no AS plan, Claim.admis_date, Claim.acc_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, Claim.fax_by, ;
	IIF(EMPTY(Claim.fax_by), Claim.abenfpaid, Claim.exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), Claim.scharge, Claim.fcharge) AS charge, ;
	IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid+Claim.over_respond, Claim.fbenfpaid+Claim.deduc) AS paid, ;
	IIF(EMPTY(Claim.fax_by), Claim.sremain, Claim.fremain) AS remain, ;
	ALLTRIM(Claim.agent)+"/"+ALLTRIM(Claim.agent_code) AS province, ;
	IIF(empty(Claim.fax_by), LEFT(result,1), "F") AS status, ;	
	Claim.result, Claim.return_date, Claim.unclean, Claim.unclean_note, ;
	((return_date-TTOD(notify_date)) - holidays(TTOD(notify_date), return_date)) AS workdays, ;
	Claim.prov_name, Claim.disc_date, Claim.illness1, Claim.illness2, Claim.illness3 ;
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.result # "C" ;
	AND Claim.assessor_date BETWEEN gtCurDate AND gtEndDate ;
INTO TABLE (gcFundCode+"_PA_ClaimMonth")
***
*
SELECT serv_type, SUM(IIF(workdays <= 1, 1, 0)) AS day_1, ;
	SUM(IIF(workdays = 2, 1, 0)) AS day_2, SUM(IIF(workdays = 3, 1, 0)) AS day_3, ;	
	SUM(IIF(workdays = 4, 1, 0)) AS day_4, SUM(IIF(workdays = 5, 1, 0)) AS day_5, ;	
	SUM(IIF(workdays = 6, 1, 0)) AS day_6, SUM(IIF(workdays >= 7 AND workdays <= 10, 1, 0)) AS day_7, ;	
	SUM(IIF(workdays > 10, 1, 0)) AS day_11 ;
FROM (gcFundCode+"_PA_ClaimMonth") ;
GROUP BY 1 ;
WHERE (result = "P1" OR result = "P61" OR result like "D%") ;
	AND EMPTY(unclean) ;
INTO TABLE (gcFundCode+"_PA_Aging")
*
**********************************
PROCEDURE q_PlanbyService_Month
*
SELECT plan, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", paid, 0)) AS opd_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", paid, 0)) AS ipd_paid, ;	
	SUM(IIF(serv_type = "OPD" AND status = "F", 1, 0)) AS opd_fnoc, ;
	SUM(IIF(serv_type = "OPD" AND status = "F", paid, 0)) AS opd_fpaid, ;
	SUM(IIF(serv_type = "IPD" AND status = "F", 1, 0)) AS ipd_fnoc, ;
	SUM(IIF(serv_type = "IPD" AND status = "F", paid, 0)) AS ipd_fpaid, ;		
	SUM(IIF(serv_type = "OPD" AND status $ "AW", 1, 0)) AS out_o_noc, ;	
	SUM(IIF(serv_type = "OPD" AND status $ "AW", paid, 0)) AS out_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW", 1, 0)) AS out_i_noc, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW", paid, 0)) AS out_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND status = "D", 1, 0)) AS d_o_noc, ;	
	SUM(IIF(serv_type = "OPD" AND status = "D", charge, 0)) d_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "D", 1, 0)) AS d_i_noc, ;	
	SUM(IIF(serv_type = "IPD" AND status = "D", charge, 0)) d_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND exgratia # 0, 1, 0)) AS e_o_noc, ;
	SUM(IIF(serv_type = "OPD" AND exgratia # 0, exgratia, 0)) AS e_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND exgratia # 0, 1, 0)) AS e_i_noc, ;
	SUM(IIF(serv_type = "IPD" AND exgratia # 0, exgratia, 0)) AS e_i_paid ;
FROM (gcFundCode+"_PA_ClaimMonth") ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc_m
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, family_no, plan, serv_type, status, ;
count(*) AS amt ;
FROM (gcFundCode+"_PA_ClaimMonth") ;
GROUP BY policy_no, family_no, plan, serv_type, status ;
INTO CURSOR pol_1
*
SELECT plan, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_nmc, ;
	SUM(IIF(serv_type = "OPD" AND status = "F", 1, 0)) AS opd_fnmc, ;	
	SUM(IIF(serv_type = "OPD" AND status $ "AW", 1, 0)) AS w_opd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status = "P",  1, 0)) AS ipd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status = "F",  1, 0)) AS ipd_fnmc, ;	
	SUM(IIF(serv_type = "IPD" and status $ "AW",  1, 0)) AS w_ipd_nmc ;	
FROM pol_1 ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR nmc_m
*
SELECT nmc_m.plan, noc_m.opd_noc, nmc_m.opd_nmc, noc_m.opd_paid, noc_m.opd_fnoc, nmc_m.opd_fnmc, noc_m.opd_fpaid, noc_m.d_o_noc, ;
	noc_m.d_o_paid, noc_m.e_o_noc, noc_m.e_o_paid, noc_m.ipd_noc, nmc_m.ipd_nmc, noc_m.ipd_paid, noc_m.ipd_fnoc, nmc_m.ipd_fnmc, ;
	noc_m.ipd_fpaid, noc_m.d_i_noc, noc_m.d_i_paid, noc_m.e_i_noc, noc_m.e_i_paid, noc_m.out_o_noc, noc_m.out_o_paid, noc_m.out_i_noc, ;
	noc_m.out_i_paid, nmc_m.w_opd_nmc, nmc_m.w_ipd_nmc ;
FROM noc_m INNER JOIN nmc_m ;
	ON noc_m.plan = nmc_m.plan ;
ORDER BY 1 ;
INTO CURSOR _SumType1
*
SELECT _SumType1
COPY TO (gcFundCode+"_Claim_PlanbyService_Month") TYPE XL5 
*
SELECT _SumMember.plan, _SumMember.nom_month, ;
	_SumMember.eqa_month, _SumMember.m_premium AS premium, _SumMember.ep_month, ;
	_SumType.opd_noc, _SumType.opd_nmc, _SumType.opd_paid, _SumType.opd_fnoc, _SumType.opd_fnmc, _SumType.opd_fpaid, ;
	_SumType.e_o_noc, _SumType.e_o_paid, _SumType.d_o_noc, _SumType.d_o_paid, ;
	_SumType.ipd_noc, _SumType.ipd_nmc, _SumType.ipd_paid, _SumType.ipd_fnoc, _SumType.ipd_fnmc, _SumType.ipd_fpaid, ;
	_SumType.e_i_noc, _SumType.e_i_paid, _SumType.d_i_noc, _SumType.d_i_paid, ;
	_SumType.w_opd_nmc+_SumType.w_ipd_nmc AS w_nmc, ;
	_SumType.out_o_noc+_SumType.out_i_noc AS w_noc, _SumType.out_o_paid+_SumType.out_i_paid AS w_paid ;	
FROM _SumType1 _SumType RIGHT JOIN _SumMember ;
	ON _SumType.plan = LEFT(_SumMember.plan,20) ;
ORDER BY 1 ;		
INTO TABLE (gcFundCode+"_PPP_PlanbyService_Month")
*End Query Current Month Report
*
*********************************************
PROCEDURE Q_PlanbyCause_Month
*
SELECT plan, ;
	SUM(IIF(!INLIST(cause_type, "MC", "PMC", "PMR", "PMW", "PMA", "PMS", "PMK", "PWA", "MA") AND status $ "PF", 1, 0)) AS me_p_noc, ;
	SUM(IIF(!INLIST(cause_type, "MC", "PMC", "PMR", "PMW", "PMA", "PMS", "PMK", "PWA", "MA") AND status $ "PF", paid, 0)) AS me_p_paid, ;
	SUM(IIF(cause_type = "MC" AND status $ "PF", 1, 0)) AS mc_p_noc, ;
	SUM(IIF(cause_type = "MC" AND status $ "PF", paid, 0)) AS mc_p_paid, ;
	SUM(IIF(cause_type = "PMC" AND status $ "PF", 1, 0)) AS pmc_p_noc, ;
	SUM(IIF(cause_type = "PMC" AND status $ "PF", paid, 0)) AS pmc_p_paid, ;	
	SUM(IIF(cause_type = "PMR" AND status $ "PF", 1, 0)) AS pmr_p_noc, ;
	SUM(IIF(cause_type = "PMR" AND status $ "PF", paid, 0)) AS pmr_p_paid, ;
	SUM(IIF(cause_type = "PMW" AND status $ "PF", 1, 0)) AS pmw_p_noc, ;
	SUM(IIF(cause_type = "PMW" AND status $ "PF", paid, 0)) AS pmw_p_paid, ;
	SUM(IIF(cause_type = "PMA" AND status $ "PF", 1, 0)) AS pma_p_noc, ;
	SUM(IIF(cause_type = "PMA" AND status $ "PF", paid, 0)) AS pma_p_paid, ;
	SUM(IIF(cause_type = "PMS" AND status $ "PF", 1, 0)) AS pms_p_noc, ;
	SUM(IIF(cause_type = "PMS" AND status $ "PF", paid, 0)) AS pms_p_paid, ;
	SUM(IIF(cause_type = "PMK" AND status $ "PF", 1, 0)) AS pmk_p_noc, ;
	SUM(IIF(cause_type = "PMK" AND status $ "PF", paid, 0)) AS pmk_p_paid, ;
	SUM(IIF(cause_type = "MA" AND status $ "PF", 1, 0)) AS ma_p_noc, ;
	SUM(IIF(cause_type = "MA" AND status $ "PF", paid, 0)) AS ma_p_paid, ;
	SUM(IIF(cause_type = "PWA" AND status $ "PF", 1, 0)) AS pwa_p_noc, ;
	SUM(IIF(cause_type = "PWA" AND status $ "PF", paid, 0)) AS pwa_p_paid, ;
	SUM(IIF(status $ "AW", 1, 0)) AS w_noc, ;
	SUM(IIF(status $ "AW", paid, 0)) AS w_paid ;	
FROM (gcFundCode+"_PA_ClaimMonth") ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR _planbycause
*
SELECT _planbycause
COPY TO (gcFundCode+"_Claim_PlanByCause_Month") TYPE XL5 
*
SELECT _SumMember.plan, _SumMember.nom_month, _SumMember.eqa_month, _SumMember.ep_month, ;
	_planbycause.me_p_noc, _planbycause.me_p_paid, _planbycause.mc_p_noc, _planbycause.mc_p_paid, _planbycause.pmc_p_noc, _planbycause.pmc_p_paid, ;	
	_planbycause.pmr_p_noc, _planbycause.pmr_p_paid, _planbycause.pmw_p_noc, _planbycause.pmw_p_paid, _planbycause.pma_p_noc, _planbycause.pma_p_paid, ;
	_planbycause.pms_p_noc, _planbycause.pms_p_paid, _planbycause.pmk_p_noc, _planbycause.pmk_p_paid, _planbycause.ma_p_noc, _planbycause.ma_p_paid, ;
	_planbycause.pwa_p_noc, pwa_p_paid, ;
	_planbycause.me_p_noc+_planbycause.mc_p_noc+_planbycause.pmc_p_noc+_planbycause.pmr_p_noc+_planbycause.pmw_p_noc+;
	_planbycause.pma_p_noc+_planbycause.pms_p_noc+_planbycause.pmk_p_noc+_planbycause.ma_p_noc+_planbycause.pwa_p_noc AS total_case, ;	
	_planbycause.me_p_paid+_planbycause.mc_p_paid+_planbycause.pmc_p_paid+_planbycause.pmr_p_paid+_planbycause.pmw_p_paid+;
	_planbycause.pma_p_paid+_planbycause.pms_p_paid+_planbycause.pmk_p_paid+_planbycause.ma_p_paid+_planbycause.pwa_p_paid AS total_paid, ;	
	w_noc, w_paid ;
FROM _planbycause RIGHT JOIN _SumMember ;
	ON _planbycause.plan = LEFT(_SumMember.plan,20) ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_PlanByCause_Month")
*
*************************************************************
PROCEDURE Q_ProvincebyCause_Month
*
* Query By accident date for this month
SELECT province, ; 
	SUM(IIF(!INLIST(cause_type, "MC", "PMC", "PMR", "PMW", "PMA", "PMS", "PMK", "PWA", "MA") AND status $ "PF", 1, 0)) AS me_p_noc, ;
	SUM(IIF(!INLIST(cause_type, "MC", "PMC", "PMR", "PMW", "PMA", "PMS", "PMK", "PWA", "MA") AND status $ "PF", paid, 0)) AS me_p_paid, ;
	SUM(IIF(cause_type = "MC" AND status $ "PF", 1, 0)) AS mc_p_noc, ;
	SUM(IIF(cause_type = "MC" AND status $ "PF", paid, 0)) AS mc_p_paid, ;
	SUM(IIF(cause_type = "PMC" AND status $ "PF", 1, 0)) AS pmc_p_noc, ;
	SUM(IIF(cause_type = "PMC" AND status $ "PF", paid, 0)) AS pmc_p_paid, ;	
	SUM(IIF(cause_type = "PMR" AND status $ "PF", 1, 0)) AS pmr_p_noc, ;
	SUM(IIF(cause_type = "PMR" AND status $ "PF", paid, 0)) AS pmr_p_paid, ;
	SUM(IIF(cause_type = "PMW" AND status $ "PF", 1, 0)) AS pmw_p_noc, ;
	SUM(IIF(cause_type = "PMW" AND status $ "PF", paid, 0)) AS pmw_p_paid, ;
	SUM(IIF(cause_type = "PMA" AND status $ "PF", 1, 0)) AS pma_p_noc, ;
	SUM(IIF(cause_type = "PMA" AND status $ "PF", paid, 0)) AS pma_p_paid, ;
	SUM(IIF(cause_type = "PMS" AND status $ "PF", 1, 0)) AS pms_p_noc, ;
	SUM(IIF(cause_type = "PMS" AND status $ "PF", paid, 0)) AS pms_p_paid, ;
	SUM(IIF(cause_type = "PMK" AND status $ "PF", 1, 0)) AS pmk_p_noc, ;
	SUM(IIF(cause_type = "PMK" AND status $ "PF", paid, 0)) AS pmk_p_paid, ;
	SUM(IIF(cause_type = "MA" AND status $ "PF", 1, 0)) AS ma_p_noc, ;
	SUM(IIF(cause_type = "MA" AND status $ "PF", paid, 0)) AS ma_p_paid, ;
	SUM(IIF(cause_type = "PWA" AND status $ "PF", 1, 0)) AS pwa_p_noc, ;
	SUM(IIF(cause_type = "PWA" AND status $ "PF", paid, 0)) AS pwa_p_paid, ;
	SUM(IIF(status $ "AW", 1, 0)) AS w_noc, ;
	SUM(IIF(status $ "AW", paid, 0)) AS w_paid ;	
FROM (gcFundCode+"_PA_ClaimMonth") ;
GROUP BY province ;
ORDER BY province ;
INTO CURSOR _provbycause
*
SELECT _sumbyprov.province, _Sumbyprov.nom_month, _SumbyProv.eqa_month, _SumbyProv.ep_month, ;
	_provbycause.me_p_noc, _provbycause.me_p_paid, _provbycause.mc_p_noc, _provbycause.mc_p_paid, _provbycause.pmc_p_noc, _provbycause.pmc_p_paid, ;	
	_provbycause.pmr_p_noc, _provbycause.pmr_p_paid, _provbycause.pmw_p_noc, _provbycause.pmw_p_paid, _provbycause.pma_p_noc, _provbycause.pma_p_paid, ;
	_provbycause.pms_p_noc, _provbycause.pms_p_paid, _provbycause.pmk_p_noc, _provbycause.pmk_p_paid, _provbycause.ma_p_noc, _provbycause.ma_p_paid, ;
	_provbycause.pwa_p_noc, pwa_p_paid, ;
	_provbycause.me_p_noc+_provbycause.mc_p_noc+_provbycause.pmc_p_noc+_provbycause.pmr_p_noc+_provbycause.pmw_p_noc+;
	_provbycause.pma_p_noc+_provbycause.pms_p_noc+_provbycause.pmk_p_noc+_provbycause.ma_p_noc+_provbycause.pwa_p_noc AS total_case, ;
	_provbycause.me_p_paid+_provbycause.mc_p_paid+_provbycause.pmc_p_paid+_provbycause.pmr_p_paid+_provbycause.pmw_p_paid+;
	_provbycause.pma_p_paid+_provbycause.pms_p_paid+_provbycause.pmk_p_paid+_provbycause.ma_p_paid+_provbycause.pwa_p_paid AS total_paid, ;	
	_provbycause.w_noc, _provbycause.w_paid ;
FROM _provbycause RIGHT JOIN _SumbyProv ;
	ON _provbycause.province = _SumbyProv.province ;
ORDER BY 1 ;
INTO CURSOR _SumProvbyCause
*
SELECT province, nom_month, eqa_month, ep_month, ;
	IIF(ISNULL(me_p_noc), 0, me_p_noc) AS me_p_noc, me_p_paid, ;
	IIF(ISNULL(mc_p_noc), 0, mc_p_noc) AS mc_p_noc, mc_p_paid, ;
	IIF(ISNULL(pmc_p_noc), 0, pmc_p_noc) AS pmc_p_noc, pmc_p_paid, ;	
	IIF(ISNULL(pmr_p_noc), 0, pmr_p_noc) AS pmr_p_noc, pmr_p_paid, ;
	IIF(ISNULL(pmw_p_noc), 0, pmw_p_noc) AS pmw_p_noc, pmw_p_paid, ;
	IIF(ISNULL(pma_p_noc), 0, pma_p_noc) AS pma_p_noc, pma_p_paid, ;
	IIF(ISNULL(pms_p_noc), 0, pms_p_noc) AS pms_p_noc, pms_p_paid, ;
	IIF(ISNULL(pmk_p_noc), 0, pmk_p_noc) AS pmk_p_noc, pmk_p_paid, ;
	IIF(ISNULL(ma_p_noc), 0, ma_p_noc) AS ma_p_noc, ma_p_paid, ;
	IIF(ISNULL(pwa_p_noc), 0, pwa_p_noc) AS pwa_p_noc, pwa_p_paid, ;
	total_case, total_paid, w_noc, w_paid ;
FROM _Sumprovbycause ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_PA_ProvinceByCause_month")
*
**********************************
PROCEDURE Q_PlanbyService_Year

SELECT plan, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", paid, 0)) AS opd_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", paid, 0)) AS ipd_paid, ;	
	SUM(IIF(serv_type = "OPD" AND status = "F", 1, 0)) AS opd_fnoc, ;
	SUM(IIF(serv_type = "OPD" AND status = "F", paid, 0)) AS opd_fpaid, ;
	SUM(IIF(serv_type = "IPD" AND status = "F", 1, 0)) AS ipd_fnoc, ;
	SUM(IIF(serv_type = "IPD" AND status = "F", paid, 0)) AS ipd_fpaid, ;		
	SUM(IIF(serv_type = "OPD" AND status $ "AW", 1, 0)) AS out_o_noc, ;	
	SUM(IIF( serv_type = "OPD" AND status $ "AW", paid, 0)) AS out_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW", 1, 0)) AS out_i_noc, ;
	SUM(IIF( serv_type = "IPD" AND status $ "AW", paid, 0)) AS out_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND status = "D", 1, 0)) AS d_o_noc, ;	
	SUM(IIF( serv_type = "OPD" AND status = "D", charge, 0)) d_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "D", 1, 0)) AS d_i_noc, ;	
	SUM(IIF( serv_type = "IPD" AND status = "D", charge, 0)) d_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND exgratia # 0, 1, 0)) AS e_o_noc, ;
	SUM(IIF( serv_type = "OPD", exgratia, 0)) AS e_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND exgratia # 0, 1, 0)) AS e_i_noc, ;
	SUM(IIF( serv_type = "IPD", exgratia, 0)) AS e_i_paid ;
FROM (gcFundCode+"_PA_Claim") ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, family_no, plan, serv_type, status, count(*) AS amt ;
FROM (gcFundCode+"_PA_Claim") ;
GROUP BY policy_no, family_no, plan, serv_type, status ;
INTO CURSOR per_pol
*
SELECT plan, SUM(IIF(serv_type = "OPD" AND status $ "P", 1, 0)) AS opd_nmc, ;
	SUM(IIF(serv_type = "OPD" AND status = "F", 1, 0)) AS opd_fnmc, ;
	SUM(IIF(serv_type = "IPD" and status = "P",  1, 0)) AS ipd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status = "F",  1, 0)) AS ipd_fnmc, ;	
	SUM(IIF(serv_type = "OPD" AND status $ "AW",  1, 0)) AS w_opd_nmc, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW",  1, 0)) AS w_ipd_nmc ;	
FROM per_pol ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR nmc
*
SELECT nmc.plan, noc.opd_noc, nmc.opd_nmc, noc.opd_paid, noc.opd_fnoc, nmc.opd_fnmc, noc.opd_fpaid, noc.d_o_noc, noc.d_o_paid, noc.e_o_noc, noc.e_o_paid, ;
	noc.ipd_noc, nmc.ipd_nmc, noc.ipd_paid, noc.ipd_fnoc, nmc.ipd_fnmc, noc.ipd_fpaid, noc.d_i_noc, noc.d_i_paid, noc.e_i_noc, noc.e_i_paid, ;
	noc.out_o_noc, noc.out_o_paid, noc.out_i_noc, noc.out_i_paid, nmc.w_opd_nmc, nmc.w_ipd_nmc ;
FROM noc INNER JOIN nmc ;
	ON noc.plan = nmc.plan ;
ORDER BY 1 ;
INTO CURSOR _SumType
*
SELECT _SumType
COPY TO (gcFundCode+"_Claim_PlanbyService_Year") TYPE XL5 
*
SELECT _SumMember.plan, _SumMember.nom_year, ;
	_SumMember.eqa_year, _SumMember.y_premium AS premium, _SumMember.ep_year, ;
	_SumType.opd_noc, _SumType.opd_nmc, _SumType.opd_paid, _SumType.opd_fnoc, _SumType.opd_fnmc, _SumType.opd_fpaid, ;
	_SumType.e_o_noc, _SumType.e_o_paid, _SumType.d_o_noc, _SumType.d_o_paid, ;
	_SumType.ipd_noc, _SumType.ipd_nmc, _SumType.ipd_paid, _SumType.ipd_fnoc, _SumType.ipd_fnmc, _SumType.ipd_fpaid, ;
	_SumType.e_i_noc, _SumType.e_i_paid, _SumType.d_i_noc, _SumType.d_i_paid, ;
	_SumType.w_opd_nmc+ _sumtype.w_ipd_nmc AS w_nmc, ;
	_SumType.out_o_noc+_SumType.out_i_noc AS w_noc, _SumType.out_o_paid+_SumType.out_i_paid AS w_paid ;	
FROM _SumType RIGHT JOIN _SumMember ;
	ON _SumType.plan = LEFT(_SumMember.plan,20) ;
ORDER BY 1 ;		
INTO TABLE (gcFundCode+"_PlanbyService_Year")
*
*
**********************************************************************
PROCEDURE Q_PlanbyCause_Year
*
SELECT plan, ;
	SUM(IIF(!INLIST(cause_type, "MC", "PMC", "PMR", "PMW", "PMA", "PMS", "PMK", "PWA", "MA") AND status $ "PF", 1, 0)) AS me_p_noc, ;
	SUM(IIF(!INLIST(cause_type, "MC", "PMC", "PMR", "PMW", "PMA", "PMS", "PMK", "PWA", "MA") AND status $ "PF", paid, 0)) AS me_p_paid, ;
	SUM(IIF(cause_type = "MC" AND status $ "PF", 1, 0)) AS mc_p_noc, ;
	SUM(IIF(cause_type = "MC" AND status $ "PF", paid, 0)) AS mc_p_paid, ;
	SUM(IIF(cause_type = "PMC" AND status $ "PF", 1, 0)) AS pmc_p_noc, ;
	SUM(IIF(cause_type = "PMC" AND status $ "PF", paid, 0)) AS pmc_p_paid, ;	
	SUM(IIF(cause_type = "PMR" AND status $ "PF", 1, 0)) AS pmr_p_noc, ;
	SUM(IIF(cause_type = "PMR" AND status $ "PF", paid, 0)) AS pmr_p_paid, ;
	SUM(IIF(cause_type = "PMW" AND status $ "PF", 1, 0)) AS pmw_p_noc, ;
	SUM(IIF(cause_type = "PMW" AND status $ "PF", paid, 0)) AS pmw_p_paid, ;
	SUM(IIF(cause_type = "PMA" AND status $ "PF", 1, 0)) AS pma_p_noc, ;
	SUM(IIF(cause_type = "PMA" AND status $ "PF", paid, 0)) AS pma_p_paid, ;
	SUM(IIF(cause_type = "PMS" AND status $ "PF", 1, 0)) AS pms_p_noc, ;
	SUM(IIF(cause_type = "PMS" AND status $ "PF", paid, 0)) AS pms_p_paid, ;
	SUM(IIF(cause_type = "PMK" AND status $ "PF", 1, 0)) AS pmk_p_noc, ;
	SUM(IIF(cause_type = "PMK" AND status $ "PF", paid, 0)) AS pmk_p_paid, ;
	SUM(IIF(cause_type = "MA" AND status $ "PF", 1, 0)) AS ma_p_noc, ;
	SUM(IIF(cause_type = "MA" AND status $ "PF", paid, 0)) AS ma_p_paid, ;
	SUM(IIF(cause_type = "PWA" AND status $ "PF", 1, 0)) AS pwa_p_noc, ;
	SUM(IIF(cause_type = "PWA" AND status $ "PF", paid, 0)) AS pwa_p_paid, ;
	SUM(IIF(status $ "AW", 1, 0)) AS w_noc, ;
	SUM(IIF(status $ "AW", paid, 0)) AS w_paid ;	
FROM (gcFundCode+"_PA_Claim") ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR _planbycause
*
SELECT _planbycause
COPY TO (gcFundCode+"_Claim_PlanByCause_Year") TYPE XL5 
*
SELECT _sumMember.plan, _SumMember.nom_year, _SumMember.eqa_year, _SumMember.ep_year, ;
	_planbycause.me_p_noc, _planbycause.me_p_paid, _planbycause.mc_p_noc, _planbycause.mc_p_paid, _planbycause.pmc_p_noc, _planbycause.pmc_p_paid, ;	
	_planbycause.pmr_p_noc, _planbycause.pmr_p_paid, _planbycause.pmw_p_noc, _planbycause.pmw_p_paid, _planbycause.pma_p_noc, _planbycause.pma_p_paid, ;
	_planbycause.pms_p_noc, _planbycause.pms_p_paid, _planbycause.pmk_p_noc, _planbycause.pmk_p_paid, _planbycause.ma_p_noc, _planbycause.ma_p_paid, ;
	_planbycause.pwa_p_noc, pwa_p_paid, ;
	_planbycause.me_p_noc+_planbycause.mc_p_noc+_planbycause.pmc_p_noc+_planbycause.pmr_p_noc+_planbycause.pmw_p_noc+;
	_planbycause.pma_p_noc+_planbycause.pms_p_noc+_planbycause.pmk_p_noc+_planbycause.ma_p_noc+_planbycause.pwa_p_noc AS total_case, ;
	_planbycause.me_p_paid+_planbycause.mc_p_paid+_planbycause.pmc_p_paid+_planbycause.pmr_p_paid+_planbycause.pmw_p_paid+;
	_planbycause.pma_p_paid+_planbycause.pms_p_paid+_planbycause.pmk_p_paid+_planbycause.ma_p_paid+_planbycause.pwa_p_paid AS total_paid, ;	
	_planbycause.w_noc, _planbycause.w_paid ;
FROM _planbycause RIGHT JOIN _SumMember ;
	ON _planbycause.plan = LEFT(_SumMember.plan,20) ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_PlanByCause_Year")
*
*********************************************************************
PROCEDURE Q_ProvincebyCause_Year
*
SELECT province, ; 
	SUM(IIF(!INLIST(cause_type, "MC", "PMC", "PMR", "PMW", "PMA", "PMS", "PMK", "PWA", "MA") AND status $ "PF", 1, 0)) AS me_p_noc, ;
	SUM(IIF(!INLIST(cause_type, "MC", "PMC", "PMR", "PMW", "PMA", "PMS", "PMK", "PWA", "MA") AND status $ "PF", paid, 0)) AS me_p_paid, ;
	SUM(IIF(cause_type = "MC" AND status $ "PF", 1, 0)) AS mc_p_noc, ;
	SUM(IIF(cause_type = "MC" AND status $ "PF", paid, 0)) AS mc_p_paid, ;
	SUM(IIF(cause_type = "PMC" AND status $ "PF", 1, 0)) AS pmc_p_noc, ;
	SUM(IIF(cause_type = "PMC" AND status $ "PF", paid, 0)) AS pmc_p_paid, ;	
	SUM(IIF(cause_type = "PMR" AND status $ "PF", 1, 0)) AS pmr_p_noc, ;
	SUM(IIF(cause_type = "PMR" AND status $ "PF", paid, 0)) AS pmr_p_paid, ;
	SUM(IIF(cause_type = "PMW" AND status $ "PF", 1, 0)) AS pmw_p_noc, ;
	SUM(IIF(cause_type = "PMW" AND status $ "PF", paid, 0)) AS pmw_p_paid, ;
	SUM(IIF(cause_type = "PMA" AND status $ "PF", 1, 0)) AS pma_p_noc, ;
	SUM(IIF(cause_type = "PMA" AND status $ "PF", paid, 0)) AS pma_p_paid, ;
	SUM(IIF(cause_type = "PMS" AND status $ "PF", 1, 0)) AS pms_p_noc, ;
	SUM(IIF(cause_type = "PMS" AND status $ "PF", paid, 0)) AS pms_p_paid, ;
	SUM(IIF(cause_type = "PMK" AND status $ "PF", 1, 0)) AS pmk_p_noc, ;
	SUM(IIF(cause_type = "PMK" AND status $ "PF", paid, 0)) AS pmk_p_paid, ;
	SUM(IIF(cause_type = "MA" AND status $ "PF", 1, 0)) AS ma_p_noc, ;
	SUM(IIF(cause_type = "MA" AND status $ "PF", paid, 0)) AS ma_p_paid, ;
	SUM(IIF(cause_type = "PWA" AND status $ "PF", 1, 0)) AS pwa_p_noc, ;
	SUM(IIF(cause_type = "PWA" AND status $ "PF", paid, 0)) AS pwa_p_paid, ;
	SUM(IIF(status $ "AW", 1, 0)) AS w_noc, ;
	SUM(IIF(status $ "AW", paid, 0)) AS w_paid ;	
FROM (gcFundCode+"_PA_claim") ;
GROUP BY province ;
ORDER BY province ;
INTO CURSOR _provbycause
*
SELECT _sumbyprov.province, _Sumbyprov.nom_year, _SumbyProv.eqa_year, _SumbyProv.ep_year, ;
	_provbycause.me_p_noc, _provbycause.me_p_paid, _provbycause.mc_p_noc, _provbycause.mc_p_paid, _provbycause.pmc_p_noc, _provbycause.pmc_p_paid, ;	
	_provbycause.pmr_p_noc, _provbycause.pmr_p_paid, _provbycause.pmw_p_noc, _provbycause.pmw_p_paid, _provbycause.pma_p_noc, _provbycause.pma_p_paid, ;
	_provbycause.pms_p_noc, _provbycause.pms_p_paid, _provbycause.pmk_p_noc, _provbycause.pmk_p_paid, _provbycause.ma_p_noc, _provbycause.ma_p_paid, ;
	_provbycause.pwa_p_noc, pwa_p_paid, ;	
	_provbycause.me_p_noc+_provbycause.mc_p_noc+_provbycause.pmc_p_noc+_provbycause.pmr_p_noc+_provbycause.pmw_p_noc+;
	_provbycause.pma_p_noc+_provbycause.pms_p_noc+_provbycause.pmk_p_noc+_provbycause.ma_p_noc+_provbycause.pwa_p_noc AS total_case, ;
	_provbycause.me_p_paid+_provbycause.mc_p_paid+_provbycause.pmc_p_paid+_provbycause.pmr_p_paid+_provbycause.pmw_p_paid+;
	_provbycause.pma_p_paid+_provbycause.pms_p_paid+_provbycause.pmk_p_paid+_provbycause.ma_p_paid+_provbycause.pwa_p_paid AS total_paid, ;	
	_provbycause.w_noc , _provbycause.w_paid;
FROM _provbycause RIGHT JOIN _SumbyProv ;
	ON _provbycause.province = _SumbyProv.province ;
ORDER BY 1 ;
INTO CURSOR _SumProvbyCause
*
SELECT province, nom_year, eqa_year, ep_year, ;
	IIF(ISNULL(me_p_noc), 0, me_p_noc) AS me_p_noc, me_p_paid, ;
	IIF(ISNULL(mc_p_noc), 0, mc_p_noc) AS mc_p_noc, mc_p_paid, ;
	IIF(ISNULL(pmc_p_noc), 0, pmc_p_noc) AS pmc_p_noc, pmc_p_paid, ;	
	IIF(ISNULL(pmr_p_noc), 0, pmr_p_noc) AS pmr_p_noc, pmr_p_paid, ;
	IIF(ISNULL(pmw_p_noc), 0, pmw_p_noc) AS pmw_p_noc, pmw_p_paid, ;
	IIF(ISNULL(pma_p_noc), 0, pma_p_noc) AS pma_p_noc, pma_p_paid, ;
	IIF(ISNULL(pms_p_noc), 0, pms_p_noc) AS pms_p_noc, pms_p_paid, ;
	IIF(ISNULL(pmk_p_noc), 0, pmk_p_noc) AS pmk_p_noc, pmk_p_paid, ;
	IIF(ISNULL(ma_p_noc), 0, ma_p_noc) AS ma_p_noc, ma_p_paid, ;
	IIF(ISNULL(pwa_p_noc), 0, pwa_p_noc) AS pwa_p_noc, pwa_p_paid, ;
	total_case, total_paid, w_noc, w_paid ;
FROM _Sumprovbycause ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_PA_ProvinceByCause_year")
*
**********************************************************
PROCEDURE q_rolling

lcRollingFile = gcFundCode+"_PPP_Rolling"
*
CREATE TABLE (lcRollingFile) FREE (months C(6), nom Y, eqal Y, ep Y, notifys Y, admit Y, return Y, noc_notify I, noc_admit I, noc_return I, dom I)
*
ldStartDate = DATE(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate))
lnDay = ICASE(MONTH(ldStartDate) = 2, IIF(MOD(YEAR(ldStartDate),4) = 0, 29, 28), INLIST(MONTH(ldStartDate), 1,3,5,7,8,10,12), 31, 30)
ldEndDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), lnDay)

m.dom = lnDay

DO WHILE ldEndDate < gdEndDate
	lnDay = ICASE(MONTH(ldStartDate) = 2, IIF(MOD(YEAR(ldStartDate),4) = 0, 29, 28), INLIST(MONTH(ldStartDate), 1,3,5,7,8,10,12), 31, 30)
	ldEndDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), lnDay)
	lcFile = "R_"+STRTRAN(DTOC(ldEndDate), "/", "")
	*
	SELECT tpacode, policy_no, plan, effective, expiry, IIF(y_cover = 0, 0, premium/y_cover) AS premium, ;
		IIF(TTOD(effective) >= ldStartDate AND TTOD(effective) <= ldEndDate, TTOD(effective), IIF(TTOD(effective) <= ldStartDate, ldStartDate, {})) AS start_month, ;
		IIF(TTOD(expiry) >= ldEndDate, ldEndDate, IIF(TTOD(expiry) >= ldStartDate AND TTOD(expiry) <= ldEndDate, TTOD(expiry), {})) AS end_month ;
	FROM Q_member ;
	INTO CURSOR curRmonth
	*
	SELECT COUNT(*) AS nom, ;
		SUM((end_month-start_month)/lnDay) AS eqal, ;
		SUM((premium/lnDayInRoll) *((end_month-start_month)+1)) AS ep ;
	FROM curRMonth ;
	WHERE !EMPTY(start_month) ;
	INTO CURSOR curMonths
	SELECT curMonths
	SCATTER MEMVAR 
	*
	SELECT Claim.notify_no, Claim.notify_date, Claim.claim_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS service, ;
	Claim.admis_date, IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid, Claim.fbenfpaid) AS paid, ;
	IIF(INLIST(result, "W5", "P5", "P62" ), "F", LEFT(result,1)) AS status, Claim.result, Claim.return_date ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.result # "C" ;	
	AND TTOD(claim_date) BETWEEN ldStartDate AND ldEndDate ;			
	INTO CURSOR curClaimN	
	*
	SELECT Claim.notify_no, Claim.notify_date, Claim.claim_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS service, ;
	Claim.admis_date, IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid, Claim.fbenfpaid) AS paid, ;
	IIF(INLIST(result, "W5", "P5", "P62"), "F", LEFT(result,1)) AS status, Claim.result, Claim.return_date ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.result # "C" ;	
	AND TTOD(Claim.admis_date) BETWEEN ldStartDate AND ldEndDate ;			
	INTO CURSOR curClaimM
	*
	SELECT Claim.notify_no, Claim.notify_date, Claim.claim_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS service, ;
	Claim.admis_date, IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid, Claim.fbenfpaid) AS paid, ;
	IIF(INLIST(result, "W5", "P5", "P62"), "F", LEFT(result,1)) AS status, Claim.result, Claim.return_date ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.result # "C" ;	
	AND Claim.return_date BETWEEN ldStartDate AND ldEndDate ;			
	INTO CURSOR curClaimR
	*	
	SELECT curClaimM
	SUM paid TO m.admit FOR status $ "PF"	
	m.noc_admit = RECCOUNT()
	*
	SELECT curClaimN
	SUM paid TO m.notifys FOR status $ "PF"	
	m.noc_notify = RECCOUNT()
	*
	SELECT curClaimR
	SUM paid TO m.return FOR status $ "PF"
	m.noc_return = RECCOUNT()
	m.months = LEFT(CMONTH(ldStartDate),3)+"-"+RIGHT(STR(YEAR(ldStartDate),4),2)
	********************************
	INSERT INTO (lcRollingFile) FROM MEMVAR 
	*************************************************************************
	ldStartDate = GOMONTH(ldStartDate,1)
	ldStartDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), DAY(ldStartDate))
ENDDO 	

*select fundcode, transdate,mid, paid, apprv from cims!claimpayment where fundcode  = 'SMG' and transdate between {^2013-08-26} and {^2013-09-25} and apprv not in (select drg_10 from cims!claim where !empty(drg_10))
*******************************
PROCEDURE q_claimrolling

lcRollingFile = gcFundCode+"_PA_ClaimRolling"
*
CREATE TABLE (lcRollingFile) FREE (months C(6), nom Y, eqal Y, ep Y, opd_amt1 I, opd_paid1 Y, ipd_amt1 I, ipd_paid1 Y, opd_amt2 I, opd_paid2 Y, ipd_amt2 I, ipd_paid2 Y, out_amt1 I, out_paid1 Y, d_amt1 I, dom I, rdate D)
*
ldStartDate = gomonth(gdEndDate,-12)+1   && DATE(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate))
lnDay = ICASE(MONTH(ldStartDate) = 2, IIF(MOD(YEAR(ldStartDate),4) = 0, 29, 28), INLIST(MONTH(ldStartDate), 1,3,5,7,8,10,12), 31, 30)
ldEndDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), lnDay)

DO WHILE ldEndDate < gdEndDate
	lnDay = ICASE(MONTH(ldStartDate) = 2, IIF(MOD(YEAR(ldStartDate),4) = 0, 29, 28), INLIST(MONTH(ldStartDate), 1,3,5,7,8,10,12), 31, 30)
	ldEndDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), lnDay)
	lcFile = "R_"+STRTRAN(DTOC(ldEndDate), "/", "")
	*
	m.dom = lnDay
	*
	SELECT tpacode, policy_no, plan, effective, expiry, IIF(y_cover = 0, 0, premium/y_cover) AS premium, ;	
		IIF(TTOD(effective) >= ldStartDate AND TTOD(effective) <= ldEndDate, TTOD(effective), IIF(TTOD(effective) <= ldStartDate, ldStartDate, {})) AS start_month, ;
		IIF(TTOD(expiry) >= ldEndDate, ldEndDate, IIF(TTOD(expiry) >= ldStartDate AND TTOD(expiry) <= ldEndDate, TTOD(expiry), {})) AS end_month ;
	 FROM Q_member ;
	INTO CURSOR curRmonth
	*
	SELECT COUNT(*) AS nom, ;
		SUM((end_month-start_month)/lnDay) AS eqal, ;
		SUM((premium/lnDayInRoll) *((end_month-start_month)+1)) AS ep ;
	FROM curRMonth ;
	WHERE !EMPTY(start_month) ;
	INTO CURSOR curMonths
	SELECT curMonths
	SCATTER MEMVAR 
	***********************************************************************
	SELECT claim_date, serv_type AS service, status, paid ;
	FROM (gcFundCode+"_PA_claim") ;
	WHERE TTOD(claim_date) BETWEEN ldStartDate AND ldEndDate ;				
		AND status $ "PF" ;
	INTO CURSOR curClaimN
	*
	SELECT LEFT(CMONTH(ldStartDate),3)+"-"+RIGHT(STR(YEAR(ldStartDate),4),2) AS months, ;
		SUM(IIF(service = "OPD" AND status $ "F", 1, 0)) AS opd_amt1, ;
		SUM(IIF(service = "OPD" AND status $ "F", paid, 0)) AS opd_paid1, ;
		SUM(IIF(service = "IPD" AND status $ "F", 1, 0)) AS ipd_amt1, ;
		SUM(IIF(service = "IPD" AND status $ "F", paid, 0)) AS ipd_paid1, ;
		SUM(IIF(service = "OPD" AND status $ "P", 1, 0)) AS opd_amt2, ;
		SUM(IIF(service = "OPD" AND status $ "P", paid, 0)) AS opd_paid2, ;
		SUM(IIF(service = "IPD" AND status $ "P", 1, 0)) AS ipd_amt2, ;
		SUM(IIF(service = "IPD" AND status $ "P", paid, 0)) AS ipd_paid2, ;
		SUM(IIF(status = "W", 1, 0)) AS out_amt1, ;
		SUM(IIF(status = "W", paid, 0)) AS out_paid1, ;
		SUM(IIF(status = "D", 1, 0)) AS d_amt1 ;		
	FROM curClaimN ;
	GROUP BY 1 ;
	INTO CURSOR curGroupN
	*
	SELECT curGroupN
	SCATTER MEMVAR 
	*
	m.rdate = ldStartDate
	m.months = LEFT(CMONTH(ldStartDate),3)+"-"+RIGHT(STR(YEAR(ldStartDate),4),2)
	********************************
	INSERT INTO (lcRollingFile) FROM MEMVAR 
	*************************************************************************
	ldStartDate = GOMONTH(ldStartDate,1)
	ldStartDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), DAY(ldStartDate))
ENDDO 	
*
********************************************************
PROCEDURE q_Hospital_Month
*
SELECT prov_name, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", paid, 0)) AS opd_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", paid, 0)) AS ipd_paid, ;	
	SUM(IIF(serv_type = "OPD" AND status = "F", 1, 0)) AS opd_fnoc, ;
	SUM(IIF(serv_type = "OPD" AND status = "F", paid, 0)) AS opd_fpaid, ;
	SUM(IIF(serv_type = "IPD" AND status = "F", 1, 0)) AS ipd_fnoc, ;
	SUM(IIF(serv_type = "IPD" AND status = "F", paid, 0)) AS ipd_fpaid, ;		
	SUM(IIF(serv_type = "OPD" AND status $ "AW", 1, 0)) AS out_o_noc, ;	
	SUM(IIF(serv_type = "OPD" AND status $ "AW", paid, 0)) AS out_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW", 1, 0)) AS out_i_noc, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW", paid, 0)) AS out_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND status = "D", 1, 0)) AS d_o_noc, ;	
	SUM(IIF(serv_type = "OPD" AND status = "D", charge, 0)) d_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "D", 1, 0)) AS d_i_noc, ;	
	SUM(IIF(serv_type = "IPD" AND status = "D", charge, 0)) d_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND exgratia # 0, 1, 0)) AS e_o_noc, ;
	SUM(IIF(serv_type = "OPD" AND exgratia # 0, exgratia, 0)) AS e_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND exgratia # 0, 1, 0)) AS e_i_noc, ;
	SUM(IIF(serv_type = "IPD" AND exgratia # 0, exgratia, 0)) AS e_i_paid ;
FROM (gcFundCode+"_PA_ClaimMonth") ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc_m
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT prov_name, plan, serv_type, status, ;
count(*) AS amt ;
FROM (gcFundCode+"_PA_ClaimMonth") ;
GROUP BY policy_no, family_no, plan, serv_type, status ;
INTO CURSOR pol_1
*
SELECT prov_name, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_nmc, ;
	SUM(IIF(serv_type = "OPD" AND status = "F", 1, 0)) AS opd_fnmc, ;	
	SUM(IIF(serv_type = "OPD" AND status $ "AW", 1, 0)) AS w_opd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status = "P",  1, 0)) AS ipd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status = "F",  1, 0)) AS ipd_fnmc, ;	
	SUM(IIF(serv_type = "IPD" and status $ "AW",  1, 0)) AS w_ipd_nmc ;	
FROM pol_1 ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR nmc_m
*
SELECT nmc_m.prov_name, noc_m.opd_noc, nmc_m.opd_nmc, noc_m.opd_paid, noc_m.opd_fnoc, nmc_m.opd_fnmc, noc_m.opd_fpaid, noc_m.d_o_noc, ;
	noc_m.d_o_paid, noc_m.e_o_noc, noc_m.e_o_paid, noc_m.ipd_noc, nmc_m.ipd_nmc, noc_m.ipd_paid, noc_m.ipd_fnoc, nmc_m.ipd_fnmc, ;
	noc_m.ipd_fpaid, noc_m.d_i_noc, noc_m.d_i_paid, noc_m.e_i_noc, noc_m.e_i_paid, noc_m.out_o_noc, noc_m.out_o_paid, noc_m.out_i_noc, ;
	noc_m.out_i_paid, nmc_m.w_opd_nmc, nmc_m.w_ipd_nmc ;
FROM noc_m INNER JOIN nmc_m ;
	ON noc_m.prov_name = nmc_m.prov_name ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_PA_Hospital_Month")
*End Query Current Month Report
*
*********************************************
PROCEDURE Q_Hospital_Year

SELECT prov_name, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", paid, 0)) AS opd_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", paid, 0)) AS ipd_paid, ;	
	SUM(IIF(serv_type = "OPD" AND status = "F", 1, 0)) AS opd_fnoc, ;
	SUM(IIF(serv_type = "OPD" AND status = "F", paid, 0)) AS opd_fpaid, ;
	SUM(IIF(serv_type = "IPD" AND status = "F", 1, 0)) AS ipd_fnoc, ;
	SUM(IIF(serv_type = "IPD" AND status = "F", paid, 0)) AS ipd_fpaid, ;		
	SUM(IIF(serv_type = "OPD" AND status $ "AW", 1, 0)) AS out_o_noc, ;	
	SUM(IIF( serv_type = "OPD" AND status $ "AW", paid, 0)) AS out_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW", 1, 0)) AS out_i_noc, ;
	SUM(IIF( serv_type = "IPD" AND status $ "AW", paid, 0)) AS out_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND status = "D", 1, 0)) AS d_o_noc, ;	
	SUM(IIF( serv_type = "OPD" AND status = "D", charge, 0)) d_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "D", 1, 0)) AS d_i_noc, ;	
	SUM(IIF( serv_type = "IPD" AND status = "D", charge, 0)) d_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND exgratia # 0, 1, 0)) AS e_o_noc, ;
	SUM(IIF( serv_type = "OPD", exgratia, 0)) AS e_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND exgratia # 0, 1, 0)) AS e_i_noc, ;
	SUM(IIF( serv_type = "IPD", exgratia, 0)) AS e_i_paid ;
FROM (gcFundCode+"_PA_Claim") ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR hosp_noc
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT prov_name, plan, serv_type, status, count(*) AS amt ;
FROM (gcFundCode+"_PA_Claim") ;
GROUP BY prov_name, serv_type, status ;
INTO CURSOR per_hosp
*
SELECT prov_name, SUM(IIF(serv_type = "OPD" AND status $ "P", 1, 0)) AS opd_nmc, ;
	SUM(IIF(serv_type = "OPD" AND status = "F", 1, 0)) AS opd_fnmc, ;
	SUM(IIF(serv_type = "IPD" and status = "P",  1, 0)) AS ipd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status = "F",  1, 0)) AS ipd_fnmc, ;	
	SUM(IIF(serv_type = "OPD" AND status $ "AW",  1, 0)) AS w_opd_nmc, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW",  1, 0)) AS w_ipd_nmc ;	
FROM per_hosp ;
GROUP BY prov_name ;
INTO CURSOR hosp_nmc
*
SELECT nmc.prov_name, noc.opd_noc, nmc.opd_nmc, noc.opd_paid, noc.opd_fnoc, nmc.opd_fnmc, noc.opd_fpaid, noc.d_o_noc, noc.d_o_paid, noc.e_o_noc, noc.e_o_paid, ;
	noc.ipd_noc, nmc.ipd_nmc, noc.ipd_paid, noc.ipd_fnoc, nmc.ipd_fnmc, noc.ipd_fpaid, noc.d_i_noc, noc.d_i_paid, noc.e_i_noc, noc.e_i_paid, ;
	noc.out_o_noc, noc.out_o_paid, noc.out_i_noc, noc.out_i_paid, nmc.w_opd_nmc, nmc.w_ipd_nmc ;
FROM hosp_noc noc INNER JOIN hosp_nmc nmc ;
	ON noc.prov_name = nmc.prov_name ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_Hospital_Year")
*