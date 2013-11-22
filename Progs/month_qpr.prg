**
SET SAFETY OFF 
PUBLIC gcFundCode, gnOption, ;
	gdStartDate, gdEndDate, gcTemp
	
gcFundCode = ""	
gdStartDate = DATE()
gdEndDate = DATE()	
gnOption = 1
********************	
DO FORM form\DateEntry
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF 
*********************
IF EMPTY(gcTemp)
	gcTemp = GETDIR()
ENDIF 	
*********************
lcMonth = ALLTRIM(gcFundCode)+"_Claim_"+STRTRAN(DTOC(gdStartDate), "/", "")+"_"+STRTRAN(DTOC(gdEndDate), "/", "")
*********************
SELECT fundcode, notify_no, policy_no, ;
	IIF(claim_with = "P", "PA", LEFT(plan,2)) plan, IIF(claim_type = 2, "IPD", "OPD") AS type, ;
	result, fbenfpaid, sbenfpaid, TTOD(notify_date) notify_dat, return_date AS return, unclean, ;
	IIF(result = "A1", "P", LEFT(result,1)) AS status ;
FROM cims!claim ;
WHERE TTOD(notify_date) BETWEEN gdStartDate AND gdEndDate ;
	OR return_date BETWEEN gdStartDate AND gdEndDate ;
HAVING fundcode = gcFundCode ;	
INTO CURSOR curClaim
******************************
SELECT fundcode, notify_no, policy_no, plan, type, result, fbenfpaid, sbenfpaid, notify_dat, return, status, ;
	unclean, IIF(notify_dat = return, 1, (return-notify_dat)-holidays(notify_dat, return)) AS amt_time ;
FROM curClaim ;
INTO DBF (ADDBS(gcTemp)+lcMonth)
************************
SELECT plan, ;
	SUM(IIF(status = "P" AND type = "OPD", 1, 0)) AS opd_noc, ;
	SUM(IIF(status = "P" AND type = "OPD", sbenfpaid, 0)) AS opd_paid, ;
	SUM(IIF(status = "P" AND type = "IPD" AND fbenfpaid = 0, 1, 0)) AS ipd_noc, ;
	SUM(IIF(status = "P" AND type = "IPD" AND fbenfpaid = 0, sbenfpaid, 0)) AS ipd_paid, ;
	SUM(IIF(status = "P" AND type = "IPD" AND fbenfpaid <> 0, 1, 0)) AS fax_noc, ;
	SUM(IIF(status = "P" AND type = "IPD" AND fbenfpaid <> 0, fbenfpaid, 0)) AS fax_paid, ;
	SUM(IIF(status = "W" OR result = "A1", 1, 0)) AS out_noc, ;
	SUM(IIF(status = "W" OR result = "A1", IIF(sbenfpaid = 0, fbenfpaid, sbenfpaid), 0)) AS out_amt ;
FROM (lcMonth) ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR curNoc
*****************************	
SELECT policy_no, plan, type, result, fbenfpaid, sbenfpaid, status, count(*) ;
FROM (lcMonth) ;
GROUP BY 1, 2, 3 ;
ORDER BY 1, 2, 3 ;
INTO CURSOR curNMC1
*****************************	
SELECT plan, ;
	SUM(IIF(status = "P" AND type = "OPD", 1, 0)) AS opd_nmc, ;
	SUM(IIF(status = "P" AND type = "IPD" AND fbenfpaid = 0, 1, 0)) AS ipd_nmc, ;
	SUM(IIF(status = "P" AND type = "IPD" AND fbenfpaid <> 0, 1, 0)) AS fax_nmc, ;
	SUM(IIF(status = "D" AND type = "IPD" AND fbenfpaid = 0, 1, 0)) AS denied_nmc, ;
	SUM(IIF((status = "W" OR result = "A1") AND type = "IPD" AND fbenfpaid = 0, 1, 0)) AS out_nmc ;
FROM curNMC1 ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR curNMC
*****************************
SELECT a.plan, a.opd_noc, b.opd_nmc, a.opd_paid, a.ipd_noc, b.ipd_nmc, a.ipd_paid, ;
	fax_noc, fax_nmc, fax_paid, denied_nmc, out_noc, out_nmc, out_amt ;
FROM curnoc A FULL JOIN curnmc B ;
	ON a.plan = b.plan ;
INTO DBF (ADDBS(gcTemp)+"claim_month")
**********************************
*Aging
*
SELECT plan, status, ;
	(return-notify_dat)-holidays(notify_dat, return) AS amt_time, COUNT(*) ;
FROM (lcMonth) ;
WHERE INLIST(status, "P", "D") ;
	AND EMPTY(unclean) ;
GROUP BY 1, 2, 3 ;
ORDER BY 1, 2, 3 ;
INTO DBF (ADDBS(gcTemp)+"aging")
