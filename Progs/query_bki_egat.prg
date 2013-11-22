PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnRolling, ;
	gnOption
	
SET SAFETY OFF 	
SET PROCEDURE TO progs\utility
********************
gcCaption = "BKI EGAT Monthly Report"
gnAll = 1
gnCover = 1
gnData = 0
gnType = 1
gcPolicyNo = "609010880"
gcStartDate = "Start Date"
gcEndDate = "End Date"
glMonth = .F.	
gcFundCode = "BKI"
gdEndDate = DATE() - DAY(DATE())
gdStartDate = getstartroll(gdEndDate, 12)
gcCustID = "PPP"
gnOption = 1
gnType = 1
gnRolling = 12
gcSaveTo = gcTemp
DO FORM form\Rollingentry2
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
lnDayInRoll = IIF(gnRolling = 12, 456.56, 365.25)
gdStartDate = getstartroll(gdEndDate, gnRolling)
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
lcPolicyNo = gcPolicyNo
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
DO q_claimrolling
****************
SET TALK OFF 
SET DEFAULT TO (lcOldDir)
**************************************************************
PROCEDURE q_Member
*
SELECT Dependants.fundcode AS tpacode, Dependants.policy_no, Dependants.plan, ;
	LEFT(Dependants.plan,2) AS plan_type, ;
	Dependants.hb_limit, Dependants.effective, Dependants.expired AS expiry, Dependants.premium, Dependants.premium/lnDayInRoll AS prem_day ;
 FROM cims!Dependants ;
 WHERE Dependants.fundcode = gcFundCode ;
   AND Dependants.policy_no = lcPolicyNo ;	
   AND Dependants.status # "C" ;
   AND Dependants.expired >= gtStartDate ;
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
INTO TABLE (gcFundCode+"_"+gcCustID+"_member")	
*
SELECT plan, ;
	SUM(m_nominal) AS nom_month, SUM(premium) AS premium, SUM(eqa_month) AS eqa_month, SUM(ep_month) AS ep_month, ;
	SUM(y_nominal) AS nom_year, SUM(eqa_year) AS eqa_year, SUM(ep_year) AS ep_year ;
FROM (gcFundcode+"_"+gcCustID+"_member") ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR _SumMember

*
*********************************************************
*
PROCEDURE q_Claim
*
SELECT Claim.notify_no, Claim.notify_date, Claim.claim_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS serv_type, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, SUBSTR(Claim.customer_id,4) AS client_no, Claim.client_name, ;
	Claim.plan, LEFT(Claim.plan,2) AS plan_type, Claim.admis_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, ;
	IIF(EMPTY(Claim.fax_by), Claim.abenfpaid, Claim.exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), Claim.scharge, Claim.fcharge) AS charge, ;	
	IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid+Claim.over_respond, Claim.fbenfpaid+Claim.deduc) AS paid, ;
	IIF(INLIST(result, "W5", "P5"), "F", LEFT(result,1)) AS status, ;	
	Claim.result, Claim.return_date, Claim.unclean, Claim.unclean_note, Claim.prov_name, ;
	((return_date-TTOD(notify_date)) - holidays(TTOD(notify_date), return_date)) AS workdays, ;	
	Claim.disc_date, Claim.illness1, Claim.illness2, Claim.illness3, Claim.indication_admit ;	
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "T" ;
	AND Claim.result # "C" ;	
	AND Claim.admis_date BETWEEN gtStartDate AND gtEndDate ;	
INTO TABLE (gcFundCode+"_"+gcCustID+"_Claim")
**
*Query Current Month Report
*
SELECT Claim.notify_no, Claim.notify_date, Claim.claim_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS serv_type, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, SUBSTR(Claim.customer_id,4) AS client_no, Claim.client_name, Claim.plan, LEFT(Claim.plan,2) AS plan_type, ;
	Claim.admis_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, Claim.fax_by, ;
	IIF(EMPTY(Claim.fax_by), Claim.abenfpaid, Claim.exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), Claim.scharge, Claim.fcharge) AS charge, ;		
	IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid+Claim.over_respond, Claim.fbenfpaid+Claim.deduc) AS paid, ;
	IIF(INLIST(result, "W5", "P5"), "F", LEFT(result,1)) AS status, ;		
	Claim.result, Claim.return_date, Claim.unclean, Claim.unclean_note, ;
	((return_date-TTOD(notify_date)) - holidays(TTOD(notify_date), return_date)) AS workdays, ;
	Claim.prov_name, Claim.disc_date, Claim.illness1, Claim.illness2, Claim.illness3, Claim.indication_admit ;		
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "T" ;
	AND Claim.result # "C" ;
	AND Claim.claim_date BETWEEN gtCurDate AND gtEndDate ;
INTO TABLE (gcFundCode+"_"+gcCustID+"_Claim_Month")
***
*Query Claim by service
SELECT A.fundcode, A.notify_no, A.claim_date,  A.serv_type,  A.policy_no, A.plan, A.plan_type, A.return_dat, ;
  A.plan+Claim_line.cat_code AS plan_cat, Claim_line.cat_code, Claim_line.description, Claim_line.benefit, ;
  IIF(EMPTY(A.fax_by), Claim_line.scharge, Claim_line.fcharge) AS charge, ;
  IIF(EMPTY(A.fax_by), Claim_line.spaid+Claim_line.dpaid, Claim_line.fpaid+Claim_line.deduc) AS paid, ;
  IIF(EMPTY(A.fax_by), Claim_line.apaid, Claim_line.exgratia) AS exgratia, A.result, A.status ;  
FROM (gcFundCode+"_"+gcCustID+"_Claim_Month") A INNER JOIN cims!claim_line ;
	ON  A.notify_no = Claim_line.notify_no ;
WHERE A.serv_type = "IPD" ;
	AND A.status $ "PF" ;	
INTO TABLE (gcFundCode+"_"+gcCustID+"_Claimline")
*
SELECT serv_type, SUM(IIF(workdays <= 1, 1, 0)) AS day_1, ;
	SUM(IIF(workdays = 2, 1, 0)) AS day_2, SUM(IIF(workdays = 3, 1, 0)) AS day_3, ;	
	SUM(IIF(workdays = 4, 1, 0)) AS day_4, SUM(IIF(workdays = 5, 1, 0)) AS day_5, ;	
	SUM(IIF(workdays = 6, 1, 0)) AS day_6, SUM(IIF(workdays >= 7 AND workdays <= 10, 1, 0)) AS day_7, ;	
	SUM(IIF(workdays > 10, 1, 0)) AS day_11 ;
FROM (gcFundCode+"_"+gcCustID+"_Claim_Month") ;
GROUP BY 1 ;
WHERE (result = "P1" OR result like "D%") ;
	AND EMPTY(unclean) ;
INTO TABLE (gcFundCode+"_"+gcCustID+"_Aging")
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
FROM (gcFundCode+"_"+gcCustID+"_Claim_Month") ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc_m
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, family_no, plan, serv_type, status, ;
count(*) AS amt ;
FROM (gcFundCode+"_"+gcCustID+"_Claim_Month") ;
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
SELECT _SumMember.plan, _SumMember.nom_month, ;
	_SumMember.eqa_month, _SumMember.premium, _SumMember.ep_month, ;
	_SumType.opd_noc, _SumType.opd_nmc, _SumType.opd_paid, _SumType.opd_fnoc, _SumType.opd_fnmc, _SumType.opd_fpaid, ;
	_SumType.e_o_noc, _SumType.e_o_paid, _SumType.d_o_noc, _SumType.d_o_paid, ;
	_SumType.ipd_noc, _SumType.ipd_nmc, _SumType.ipd_paid, _SumType.ipd_fnoc, _SumType.ipd_fnmc, _SumType.ipd_fpaid, ;
	_SumType.e_i_noc, _SumType.e_i_paid, _SumType.d_i_noc, _SumType.d_i_paid, ;
	_SumType.w_opd_nmc+_SumType.w_ipd_nmc AS w_nmc, ;
	_SumType.out_o_noc+_SumType.out_i_noc AS w_noc, _SumType.out_o_paid+_SumType.out_i_paid AS w_paid ;	
FROM _SumType1 _SumType RIGHT JOIN _SumMember ;
	ON _SumType.plan = _SumMember.plan ;
ORDER BY 1 ;		
INTO TABLE (gcFundCode+"_"+gcCustID+"_PlanbyService_Month")
*End Query Current Month Report
*
**********************************
PROCEDURE Q_PlanbyService_Year

SELECT plan, ;
	SUM(IIF(serv_type = "OPD" AND status $ "P", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD" AND status $ "P", paid, 0)) AS opd_paid, ;
	SUM(IIF(serv_type = "IPD" AND status $ "P", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD" AND status $ "P", paid, 0)) AS ipd_paid, ;	
	SUM(IIF(serv_type = "OPD" AND status $ "F", 1, 0)) AS opd_fnoc, ;
	SUM(IIF(serv_type = "OPD" AND status $ "F", paid, 0)) AS opd_fpaid, ;
	SUM(IIF(serv_type = "IPD" AND status $ "F", 1, 0)) AS ipd_fnoc, ;
	SUM(IIF(serv_type = "IPD" AND status $ "F", paid, 0)) AS ipd_fpaid, ;		
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
FROM (gcFundCode+"_"+gcCustID+"_Claim") ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, family_no, plan, serv_type, status, count(*) AS amt ;
FROM (gcFundCode+"_"+gcCustID+"_Claim") ;
GROUP BY policy_no, family_no, plan, serv_type, status ;
INTO CURSOR per_pol
*
SELECT plan, SUM(IIF(serv_type = "OPD" AND status $ "P", 1, 0)) AS opd_nmc, ;
	SUM(IIF(serv_type = "OPD" AND status $ "F", 1, 0)) AS opd_fnmc, ;
	SUM(IIF(serv_type = "IPD" and status $ "P",  1, 0)) AS ipd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status $ "F",  1, 0)) AS ipd_fnmc, ;	
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
SELECT _SumMember.plan, _SumMember.nom_year, ;
	_SumMember.eqa_year, _SumMember.premium, _SumMember.ep_year, ;
	_SumType.opd_noc, _SumType.opd_nmc, _SumType.opd_paid, _SumType.opd_fnoc, _SumType.opd_fnmc, _SumType.opd_fpaid, ;
	_SumType.e_o_noc, _SumType.e_o_paid, _SumType.d_o_noc, _SumType.d_o_paid, ;
	_SumType.ipd_noc, _SumType.ipd_nmc, _SumType.ipd_paid, _SumType.ipd_fnoc, _SumType.ipd_fnmc, _SumType.ipd_fpaid, ;
	_SumType.e_i_noc, _SumType.e_i_paid, _SumType.d_i_noc, _SumType.d_i_paid, ;
	_SumType.w_opd_nmc+ _sumtype.w_ipd_nmc AS w_nmc, ;
	_SumType.out_o_noc+_SumType.out_i_noc AS w_noc, _SumType.out_o_paid+_SumType.out_i_paid AS w_paid ;	
FROM _SumType RIGHT JOIN _SumMember ;
	ON _SumType.plan = _SumMember.plan ;
ORDER BY 1 ;		
INTO TABLE (gcFundCode+"_"+gcCustID+"_PlanbyService_Year")
*
**********************************
PROCEDURE Q_PlanbyCategory_Month

SELECT plan, cat_code, descriptio, benefit, ;
	SUM(IIF(status $ "PF", charge, 0)) AS charge, ;
	SUM(IIF(status $ "PF", paid, 0)) AS paid, ;
	SUM(IIF(status $ "PF", exgratia, 0)) AS exgratia, ;
	SUM(IIF(status $ "PF", 1, 0)) AS noc ;
FROM (gcFundCode+"_"+gcCustID+"_Claimline") ;
WHERE cat_code # "OTHER" ;
GROUP BY plan, cat_code, benefit ;
ORDER BY plan ;
INTO TABLE (gcFundCode+"_"+gcCustID+"_PlanbyCategory_Month")
*
*End Query Claim by service
*
**********************************************************
PROCEDURE q_rolling

lcRollingFile = gcFundCode+"_"+gcCustID+"_Rolling"
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
	SELECT Claim.notify_no, Claim.notify_date, Claim.claim_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS service, ;
	Claim.admis_date, IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid+Claim.over_respond, Claim.fbenfpaid+Claim.deduc) AS paid, ;
	IIF(INLIST(result, "W5", "P5"), "F", LEFT(result,1)) AS status, Claim.result, Claim.return_date ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "T" ;
	AND Claim.result # "C" ;	
	AND TTOD(claim_date) BETWEEN ldStartDate AND ldEndDate ;			
	INTO CURSOR curClaimN	
	*
	SELECT Claim.notify_no, Claim.notify_date, Claim.claim_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS service, ;
	Claim.admis_date, IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid+Claim.over_respond, Claim.fbenfpaid+Claim.deduc) AS paid, ;
	IIF(INLIST(result, "W5", "P5"), "F", LEFT(result,1)) AS status, Claim.result, Claim.return_date ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "T" ;
	AND Claim.result # "C" ;	
	AND TTOD(Claim.admis_date) BETWEEN ldStartDate AND ldEndDate ;			
	INTO CURSOR curClaimM
	*
	SELECT Claim.notify_no, Claim.notify_date, Claim.claim_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS service, ;
	Claim.admis_date, IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid+Claim.over_respond, Claim.fbenfpaid+Claim.deduc) AS paid, ;
	IIF(INLIST(result, "W5", "P5"), "F", LEFT(result,1)) AS status, Claim.result, Claim.return_date ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "T" ;
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
PROCEDURE q_claimrolling

lcRollingFile = gcFundCode+"_"+gcCustID+"_ClaimRolling"
*
CREATE TABLE (lcRollingFile) FREE (months C(6), nom Y, eqal Y, ep Y, opd_amt1 I, opd_paid1 Y, ipd_amt1 I, ipd_paid1 Y, out_amt1 I, out_paid1 Y, d_amt1 I, opd_amt2 I, opd_paid2 Y, ipd_amt2 I, ipd_paid2 Y, d_amt2 I)
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
	SELECT Claim.notify_no, Claim.notify_date, Claim.claim_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS service, ;
	Claim.admis_date, IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid+Claim.over_respond, Claim.fbenfpaid+Claim.deduc) AS paid, ;
	IIF(INLIST(result, "W5", "P5"), "F", LEFT(result,1)) AS status, Claim.result, Claim.return_date ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "T" ;
	AND Claim.result # "C" ;	
	AND TTOD(claim_date) BETWEEN ldStartDate AND ldEndDate ;			
	INTO CURSOR curClaimN	
	*
	SELECT LEFT(CMONTH(ldStartDate),3)+"-"+RIGHT(STR(YEAR(ldStartDate),4),2) AS months, ;
		SUM(IIF(service = "OPD" AND status $ "PF", 1, 0)) AS opd_amt1, ;
		SUM(IIF(service = "OPD" AND status $ "PF", paid, 0)) AS opd_paid1, ;
		SUM(IIF(service = "IPD" AND status $ "PF", 1, 0)) AS ipd_amt1, ;
		SUM(IIF(service = "IPD" AND status $ "PF", paid, 0)) AS ipd_paid1, ;
		SUM(IIF(status = "W", 1, 0)) AS out_amt1, ;
		SUM(IIF(status = "W", paid, 0)) AS out_paid1, ;
		SUM(IIF(status = "D", 1, 0)) AS d_amt1 ;
	FROM curClaimN ;
	GROUP BY 1 ;
	INTO CURSOR curGroupN
	*
	SELECT Claim.notify_no, Claim.notify_date, Claim.claim_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS service, ;
	Claim.admis_date, IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid+Claim.over_respond, Claim.fbenfpaid+Claim.deduc) AS paid, ;
	IIF(INLIST(result, "W5", "P5"), "F", LEFT(result,1)) AS status, Claim.result, Claim.return_date ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no = lcPolicyNo ;	
	AND Claim.claim_with = "T" ;
	AND Claim.result # "C" ;	
	AND Claim.return_date BETWEEN ldStartDate AND ldEndDate ;			
	INTO CURSOR curClaimR
	*
	SELECT LEFT(CMONTH(ldStartDate),3)+"-"+RIGHT(STR(YEAR(ldStartDate),4),2) AS months, ;
		SUM(IIF(service = "OPD" AND LEFT(result, 1) = "P", 1, 0)) AS opd_amt2, ;
		SUM(IIF(service = "OPD" AND LEFT(result, 1) = "P", paid, 0)) AS opd_paid2, ;
		SUM(IIF(service = "IPD" AND LEFT(result, 1) = "P", 1, 0)) AS ipd_amt2, ;
		SUM(IIF(service = "IPD" AND LEFT(result, 1) = "P", paid, 0)) AS ipd_paid2, ;
		SUM(IIF(LEFT(result, 1) = "D", 1, 0)) AS d_amt2 ;
	FROM curClaimR ;
	GROUP BY 1 ;
	INTO CURSOR curGroupR
	*
	SELECT curGroupN
	SCATTER MEMVAR 
	SELECT curGroupR
	SCATTER MEMVAR 	
	*
	m.months = LEFT(CMONTH(ldStartDate),3)+"-"+RIGHT(STR(YEAR(ldStartDate),4),2)
	********************************
	INSERT INTO (lcRollingFile) FROM MEMVAR 
	*************************************************************************
	ldStartDate = GOMONTH(ldStartDate,1)
	ldStartDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), DAY(ldStartDate))
ENDDO 	
*******************************
