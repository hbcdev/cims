PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption
********************	
gcFundCode = "BUI"
gdEndDate = DATE()
gdStartDate = DATE(YEAR(gdEndDate), MONTH(gdEndDate), 1)
gnOption = 1
gcSaveTo = ADDBS(gcTemp)
DO FORM form\dateentry1
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
gcSaveTo =ADDBS( IIF(EMPTY(gcSaveTo), gcTemp, gcSaveTo))
IF !DIRECTORY(gcSaveTo)
	MD (gcSaveTo)
ENDIF 
gcSaveTo = ADDBS(gcSaveTo)	
************************************
lcDbf = gcFundCode+"_Claim"
lcMonth = gcFundCode+"_Monthly"
lcDenied = gcFundCode+"_Denied"
lcRoll = gcFundCode+"_Rolling"
lcSum = gcFundCode+"_Summary"
lcGraph = "Graph"
*************************************
IF FILE(gcSaveTo+lcMonth+".dbf") AND FILE(gcSaveTo+lcDenied+".dbf") AND FILE(gcSaveTo+lcRoll+".dbf") AND FILE(gcSaveTo+lcSum+".dbf") AND FILE(gcSaveTo+lcGraph+".dbf")
	DO Print_report IN query_bui
ELSE 
	DO Query_Data IN query_bui
	DO Print_report IN query_bui
ENDIF 		
*
=MESSAGEBOX("Query Data sucess", 0, "Message")
********************************************
PROCEDURE query_data
*
SELECT notify_no, notify_date, policy_no, policy_holder, client_name, ;
	IIF(LEFT(plan,3) = "413", IIF(LEFT(RIGHT(ALLTRIM(plan),3),1) $ "1234", "·ºπ "+LEFT(RIGHT(ALLTRIM(plan),3),1), "æ‘‡»… "+STR(VAL(LEFT(RIGHT(ALLTRIM(plan),3),1))-4,1)), plan) AS plan, ;
	IIF(service_type = "IPD", service_type, "OPD") AS service, ;
	prov_name, admis_date, fcharge, fbenfpaid, fremain, scharge, ;
	sbenfpaid, sremain, result, note2ins, plan AS i_plan, ;
	IIF(EMPTY(fax_by), 0, fcharge) AS f_charge, ;
	IIF(EMPTY(fax_by), 0, fbenfpaid) AS f_paid, ;
	IIF(EMPTY(fax_by), 0, fremain) AS f_remain, ;
	IIF(!EMPTY(fax_by), scharge, 0) AS s_charge, ;
	IIF(!EMPTY(fax_by), sbenfpaid, 0) AS s_paid, ;
	IIF(!EMPTY(fax_by), sremain, 0) AS s_remain, ;
	IIF(!EMPTY(fax_by), scharge, fcharge) AS charge, ;
	IIF(!EMPTY(fax_by), sbenfpaid, fbenfpaid) AS paid, ;
	IIF(!EMPTY(fax_by), sremain, fremain) AS remain, ;
	IIF(EMPTY(fax_by), "S", "F") AS c_type, ;
	MONTH(notify_date) AS n_month, fax_by ;
FROM cims!claim ;
WHERE fundcode = gcFundCode ;
	AND result = "P" ;
	AND YEAR(notify_date) = YEAR(gdendDate) ;
	AND MONTH(notify_date) <= MONTH(gdEndDate) ;
ORDER BY policy_no ;
INTO DBF (gcSaveTo+lcDbf)	
*
*********************************************************************************************
*Denied Claim and percert
SELECT notify_no, notify_date, policy_no, LEFT(client_name,50) AS client_name, ;
	IIF(LEFT(plan,3) = "413", IIF(LEFT(RIGHT(ALLTRIM(plan),3),1) $ "1234", "·ºπ "+LEFT(RIGHT(ALLTRIM(plan),3),1), "æ‘‡»… "+STR(VAL(LEFT(RIGHT(ALLTRIM(plan),3),1))-4,1)), plan) AS plan, ;
	LEFT(prov_name,30) AS prov_name, admis_date, note2ins, plan AS i_plan ;
FROM cims!claim ;
WHERE fundcode = gcfundCode ;
	AND TTOD(notify_date) BETWEEN gdStartDate AND gdEndDate ;
	AND result = "D" ;
UNION ALL ;
SELECT notify_no, notify_date, policy_no, client_name, ;
	IIF(LEFT(plan,3) = "413", IIF(LEFT(RIGHT(ALLTRIM(plan),3),1) $ "1234", "·ºπ "+LEFT(RIGHT(ALLTRIM(plan),3),1), "æ‘‡»… "+STR(VAL(LEFT(RIGHT(ALLTRIM(plan),3),1))-4,1)), plan) AS plan , ;
	prov_name, admis_date, note2ins, plan AS i_plan ;
FROM cims!notify ;
WHERE fundcode = gcfundCode ;
	AND TTOD(notify_date) BETWEEN gdStartDate AND gdEndDate ;
	AND comment > 1 AND !EMPTY(note2ins) ;
ORDER BY 1 ;	
INTO DBF (gcSaveTo+lcDenied)
***************************************************************************
*Monthly Report
SELECT policy_no, plan, ;
	SUM(IIF(service = "OPD" AND c_type = "F", 1, 0)) AS f_opd_frq, ;
	SUM(IIF(service = "OPD", f_charge, 0)) AS fopd_charge, ;
	SUM(IIF(service = "OPD", f_paid, 0)) AS fopd_paid, ;
	SUM(IIF(service = "OPD", f_remain, 0)) AS fopd_over, ;
	SUM(IIF(service = "IPD" AND c_type = "F", 1, 0)) AS f_ipd_frq, ;
	SUM(IIF(service = "IPD", f_charge, 0)) AS fipd_charge, ;
	SUM(IIF(service = "IPD", f_paid, 0)) AS fipd_paid, ;
	SUM(IIF(service = "IPD", f_remain, 0)) AS fipd_over, ;
	SUM(IIF(service = "OPD" AND c_type = "S", 1, 0)) AS opd_frq, ;
	SUM(IIF(service = "OPD", s_charge, 0)) AS opd_charge, ;
	SUM(IIF(service = "OPD", s_paid, 0)) AS opd_paid, ;
	SUM(IIF(service = "OPD", s_remain, 0)) AS opd_over, ;
	SUM(IIF(service = "IPD" AND c_type = "S", 1, 0)) AS ipd_frq, ;
	SUM(IIF(service = "IPD", s_charge, 0)) AS ipd_charge, ;
	SUM(IIF(service = "IPD", s_paid, 0)) AS ipd_paid, ;
	SUM(IIF(service = "IPD", s_remain, 0)) AS ipd_over, ;
	plan AS i_plan ;	
FROM (gcSaveTo+lcDbf) ;
WHERE notify_dat BETWEEN gdStartDate AND gdEndDate ;
GROUP BY 1, 2 ;
ORDER BY policy_no ;
INTO DBF (gcSaveTo+lcMonth)
*
****************************************************************************
*Summary 
SELECT policy_no, policy_hol, n_month, notify_dat, ;
	SUM(IIF(service = "IPD", 1, 0)) AS ipd_frq, ;
	SUM(IIF(service = "IPD", charge, 0)) AS ipd_charge, ;
	SUM(IIF(service = "IPD", paid, 0)) AS ipd_paid, ;
	SUM(IIF(service = "IPD", remain, 0)) AS ipd_over, ;
	SUM(IIF(service = "OPD", 1, 0)) AS opd_frq, ;
	SUM(IIF(service = "OPD", charge, 0)) AS opd_charge, ;
	SUM(IIF(service = "OPD", paid, 0)) AS opd_paid, ;
	SUM(IIF(service = "OPD", remain, 0)) AS opd_over ;
FROM (gcSaveTo+lcDbf) ;
GROUP BY 1,3 ;
ORDER BY 1,3 ;
INTO DBF (gcSaveTo+lcSum)
*
****************************************************************************
SELECT n_month, notify_dat, ;
	SUM(IIF(service = "IPD", 1, 0)) AS ipd_frq, ;
	SUM(IIF(service = "IPD", charge, 0)) AS ipd_charge, ;
	SUM(IIF(service = "IPD", paid, 0)) AS ipd_paid, ;
	SUM(IIF(service = "IPD", remain, 0)) AS ipd_over, ;
	SUM(IIF(service = "OPD", 1, 0)) AS opd_frq, ;
	SUM(IIF(service = "OPD", charge, 0)) AS opd_charge, ;
	SUM(IIF(service = "OPD", paid, 0)) AS opd_paid, ;
	SUM(IIF(service = "OPD", remain, 0)) AS opd_over ;
FROM (gcSaveto+lcDbf) ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO DBF (gcSaveTo+lcRoll)
*
*****************************************************
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
**********************************************
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

