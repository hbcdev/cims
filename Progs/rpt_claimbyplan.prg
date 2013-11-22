PUBLIC m.cFundCode,;
	m.nMonth,;
	m.nYear,;
	m.nOutput
LOCAL loMonthPick
m.cFundCode = ""
m.nMonth = MONTH(DATE())
m.nYear = STR(YEAR(DATE()),4)
m.nOutput = 1
loMonthPick = CREATEOBJECT("monthpick")
IF TYPE("loMonthPick") <> "O"
	RETURN
ENDIF
loMonthPick.Show
*************************************************************************************
WAIT WINDOW "Query Claim by plan" NOWAIT
* --- Query For Claim by service type report
SELECT notify_date, plan,;
	SUM(IIF(claim_type <> 2, 1,0)) AS opd_amt,;
	SUM(IIF(claim_type <> 2, sCharge, 0)) AS opd_charge,;
	SUM(IIF(claim_type <> 2, sBenfpaid, 0)) AS opd_benf,;
	SUM(IIF(claim_type=2, 1,0)) ipd_amt,;
	SUM(IIF(claim_type = 2,  fcharge, 0)) AS ipd_fcharge,;
	SUM(IIF(claim_type = 2,  fbenfpaid, 0)) AS ipd_fbenf,;
	SUM(IIF(claim_type = 2,  scharge, 0)) AS ipd_scharge,;
	SUM(IIF(claim_type = 2,  sbenfpaid, 0)) AS ipd_sbenf,;
	SUM(exgratia) AS exgratia;
FROM cims!Claim ;
WHERE LEFT(Claim.customer_id,3) = M.cfundcode;
   AND MONTH(Claim.notify_date) = M.nmonth;
   AND STR(YEAR(Claim.notify_date),4) = M.nyear;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR service
IF _TALLY > 1
	DO CASE
	CASE m.nOutput = 1
		REPORT FORM (gcReportPath+"service.frx") PREVIEW NOCONSOLE
	CASE m.nOutput = 2
		REPORT FORM (gcReportPath+"service.frx") TO PRINTER PROMPT NOCONSOLE
	CASE m.nOutput = 3
		DO progs\tran2excel WITH "service", GETDIR()
	ENDCASE
ELSE
	=MESSAGEBOX("ไม่พบรายการเคลมของ "+M.cFundCode+" ในเดือน"+TMonth(M.nMonth)+" ปี "+M.nYear, 0, "Error")
ENDIF
loMonthPick.Release
RELEASE M.cFundCode, M.nMonth, M.nYear
USE IN service