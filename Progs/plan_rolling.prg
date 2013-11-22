SELECT A.product, SUM(1) AS nmp, SUM(A.premday*A.DayCover) AS epr;
FROM rollmember A;
GROUP BY A.product;
ORDER BY A.product;
INTO CURSOR nmp 
*
SELECT A.product, SUM(IIF(B.claim_type = 1,1,0)) AS noc_opd,;
	SUM(IIF(B.claim_type = 2, 1, 0)) AS noc_ipd;
FROM rollmember A, rollclaim B;
WHERE A.customer_i = b.customer_i;
GROUP BY a.product;
ORDER BY A.product;
INTO CURSOR noc

SELECT * ;
FROM rollclaim;
GROUP BY customer_i;
INTO CURSOR nmc
	
SELECT A.product, SUM(IIF(B.claim_type = 1,1,0)) AS nmc_opd,;
	SUM(IIF(B.claim_type = 2, 1, 0)) AS nmc_ipd,;
	SUM(B.fbenfpaid) AS tcp;
FROM rollmember A, nmc B;
WHERE A.customer_i = B.customer_i;
GROUP BY A.product;
ORDER BY A.product;
INTO CURSOR nmc1

SELECT noc.product,nmp.epr,nmc1.tcp, noc_opd, noc_ipd, nmc_opd, nmc_ipd,;
	noc.noc_opd/nmp.nmp AS mir_opd,;
	noc.noc_ipd/nmp.nmp AS mir_ipd,;
	noc.noc_opd/nmc1.nmc_opd AS cir_opd,;
	noc.noc_ipd/nmc1.nmc_ipd AS cir_ipd;
FROM noc,nmc1,nmp;
WHERE noc.product = nmc1.product AND noc.product = nmp.product;
ORDER BY noc.product;
INTO CURSOR plan_1

REPORT FORM plan_rolling PREVIEW
WAIT WINDOW
REPORT FORM plan_rolling1 PREVIEW

