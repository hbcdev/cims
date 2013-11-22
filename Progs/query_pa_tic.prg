PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption
********************	
gcStartDate = "Start Date"
gcEndDate = "End Date"
glMonth = .F.	
gcFundCode = "TIC"
gdEndDate = DATE() - DAY(DATE())
gdStartDate = (gdEndDate - IIF(MOD(YEAR(gdEndDate),4) = 0, 366, 365))+1
gnOption = 3
gnType = 1
gnRolling = 12
gcSaveTo = gcTemp
DO FORM form\Rollingentry
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
gdCurDate = DATE(YEAR(gdEndDate), MONTH(gdEndDate), 1)
gtCurDate = DATETIME(YEAR(gdEndDate), MONTH(gdEndDate), 1, 00, 00)
gtStartDate = DATETIME(YEAR(gdStartDate), MONTH(gdStartDate), DAY(gdStartDate), 00, 00)
gtEndDate = DATETIME(YEAR(gdEndDate), MONTH(gdEndDate), DAY(gdEndDate), 23, 59)
gcSaveTo = ALLTRIM(IIF(EMPTY(gcSaveTo), gcTemp, gcSaveTo))

IF !DIRECTORY(gcSaveTo)
	MKDIR &gcSaveTo
ENDIF 	
***********************
lcOldDir = SYS(5)+SYS(2003)
SET DEFAULT TO (gcSaveTo)
SET TALK ON 
SET TALK WINDOW 
************************************
lcDbf = gcFundCode+"_PA_Claim"
lcMonth = gcFundCode+"_PA_Monthly"
lcDenied = gcFundCode+"_PA_Denied"
lcRoll = gcFundCode+"_PA_Rolling"
lcSum = gcFundCode+"_PA_Summary"
lcGraph = "Graph"
*************************************
DO Query_Data 
DO Print_report 
*
=MESSAGEBOX("Query Data sucess", 0, "Message")
********************************************
PROCEDURE query_data
*
SELECT notify_no, notify_date, policy_no, policy_holder, client_name, ALLTRIM(plan) AS plan, ;
	IIF(service_type = "IPD", service_type, "OPD") AS service_type, ;
	prov_name, admis_date, fcharge, fbenfpaid, fremain, scharge, sbenfpaid, sremain, result, note2ins, plan AS i_plan ;
FROM cims!claim ;
WHERE fundcode = gcFundCode ;
	AND INLIST(claim_with, "A", "P") ;
	AND notify_date BETWEEN gtStartDate AND gtEndDate ;
ORDER BY plan ;
INTO TABLE (gcSaveTo+lcDbf)	
*********************************************************************************************
SELECT plan, ;
	SUM(IIF(service_type <> "IPD" AND !EMPTY(fax_by), 1, 0)) AS f_opd_frq, ;
	SUM(IIF(service_type <> "IPD" AND !EMPTY(fax_by), fcharge, 0)) AS fopd_charge, ;
	SUM(IIF(service_type <> "IPD" AND !EMPTY(fax_by), fbenfpaid, 0)) AS fopd_paid, ;
	SUM(IIF(service_type <> "IPD" AND !EMPTY(fax_by), fremain, 0)) AS fopd_over, ;
	SUM(IIF(service_type = "IPD" AND !EMPTY(fax_by), 1, 0)) AS f_ipd_frq, ;
	SUM(IIF(service_type = "IPD", IIF(!EMPTY(fax_by), fcharge, 0), 0)) AS fipd_charge, ;
	SUM(IIF(service_type = "IPD", IIF(!EMPTY(fax_by), fbenfpaid, 0), 0)) AS fipd_paid, ;
	SUM(IIF(service_type = "IPD", IIF(!EMPTY(fax_by), fremain, 0), 0)) AS fipd_over, ;
	SUM(IIF(service_type <> "IPD" AND EMPTY(fax_by), 1, 0)) AS opd_frq, ;
	SUM(IIF(service_type <> "IPD" AND EMPTY(fax_by), scharge, 0)) AS opd_charge, ;	
	SUM(IIF(service_type <> "IPD" AND EMPTY(fax_by), sbenfpaid, 0)) AS opd_paid, ;	
	SUM(IIF(service_type <> "IPD" AND EMPTY(fax_by), sremain, 0)) AS opd_over, ;	
	SUM(IIF(service_type = "IPD" AND EMPTY(fax_by), 1, 0)) AS ipd_frq, ;
	SUM(IIF(service_type = "IPD", IIF(EMPTY(fax_by), scharge, 0), 0)) AS ipd_charge, ;	
	SUM(IIF(service_type = "IPD", IIF(EMPTY(fax_by), sbenfpaid, 0), 0)) AS ipd_paid, ;
	SUM(IIF(service_type = "IPD", IIF(EMPTY(fax_by), sremain, 0), 0)) AS ipd_over, ;
	plan AS i_plan, MONTH(notify_date) AS not_month ;	
FROM cims!claim ;
WHERE fundcode = gcfundCode ;
	AND INLIST(claim_with, "A", "P") ;
	AND MONTH(notify_date) = MONTH(gdEndDate) ;
	AND YEAR(notify_date) = YEAR(gdEndDate)  ;
	AND INLIST(result, "P1", "P5", "W5", "W6", "A1") ;
GROUP BY 1 ;
ORDER BY plan;
INTO TABLE (gcSaveTo+lcMonth)
*
*******************************************************
SELECT notify_no, notify_date, policy_no, LEFT(client_name,50) AS client_name, ALLTRIM(plan) AS plan, ;
	LEFT(prov_name,30) AS prov_name, admis_date, note2ins, plan AS i_plan ;
FROM cims!claim ;
WHERE fundcode = gcfundCode ;
	AND claim_with = "P" ;
	AND notify_date BETWEEN gtStartDate AND gtEndDate ;
	AND result = "D" ;
UNION ALL ;
SELECT notify_no, notify_date, policy_no, client_name, ALLTRIM(plan) AS plan, ;
	prov_name, admis_date, note2ins, plan AS i_plan ;
FROM cims!notify ;
WHERE fundcode = gcfundCode ;
	AND INLIST(notify_with, "A", "P") ;
	AND MONTH(notify_date) = MONTH(gdEndDate) ;
	AND YEAR(notify_date) = YEAR(gdEndDate)  ;
	AND comment > 1 AND !EMPTY(note2ins) ;
ORDER BY 1 ;	
INTO TABLE (gcSaveTo+lcDenied)
***************************************************************************
SELECT plan, MONTH(notify_date) AS n_month, notify_date, ;
	SUM(IIF(service_type = "IPD", 1, 0)) AS ipd_frq, ;
	SUM(IIF(service_type = "IPD", IIF(!EMPTY(fax_by), fcharge, scharge), 0)) AS ipd_charge, ;
	SUM(IIF(service_type = "IPD", IIF(!EMPTY(fax_by), fbenfpaid, sbenfpaid), 0)) AS ipd_paid, ;
	SUM(IIF(service_type = "IPD", IIF(!EMPTY(fax_by), fremain, sremain), 0)) AS ipd_over, ;
	SUM(IIF(service_type <> "IPD", 1, 0)) AS opd_frq, ;
	SUM(IIF(service_type <> "IPD", IIF(fcharge = 0, scharge, fcharge), 0)) AS opd_charge, ;
	SUM(IIF(service_type <> "IPD", IIF(fbenfpaid = 0, sbenfpaid, fbenfpaid), 0)) AS opd_paid, ;
	SUM(IIF(service_type <> "IPD", IIF(fremain = 0, sremain, fremain), 0)) AS opd_over ;
FROM cims!claim ;
WHERE fundcode = gcFundCode ;	
	AND INLIST(claim_with, "A", "P") ;
	AND notify_date BETWEEN gtStartDate AND gtEndDate ;
	AND INLIST(result, "P1", "P5", "W5", "W6", "A1") ;
GROUP BY 1,2 ;
ORDER BY 1,2 ;
INTO TABLE (gcSaveTo+lcSum)
*
****************************************************************************
SELECT MONTH(notify_date) AS not_month, notify_date, ;
	SUM(IIF(service_type = "IPD", 1, 0)) AS ipd_frq, ;
	SUM(IIF(service_type = "IPD", IIF(!EMPTY(fax_by), fcharge, scharge), 0)) AS ipd_charge, ;
	SUM(IIF(service_type = "IPD", IIF(!EMPTY(fax_by), fbenfpaid, sbenfpaid), 0)) AS ipd_paid, ;
	SUM(IIF(service_type = "IPD", IIF(!EMPTY(fax_by), fremain, sremain), 0)) AS ipd_over, ;
	SUM(IIF(!INLIST(service_type, "IPD", "MIS", "LAB"), 1, 0)) AS opd_frq, ;
	SUM(IIF(!INLIST(service_type, "IPD", "MIS", "LAB"), IIF(fcharge = 0, scharge, fcharge), 0)) AS opd_charge, ;
	SUM(IIF(!INLIST(service_type, "IPD", "MIS", "LAB"), IIF(fbenfpaid = 0, sbenfpaid, fbenfpaid), 0)) AS opd_paid, ;
	SUM(IIF(!INLIST(service_type, "IPD", "MIS", "LAB"), IIF(fremain = 0, sremain, fremain), 0)) AS opd_over, ;	
	SUM(IIF(service_type = "MIS", 1, 0)) AS mis_frq, ;
	SUM(IIF(service_type = "MIS", IIF(!EMPTY(fax_by), fcharge, scharge), 0)) AS mis_charge, ;
	SUM(IIF(service_type = "MIS", IIF(!EMPTY(fax_by), fbenfpaid, sbenfpaid), 0)) AS mis_paid, ;
	SUM(IIF(service_type = "MIS", IIF(!EMPTY(fax_by), fremain, sremain), 0)) AS mis_over, ;
	SUM(IIF(service_type = "LAB", 1, 0)) AS lab_frq, ;		
	SUM(IIF(service_type = "LAB", IIF(!EMPTY(fax_by), fcharge, scharge), 0)) AS lab_charge, ;			
	SUM(IIF(service_type = "LAB", IIF(!EMPTY(fax_by), fbenfpaid, sbenfpaid), 0)) AS lab_paid, ;
	SUM(IIF(service_type = "LAB", IIF(!EMPTY(fax_by), fremain, sremain), 0)) AS lab_over ;				
FROM cims!claim ;
WHERE fundcode = gcFundCode ;	
	AND INLIST(claim_with, "A", "P") ;
	AND notify_date BETWEEN gtStartDate AND gtEndDate ;
	AND INLIST(result, "P1", "P5", "W5", "W6", "A1") ;
GROUP BY 1 ;
ORDER BY 2 ;
INTO TABLE (gcSaveTo+lcRoll)
*****************************************************
*Sum current month
SELECT not_month, ;
	SUM(f_opd_frq+opd_frq) AS opd_frq, ;
	SUM(fopd_charg+opd_charge) AS opd_charge, ;
	SUM(fopd_paid+opd_paid) AS opd_paid, ;
	SUM(fopd_over+opd_over) AS opd_over, ;
	SUM(f_ipd_frq+ipd_frq) AS ipd_frq, ;
	SUM(fipd_charg+ipd_charge) AS ipd_charge, ;
	SUM(fipd_paid+ipd_paid) AS ipd_paid, ;
	SUM(fipd_over+ipd_over) AS ipd_over ;		
FROM (gcSaveTo+lcMonth) ;
INTO CURSOR curMonth
*
SELECT curMonth 
SCATTER FIELDS ipd_frq, ipd_charge, ipd_paid, ipd_over, opd_frq, opd_charge, opd_paid, opd_over MEMVAR 
*
SELECT (lcRoll)
GO TOP 
LOCATE FOR curMonth.not_month = not_month
IF FOUND()
	GATHER FIELDS ipd_frq, ipd_charge, ipd_paid, ipd_over, opd_frq, opd_charge, opd_paid, opd_over MEMVAR 
ENDIF 
**********************************************
*Genarate Graph
CREATE TABLE (gcSaveTo+lcGraph) FREE (graph G)
APPEND BLANK IN (lcGraph)
lcFullGraph = gcSaveTo+lcGraph+".dbf"
*
SELECT CMONTH(notify_dat) AS months, ipd_paid+opd_paid AS paid ;
FROM (lcRoll) ;
INTO CURSOR curGraph
*
lcText = "Claim Summary of Year "+STR(YEAR(gdEndDate),4)
DO (gcProgPath+"wzgraph.app") WITH "AUTOGRAPH", 4, 1, lcText, .F., .T.,.T., lcFullGraph, .T.
**********************************************************************
*
PROCEDURE Print_report
*
IF !USED(lcMonth)
	USE (gcSaveTo+lcMonth) IN 0
ENDIF 	
*
IF !USED(lcDenied)
	USE (gcSaveTo+lcDenied) IN 0
ENDIF 	
*
IF !USED(lcSum)
	USE (gcSaveTo+lcSum) IN 0
ENDIF 	
*
IF !USED(lcRoll)
	USE (gcSaveTo+lcRoll) IN 0
ENDIF 	
*
IF !USED(lcGraph)
	USE (gcSaveTo+lcGraph) IN 0 
ENDIF 	
*****************************
DO CASE 
CASE gnOption = 1
	lcReportFile = gcReportPath+"bui_month.frx"
	IF FILE(lcReportFile)
		SELECT (lcMonth)
		REPORT FORM (lcReportFile) TO PRINTER PROMPT NOCONSOLE 
	ENDIF 
	********************
	lcReportFile = gcReportPath+"bui_denied.frx"
	IF FILE(lcReportFile)
		SELECT (lcDenied)
		REPORT FORM (lcReportFile) TO PRINTER PROMPT NOCONSOLE 
	ENDIF 	
	********************
	lcReportFile = gcReportPath+"bui_rolling.frx"
	IF FILE(lcReportFile)
		SELECT (lcRoll)
		REPORT FORM (lcReportFile) TO PRINTER PROMPT NOCONSOLE 
	ENDIF 
	********************
	lcReportFile = gcReportPath+"bui_summary.frx"
	IF FILE(lcReportFile)
		SELECT (lcSum)
		REPORT FORM (lcReportFile) TO PRINTER PROMPT NOCONSOLE 
	ENDIF 	
CASE gnOption = 2
	IF USED(lcMonth)
		lcReportFile = gcReportPath+"bui_month.frx"
		IF FILE(lcReportFile)
			SELECT (lcMonth)
			REPORT FORM (lcReportFile) TO PRINTER PROMPT PREVIEW NOCONSOLE 
		ENDIF 
	ENDIF 	
	********************
	IF USED(lcDenied)
		lcReportFile = gcReportPath+"bui_denied.frx"
		IF FILE(lcReportFile)
			SELECT (lcdenied)
			REPORT FORM (lcReportFile) TO PRINTER PROMPT PREVIEW NOCONSOLE 
		ENDIF 
	ENDIF 	
	********************
	IF USED(lcRoll) AND USED(lcGraph)
		lcReportFile = gcReportPath+"bui_rolling.frx"
		IF FILE(lcReportFile)
			SELECT (lcRoll)
			REPORT FORM (lcReportFile) TO PRINTER PROMPT PREVIEW NOCONSOLE 
		ENDIF 
	ENDIF 	
	********************
	IF USED(lcSum)
		lcReportFile = gcReportPath+"bui_summary.frx"
		IF FILE(lcReportFile)
			SELECT (lcSum)
			REPORT FORM (lcReportFile) TO PRINTER PROMPT PREVIEW NOCONSOLE 
		ENDIF 
	ENDIF 	
CASE gnOption = 3
ENDCASE 	
*
IF USED(lcMonth)
	USE IN (lcMonth)
ENDIF 	
*
IF USED(lcDenied)
	USE IN (lcDenied)
ENDIF 	
*
IF USED(lcSum)
	USE IN (lcSum)
ENDIF 	
*
IF USED(lcRoll)
	USE IN (lcRoll)
ENDIF 	
*
IF USED(lcGraph)
	USE IN (lcGraph)
ENDIF 	
