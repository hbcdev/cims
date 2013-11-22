PUBLIC m.cFundCode,;
	m.nMonth,;
	m.nYear,;
	m.nOutput
LOCAL loMonthPick,;
	lcDocName
	
m.cFundCode = ""
m.nMonth = MONTH(DATE())
m.nYear = YEAR(DATE())
m.nOutput = 1
loMonthPick = CREATEOBJECT("monthpick")

IF TYPE("loMonthPick") <> "O"
	RETURN
ENDIF
loMonthPick.Show
*************************
lcFileName = "\\HBCNT\REPORT\"+m.cFundcode+"ClaimByAgent_"+STR(m.nYear,4)+ALLTRIM(STR(m.nMonth,2))
IF _TALLY > 1
	DO CASE
	CASE m.nOutput = 1
		REPORT FORM (gcReportPath+"claimbyagent.frx") PREVIEW NOCONSOLE
	CASE m.nOutput = 2
		REPORT FORM (gcReportPath+"claimbyagent.frx") TO PRINTER PROMPT NOCONSOLE
	CASE m.nOutput = 3
		SELECT Member.agentcy, Member.agent, Claim.policy_no, Claim.client_name, Claim.plan,;
		  Claim.notify_date,;
		  IIF(EMPTY(Claim.fax_by),Claim.scharge,Claim.fcharge) AS charge,;
		  IIF(EMPTY(Claim.fax_by),Claim.sbenfpaid,Claim.fbenfpaid) AS benf_paid,;
		  IIF(EMPTY(Claim.return_date), Claim.fax_date, Claim.return_date) AS paid_date,;
		  Claim.exgratia,;
		  IIF(EMPTY(Claim.fax_by),Claim.snote,Claim.fnote) AS notes;
		 FROM  cims!claim INNER JOIN cims!Member ;
		   ON  Claim.fundcode+Claim.policy_no  = Member.tpacode+Member.policy_no;
		 WHERE Claim.fundcode = M.cfundcode;
		   AND MONTH(Claim.notify_date) = M.nmonth;
		   AND YEAR(Claim.notify_date) = M.nyear;
		 ORDER BY Member.agent;
		 INTO CURSOR claimbyagen
		 IF _TALLY > 0
			DO progs\tran2excel WITH "claimbyagen", GETDIR()
		ENDIF 	
	ENDCASE 		
ELSE
	=MESSAGEBOX("ไม่พบรายการเคลมของ "+M.cFundCode+" ในเดือน"+TMonth(M.nMonth)+" ปี "+M.nYear, 0, "Error")
ENDIF
loMonthPick.Release
RELEASE M.cFundCode, M.nMonth, M.nYear, M.nOutput