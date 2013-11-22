SELECT TOP (tnTopDiags) illNess1 AS icd10,;
	 SUM(IIF(claim_type <> 2, 1, 0)) AS no_opd,;
	 SUM(IIF(claim_type <> 2, IIF(scharge = 0, fcharge,sCharge), 0)) AS charge_opd,;
	 SUM(IIF(claim_type <> 2, IIF(sbenfpaid = 0, fbenfpaid, sBenfpaid), 0)) AS benf_opd,;
	 SUM(IIF(claim_type = 2, 1, 0)) AS no_ipd,;
	 SUM(IIF(claim_type = 2, IIF(scharge = 0, fcharge, sCharge), 0)) AS charge_ipd,;
	 SUM(IIF(claim_type = 2, IIF(sbenfpaid = 0, fbenfpaid, sBenfpaid), 0)) AS benf_ipd,;
	 SUM(1) AS sum_no,;
	 SUM(IIF(scharge = 0, fcharge, sCharge)) AS sum_charge,;
	 SUM(IIF(sbenfpaid = 0, fbenfpaid, sBenfpaid)) AS sum_benfpaid;
FROM curRollClaim;
WHERE !EMPTY(illness1) ;
GROUP BY icd10 ;
ORDER BY  sum_charge DESC ,sum_benfpaid DESC ,sum_no DESC ;
INTO CURSOR curTopIcd
