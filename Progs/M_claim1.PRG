SET SAFETY OFF 

SELECT LEFT(plan,2) AS plan, ;
	SUM(IIF(!INLIST(service_type, "HB", "IPD"), 1, 0)) AS OPD_NOC, ;
	SUM(IIF(!INLIST(service_type, "HB", "IPD", sbenfpaid, 0)) AS OPD_paid, ;
	SUM(IIF(service_type = "IPD" AND fbenfpaid = 0, 1, 0)) AS IPD_NOC, ;
	SUM(IIF(service_type = "IPD" AND fbenfpaid = 0, sbenfpaid, 0)) AS IPD_paid, ;	
	SUM(IIF(LEFT(plan,2) = "HB", 1, 0)) AS HB_NOC, ;
	SUM(IIF(LEFT(plan,2) = "HB", sbenfpaid, 0)) AS HB_paid ;
FROM cims!claim ;
ORDER BY 1 ;
WHERE 	fundcode = gcFundcode ;
	AND return_date BETWEEN gdStartDate AND gdEndDate ;
	AND INLIST(claim_with, "I", "P") ;
	AND LEFT(result,1) = "P" ;
	AND result <> "P5" ;
GROUP BY 1 ;
INTO DBF g:\report\claim_noc
*
SELECT LEFT(plan,2), policy_no, service_type, count(*) ;
FROM cims!claim ;
WHERE fundcode = gcfundcode ;
	AND return_date BETWEEN gdStartDate AND gdEndDate ;
	AND claim_with <> "G" AND LEFT(result,1) = "P" ;
	AND result <> "P5" ;
GROUP BY 1, 2,3, ;
ORDER BY 1,2,3 ;
INTO CURSOR curNmc
*
SELECT plan, ;
	SUM(IIF(!INLIST(service_type, "HB", "IPD"), 1, 0)) opd_nmc, ;
	SUM(IIF(service_type =  "IPD" , 1, 0)) ipd_nmc, ;
	SUM(IIF(plan = "HB", 1, 0)) hb_nmc, ;
FROM curNMC ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO dbf g:\report\claim_nmc		
*

** Out standing
SELECT LEFT(plan,2) plan, ;
	SUM(IIF(LEFT(result,1) = "P" AND service_type <> "IPD", 1, 0)) AS OPD_NMC, ;
	SUM(IIF(LEFT(result,1) = "P" AND service_type = "IPD" AND fbenfpaid = 0, 1, 0)) AS IPD_NMC, ;
	SUM(IIF(LEFT(result,1) = "P" AND service_type = "IPD" AND fbenfpaid <> 0, 1, 0)) AS IPDF_NMC, ;
	SUM(IIF(LEFT(result,1) = "D", 1, 0)) AS NMC_denied, ; 	
	SUM(IIF(LEFT(result,1) $ "WA", 1, 0)) AS out_NMC, ;
	SUM(IIF(LEFT(result,1) $ "WA", sbenfpaid, 0)) AS out_paid ;
FROM cims!claim ;
ORDER BY 1 ;
WHERE claim_with <> "G" ;
	AND (return_date BETWEEN gdStartDate AND gdEndDate ;
	OR TTOD(notify_date) BETWEEN gdStartDate AND gdEndDate) ;
GROUP BY 1 ;
HAVING fundcode = gcFundCode ;
INTO CURSOR curnmc
*
PROCEDURE all
SELECT fundcode, ;
	LEFT(plan,2) AS plan, ;
	service_type, ;
	fbenfpaid, ;
	sbenfpaid, ;
	result, ;
	return_date
FROM cims!claim ;
ORDER BY 2 ;
WHERE fundcode = gcFundCode ;
	AND claim_with <> "G" ;
	AND (return_date BETWEEN gdStartDate AND gdEndDate ;
	OR TTOD(notify_date) BETWEEN gdStartDate AND gdEndDate)