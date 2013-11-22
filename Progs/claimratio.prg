* --- Query For Plan Rolling report
WAIT WINDOW NOWAIT "Query claim by plan "
* Query Current Month Earned Premium
* Query rolling earned Premium and amount member between plan
* nop = No. of member per plan
* epr = Earned premium (rolling)
SELECT product AS plan,;
	COUNT(*) AS nop,;
	SUM(premday*DayCover) AS epr;
FROM curRollMember;
GROUP BY plan;
ORDER BY plan;
INTO CURSOR curNop
*
* Query no of claim group saparate by service type of each plan
* noc = No. of claims
* noc_opd = No. of claims per opd
* noc_ipd = No. of claims per ipd
* cpr = Claims paid (rolling)
* cp = Current month claim paid
* tcpr = Total claims paid (rolling)
SELECT plan,;
	COUNT(*) AS noc,;
	SUM(IIF(claim_type <> 2, 1, 0)) AS noc_opd,;
	SUM(IIF(claim_type = 2, 1, 0)) AS noc_ipd,;
	SUM(IIF(LEFT(result,1) <> "D", fbenfpaid+sbenfpaid, 0)) AS cpr,;
	SUM(IIF(LEFT(result,1) = "P", fbenfpaid+sbenfpaid, 0)) AS tcpr;
FROM curRollClaim	;
GROUP BY plan;
ORDER BY plan;
INTO CURSOR curClaimRatio
*******************************************
* nmc_opd = No. of member claims per opd
* nmc_ipd = No. of member claims per ipd
SELECT plan,;
	SUM(IIF(claim_type <> 2, 1, 0) AS nmc_opd,;
	SUM(IIF(claim_type = 2, 1, 0) AS nmc_ipd;
FROM curRollClaim;
GROUP BY policy_no;
ORDER BY plan;
INTO CURSOR curNmc	
********************************************
SELECT curNmc.plan,;
	curClaimRatio.noc_opd/curNmc.nmc_opd AS cir_opd,;
	curClaimRatio.noc_ipd/curNmc.nmc_ipd AS cir_ipd,;
	curClaimRatio.noc_opd/curNop.nop AS mir_opd,;
	curClaimRatio.noc_ipd/curNop.nop AS mir_ipd,;
	curNop.epr/curClaimRatio.cpr AS gcr_r;
FROM curNmc, curClaimRatio, curNmc, curNop;
ORDER BY plan;
INTO CURSOR curClaimRatio_r