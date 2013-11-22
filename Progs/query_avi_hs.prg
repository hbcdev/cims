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
gcFundCode = "AVI"
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
DO q_PlanbyItems_Year
DO q_PlanbyItems_Month
DO q_rolling
****************
SET TALK OFF 
SET DEFAULT TO (lcOldDir)
**************************************************************
PROCEDURE q_Member
*
SELECT Member.tpacode, Member.policy_no, Member.product AS plan, ;
	LEFT(Member.product,2) AS plan_type, ;
	Member.hb_limit, Member.effective, Member.expiry, Member.premium, Member.premium/365.25 AS prem_day ;
 FROM cims!Member ;
 WHERE Member.tpacode = gcFundCode ;
   AND Member.expiry >= gtStartDate ;
   AND customer_type = "H" ;
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
**********************************************************
PROCEDURE q_Claim
*
SELECT Claim.notify_no, Claim.notify_date, Claim.service_type AS serv_type, Claim.cause_type, Claim.prov_name, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, Claim.client_name, Claim.plan, LEFT(Claim.policy_no,3) AS agent, ;
	Claim.admis_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, Claim.fax_by, ;
	IIF(EMPTY(Claim.fax_by), Claim.scharge, Claim.fcharge) AS charge, ;	
	IIF(EMPTY(Claim.fax_by), Claim.abenfpaid, Claim.exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid, Claim.fbenfpaid) AS paid, ;
	iif(LEFT(result,1) = 'A', 'P', LEFT(result,1))  AS status, Claim.result, ;
	Claim.return_date, Claim.unclean, Claim.unclean_note, ;
	((return_date-TTOD(ref_date)) - holidays(TTOD(ref_date), return_date)) AS workdays ;
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.claim_with = "H" ;
	AND Claim.result # "C" ;	
	AND Claim.admis_date BETWEEN gtStartDate AND gtEndDate ;	
INTO TABLE (gcFundCode+"_HS_Claim")
***
*Query Claim by cause
SELECT A.fundcode, A.notify_no, A.notify_dat,  A.prov_name, A.admis_date, A.cause_type, A.policy_no, A.plan, A.agent, ;
  A.plan+Claim_line.cat_code AS plan_cat, Claim_line.cat_code, Claim_line.description, Claim_line.benefit, ;
  SUBSTR(claim_line.cat_code, 3, 2)+RIGHT(LEFT(ALLTRIM(a.plan), 6),1) AS covercode, ;
  IIF(EMPTY(A.fax_by), Claim_line.scharge, Claim_line.fcharge) AS charge, ;
  IIF(EMPTY(A.fax_by), Claim_line.spaid, Claim_line.fpaid) AS paid, ;
  IIF(EMPTY(A.fax_by), Claim_line.apaid, Claim_line.exgratia) AS exgratia, A.result, A.status ;  
FROM (gcFundCode+"_HS_Claim") A INNER JOIN cims!claim_line ;
	ON  A.notify_no = Claim_line.notify_no ;	
	AND A.status = "P" ;	
WHERE claim_line.scharge <> 0 ;	
INTO TABLE (gcFundCode+"_HS_Claimline_Year")
**
*Query Current Month Report
*
SELECT Claim.notify_no, Claim.notify_date, Claim.service_type AS serv_type, Claim.cause_type, Claim.prov_name, ;
	Claim.fundcode, Claim.policy_no, Claim.family_no, Claim.client_name, Claim.plan, LEFT(Claim.policy_no,3) AS agent, ;
	Claim.admis_date, Claim.fcharge, Claim.fbenfpaid, Claim.scharge, Claim.sbenfpaid, Claim.fax_by, ;
	IIF(EMPTY(Claim.fax_by), Claim.scharge, Claim.fcharge) AS charge, ;	
	IIF(EMPTY(Claim.fax_by), Claim.abenfpaid, Claim.exgratia) AS exgratia, ;
	IIF(EMPTY(Claim.fax_by), Claim.sbenfpaid, Claim.fbenfpaid) AS paid, ;
	iif(LEFT(result,1) = 'A', 'P', LEFT(result,1)) AS status, Claim.result, ;
	Claim.return_date, Claim.unclean, Claim.unclean_note, ;
	((return_date-TTOD(ref_date)) - holidays(TTOD(ref_date), return_date)) AS workdays ;
FROM  cims!claim ;
WHERE Claim.fundcode = gcFundCode ;
	AND Claim.claim_with = "H" ;
	AND inlist(Claim.result, 'A1', 'A11', 'D3', 'D31', 'W6') ;
	AND Claim.ref_date BETWEEN gtCurDate AND gtEndDate ;
INTO TABLE (gcFundCode+"_HS_Claim_Month")
***
*Query Claim by cause
SELECT A.fundcode, A.notify_no, A.notify_dat, A.cause_type, A.policy_no, A.plan, A.agent, ;
  A.plan+Claim_line.cat_code AS plan_cat, Claim_line.cat_code, Claim_line.description, Claim_line.benefit, ;
  SUBSTR(claim_line.cat_code, 3, 2)+RIGHT(LEFT(ALLTRIM(a.plan), 6),1) AS covercode, ;
  IIF(EMPTY(A.fax_by), Claim_line.scharge, Claim_line.fcharge) AS charge, ;
  IIF(EMPTY(A.fax_by), Claim_line.spaid, Claim_line.fpaid) AS paid, ;
  IIF(EMPTY(A.fax_by), Claim_line.apaid, Claim_line.exgratia) AS exgratia, A.result, A.status ;  
FROM (gcFundCode+"_HS_Claim_Month") A INNER JOIN cims!claim_line ;
	ON  A.notify_no = Claim_line.notify_no ;
WHERE claim_line.scharge <> 0 ;
INTO TABLE (gcFundCode+"_HS_Claimline_Month")
*
SELECT serv_type, SUM(IIF(workdays <= 1, 1, 0)) AS day_1, ;
	SUM(IIF(workdays = 2, 1, 0)) AS day_2, SUM(IIF(workdays = 3, 1, 0)) AS day_3, ;	
	SUM(IIF(workdays = 4, 1, 0)) AS day_4, SUM(IIF(workdays = 5, 1, 0)) AS day_5, ;	
	SUM(IIF(workdays = 6, 1, 0)) AS day_6, SUM(IIF(workdays >= 7 AND workdays <= 10, 1, 0)) AS day_7, ;	
	SUM(IIF(workdays > 10, 1, 0)) AS day_11 ;
FROM (gcFundCode+"_HS_Claim_Month") ;
GROUP BY 1 ;
WHERE INLIST(status, "D", "P") ;
	AND EMPTY(unclean) ;
	AND result # "P5" ;
INTO TABLE (gcFundCode+"_HS_Aging")
*
**********************************************
PROCEDURE q_PlanbyItems_Month
*
SELECT cause_type, ;
	SUM(IIF(status = "P", 1, 0)) AS p_noc, ;
	SUM(IIF(status = "P", paid, 0)) AS p_paid, ;
	SUM(IIF(status = "W", 1, 0)) AS w_noc, ;
	SUM(IIF(status = "W", paid, 0)) AS w_paid ;
FROM (gcFundCode+"_HS_Claim_Month") ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_HS_PlanbyItems_Month")
*End Query Current Month Report
*
**********************************************
PROCEDURE Q_PlanbyItems_Year
*
SELECT cause_type, ;
	SUM(IIF(status = "P", 1, 0)) AS p_noc, ;
	SUM(IIF(status = "P", paid, 0)) AS p_paid, ;
	SUM(IIF(status = "W", 1, 0)) AS w_noc, ;
	SUM(IIF(status = "W", paid, 0)) AS w_paid ;
FROM (gcFundCode+"_HS_Claim") ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO TABLE (gcFundCode+"_HS_PlanbyItems_Year")
*
**********************************************************
PROCEDURE q_rolling

lcRollingFile = gcFundCode+"_HS_Rolling"
*
CREATE TABLE (lcRollingFile) FREE (months C(6), nom Y, eqal Y, ep Y, notifys Y, admit Y)
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
	SELECT notify_no, notify_date, IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid) AS paid ;		
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.claim_with = "H" ;
	AND Claim.result = "A" ;
	AND TTOD(Claim.ref_date) BETWEEN ldStartDate AND ldEndDate ;			
	INTO CURSOR curClaimN	
	*
	SELECT notify_no, admis_date, IIF(EMPTY(Claim.fax_by), sbenfpaid, fbenfpaid) AS paid ;	
	FROM cims!claim ;
	WHERE Claim.fundcode = gcFundCode ;
	AND Claim.claim_with = "H" ;
	AND Claim.result = "A" ;	
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
	INSERT INTO (lcRollingFile) FROM MEMVAR 
	*************************************************************************
	ldStartDate = GOMONTH(ldStartDate,1)
	ldStartDate = DATE(YEAR(ldStartDate), MONTH(ldStartDate), DAY(ldStartDate))
ENDDO 	