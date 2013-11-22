PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption
	
SET SAFETY OFF 	
********************
glMonth = .F.	
gcStartDate = "Start Date"
gcEndDate = "End Date"
gcFundCode = "KTA"
gdEndDate = DATE(YEAR(DATE()), MONTH(DATE()), 25)
gdStartDate = (gdEndDate - IIF(MOD(YEAR(gdEndDate),4) = 0, 366, 365))+1
gnOption = 1
gnType = 1
gnRolling = 12
gcSaveTo = gcTemp
DO FORM form\Rollingentry
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF

gdCurDate = gdEndDate - IIF(INLIST(MONTH(gdEndDate), 1,3,5,7,8,10,12), 31, IIF(MONTH(gdEnddate) = 2, IIF(MOD(YEAR(gdEndDate),4) = 0, 29, 28), 30))
gtCurDate = DATETIME(YEAR(gdCurDate), MONTH(gdCurDate), 26, 00, 00)
gtStartDate = DATETIME(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate), 00, 00)
gtEndDate = DATETIME(YEAR(gdEndDate), MONTH(gdEndDate), DAY(gdEndDate), 23, 59)
gcSaveTo = IIF(EMPTY(gcSaveTo), gcTemp, gcSaveTo)

IF !DIRECTORY(gcSaveTo)
	MKDIR &gcSaveTo
ENDIF 	
***********************
lcOldDir = SYS(5)+SYS(2003)
SET DEFAULT TO (gcSaveTo)
SET TALK ON 
SET TALK WINDOW 
****************
DO q_member
DO q_claim
DO q_run
DO c_run
****************
SET TALK OFF 
SET DEFAULT TO (lcOldDir)
**************************************************************
PROCEDURE q_member
*
SELECT tpacode, ALLTRIM(policy_no) AS policy_no, ;
	IIF(INLIST(LEFT(product,2), "HS", "HI"), STRTRAN(product, "BN", "-N"), ;
	IIF(customer_type = "G", LEFT(policy_no,3), IIF(LEFT(product,3) = "MEA", LEFT(product,4), STRTRAN(product, "BN", "-N")))) AS plan,;
	IIF(product = "MEA", LEFT(product,3), LEFT(product,2)+RIGHT(ALLTRIM(product),2)) AS plan_type, IIF(LEN(ALLTRIM(policy_no)) = 8, start_date, effective) AS effective, expiry, premium, ;
	premium/365.25 AS prem_day ;
 FROM cims!member ;
 WHERE tpacode = gcFundCode ;
 	AND expiry >= gdStartDate ;
 	AND customer_type $ "IG" ;
 	AND !INLIST(LEFT(product,2), "AI", "HB") ;
INTO CURSOR Q_member

SELECT tpacode, policy_no, plan, plan_type, effective, expiry, premium, prem_day, ;	
	IIF(effective >= gtCurDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtCurDate AND expiry >= gtCurDate, TTOD(gtCurDate), {})) AS start_month, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry >= gtCurDate AND expiry <= gtEndDate, TTOD(expiry), {})) AS end_month, ;
	IIF(effective >= gtStartDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtStartDate AND expiry >= gtStartDate, gdStartDate, {})) AS start_roll, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry <= gtEndDate, TTOD(expiry), {})) AS end_roll ;
 FROM Q_member ;
INTO CURSOR Q_memb
*
SELECT tpacode, policy_no, plan, plan_type, effective, expiry, premium, prem_day, ;
	start_month, end_month, IIF(EMPTY(start_month), 0, 1) AS m_nominal, ;
	IIF(EMPTY(start_month), 000, (end_month-start_month)+1) AS m_days, ;
	IIF(EMPTY(start_month), 000.0000, ((end_month-start_month)+1)/((gdEndDate - gdCurDate)+1)) AS eqa_month, ;
	IIF(EMPTY(start_month), 000.0000, ((end_month-start_month)+1)*prem_day) AS ep_month, ;	
	start_roll, end_roll, IIF(EMPTY(start_roll), 0, 1) AS y_nominal, ;
	IIF(EMPTY(start_roll), 000, (end_roll-start_roll)+1) AS y_days, ;	
	IIF(EMPTY(start_roll), 000.0000, ((end_roll-start_roll)+1)/((gdEndDate - gdStartDate)+1)) AS eqa_year, ;
	IIF(EMPTY(start_roll), 000.0000, ((end_roll-start_roll)+1)*prem_day) AS ep_year ;	
FROM Q_memb ;	
INTO TABLE (gcFundCode+"_member")	
*
*******************************************
*
PROCEDURE q_claim
SELECT notify_no, notify_date, policy_no, client_name, ;
	IIF(INLIST(LEFT(plan,2), "HS", "HI"), STRTRAN(plan, "BN", "-N"), ;
	IIF(claim.claim_with = "G", LEFT(policy_no,3), IIF(LEFT(plan,3) = "MEA", LEFT(plan,4),STRTRAN(plan, "BN", "-N")))) AS plan,;	
	IIF(plan = "MEA", plan, LEFT(plan,2)+RIGHT(ALLTRIM(plan),2)) AS plan_type, ;
	IIF(claim_type = 2, "IPD", "OPD") AS serv_type, admis_date, disc_date, ;
	LEFT(CMONTH(admis_date),3)+"-"+RIGHT(STR(YEAR(admis_date),4),2) AS admis_m, ;
	fcharge-fdiscount AS fcharge, fbenfpaid, fnopaid, ;
	scharge-sdiscount AS scharge, sbenfpaid, snopaid, IIF(EMPTY(fax_by), abenfpaid, exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid) + IIF(EMPTY(fax_by), abenfpaid, exgratia) AS paid, ;	
	IIF(LEFT(result,1) = "W", "W", IIF(LEFT(result,1) = "D", "D", "P")) AS status, return_date, result  ;
FROM cims!claim ;
WHERE fundcode = gcFundCode ;
	AND result # "C1" ;
	AND admis_date between gtStartDate AND gtEndDate ;
INTO TABLE (gcFundCode+"_claim_Actuary")
*
SELECT notify_no, notify_date, policy_no, client_name, refno, ;
	IIF(claim.claim_with = "G", LEFT(policy_no,3), IIF(LEFT(plan,3) = "MEA", LEFT(plan,4), STRTRAN(plan, "BN", "-N"))) AS plan,;	
	IIF(plan = "MEA", LEFT(plan,3), LEFT(plan,2)+RIGHT(ALLTRIM(plan),2)) AS plan_type, ;
	IIF(claim_type = 2, "IPD", "OPD") AS serv_type, ;
	admis_date, disc_date, ;
	LEFT(CMONTH(admis_date),3)+"-"+RIGHT(STR(YEAR(admis_date),4),2) AS admis_m, ;
	fcharge-fdiscount AS fcharge, fbenfpaid, fnopaid, ;
	scharge-sdiscount AS scharge, sbenfpaid, snopaid, IIF(EMPTY(fax_by), abenfpaid, exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid) + IIF(EMPTY(fax_by), abenfpaid, exgratia) AS paid, ;	
	IIF(EMPTY(Claim.fax_by), IIF(LEFT(result,1) = "W", "W", IIF(LEFT(result,1) = "D", "D", "P")), "F") AS status, return_date, result, unclean, unclean_note, ;
	((return_date-TTOD(notify_date)) - holidays(TTOD(notify_date), return_date)) AS workdays, LEFT(Claim.agent_code,5) AS agent_code ;		
FROM cims!claim ;
WHERE fundcode = gcFundCode ;
	AND !INLIST(result, "P5", "C1") ;	
	AND notify_date between gtCurDate AND gtEndDate ;	
INTO TABLE  (gcFundCode+"_claim_DPT")
*
***********************************************
PROCEDURE q_run

*Query for Actuary Report
SELECT plan, plan_type, SUM(eqa_month) AS eqa_month, SUM(ep_month) AS ep_month, ;
	SUM(eqa_year) AS eqa_year, SUM(ep_year) AS ep_year ;
FROM kta_member ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR eal
**
SELECT plan, plan_type, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", paid, 0)) opd_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", paid, 0)) ipd_paid, ;	
	SUM(IIF(serv_type = "OPD" AND status = "W", 1, 0)) AS out_o_noc, ;	
	SUM(IIF( serv_type = "OPD" AND status = "W", paid, 0)) out_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "W", 1, 0)) AS out_i_noc, ;
	SUM(IIF( serv_type = "IPD" AND status = "W", paid, 0)) out_i_paid, ;
	SUM(IIF(status = "P", paid, 0)) AS cp, ;
	SUM(IIF( status = "W", paid, 0)) out_paid ;	
FROM kta_claim_actuary ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR noc
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, plan, plan_type, serv_type, count(*) AS amt ;
FROM kta_claim_actuary ;
GROUP BY policy_no, plan, serv_type ;
WHERE LEFT(result,1) = "P" ;
INTO CURSOR per_pol

SELECT plan, plan_type, SUM(IIF(serv_type = "OPD", 1, 0)) AS opd_nmc, ;
	SUM(IIF(serv_type = "IPD",  1, 0)) AS ipd_nmc ;
FROM per_pol ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR nmc
*
SELECT eal.plan, EAL.plan_type, EAL.eqa_year, EAL.ep_year, ;
	NOC.opd_noc, NOC.opd_paid, NOC.ipd_noc, NOC.ipd_paid, NOC.out_o_noc, NOC.out_o_paid, NOC.out_i_noc, NOC.out_i_paid ;
FROM eal  LEFT JOIN noc ;
	ON EAL.plan = NOC.plan ;
INTO CURSOR utili
*
SELECT UTILI.plan, UTILI.plan_type, UTILI.eqa_year, UTILI.ep_year, UTILI.opd_noc, UTILI.opd_paid, UTILI.ipd_noc, UTILI.ipd_paid, ;
	UTILI.out_o_noc, UTILI.out_o_paid, UTILI.out_i_noc, UTILI.out_i_paid, NMC.opd_nmc, NMC.ipd_nmc ;
FROM utili LEFT JOIN nmc ;
	ON UTILI.plan = NMC.plan ;
ORDER BY 2 ;	
INTO TABLE utilization
*
*******************************************************************************************
PROCEDURE c_run 


SELECT plan, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", paid, 0)) opd_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", paid, 0)) ipd_paid, ;	
	SUM(IIF(serv_type = "OPD" AND status = "W", 1, 0)) AS out_o_noc, ;	
	SUM(IIF( serv_type = "OPD" AND status = "W", paid, 0)) out_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "W", 1, 0)) AS out_i_noc, ;
	SUM(IIF( serv_type = "IPD" AND status = "W", paid, 0)) out_i_paid, ;
	SUM(IIF(status = "P", paid, 0)) AS cp_month, ;
	SUM(IIF(status = "W", paid, 0)) odc_paid ;	
FROM kta_claim_DPT ;
GROUP BY plan ;
ORDER BY plan ;
INTO TABLE Claim_DPT
*
SELECT agent_code, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", paid, 0)) opd_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", paid, 0)) ipd_paid, ;	
	SUM(IIF(serv_type = "OPD" AND status = "W", 1, 0)) AS out_o_noc, ;	
	SUM(IIF( serv_type = "OPD" AND status = "W", paid, 0)) out_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "W", 1, 0)) AS out_i_noc, ;
	SUM(IIF( serv_type = "IPD" AND status = "W", paid, 0)) out_i_paid, ;
	SUM(IIF(status = "P", paid, 0)) AS cp_month, ;
	SUM(IIF( status = "W", paid, 0)) odc_paid ;	
FROM kta_claim_DPT ;
GROUP BY agent_code ;
ORDER BY agent_code ;
INTO TABLE Claim_Agent
*
SELECT eal.plan, eal.ep_month, claim_dpt.cp_month, claim_dpt.odc_paid ;
FROM eal LEFT JOIN claim_dpt ;
	ON eal.plan = claim_dpt.plan ;
ORDER BY 1 ;
INTO TABLE loss	
*
SELECT LEFT(plan,2) AS plan, SUM(eqa_month) AS eqa_month, SUM(ep_month) AS ep_month ;
FROM kta_member ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR eal_m
*
*query No. of member claims(หาจำนวนที่ผู้เอาประกันเคลม)
SELECT policy_no, plan, serv_type, result, status, count(*) AS amt ;
FROM kta_claim_DPT ;
GROUP BY policy_no, plan, serv_type, status ;
INTO CURSOR per_pol
*
SELECT LEFT(plan,2) AS plan, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS p_opd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status = "P",  1, 0)) AS p_ipd_nmc, ;
	SUM(IIF(serv_type = "OPD" AND status = "F", 1, 0)) AS f_opd_nmc, ;
	SUM(IIF(serv_type = "IPD" and status = "F",  1, 0)) AS f_ipd_nmc, ;
	SUM(IIF(status = "D", 1, 0)) AS denied_nmc, ;
	SUM(IIF(status = "W", 1, 0)) AS out_nmc, ;
	SUM(IIF(INLIST(result, "W2", "W4", "W8"), 1, 0)) AS wd_nmc, ;
	SUM(IIF(INLIST(result, "W7"), 1, 0)) AS wi_nmc ;					
FROM per_pol ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR nmc_m
*
SELECT LEFT(plan,2) AS plan, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS p_opd, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", paid, 0)) AS p_opaid, ;
	SUM(IIF(serv_type = "IPD" and status = "P",  1, 0)) AS p_ipd, ;
	SUM(IIF(serv_type = "IPD" and status = "P",  paid, 0)) AS p_ipaid, ;	
	SUM(IIF(serv_type = "OPD" AND status = "F", 1, 0)) AS f_opd, ;
	SUM(IIF(serv_type = "OPD" AND status = "F", paid, 0)) AS f_opaid, ;	
	SUM(IIF(serv_type = "IPD" and status = "F",  1, 0)) AS f_ipd, ;
	SUM(IIF(serv_type = "IPD" and status = "F",  paid, 0)) AS f_ipaid, ;
	SUM(IIF(status = "D", 1, 0)) AS denied, ;
	SUM(IIF(status = "W", 1, 0)) AS out_noc, ;
	SUM(IIF(status = "W", paid, 0)) AS out_paid, ;
	SUM(IIF(INLIST(result, "W2", "W4", "W8"), 1, 0)) AS wd_noc, ;
	SUM(IIF(INLIST(result, "W2", "W4", "W8"), paid, 0)) AS wd_paid, ;
	SUM(IIF(INLIST(result, "W7"), 1, 0)) AS wi_noc, ;
	SUM(IIF(INLIST(result, "W7"), paid, 0)) AS wi_paid ;	
FROM kta_claim_dpt ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR noc_m
*
SELECT nmc_m.plan, nmc_m.p_opd_nmc, noc_m.p_opd, noc_m.p_opaid, nmc_m.p_ipd_nmc, noc_m.p_ipd, noc_m.p_ipaid, ;
	nmc_m.f_opd_nmc + nmc_m.f_ipd_nmc AS f_nmc, noc_m.f_opd + noc_m.f_ipd AS f_noc, noc_m.f_opaid, + noc_m.f_ipaid AS f_paid, ;
	nmc_m.denied_nmc, nmc_m.out_nmc, noc_m.out_noc, noc_m.out_paid, nmc_m.wd_nmc, noc_m.wd_noc, noc_m.wd_paid, nmc_m.wi_nmc, noc_m.wi_noc, noc_m.wi_paid ;
FROM nmc_m FULL JOIN noc_m ;
	ON nmc_m.plan = noc_m.plan ;
INTO CURSOR cCur		
*
SELECT eal_m.plan, cCur.p_opd_nmc, cCur.p_opd, cCur.p_opaid, cCur.p_ipd_nmc, cCur.p_ipd, cCur.p_ipaid, ;
	cCur.f_nmc, cCur.f_noc, cCur.f_paid, cCur.denied_nmc, cCur.out_nmc, cCur.out_noc, CCur.out_paid, cCur.wd_nmc, cCur.wd_noc, cCur.wd_paid, cCur.wi_nmc, cCur.wi_noc, cCur.wi_paid, ;
	eal_m.ep_month, eal_m.eqa_month ;
FROM cCur RIGHT JOIN eal_m ;
	ON cCur.plan = eal_m.plan ;
INTO TABLE claim_cur		
*
SELECT LEFT(plan,2) as plan, SUM(IIF(workdays <= 1, 1, 0)) AS day_1, ;
	SUM(IIF(workdays = 2, 1, 0)) AS day_2, SUM(IIF(workdays = 3, 1, 0)) AS day_3, ;	
	SUM(IIF(workdays = 4, 1, 0)) AS day_4, SUM(IIF(workdays = 5, 1, 0)) AS day_5, ;	
	SUM(IIF(workdays = 6, 1, 0)) AS day_6, SUM(IIF(workdays >= 7 AND workdays <= 10, 1, 0)) AS day_7, ;	
	SUM(IIF(workdays > 10, 1, 0)) AS day_11 ;
FROM kta_claim_DPT ;
GROUP BY 1 ;
WHERE status $ "PD" ;
	AND EMPTY(unclean) ;
	AND result # "P5" ;
INTO TABLE aging