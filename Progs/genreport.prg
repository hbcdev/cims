LPARAMETER tcFundCode,tdReport,tnRolling,tnTopDiags,tcExportTo
PUBLIC m.rollstart,;
	m.rollend,;
	m.rolling,;
	m.curmonth,;
	m.bom,;
	m.eom,;
	m.TopDiags
******************	
IF PARAMETER() = 0
	RETURN
ENDIF
IF PARAMETER() = 1	
	tdReport = Date()
	tnRolling = 12
ELSE
	IF PARAMETER() = 2
		tnRolling = 12
	ELSE
		IF PARAMETER() = 3
			tnTopDiags = 20
		ELSe
			IF PARAMETER() = 4
				tcExportTo = "\\HBCNT\APPS\REPORT"
			ENDIF		
		ENDIF
	ENDIF		
ENDIF
*******************************************
IF EMPTY(tcFundcode)
	RETURN
ENDIF
#INCLUDE include\cims.h
LOCAL lcMY,;
	llExport
tdReport = IIF(EMPTY(tdReport), DATE(), tdReport)
lcMy = STRTRAN(STR(MONTH(tdReport-1),2), " ", "0")+STR(YEAR(tdReport-1),4)
tcExportTo = ADDBS(tcExportTo)+tcFundCode+"\"+lcMy
tcExportTo = ADDBS(tcExportTo)
m.Rolling = IIF(EMPTY(tnRolling), 12, tnRolling)
m.TopDiags = IIF(EMPTY(tnTopDiags), 20, tnTopDiags)
*************************************************
IF !DIRECTORY(tcExportTo)
	MD (tcExportTo)
ENDIF	
llExport = DIRECTORY(tcExportTo)
***************************************************
IF "FOCUS.FLL" $ SET("library")
	pcWinDir = ADDBS(GETENV("WINDIR"))
	IF "WINNT" $ pcWindir
		pcWinDir = pcWindir + "SYSTEM32\"
	ELSE	
		pcWinDir = pcWindir + "SYSTEM\"
	ENDIF
	IF !FILE(pcWinDir+"KERNEL.DLL")
		=MESSAGEBOX("ไม่พบแฟ้ม kernel.dll ใน "+pcWindir+" กรุณาติดต่อกับ ผู้ดุแลระบบ", MB_OK, "Genarate Report")
		RETURN 
	ENDIF
	IF FILE(gcProgDir+"LIBS\FOCUS.FLL")
		SET LIBR TO (gcProgDir+"LIBS\FOCUS.FLL")
	ENDIF	
ENDIF	
IF !"FOCUS.FLL" $ SET("library")
	=MESSAGEBOX("Cannot run this program")
	RETURN
ENDIF
SET PROC TO progs\utility
SET TALK ON WINDOW
*****************************************
m.rollstart = tdReport - 365 &&GetStartRoll(tdReport,m.Rolling)
m.rollend = tdReport-1
m.cutdate = tdReport
m.TotalDay = m.rollend - m.rollstart
m.CurMonth = MONTH(m.rollend)
m.bom = DAT_bom(m.rollEnd)
m.eom = DAT_eom(m.rollend)
IF m.CurMonth = 2
	m.numofdays = DAT_numberofdays(m.CurMonth)+IIF(DAT_Isleap(m.rollend), 1, 0)
ELSE
	m.numofdays = DAT_numberofdays(m.CurMonth)
ENDIF	
*****************************************
*เลื่อกข้อมูลผู้เอาประกัน ของบริษัท ที่กำหนด ที่ tcFundCode
* เลือกผู้เอาประกันที่มีความคุ้มครองในช่วงที่ทำ Rolling
*
WAIT WINDOW "Query Rolling Member" NOWAIT
SELECT Member.customer_id, Member.policy_no, Member.product, Member.premium,;
	Member.effective, Member.expiry, ALLTRIM(Member.agent) AS agent, Member.agentcy,;
	IIF(EMPTY(TTOD(Member.expiry)) OR TTOD(Member.expiry) > m.rollend,;
	 (m.rollend - TTOD(Member.effective))+LeapDay(TTOD(Member.effective), m.rollend)+1,;
	IIF(TTOD(Member.effective) < m.rollstart,;
		  (TTOD(Member.expiry) - m.rollstart) +LeapDay(m.rollstart, TTOD(Member.expiry))+ 1,;
			(TTOD(Member.expiry) - TTOD(Member.effective))+LeapDay(TTOD(Member.effective), TTOD(Member.expiry))+1)) AS DayCover,;
 	Member.premium/365.25 AS premday;
FROM cims!member;
WHERE Member.tpacode = tcFundCode;
	AND (TTOD(Member.effective) BETWEEN m.rollstart AND m.cutdate;
	OR TTOD(Member.expiry) BETWEEN  m.rollstart AND m.cutdate);
ORDER BY effective, expiry;
INTO CURSOR  curRollMember
IF _TALLY < 1
	=WarningBOX("ไม่พบข้อมูลผู้เอาประกัน ในช่วงวันที่ "+DTOC(m.rollStart)+" ถึง วันที่ "+DTOC(m.rollEnd))
	RETURN
ENDIF
WAIT CLEAR
IF llExport
	EXPORT TO (tcExportTo+"RollMember") TYPE XL5
ENDIF	
**********************************************
WAIT WINDOW "Query Rolling Claim" NOWAIT
* เลือก claim เฉพาะ Rolling
SELECT Claim.customer_id,  Claim.policy_no, Claim.client_name, Claim.claim_type, Claim.type_claim,;
	Claim.plan, Claim.prov_id, Claim.admis_date, Claim.disc_date,;
	Claim.illness1, Claim.fday, Claim.fcharge, Claim.fbenfpaid,;
	Claim.sday, Claim.scharge, Claim.sbenfpaid,Claim.sremain, Claim.exgratia, Claim.result,;
	IIF(EMPTY(Claim.ref_date), Claim.doc_date, Claim.ref_date) AS summit_date, Claim.return_date,;
	Claim.notify_no, Claim.claim_id, Month(Claim.admis_date) AS Admit_Month;
FROM  cims!claim;
WHERE LEFT(Claim.customer_id,3) = tcFundCode;
	AND TTOD(Claim.admis_date) BETWEEN m.rollstart AND m.cutdate;
ORDER BY Claim.admis_date ;
INTO CURSOR curRollClaim
IF _TALLY < 1
	=WarningBOX("ไม่พบข้อมูลผู้เอาประกันเคลม ในช่วงวันที่ "+DTOC(m.rollStart)+" ถึง วันที่ "+DTOC(m.rollEnd))
	RETURN
ENDIF
IF llExport
	EXPORT TO (tcExportTo+"rollClaim") TYPE XL5
ENDIF	 
**************************************************************
*เลื่อกข้อมูลผู้เอาประกัน ของบริษัท ที่กำหนด ที่ tcFundCode
* เลือกผู้เอาประกันที่มีความคุ้มครองใน เดือนปัจจุบัน
WAIT WINDOW "Query Current Month Member" NOWAIT
SELECT Member.customer_id, Member.policy_no, Member.product, Member.premium,;
	Member.effective, Member.expiry, ALLTRIM(Member.agent) AS agent, Member.agentcy,;
	IIF(EMPTY(TTOD(Member.expiry)) OR TTOD(Member.expiry) > m.eom, m.eom - TTOD(Member.effective), ;
		IIF(TTOD(Member.effective) < m.bom, TTOD(Member.expiry) - m.bom,;
			TTOD(Member.expiry) - TTOD(Member.effective))) AS DayCover,;
 	Member.premium/365.25 AS premday;
FROM cims!member;
WHERE Member.tpacode = tcFundCode;
	AND (TTOD(Member.effective) BETWEEN m.bom AND m.eom;
	OR TTOD(Member.expiry) BETWEEN  m.bom AND m.eom); 
ORDER BY effective, expiry;
INTO CURSOR  curCurrentMember
IF _TALLY < 1
	=WarningBOX("ไม่พบข้อมูลผู้เอาประกัน ในช่วงวันที่ "+DTOC(m.bom)+" ถึง วันที่ "+DTOC(m.eom))
	RETURN
ENDIF
WAIT CLEAR
*
IF llExport
	EXPORT TO (tcExportTo+"CurMember") TYPE XL5
ENDIF	 
**************************************
WAIT WINDOW "Query Current Month Claim" NOWAIT
* เลือก claim ที่ admit ในเดือนปัจจุบัน
SELECT Claim.notify_date, Claim.customer_id,  Claim.policy_no, Claim.claim_type, Claim.type_claim,;
	Claim.plan, Claim.prov_id, Claim.admis_date, Claim.disc_date,;
	Claim.illness1, Claim.fday, Claim.fcharge, Claim.fbenfpaid,;
	Claim.sday, Claim.scharge, Claim.sbenfpaid,Claim.sremain, Claim.exgratia, Claim.result,;
	IIF(EMPTY(Claim.ref_date), Claim.doc_date, Claim.ref_date) AS summit_date, Claim.return_date,;
	 Claim.notify_no, Claim.claim_id, Month(Claim.admis_date) AS Admit_Month;
FROM  cims!claim;
WHERE LEFT(Claim.customer_id,3) = tcFundCode;
	AND TTOD(Claim.notify_date) BETWEEN m.bom AND m.eom;
ORDER BY Claim.admis_date ;
INTO CURSOR curCurrentClaim
IF _TALLY < 1
	=WarningBOX("ไม่พบข้อมูลผู้เอาประกันเคลม ในช่วงวันที่ "+DTOC(m.bom)+" ถึง วันที่ "+DTOC(m.eom))
	RETURN
ENDIF
IF llExport
	EXPORT TO (tcExportTo+"CurClaim") TYPE XL5
ENDIF	 
*************************************************************************************
WAIT WINDOW "Query Rolling No. of Claim by plan" NOWAIT
* --- Query For Claim by service type report
SELECT plan, SUM(IIF(claim_type <> 2, 1,0)) AS oOpd_amt,;
	SUM(IIF(claim_type <> 2, sCharge, 0)) AS opd_charge,;
	SUM(IIF(claim_type <> 2, sBenfpaid, 0)) AS opd_benf,;
	SUM(IIF(claim_type=2, fday,0)) ipd_flos,;
	SUM(IIF(claim_type = 2,  fcharge, 0)) AS ipd_fcharge,;
	SUM(IIF(claim_type = 2,  fbenfpaid, 0)) AS ipd_fbenf,;
	SUM(IIF(claim_type=2, sday,0)) ipd_slos,;
	SUM(IIF(claim_type = 2,  scharge, 0)) AS ipd_scharge,;
	SUM(IIF(claim_type = 2,  sbenfpaid, 0)) AS ipd_sbenf,;
	SUM(exgratia) AS exgratia;
FROM curRollClaim ;
GROUP BY plan ;
ORDER BY plan ;
INTO CURSOR service
IF llExport
	EXPORT TO (tcExportTo+"Service") TYPE XL5
ENDIF	 
*************************************************
* Query Top Illness report
WAIT WINDOW NOWAIT "Query Top Illness report"
SELECT illNess1 AS icd10,;
	 SUM(IIF(claim_type <> 1, 1, 0)) AS no_opd,;
	 SUM(IIF(claim_type <> 1, IIF(scharge = 0, fcharge, sCharge), 0)) AS charge_opd,;
	 SUM(IIF(claim_type <> 2, sbenfpaid, 0)) AS benf_opd,;
	 SUM(IIF(claim_type = 2, 1, 0)) AS no_ipd,;
	 SUM(IIF(claim_type = 2, IIF(scharge = 0, fcharge, scharge), 0)) AS charge_ipd,;
	 SUM(IIF(claim_type = 2, IIF(sbenfpaid = 0, fbenfpaid, sBenfpaid), 0)) AS benf_ipd,;
	 SUM(1) AS sum_no,;
	 SUM(IIF(scharge = 0, fcharge, scharge)) AS sum_charge,;
	 SUM(IIF(sbenfpaid = 0,fbenfpaid, sbenfpaid)) AS sum_benfpaid;
FROM curRollClaim;
WHERE EMPTY(illness1);
GROUP BY icd10;
INTO CURSOR curEmptyIcd
*
SELECT TOP (m.TopDiags) illNess1 AS icd10,;
	 SUM(IIF(claim_type <> 2, 1, 0)) AS no_opd,;
	 SUM(IIF(claim_type <> 2, scharge, 0)) AS charge_opd,;
	 SUM(IIF(claim_type <> 2, sbenfpaid, 0)) AS benf_opd,;
	 SUM(IIF(claim_type = 2, 1, 0)) AS no_ipd,;
	 SUM(IIF(claim_type = 2, IIF(scharge = 0, fcharge, scharge), 0)) AS charge_ipd,;
	 SUM(IIF(claim_type = 2, IIF(sbenfpaid = 0, fbenfpaid, sbenfpaid), 0)) AS benf_ipd,;
	 SUM(1) AS sum_no,;
	 SUM(IIF(scharge = 0, fcharge, scharge)) AS sum_charge,;
	 SUM(IIF(sbenfpaid = 0,fbenfpaid, sbenfpaid)) AS sum_benfpaid;
FROM curRollClaim;
WHERE !EMPTY(illness1);
GROUP BY icd10;
ORDER BY  sum_charge DESC, sum_benfpaid DESC, sum_no DESC;
INTO CURSOR curTopIcd
IF llExport
	EXPORT TO (tcExportTo+"TopDiags") TYPE XL5
ENDIF	 

**************************************************
WAIT WINDOW NOWAIT "Query Claim by Provider"
SELECT provider.name,;
	SUM(IIF(claim.claim_type <> 2, 1, 0)) AS no_opd,;
	SUM(IIF(claim.claim_type <> 2, scharge, 0)) AS charge_opd,;
	SUM(IIF(claim.claim_type <> 2, sbenfpaid, 0)) AS benf_opd,;
	SUM(IIF(claim.claim_type = 2, 1, 0)) AS no_ipd,;
	SUM(IIF(claim.claim_type = 2,  IIF(sbenfpaid = 0, fcharge, scharge), 0)) AS charge_ipd,;
	SUM(IIF(claim.claim_type = 2,  IIF(sbenfpaid = 0, fbenfpaid, sbenfpaid), 0)) AS benf_ipd,;
	SUM(scharge) AS sum_charge,;
	SUM(sbenfpaid) AS sum_benfpaid;
FROM curRollClaim claim INNER JOIN cims!provider ;
	ON claim.prov_id = provider.prov_id;
GROUP BY Name ;
ORDER BY Name ;
INTO CURSOR curClaimByProv
WAIT CLEAR
IF llExport
	EXPORT TO (tcExportTo+"ClaimByProvider") TYPE XL5
ENDIF	 
****************************************
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
IF llExport
	EXPORT TO (tcExportTo+"No_member_plan") TYPE XL5
ENDIF	 
***************************************************
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
	SUM(IIF(LEFT(result,1) <> "D", IIF(sbenfpaid = 0, fbenfpaid, sbenfpaid), 0)) AS cpr,;
	SUM(IIF(LEFT(result,1) = "P", IIF(sbenfpaid = 0, fbenfpaid, sbenfpaid), 0)) AS tcpr;
FROM curRollClaim	;
GROUP BY plan;
ORDER BY plan;
INTO CURSOR curClaimRatio
IF llExport
	EXPORT TO (tcExportTo+"ClaimRatio") TYPE XL5
ENDIF	 
*******************************************
SELECT policy_no, plan, claim_type;
FROM curRollClaim;
GROUP BY policy_no;
ORDER BY policy_no;
INTO CURSOR curRollNmc
*******************************************
* nmc_opd = No. of member claims per opd
* nmc_ipd = No. of member claims per ipd
SELECT plan,;
	SUM(IIF(claim_type <> 2, 1, 0)) AS nmc_opd,;
	SUM(IIF(claim_type = 2, 1, 0)) AS nmc_ipd;
FROM curRollNmc;
GROUP BY plan;
ORDER BY plan;
INTO CURSOR curNmc
IF llExport
	EXPORT TO (tcExportTo+"No_Member_claim") TYPE XL5
ENDIF	 
********************************************
SELECT curClaimRatio.plan,;
	curClaimRatio.noc_opd/curNmc.nmc_opd AS cir_opd,;
	curClaimRatio.noc_ipd/curNmc.nmc_ipd AS cir_ipd,;
	curClaimRatio.noc_opd/curNop.nop AS mir_opd,;
	curClaimRatio.noc_ipd/curNop.nop AS mir_ipd,;
	curNop.epr/curClaimRatio.cpr AS gcr_r;
FROM curClaimRatio, curNmc, curNop;
ORDER BY curClaimRatio.plan;
INTO CURSOR curClaimRatio_r	
IF llExport
	EXPORT TO (tcExportTo+"Roll_claim_ratio") TYPE XL5
ENDIF	 
**********************************************************************
SET TALK OFF
**
WAIT "Genarate Report Sucess" WINDOW NOWAIT

proc aa
IF USED("curClaimByProv")
	WAIT WINDOW NOWAIT "Print Claim by Provider report"
	SELECT curClaimByProv
	REPORT FORM report\provider_roll TO PRINTER NOCONSOLE
ENDIF	

IF USED("curEmptyIcd") AND USED("curTopIcd")
	WAIT WINDOW NOWAIT "Print Top Illness report"
	SELECT curTopICD
	REPORT FORM report\topDiags TO PRINTER NOCONSOLE
ENDIF	
IF USED("service")
	WAIT WINDOW NOWAIT "Print  claim by service type report"
	SELECT service
	REPORT FORM report\service TO PRINTER NOCONSOLE
ENDIF	
IF USED("plan_1")
	WAIT WINDOW NOWAIT "Print claim by plan  report"
	SELECT plan_1
	REPORT FORM report\plan_rolling TO PRINTER NOCONSOLE
*	REPORT FORM report\plan_rolling1 TO PRINTER NOCONSOLE
ENDIF