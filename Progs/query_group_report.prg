PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gcPolicyNo

CLEAR 
CLOSE ALL 	
SET SAFETY OFF 	
SET DELETED ON 
SET ENGINEBEHAVIOR 70 
SET DEFAULT TO e:\hips_src
SET PROCEDURE TO progs\utility
********************
gcTemp = "F:\report\dvs\monthly\"
gcCaption = "Group Monthly Report"
gnRolling = 12
gcStartDate = "Start Date"
gcEndDate = "End Date"
glMonth = .F.	
gcFundCode = "DVS"
gdEndDate = DATE() - DAY(DATE())
gdStartDate = GOMONTH(gdEndDate, -12)
gcPolicyNo = "00/2006-H0000426-NHG"
gcSaveTo = gcTemp
*DO FORM form\Rollingentry1
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
gcPolicyNo = ALLTRIM(gcPolicyNo)+"%"
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
DO q_PlanbyCategory_Year
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
SELECT Dependants.fundcode AS tpacode, Dependants.policy_no, Dependants.plan, Dependants.age, ;
	LEFT(Dependants.plan,2) AS plan_type, ;
	Dependants.hb_limit, Dependants.effective, Dependants.expired AS expiry, Dependants.premium, Dependants.premium/365.25 AS prem_day ;
 FROM cims!Dependants ;
 WHERE Dependants.fundcode = gcFundCode ;
   AND Dependants.policy_no Like gcPolicyNo ;	
   AND Dependants.expired >= gtStartDate ;
 INTO CURSOR Q_member
*
IF RECCOUNT("Q_Member") = 0
	RETURN 
ENDIF 
*	
SELECT tpacode, policy_no, plan, plan_type, hb_limit, effective, expiry, premium, age, prem_day, ;	
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
INTO TABLE (gcFundCode+"_SCG_member")	
*
SELECT plan, ;
	SUM(m_nominal) AS nom_month, SUM(eqa_month) AS eqa_month, SUM(ep_month) AS ep_month, ;
	SUM(y_nominal) AS nom_year, SUM(eqa_year) AS eqa_year, SUM(ep_year) AS ep_year ;
FROM (gcFundcode+"_SCG_member") ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR _SumMember
*
*********************************************************
*
PROCEDURE q_Claim
*
SELECT Claim.notify_no, Claim.notify_date, Claim.claim_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS serv_type, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, Claim.client_name, Claim.plan, LEFT(Claim.plan,2) AS plan_type, claim.plan_id,  ;
	Claim.admis_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, ;
	IIF(EMPTY(Claim.fax_by), Claim.abenfpaid, Claim.exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid+Claim.over_respond, Claim.fbenfpaid+Claim.deduc) AS paid, ;
	IIF(INLIST(result, "W5", "P5"), "F", LEFT(result,1)) AS status, SUBSTR(Claim.customer_id, 4, 11) AS clientID, ;	
	Claim.result, Claim.return_date, Claim.unclean, Claim.unclean_note, Claim.fax_by, Claim.illness1, Icd10thai.thainame, ;
	Claim.prov_name, Claim.dob, Claim.age, ;
	((Claim.return_date-TTOD(Claim.notify_date)) - holidays(TTOD(Claim.notify_date), Claim.return_date)) AS workdays ;	
FROM  cims!claim LEFT JOIN cims!icd10thai ;
	ON claim.illness1 = icd10th.code ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no Like gcPolicyNo ;	
	AND Claim.claim_with = "T" ;
	AND Claim.result # "C" ;	
	AND Claim.admis_date BETWEEN gtStartDate AND gtEndDate ;	
INTO TABLE (gcFundCode+"_SCG_Claim")
**
*Query Claim by Benefit items
SELECT A.fundcode, A.notify_no, A.claim_date,  A.serv_type,  A.policy_no, A.plan_id, A.plan, A.plan_type, A.return_dat, ;
  A.plan+Claim_line.cat_code AS plan_cat, Claim_line.cat_id, Claim_line.cat_code, Claim_line.description, claim_line.group, ;
  IIF(EMPTY(A.fax_by), Claim_line.scharge, Claim_line.fcharge) AS charge, ;
  IIF(EMPTY(A.fax_by), Claim_line.spaid+Claim_line.dpaid, Claim_line.fpaid+Claim_line.deduc) AS paid, ;
  IIF(EMPTY(A.fax_by), Claim_line.apaid, Claim_line.exgratia) AS exgratia, A.result, A.status ;  
FROM (gcFundCode+"_SCG_Claim") A INNER JOIN cims!claim_line ;
	ON  A.notify_no = Claim_line.notify_no ;
WHERE A.status $ "FP" ;	
INTO TABLE (gcFundCode+"_SCG_ClaimlineYear")
*
*Query Current Month Report
*
SELECT Claim.notify_no, Claim.notify_date, Claim.claim_date, IIF(Claim.service_type = "IPD", "IPD", "OPD") AS serv_type, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, Claim.client_name, Claim.plan, LEFT(Claim.plan,2) AS plan_type, ;
	Claim.admis_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, Claim.fax_by, ;
	IIF(EMPTY(Claim.fax_by), Claim.abenfpaid, Claim.exgratia) AS exgratia, Claim.illness1, Claim.prov_name, Claim.dob, Claim.age, ;
	IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid+Claim.over_respond, Claim.fbenfpaid+Claim.deduc) AS paid, ;
	LEFT(result,1) AS status, Claim.result, Claim.return_date, Claim.unclean, Claim.unclean_note, SUBSTR(Claim.customer_id, 4, 11) AS clientID, ;
	((return_date-TTOD(notify_date)) - holidays(TTOD(notify_date), return_date)) AS workdays ;	
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no Like gcPolicyNo ;	
	AND Claim.claim_with = "T" ;
	AND Claim.result # "C" ;
	AND Claim.claim_date BETWEEN gtCurDate AND gtEndDate ;
INTO TABLE (gcFundCode+"_SCG_Claim_Month")
***
*Query Claim by service
SELECT A.fundcode, A.notify_no, A.claim_date,  A.serv_type,  A.policy_no, A.plan, A.plan_type, A.return_dat, ;
  A.plan+Claim_line.cat_code AS plan_cat, Claim_line.cat_code, Claim_line.description, Claim_line.benefit, ;
  IIF(EMPTY(A.fax_by), Claim_line.scharge, Claim_line.fcharge) AS charge, ;
  IIF(EMPTY(A.fax_by), Claim_line.spaid+Claim_line.dpaid, Claim_line.fpaid+Claim_line.deduc) AS paid, ;
  IIF(EMPTY(A.fax_by), Claim_line.apaid, Claim_line.exgratia) AS exgratia, A.result, A.status ;  
FROM (gcFundCode+"_SCG_Claim_Month") A INNER JOIN cims!claim_line ;
	ON  A.notify_no = Claim_line.notify_no ;
WHERE A.serv_type = "IPD" ;
	AND A.status = "P" ;	
INTO TABLE (gcFundCode+"_SCG_Claimline")
*
SELECT serv_type, SUM(IIF(workdays <= 1, 1, 0)) AS day_1, ;
	SUM(IIF(workdays = 2, 1, 0)) AS day_2, SUM(IIF(workdays = 3, 1, 0)) AS day_3, ;	
	SUM(IIF(workdays = 4, 1, 0)) AS day_4, SUM(IIF(workdays = 5, 1, 0)) AS day_5, ;	
	SUM(IIF(workdays = 6, 1, 0)) AS day_6, SUM(IIF(workdays >= 7 AND workdays <= 10, 1, 0)) AS day_7, ;	
	SUM(IIF(workdays > 10, 1, 0)) AS day_11 ;
FROM (gcFundCode+"_SCG_Claim_Month") ;
GROUP BY 1 ;
WHERE status $ "DP" ;
	AND EMPTY(unclean) ;
	AND result # "P5" ;
INTO TABLE (gcFundCode+"_SCG_Aging")
*
**********************************
PROCEDURE q_PlanbyService_Month
*
SELECT plan, ;
	SUM(IIF(serv_type = "OPD" AND status $ "PF", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD" AND status $ "PF", paid, 0)) AS opd_paid, ;
	SUM(IIF(serv_type = "IPD" AND status $ "PF", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", paid, 0)) AS ipd_paid, ;	
	SUM(IIF(serv_type = "OPD" AND status $ "AW", 1, 0)) AS out_o_noc, ;	
	SUM(IIF(serv_type = "OPD" AND status $ "AW", paid, 0)) AS out_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW", 1, 0)) AS out_i_noc, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW", paid, 0)) AS out_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND status = "D", 1, 0)) AS d_o_noc, ;	
	SUM(IIF(serv_type = "OPD" AND status = "D", paid, 0)) d_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "D", 1, 0)) AS d_i_noc, ;	
	SUM(IIF(serv_type = "IPD" AND status = "D", paid, 0)) d_i_paid, ;
	SUM(IIF(serv_type = "OPD" AND exgratia # 0, 1, 0)) AS e_o_noc, ;
	SUM(IIF(serv_type = "OPD" AND exgratia # 0, exgratia, 0)) AS e_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND exgratia # 0, 1, 0)) AS e_i_noc, ;
	SUM(IIF(serv_type = "IPD" AND exgratia # 0, exgratia, 0)) AS e_i_paid ;
FROM (gcFundCode+"_SCG_Claim_Month") ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc_m
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, family_no, plan, serv_type, status, count(*) AS amt ;
FROM (gcFundCode+"_SCG_Claim_Month") ;
GROUP BY policy_no, family_no, plan, serv_type, status ;
INTO CURSOR pol_1
*
SELECT plan, ;
	SUM(IIF(serv_type = "OPD" AND status $ "PF", 1, 0)) AS opd_nmc, ;
	SUM(IIF(serv_type = "OPD" AND status $ "AW", 1, 0)) AS w_opd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status $ "PF",  1, 0)) AS ipd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status $ "AW",  1, 0)) AS w_ipd_nmc ;	
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
INTO TABLE (gcFundCode+"_SCG_PlanbyService_Month")
*End Query Current Month Report
*
**********************************
PROCEDURE Q_PlanbyService_Year

SELECT plan, ;
	SUM(IIF(serv_type = "OPD" AND status $ "PF", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD" AND status $ "PF", paid, 0)) AS opd_paid, ;
	SUM(IIF(serv_type = "IPD" AND status $ "PF", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD" AND status $ "PF", paid, 0)) AS ipd_paid, ;	
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
FROM (gcFundCode+"_SCG_Claim") ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, family_no, plan, serv_type, status, count(*) AS amt ;
FROM (gcFundCode+"_SCG_Claim") ;
GROUP BY policy_no, family_no, plan, serv_type, status ;
INTO CURSOR per_pol
*
SELECT plan, SUM(IIF(serv_type = "OPD" AND status $ "PF", 1, 0)) AS opd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status $ "PF",  1, 0)) AS ipd_nmc, ;
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
INTO TABLE (gcFundCode+"_SCG_PlanbyService_Year")
*
**********************************
PROCEDURE Q_PlanbyCategory_Year

SELECT plan_id, plan, cat_id, cat_code, descriptio, ;
	SUM(IIF(status $ "PF", charge, 0)) AS charge, ;
	SUM(IIF(status $ "PF", paid, 0)) AS paid, ;
	SUM(IIF(status $ "PF", exgratia, 0)) AS exgratia, ;
	SUM(IIF(status $ "PF", 1, 0)) AS noc ;
FROM (gcFundCode+"_SCG_Claimlineyear") ;	
WHERE cat_code # "OTHER" ;
	AND status $ "PF" ;
GROUP BY plan_id, plan, cat_id, descriptio ;
ORDER BY cat_id, plan ;
INTO CURSOR curCategoryYear	

SELECT lines.cat_id, lines.descriptio AS items_desc, lines.plan,  plan2cat.benefit, lines.charge, lines.paid, lines.exgratia ;
FROM curCategoryYear lines LEFT JOIN cims!plan2cat ;
	ON lines.plan_id = plan2cat.plan_id AND lines.cat_id = plan2cat.cat_id ;
ORDER BY 1, 3 ;	
INTO TABLE (gcFundCode+"_SCG_Items_Year")
*******
CREATE TABLE (gcFundCode+"_SCG_SumItems_Year") FREE (items_desc C(50), charge1 Y, paid1 Y, exgratia1 Y, charge2 Y, paid2 Y, exgratia2 Y, charge3 Y, paid3 Y, exgratia3 Y, ;
		charge4 Y, paid4 Y, exgratia4 Y, charge5 Y, paid5 Y, exgratia5 Y, charge6 Y, paid6 Y, exgratia6 Y, charge7 Y, paid7 Y, exgratia7 Y, charge8 Y, paid8 Y, exgratia8 Y,;
		charge9 Y, paid9 Y, exgratia9 Y, charge10 Y, paid10 Y, exgratia10 Y, charge11 Y, paid11 Y, exgratia11 Y)			
*
SELECT (gcFundCode+"_SCG_Items_Year")
DO WHILE !EOF()
	SCATTER MEMVAR 
	STORE 0 TO m.charge1, m.paid1, m.exgratia1, m.charge2, m.paid2, m.exgratia2, m.charge3, m.paid3, m.exgratia3, ; 
		m.charge4, m.paid4, m.exgratia4, m.charge5, m.paid5, m.exgratia5, m.charge6, m.paid6, m.exgratia6, ; 	
		m.charge7, m.paid7, m.exgratia7, m.charge8, m.paid8, m.exgratia8, m.charge9, m.paid9, m.exgratia9, ;
		m.charge10, m.paid10, m.exgratia10, m.charge11, m.paid11, m.exgratia11	
	DO WHILE items_desc = m.items_desc AND !EOF()
		lcCharge = "m.charge"+ALLTRIM(plan)
		lcPaid = "m.paid"+ALLTRIM(plan)
		lcExgratia = "m.exgratia"+ALLTRIM(plan)
	
		&lcCharge = charge
		&lcPaid = paid
		&lcExgratia = exgratia
		SKIP 
	ENDDO 
	INSERT INTO (gcFundCode+"_SCG_SumItems_Year") FROM MEMVAR 
ENDDO
*End Query Claim by benefit items
*
**********************************************************
PROCEDURE Q_PlanbyCategory_Month

SELECT plan, cat_code, descriptio, benefit, ;
	SUM(IIF(status $ "PF", charge, 0)) AS charge, ;
	SUM(IIF(status $ "PF", paid, 0)) AS paid, ;
	SUM(IIF(status $ "PF", exgratia, 0)) AS exgratia, ;
	SUM(IIF(status $ "PF", 1, 0)) AS noc ;
FROM (gcFundCode+"_SCG_Claimline") ;
WHERE cat_code # "OTHER" ;
GROUP BY plan, cat_code, descriptio, benefit ;
ORDER BY plan ;
INTO TABLE (gcFundCode+"_SCG_PlanbyCategory_Month")
*
*End Query Claim by service
*************************************************************
PROCEDURE q_rolling

lcRollingFile = gcFundCode+"_PSCG_Rolling"
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
	SELECT notify_no, claim_date, IIF(service_type = "IPD", "IPD", "OPD") AS service, ;
	IIF(EMPTY(claim.fax_by), sbenfpaid, fbenfpaid) AS paid, ;
	IIF(INLIST(result, "W5", "P5"), "F", LEFT(result,1)) AS status, result ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no Like gcPolicyNo ;	
	AND Claim.claim_with = "T" ;
	AND Claim.result # "C" ;	
	AND TTOD(claim_date) BETWEEN ldStartDate AND ldEndDate ;				
	INTO CURSOR curClaimN	
	*
	SELECT notify_no, admis_date, IIF(service_type = "IPD", "IPD", "OPD")  AS service, ;
	IIF(EMPTY(claim.fax_by), sbenfpaid, fbenfpaid) AS paid, ;
	IIF(INLIST(result, "W5", "P5"), "F", LEFT(result,1)) AS status, result ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no Like gcPolicyNo ;
	AND Claim.claim_with = "T" ;
	AND Claim.result # "C" ;	
	AND TTOD(admis_date) BETWEEN ldStartDate AND ldEndDate ;				
	INTO CURSOR curClaimM
	*
	SELECT curClaimM
	SUM paid TO m.admit FOR status $ "PF"
	m.noc_admit = RECCOUNT()
	*
	SELECT curClaimN
	SUM paid TO m.notifys FOR status $ "PF"	
	m.noc_notify = RECCOUNT()
	*
	m.months = LEFT(CMONTH(ldStartDate),3)+"-"+RIGHT(STR(YEAR(ldStartDate),4),2)
	********************************
	INSERT INTO (lcRollingFile) FROM MEMVAR 
	*************************************************************************
	ldStartDate = GOMONTH(ldStartDate,1)
	ldStartDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), DAY(ldStartDate))
ENDDO 	
*******************************
PROCEDURE q_claimrolling

lcRollingFile = gcFundCode+"_PSCG_ClaimRolling"
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
		SUM(prem_day *((end_month-start_month)+1)) AS ep ;
	FROM curRMonth ;
	WHERE !EMPTY(start_month) ;
	INTO CURSOR curMonths
	SELECT curMonths
	SCATTER MEMVAR 
	***********************************************************************
	SELECT notify_no, claim_date, IIF(service_type = "IPD", "IPD", "OPD")  AS service, ;
	IIF(EMPTY(claim.fax_by), sbenfpaid, fbenfpaid) AS paid, ;
	IIF(INLIST(result, "W5", "P5"), "F", LEFT(result,1)) AS status, result ;
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.policy_no Like gcPolicyNo ;	
	AND Claim.claim_with = "T" ;
	AND Claim.result # "C" ;	
	AND TTOD(claim_date) BETWEEN ldStartDate AND ldEndDate ;			
	INTO CURSOR curClaimN	
	*
	SELECT LEFT(CMONTH(claim_date),3)+"-"+RIGHT(STR(YEAR(claim_date),4),2) AS months, ;
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
*!*		SELECT notify_no, TTOD(admis_date) AS admit, IIF(service_type = "IPD", "IPD", "OPD")  AS service, ;
*!*		IIF(EMPTY(claim.fax_by), sbenfpaid, fbenfpaid) AS paid, ;
*!*		IIF(INLIST(result, "W5", "P5"), "F", LEFT(result,1)) AS status, result ;
*!*		FROM cims!claim ;
*!*		WHERE Claim.fundcode = gcFundCode ;
*!*		AND Claim.policy_no Like gcPolicyNo ;	
*!*		AND Claim.claim_with = "T" ;
*!*		AND Claim.result # "C" ;	
*!*		AND TTOD(Claim.admis_date) BETWEEN ldStartDate AND ldEndDate ;			
*!*		INTO CURSOR curClaimR
	*
	SELECT notify_no, TTOD(admis_date) AS admit, serv_type AS service, paid, status ;
	FROM (gcFundCode+"_SCG_Claim") ;
	WHERE TTOD(admis_date) BETWEEN ldStartDate AND ldEndDate ;
	INTO CURSOR curClaimR
	*
	SELECT LEFT(CMONTH(admit),3)+"-"+RIGHT(STR(YEAR(admit),4),2) AS months, ;
		SUM(IIF(service = "OPD" AND status $ "PF", 1, 0)) AS opd_amt2, ;
		SUM(IIF(service = "OPD" AND status $ "PF", paid, 0)) AS opd_paid2, ;
		SUM(IIF(service = "IPD" AND status $ "PF", 1, 0)) AS ipd_amt2, ;
		SUM(IIF(service = "IPD" AND status $ "PF", paid, 0)) AS ipd_paid2, ;
		SUM(IIF(status = "D", 1, 0)) AS d_amt2 ;
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
