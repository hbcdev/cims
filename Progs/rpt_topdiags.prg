PUBLIC m.cFundCode,;
	m.nMonth,;
	m.nYear,;
	m.noutput,;
	tnTopDiags
LOCAL loMonthPick,;
	lcDocName
	
m.cFundCode = ""
tnTopDiags = 20
m.nMonth = MONTH(DATE())
m.nYear = STR(YEAR(DATE()),4)
m.nOutput = 1
loMonthPick = CREATEOBJECT("monthpick")
IF TYPE("loMonthPick") <> "O"
	RETURN
ENDIF
loMonthPick.Show
**************************************
WAIT WINDOW NOWAIT "Query Top Illness report"
SET TALK ON
SELECT notify_no, notify_date, customer_id, illNess1 AS icd10,;
	 SUM(IIF(claim_type <> 2, 1, 0)) AS no_opd,;
	 SUM(IIF(claim_type <> 2, scharge, 0)) AS charge_opd,;
	 SUM(IIF(claim_type <> 2, sbenfpaid, 0)) AS benf_opd,;
	 SUM(IIF(claim_type = 2, 1, 0)) AS no_ipd,;
	 SUM(IIF(claim_type = 2, IIF(EMPTY(fax_by), scharge, fcharge), 0)) AS charge_ipd,;
	 SUM(IIF(claim_type = 2, IIF(EMPTY(fax_by), sbenfpaid, fbenfpaid), 0)) AS benf_ipd,;
	 SUM(1) AS sum_no,;
	 SUM(IIF(EMPTY(fax_by), scharge, fcharge)) AS sum_charge,;
	 SUM(IIF(EMPTY(fax_by), sbenfpaid, fbenfpaid)) AS sum_benfpaid;
FROM Claim;
WHERE fundcode = M.cfundcode;
   AND MONTH(Claim.notify_date) = M.nmonth;
   AND STR(YEAR(Claim.notify_date),4) = M.nyear;
   AND EMPTY(illness1);
GROUP BY icd10;
INTO CURSOR curEmptyIcd
*
SELECT TOP (tnTopDiags) notify_no, notify_date, customer_id, illNess1 AS icd10,;
	 SUM(IIF(claim_type <> 2, 1, 0)) AS no_opd,;
	 SUM(IIF(claim_type <> 2, scharge, 0)) AS charge_opd,;
	 SUM(IIF(claim_type <> 2, sbenfpaid, 0)) AS benf_opd,;
	 SUM(IIF(claim_type = 2, 1, 0)) AS no_ipd,;
	 SUM(IIF(claim_type = 2, IIF(EMPTY(fax_by), scharge, fcharge), 0)) AS charge_ipd,;
	 SUM(IIF(claim_type = 2, IIF(EMPTY(fax_by), sbenfpaid, fbenfpaid), 0)) AS benf_ipd,;
	 SUM(1) AS sum_no,;
	 SUM(IIF(EMPTY(fax_by), scharge, fcharge)) AS sum_charge,;
	 SUM(IIF(EMPTY(fax_by), sbenfpaid, fbenfpaid)) AS sum_benfpaid;
FROM Claim;
WHERE fundcode = M.cfundcode;
   AND MONTH(Claim.notify_date) = M.nmonth;
   AND STR(YEAR(Claim.notify_date),4) = M.nyear;
   AND !EMPTY(illness1);
GROUP BY icd10;
ORDER BY  sum_charge DESC, sum_benfpaid DESC, sum_no DESC;
INTO CURSOR curTopIcd
SET TALK OFF
WAIT CLEAR
IF _TALLY > 1
	DO CASE 
	CASE m.nOutput = 1
		REPORT FORM (gcReportPath+"topdiags.frx") NOCONSOLE PREVIEW
	CASE m.nOutput = 2
		REPORT FORM (gcReportPath+"topdiags.frx") NOCONSOLE TO PRINTER PROMPT
	CASE m.nOutput = 3
	ENDCASE
ENDIF	
USE IN curTopIcd
USE IN curEmptyIcd