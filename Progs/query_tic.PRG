PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption
	
SET SAFETY OFF 	
********************
lcOldDir = SYS(5)+SYS(2003)
glMonth = .F.	
gcFundCode = "TIC"
gdEndDate = DATE() - DAY(DATE())
gdStartDate = gdEndDate - IIF(MOD(YEAR(gdEndDate),4) = 0, 366, 365)
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
lcOldDir = SYS(5)+SYS(2003)
SET DEFAULT TO (gcSaveTo)

DO m_run
DO c_run
*********************************************************
PROCEDURE m_run
SELECT Member.tpacode, Member.policy_no, Member.product AS plan, ;
	Member.effective, Member.expiry, Member.premium, ;
 	LEFT(CMONTH(effective),3)+"-"+RIGHT(STR(YEAR(effective),4),2) AS eff_m, ;
  	IIF(effective >= gtCurDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtCurDate AND expiry >= gtCurDate, TTOD(gtCurDate), {})) AS start_month, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry >= gtCurDate AND expiry <= gtEndDate, TTOD(expiry), {})) AS end_month, ;
	IIF(effective >= gtStartDate AND effective <= gtEndDate, TTOD(effective), IIF(effective <= gtStartDate AND expiry >= gtStartDate, gdStartDate, {})) AS start_roll, ;
	IIF(expiry >= gtEndDate, gdEndDate, IIF(expiry <= gtEndDate, TTOD(expiry), {})) AS end_roll, ;
	premium/365.25 AS prem_day ;
FROM cims!Member;
WHERE Member.tpacode = gcFundCode;
   AND Member.expiry >= gtStartDate;
INTO CURSOR Q_memb
 *
SELECT tpacode, policy_no, plan, effective, expiry, premium, eff_m, prem_day, ;
	start_month, end_month, IIF(EMPTY(start_month), 0, 1) AS m_nominal, ;
	IIF(EMPTY(start_month), 0.0000, (end_month-start_month)+1) AS m_days, ;
	IIF(EMPTY(start_month), 0.0000, ((end_month-start_month)+1)/((gdEndDate - gdCurDate)+1)) AS eqa_month, ;
	IIF(EMPTY(start_month), 0.0000, ((end_month-start_month)+1)*prem_day) AS ep_month, ;	
	start_roll, end_roll, IIF(EMPTY(start_roll), 0, 1) AS y_nominal, ;
	IIF(EMPTY(start_roll), 0, (end_roll-start_roll)+1) AS y_days, ;	
	IIF(EMPTY(start_roll), 0, ((end_roll-start_roll)+1)/((gdEndDate - gdStartDate)+1)) AS eqa_year, ;
	IIF(EMPTY(start_roll), 0, ((end_roll-start_roll)+1)*prem_day) AS ep_year ;	
FROM Q_memb ;	
INTO DBF (gcFundCode+"_member")	
*
**************************************************************************
SELECT Claim.notify_no, Claim.notify_date, ;
	IIF(Claim.service_type = "IPD","IPD","OPD") AS serv_type, Claim.fundcode, ;
	Claim.policy_no, Claim.plan, Claim.client_name, Claim.admis_date, Claim.disc_date, ;
 	LEFT(CMONTH(admis_date),3)+"-"+RIGHT(STR(YEAR(admis_date),4),2) AS admis_m, ;
	fcharge-fdiscount AS fcharge, fbenfpaid, fnopaid, ;
	scharge-sdiscount AS scharge, sbenfpaid, snopaid, exgratia, ;
	IIF(sbenfpaid = 0 AND fbenfpaid = 0, exgratia, IIF(sbenfpaid = 0, fbenfpaid, IIF(sbenfpaid <> 0 AND exgratia <> 0, sbenfpaid+exgratia, sbenfpaid))) AS paid, ;
	LEFT(result,1) AS status, return_date, result, ;
	((return_date-TTOD(notify_date)) - holidays(TTOD(notify_date), return_date))+1 AS workdays ;	
FROM cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.notify_date BETWEEN gtStartDate AND gtEndDate ;
	AND Claim.admis_date BETWEEN gtStartDate AND gtEndDate ;
	AND !INLIST(LEFT(result,1), "C", "D") AND result # "W2" ;
INTO TABLE (gcFundCode + "_Claim")
*
SELECT Claim.notify_no, Claim.notify_date,;
	IIF(Claim.service_type = "IPD","IPD","OPD") AS serv_type, Claim.fundcode, ;
	Claim.policy_no, Claim.plan, Claim_line.cat_code, Claim_line.description, ;
	Claim_line.fcharge, Claim_line.fpaid, Claim_line.scharge, ;
	Claim_line.spaid, Claim_line.exgratia, Claim.result, ;
	IIF(Claim_line.spaid = 0 AND Claim_line.fpaid = 0, Claim_line.exgratia, IIF(Claim_line.spaid = 0, Claim_line.fpaid, Claim_line.spaid+Claim_line.exgratia)) AS paid ; 
 FROM  cims!claim INNER JOIN cims!claim_line ;
   ON  Claim.notify_no = Claim_line.notify_no;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.notify_date BETWEEN gtStartDate AND gtEndDate ;
	AND Claim.admis_date BETWEEN gtStartDate AND gtEndDate ;
	AND !INLIST(LEFT(result,1), "C", "D") AND result # "W2" ;
INTO TABLE (gcFundCode + "_ClaimLine")
*****************************************************
PROCEDURE c_run
*
SELECT plan, SUM(y_nominal) AS nominal_y, ; 
	SUM(eqa_year) AS eqa_year, ;
	SUM(ep_year) AS ep_year, ;
	SUM(eqa_month) AS eqa_month, ;
	SUM(ep_month) AS ep_month ;
FROM tic_member ;
GROUP BY plan ;
INTO CURSOR eal 
*
SELECT plan, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD" AND status = "P", paid, 0)) opd_paid, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD" AND status = "P", paid, 0)) ipd_paid, ;	
	SUM(IIF(serv_type = "OPD" AND status $ "AW", 1, 0)) AS out_o_noc, ;	
	SUM(IIF( serv_type = "OPD" AND status $ "AW", paid, 0)) out_o_paid, ;
	SUM(IIF(serv_type = "IPD" AND status $ "AW", 1, 0)) AS out_i_noc, ;
	SUM(IIF( serv_type = "IPD" AND status $ "AW", paid, 0)) out_i_paid, ;
	SUM(IIF(status = "P", paid, 0)) AS cp ;
FROM tic_claim ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR noc
*
SELECT eal.plan, eal.nominal_y, eal.eqa_year, eal.ep_year, ;
	noc.opd_noc, noc.opd_paid, noc.ipd_noc, noc.ipd_paid, ;
	noc.out_o_noc, noc.out_o_paid, noc.out_i_noc, noc.out_i_paid, noc.cp, ;
	eal.ep_month, eal.eqa_month ;
FROM eal INNER JOIN noc ;
	ON eal.plan = noc.plan ;
ORDER BY eal.plan ;
INTO DBF Tic_Rolling		
*
**************************************************************
*
SELECT eff_m, ;
	SUM(eqa_year) AS eqa_year, ;
	SUM(ep_year) AS ep_year ;
FROM tic_member ;
GROUP BY eff_m ;
INTO CURSOR eal_m
*
SELECT admis_m, ;
	SUM(IIF(status = "P", paid, 0)) AS cp_m ;
FROM tic_claim ;
GROUP BY admis_m ;
INTO CURSOR cp_m
*
SELECT eal_m.eff_m, eal_m.eqa_year, eal_m.ep_year, cp_m.cp_m ;
FROM eal_m INNER JOIN cp_m ;
	ON eal_m.eff_m = cp_m.admis_m ;
ORDER BY 1 ;
INTO DBF month
*	 	 
SELECT serv_type, ;
	SUM(IIF(serv_type = "OPD", 1, 0)) AS opd_noc, ;
	SUM(IIF(serv_type = "OPD", paid, 0)) AS opd_paid, ;
	SUM(IIF(serv_type = "IPD", 1, 0)) AS ipd_noc, ;
	SUM(IIF(serv_type = "IPD", paid, 0)) AS ipd_paid ;
FROM tic_claimline ;
GROUP BY serv_type ;
INTO DBF service
*
SELECT cat_code, ;
	SUM(scharge) AS charge, ;
	SUM(paid) AS paid ;
FROM tic_claimline ;
GROUP BY cat_code ;
INTO DBF ipd_benefit	
*
SELECT serv_type, SUM(IIF(workdays <= 1, 1, 0)) AS day_1, ;
	SUM(IIF(workdays = 2, 1, 0)) AS day_2, SUM(IIF(workdays = 3, 1, 0)) AS day_3, ;	
	SUM(IIF(workdays = 4, 1, 0)) AS day_4, SUM(IIF(workdays = 5, 1, 0)) AS day_5, ;	
	SUM(IIF(workdays = 6, 1, 0)) AS day_6, SUM(IIF(workdays >= 7 AND workdays <= 10, 1, 0)) AS day_7, ;	
	SUM(IIF(workdays > 10, 1, 0)) AS day_11 ;
FROM tic_claim ;
GROUP BY 1 ;
WHERE status $ "DP" ;
	AND result # "P" ;
INTO DBF aging