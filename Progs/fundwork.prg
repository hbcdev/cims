PUBLIC gdStartDate, gdEndDate
gdStartDate = DATE()
gdEndDate = DATE()+30
*
DO FORM form\daterange
IF EMPTY(gdStartDate)
	RETURN 
ENDIF	
**
WAIT WINDOW "Query Logbook" NOWAIT 
*Log
SELECT Notify_log.fundcode, Notify_log.summit AS date, count(notify_log.notify_no) as amount;
 FROM cims!notify_log;
 WHERE Notify_log.summit BETWEEN gdstartdate AND gdenddate;
 GROUP BY 1, 2;
 INTO CURSOR wklog
 ************************
 WAIT WINDOW "Query Precert" NOWAIT 
* Precert
SELECT fundcode, TTOD(notify_date) as date,count(notify_no) as amount;
 FROM cims!notify;
 WHERE TTOD(Notify.notify_date) BETWEEN gdstartdate AND gdenddate;
 GROUP BY 1, 2;
 INTO CURSOR wkprecert
 **
 WAIT WINDOW "Query Faxclaim" NOWAIT 
 *Faxclaim
 SELECT fundcode, TTOD(fax_date) as date,count(notify_no) as amount;
 FROM cims!claim;
 WHERE TTOD(fax_date) BETWEEN gdstartdate AND gdenddate;
 GROUP BY 1, 2;
 INTO CURSOR wkfax
**
WAIT WINDOW "Query Assess" NOWAIT 
*Assess
SELECT fundcode, TTOD(assessor_date) as date,count(notify_no) as amount;
 FROM cims!claim;
 WHERE TTOD(assessor_date) BETWEEN gdstartdate AND gdenddate;
 GROUP BY 1, 2;
 INTO CURSOR wkassess
**
WAIT WINDOW "Query Audit" NOWAIT 
* Audit
SELECT fundcode, TTOD(audit_date) as date,count(notify_no) as amount;
 FROM cims!claim;
 WHERE TTOD(audit_date) BETWEEN gdstartdate AND gdenddate;
 GROUP BY 1, 2;
 INTO CURSOR wkaudit
******************************************************************
WAIT WINDOW "Export To Excel" NOWAIT 
o = CREATEOBJECT("Excel.application")
oBook = o.Workbooks.Add
oSheet = oBook.WorkSheets("Sheet1")
oSheet.Name = "Log"
*********************************
WITH oSheet
	.Cells(1,1) = "Fund code"
	.Cells(1,2) = "Date"
	.Cells(1,3) = "Amount"
ENDWITH 	
**********************
i = 2
SELECT wklog
SCAN
	WITH oSheet
		.Cells(i,1) = fundcode
		.Cells(i,2) = date
		.Cells(i,3) = amount
	ENDWITH 	
	i = i + 1
ENDSCAN
*************************
oSheet = oBook.WorkSheets("Sheet2")
oSheet.Name = "Precert"
*********************************
WITH oSheet
	.Cells(1,1) = "Fund code"
	.Cells(1,2) = "Date"
	.Cells(1,3) = "Amount"
ENDWITH 	
**********************
i = 2
SELECT wkprecert
SCAN 
	WITH oSheet
		.Cells(i,1) = fundcode
		.Cells(i,2) = date
		.Cells(i,3) = amount
	ENDWITH 	
	i = i + 1
ENDSCAN
*************************
oSheet = oBook.WorkSheets("Sheet3")
oSheet.Name = "Faxclaim"
*********************************
WITH oSheet
	.Cells(1,1) = "Fund code"
	.Cells(1,2) = "Date"
	.Cells(1,3) = "Amount"
ENDWITH 	
**********************
i = 2
SELECT wkfax
SCAN 
	WITH oSheet
		.Cells(i,1) = fundcode
		.Cells(i,2) = date
		.Cells(i,3) = amount
	ENDWITH 	
	i = i + 1
ENDSCAN
*************************
oSheet = oBook.WorkSheets.Add
oSheet = oBook.WorkSheets("Sheet4")
oSheet.Name = "Assess"
*********************************
WITH oSheet
	.Cells(1,1) = "Fund code"
	.Cells(1,2) = "Date"
	.Cells(1,3) = "Amount"
ENDWITH 	
**********************
i = 2
SELECT wkAssess
SCAN 
	WITH oSheet
		.Cells(i,1) = fundcode
		.Cells(i,2) = date
		.Cells(i,3) = amount
	ENDWITH 	
	i = i + 1
ENDSCAN
*************************
oSheet = oBook.WorkSheets.Add
oSheet = oBook.WorkSheets("Sheet5")
oSheet.Name = "Audit"
*********************************
WITH oSheet
	.Cells(1,1) = "Fund code"
	.Cells(1,2) = "Date"
	.Cells(1,3) = "Amount"
ENDWITH 	
**********************
i = 2
SELECT wkAudit
SCAN 
	WITH oSheet
		.Cells(i,1) = fundcode
		.Cells(i,2) = date
		.Cells(i,3) = amount
	ENDWITH 	
	i = i + 1
ENDSCAN
*************************
lcExcel = PUTFILE("Save excel file to", "Fund count_"+DTOC(gdStartDate)+"_"+DTOC(gdEnddate), "XLS")
oBook.SaveAs(lcExcel)
o.Quit
WAIT WINDOW "Genarate sucess" NOWAIT 