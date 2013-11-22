PUBLIC gdStartDate, gdEndDate
gdStartDate = DATE()
gdEndDate = DATE()+30
*
DO form\daterange
IF EMPTY(gdStartDate)
	RETURN 
ENDIF	
**
WAIT WINDOW "Query Logbook" NOWAIT 
*Log
SELECT Notify_log.record_by AS users, Notify_log.summit AS date, count(notify_log.notify_no) as amount;
 FROM cims!notify_log;
 WHERE Notify_log.summit BETWEEN gdstartdate AND gdenddate;
 GROUP BY 1, 2;
 INTO CURSOR wklog
 ************************
 WAIT WINDOW "Query Precert" NOWAIT 
* Precert
SELECT record_by AS users, TTOD(notify_date) as date,count(notify_no) as amount;
 FROM cims!notify;
 WHERE TTOD(Notify.notify_date) BETWEEN gdstartdate AND gdenddate;
 GROUP BY 1, 2;
 INTO CURSOR wkprecert
 **
 WAIT WINDOW "Query Faxclaim" NOWAIT 
 *Faxclaim
 SELECT fax_by AS users, TTOD(fax_date) as date,count(notify_no) as amount;
 FROM cims!claim;
 WHERE TTOD(fax_date) BETWEEN gdstartdate AND gdenddate AND !EMPTY(fax_by);
 GROUP BY 1, 2;
 INTO CURSOR wkfax
**
 SELECT fax_audit AS users, TTOD(fax_date) as date,count(notify_no) as amount;
 FROM cims!claim;
 WHERE TTOD(fax_date) BETWEEN gdstartdate AND gdenddate AND !EMPTY(fax_by);
 GROUP BY 1, 2;
 INTO CURSOR wkfaxAudit
**
WAIT WINDOW "Query Assess" NOWAIT 
*Assess
SELECT assessor_by AS users, TTOD(assessor_date) as date,count(notify_no) as amount;
 FROM cims!claim;
 WHERE TTOD(assessor_date) BETWEEN gdstartdate AND gdenddate AND !EMPTY(assessor_by);
 GROUP BY 1, 2;
 INTO CURSOR wkassess
**
WAIT WINDOW "Query Audit" NOWAIT 
* Audit
SELECT audit_by AS users, TTOD(audit_date) as date,count(notify_no) as amount;
 FROM cims!claim;
 WHERE TTOD(audit_date) BETWEEN gdstartdate AND gdenddate AND !EMPTY(audit_by);
 GROUP BY 1, 2;
 INTO CURSOR wkaudit
******************************************************************
WAIT WINDOW "Export To Excel" NOWAIT 
o = CREATEOBJECT("Excel.application")
oBook = o.Workbooks.Add
oSheet = oBook.WorkSheets.Add
oSheet.Name = "Log"
*********************************
WITH oSheet
	.Cells(1,1) = "Users"
	.Cells(1,2) = "Date"
	.Cells(1,3) = "Amount"
ENDWITH 	
**********************
i = 2
SELECT wklog
SCAN
	WITH oSheet
		.Cells(i,1) = users
		.Cells(i,2) = date
		.Cells(i,3) = amount
	ENDWITH 	
	i = i + 1
ENDSCAN
*************************
oSheet = oBook.WorkSheets.Add
oSheet.Name = "Precert"
*********************************
WITH oSheet
	.Cells(1,1) = "Users"
	.Cells(1,2) = "Date"
	.Cells(1,3) = "Amount"
ENDWITH 	
**********************
i = 2
SELECT wkprecert
SCAN 
	WITH oSheet
		.Cells(i,1) = users
		.Cells(i,2) = date
		.Cells(i,3) = amount
	ENDWITH 	
	i = i + 1
ENDSCAN
*************************
oSheet = oBook.WorkSheets.Add
oSheet.Name = "Faxclaim"
*********************************
WITH oSheet
	.Cells(1,1) = "Users"
	.Cells(1,2) = "Date"
	.Cells(1,3) = "Amount"
ENDWITH 	
**********************
i = 2
SELECT wkfax
SCAN 
	WITH oSheet
		.Cells(i,1) = users
		.Cells(i,2) = date
		.Cells(i,3) = amount
	ENDWITH 	
	i = i + 1
ENDSCAN
*************************
oSheet = oBook.WorkSheets.Add
oSheet.Name = "Fax Audit"
*********************************
WITH oSheet
	.Cells(1,1) = "Users"
	.Cells(1,2) = "Date"
	.Cells(1,3) = "Amount"
ENDWITH 	
**********************
i = 2
SELECT wkfaxAudit
SCAN 
	WITH oSheet
		.Cells(i,1) = users
		.Cells(i,2) = date
		.Cells(i,3) = amount
	ENDWITH 	
	i = i + 1
ENDSCAN
*************************
oSheet = oBook.WorkSheets.Add
oSheet.Name = "Assess"
*********************************
WITH oSheet
	.Cells(1,1) = "Users"
	.Cells(1,2) = "Date"
	.Cells(1,3) = "Amount"
ENDWITH 	
**********************
i = 2
SELECT wkAssess
SCAN 
	WITH oSheet
		.Cells(i,1) = users
		.Cells(i,2) = date
		.Cells(i,3) = amount
	ENDWITH 	
	i = i + 1
ENDSCAN
*************************
oSheet = oBook.WorkSheets.Add
oSheet.Name = "Audit"
*********************************
WITH oSheet
	.Cells(1,1) = "Users"
	.Cells(1,2) = "Date"
	.Cells(1,3) = "Amount"
ENDWITH 	
**********************
i = 2
SELECT wkAudit
SCAN 
	WITH oSheet
		.Cells(i,1) = users
		.Cells(i,2) = date
		.Cells(i,3) = amount
	ENDWITH 	
	i = i + 1
ENDSCAN
*************************
lcExcel = PUTFILE("Save excel file to", "Users count_"+DTOC(gdStartDate)+"_"+DTOC(gdEnddate), "XLS")
oBook.SaveAs(lcExcel)
o.Quit
WAIT WINDOW "Genarate sucess" NOWAIT 