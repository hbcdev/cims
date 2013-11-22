PUBLIC m.cFundCode,;
	m.nMonth,;
	m.nYear,;
	m.nOutput
LOCAL loMonthPick,;
	lcDocName
	
m.cFundCode = ""
m.nMonth = MONTH(DATE())
m.nYear = STR(YEAR(DATE()),4)
m.noutput = 1
loMonthPick = CREATEOBJECT("monthpick")

IF TYPE("loMonthPick") <> "O"
	RETURN
ENDIF
loMonthPick.Show
**************************************
WAIT WINDOW NOWAIT "Query Claim by Provider"
SET TALK ON
SELECT claim.notify_no, claim.notify_date, provider.name,;
	SUM(IIF(claim.claim_type <> 2, 1, 0)) AS no_opd,;
	SUM(IIF(claim.claim_type <> 2, scharge, 0)) AS charge_opd,;
	SUM(IIF(claim.claim_type <> 2, sbenfpaid, 0)) AS benf_opd,;
	SUM(IIF(claim.claim_type = 2, 1, 0)) AS no_ipd,;
	SUM(IIF(claim.claim_type = 2,  IIF(sbenfpaid = 0, fcharge, scharge), 0)) AS charge_ipd,;
	SUM(IIF(claim.claim_type = 2,  IIF(sbenfpaid = 0, fbenfpaid, sbenfpaid), 0)) AS benf_ipd,;
	SUM(scharge) AS sum_charge,;
	SUM(sbenfpaid) AS sum_benfpaid;
FROM FORCE cims!claim INNER JOIN cims!provider ;
	ON claim.prov_id = provider.prov_id;
GROUP BY Name ;
ORDER BY Name ;
WHERE LEFT(customer_id,3) = M.cfundcode;
   AND MONTH(Claim.notify_date) = M.nmonth;
   AND STR(YEAR(Claim.notify_date),4) = M.nyear;
INTO CURSOR curClaimByProv
SET TALK OFF
WAIT CLEAR
IF _TALLY > 1
	DO CASE
	CASE m.nOutput = 1
		REPORT FORM (gcReportPath+"provider.frx") PREVIEW NOCONSOLE
	CASE m.nOutput = 2
		REPORT FORM (gcReportPath+"provider.frx") TO PRINTER PROMPT NOCONSOLE
	CASE m.nOutput = 3
		DO progs\tran2excel WITH "curClaimbyprov", GETDIR()
	ENDCASE	
ELSE
	=MESSAGEBOX("ไม่พบรายการเคลมของ "+M.cFundCode+" ในเดือน"+TMonth(M.nMonth)+" ปี "+M.nYear, 0, "Error")
ENDIF
loMonthPick.Release
RELEASE M.cFundCode, M.nMonth, M.nYear
USE IN curClaimByProv