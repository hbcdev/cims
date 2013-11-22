SET PROCEDURE TO progs\utility

gcFundCode = "KTA"
gdStartDate = {^2008-01-01}
gdEndDate = {^2008-04-30}
lcFile = "F:\report\"+gcfundcode+"\"+gcFundCode+"_Trunaround_time from"+STR(DAY(gdStartDate),2)+"_"+LEFT(CMONTH(gdStartDate),3)+"_"+STR(YEAR(gdStartDate),4)+"-"+STR(DAY(gdEndDate),2)+"_"+LEFT(CMONTH(gdEndDate),3)+"_"+STR(YEAR(gdEndDate),4)
*
SELECT notify_no, notify_date, service_type, fax_date, assessor_date, audit_date, paid_date, ;
timein, timeout, docin, docout,  LEFT(result,1) AS status, result, ;
paid_date - TTOD(notify_date) AS reimtime, ;
((VAL(LEFT(timeout,2))*60)+VAL(RIGHT(timeout,2))) - ((VAL(LEFT(timein,2))*60)+VAL(RIGHT(timein,2))) AS timeused, ;
((VAL(LEFT(docout,2))*60)+VAL(RIGHT(docout,2))) - ((VAL(LEFT(docin,2))*60)+VAL(RIGHT(docin,2))) AS docused ; 
FROM cims!claim WHERE fundcode = gcfundCode AND TTOD(fax_date) between gdStartDate and gdEndDate ;
and result # "C" AND !EMPTY(fax_by) ;
INTO CURSOR curTrun1
*
SELECT notify_no, notify_date, service_type, fax_date, assessor_date, audit_date, paid_date, ;
timein, timeout, docin, docout,  LEFT(result,1) AS status, result, ;
(paid_date - TTOD(notify_date)) - holidays(TTOD(notify_date), paid_date) AS reimtime, ;
(return_date - TTOD(notify_date)) - holidays(TTOD(notify_date), return_date) AS rettime, ;
(paid_date - return_date) - holidays(paid_date, return_date) AS paidtime, ;
(return_date - TTOD(assessor_date)) - holidays(TTOD(assessor_date), return_date)AS audittime ;
FROM cims!claim WHERE fundcode = gcfundCode AND TTOD(notify_date) between gdStartDate and gdEndDate ;
and INLIST(result, "P1", "P2", "P3", "P4") AND !EMPTY(paid_date) ;
INTO CURSOR curReim

*
SELECT MONTH(notify_date), LEFT(CMONTH(notify_date),3) AS months, ;
SUM(IIF(reimtime <= 5, 1, 0)) AS d1, ;
SUM(IIF(reimtime > 5 AND reimtime <= 10, 1, 0)) AS d2, ;
SUM(IIF(reimtime > 10 AND reimtime <= 15, 1, 0)) AS d3, ;
SUM(IIF(reimtime > 15 AND reimtime <= 20, 1, 0)) AS d4, ;
SUM(IIF(reimtime > 20 AND reimtime <= 25, 1, 0)) AS d5, ;
SUM(IIF(reimtime > 25 AND reimtime <= 30, 1, 0)) AS d6, ;
SUM(IIF(reimtime > 30, 1, 0)) AS d7 ;
FROM curReim ;
GROUP BY 1, 2 ;
INTO CURSOR curReim1
*
SELECT MONTH(notify_date), LEFT(CMONTH(notify_date),3) AS months, ;
SUM(IIF(rettime <= 3, 1, 0)) AS d1, ;
SUM(IIF(rettime > 3 AND rettime <= 10, 1, 0)) AS d2, ;
SUM(IIF(rettime > 10 AND rettime <= 15, 1, 0)) AS d3, ;
SUM(IIF(rettime > 15 AND rettime <= 20, 1, 0)) AS d4, ;
SUM(IIF(rettime > 20 AND rettime <= 25, 1, 0)) AS d5, ;
SUM(IIF(rettime > 25 AND rettime <= 30, 1, 0)) AS d6, ;
SUM(IIF(rettime > 30, 1, 0)) AS d7 ;
FROM curReim ;
GROUP BY 1, 2 ;
INTO CURSOR curReim2
*
SELECT MONTH(notify_date), LEFT(CMONTH(notify_date),3) AS months, ;
SUM(IIF(paidtime <= 2, 1, 0)) AS d1, ;
SUM(IIF(paidtime > 2 AND paidtime <= 10, 1, 0)) AS d2, ;
SUM(IIF(paidtime > 10 AND paidtime <= 15, 1, 0)) AS d3, ;
SUM(IIF(paidtime > 15 AND paidtime <= 20, 1, 0)) AS d4, ;
SUM(IIF(paidtime > 20 AND paidtime <= 25, 1, 0)) AS d5, ;
SUM(IIF(paidtime > 25 AND paidtime <= 30, 1, 0)) AS d6, ;
SUM(IIF(paidtime > 30, 1, 0)) AS d7 ;
FROM curReim ;
GROUP BY 1, 2 ;
INTO CURSOR curReim3
*
SELECT MONTH(notify_date), LEFT(CMONTH(notify_date),3) AS months, ;
SUM(IIF(audittime <= 2, 1, 0)) AS d1, ;
SUM(IIF(audittime > 2 AND audittime <= 10, 1, 0)) AS d2, ;
SUM(IIF(audittime > 10 AND audittime <= 15, 1, 0)) AS d3, ;
SUM(IIF(audittime > 15 AND audittime <= 20, 1, 0)) AS d4, ;
SUM(IIF(audittime > 20 AND audittime <= 25, 1, 0)) AS d5, ;
SUM(IIF(audittime > 25 AND audittime <= 30, 1, 0)) AS d6, ;
SUM(IIF(audittime > 30, 1, 0)) AS d7 ;
FROM curReim ;
GROUP BY 1, 2 ;
INTO CURSOR curReim4
*
SELECT MONTH(fax_date), LEFT(CMONTH(fax_date),3) AS months, ;
SUM(IIF(timeused <= 30, 1, 0)) AS t30, ;
SUM(IIF(timeused > 30 AND timeused <= 45, 1, 0)) AS t45, ;
SUM(IIF(timeused > 45 AND timeused <= 60, 1, 0)) AS t60, ;
SUM(IIF(timeused > 60, 1, 0)) AS t61 ;
FROM curTrun1 ;
WHERE EMPTY(docin) ;
GROUP BY 1, 2 ;
INTO CURSOR curTrun2
*
SELECT CMONTH(fax_date) AS months, ;
SUM(IIF(docused <= 30, 1, 0)) AS t30, ;
SUM(IIF(docused > 30 AND docused <= 45, 1, 0)) AS t45, ;
SUM(IIF(docused > 45 AND docused <= 60, 1, 0)) AS t60, ;
SUM(IIF(docused > 60, 1, 0)) AS t61 ;
FROM curTrun1 ;
WHERE !EMPTY(docin) ;
GROUP BY 1 ;
INTO CURSOR curTrun3
*
SELECT MONTH(fax_date), LEFT(CMONTH(fax_date),3) AS months, ;
SUM(IIF(timeused <= 30, 1, 0)) AS t30, ;
SUM(IIF(timeused > 30 AND timeused <= 45, 1, 0)) AS t45, ;
SUM(IIF(timeused > 45 AND timeused <= 60, 1, 0)) AS t60, ;
SUM(IIF(timeused > 60, 1, 0)) AS t61 ;
FROM curTrun1 ;
WHERE !EMPTY(docin) ;
GROUP BY 1, 2 ;
INTO CURSOR curTrun4
*
SELECT notify_no, notify_date, service_type, timein, timeout, audit_date, ;
(audit_date - notify_date)/60 AS useds ;
FROM cims!notify WHERE fundcode = gcfundCode AND TTOD(notify_date) between gdStartDate and gdEndDate ;
INTO CURSOR curpercert1

SELECT MONTH(notify_date), LEFT(CMONTH(notify_date),3) AS months, ;
SUM(IIF(useds <= 30, 1, 0)) AS t30, ;
SUM(IIF(useds > 30 AND useds <= 45, 1, 0)) AS t45, ;
SUM(IIF(useds > 45 AND useds <= 60, 1, 0)) AS t60, ;
SUM(IIF(useds > 60, 1, 0)) AS t61, ;
SUM(IIF(useds > 480, 1, 0)) AS h4 ;
FROM curpercert1 ;
GROUP BY 1,2 ;
INTO CURSOR curpercert3

*
IF RECCOUNT("curTrun2") = 0 OR RECCOUNT("curtrun4") = 0 OR RECCOUNT("curpercert3") = 0 OR RECCOUNT("curreim") = 0
	RETURN 
ENDIF 

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()
oSheet = oWorkBook.worksheets(1)
osheet.name = "Trun Around time"

oSheet.Cells(4,1).value = "Month"
oSheet.Cells(4,2).value = "ไม่เกิน 30 นาที"
oSheet.Cells(4,3).value = "31-45 นาที"
oSheet.Cells(4,4).value = "46-60 นาที"
oSheet.Cells(4,5).value = "61 นาทีขึ้นไป"
oSheet.Cells(4,6).value = "> 4 ชั่วโมง"


lnRow = 5
SELECT curTrun2
GO TOP 
osheet.Cells(lnrow,1) = "Normal faxclaim process"
lnrow = lnrow+1
SCAN 
	osheet.Cells(lnRow,1).value = months
	osheet.Cells(lnRow,2).value = t30
	osheet.Cells(lnRow,3).value = t45
	osheet.Cells(lnRow,4).value = t60
	osheet.Cells(lnRow,5).value = t61
	lnrow = lnrow + 1
ENDSCAN 	
	
lnRow = lnrow + 5
SELECT curTrun4
GO TOP 
osheet.Cells(lnrow,1) = "Abnormal faxclaim process"
lnrow = lnrow+1
SCAN 
	osheet.Cells(lnRow,1).value = months
	osheet.Cells(lnRow,2).value = t30
	osheet.Cells(lnRow,3).value = t45
	osheet.Cells(lnRow,4).value = t60
	osheet.Cells(lnRow,5).value = t61
	lnrow = lnrow + 1	
ENDSCAN 	

lnRow = lnrow + 5
SELECT curpercert3
GO TOP 
osheet.Cells(lnrow,1) = "Percertification process(audit date - notify date)"
lnrow = lnrow+1
SCAN 
	osheet.Cells(lnRow,1).value = months
	osheet.Cells(lnRow,2).value = t30
	osheet.Cells(lnRow,3).value = t45
	osheet.Cells(lnRow,4).value = t60
	osheet.Cells(lnRow,5).value = t61
	osheet.Cells(lnRow,6).value = h4	
	lnrow = lnrow + 1	
ENDSCAN 	




lnRow = lnrow + 5
osheet.Cells(lnrow,1) = "Reimbursement Claim"
lnrow = lnrow+1

oSheet.Cells(lnrow,1).value = "Month"
oSheet.Cells(lnrow,2).value = "<= 5 Days"
oSheet.Cells(lnrow,3).value = "6-10 Days"
oSheet.Cells(lnrow,4).value = "11-15 Days"
oSheet.Cells(lnrow,5).value = "16-20 Days"
oSheet.Cells(lnrow,6).value = "21-25 Days"
oSheet.Cells(lnrow,7).value = "26-30 Days"
oSheet.Cells(lnrow,8).value = ">30 Days"

SELECT curReim1
GO TOP 
lnrow = lnrow+1
SCAN 
	osheet.Cells(lnRow,1).value = months
	osheet.Cells(lnRow,2).value = d1
	osheet.Cells(lnRow,3).value = d2
	osheet.Cells(lnRow,4).value = d3
	osheet.Cells(lnRow,5).value = d4
	osheet.Cells(lnRow,6).value = d6
	osheet.Cells(lnRow,7).value = d7
	lnrow = lnrow + 1
ENDSCAN 	

lnRow = lnrow + 5
osheet.Cells(lnrow,1) = "Reimbursement Claim(Receive date -> Return date)"
lnrow = lnrow+1

oSheet.Cells(lnrow,1).value = "Month"
oSheet.Cells(lnrow,2).value = "<= 3 Days"
oSheet.Cells(lnrow,3).value = "4-10 Days"
oSheet.Cells(lnrow,4).value = "11-15 Days"
oSheet.Cells(lnrow,5).value = "16-20 Days"
oSheet.Cells(lnrow,6).value = "21-25 Days"
oSheet.Cells(lnrow,7).value = "26-30 Days"
oSheet.Cells(lnrow,8).value = ">30 Days"

SELECT curReim2
GO TOP 
lnrow = lnrow+1
SCAN 
	osheet.Cells(lnRow,1).value = months
	osheet.Cells(lnRow,2).value = d1
	osheet.Cells(lnRow,3).value = d2
	osheet.Cells(lnRow,4).value = d3
	osheet.Cells(lnRow,5).value = d4
	osheet.Cells(lnRow,6).value = d6
	osheet.Cells(lnRow,7).value = d7
	lnrow = lnrow + 1
ENDSCAN 	


lnRow = lnrow + 5
osheet.Cells(lnrow,1) = "Reimbursement Claim(Return date -> Paid Date)"
lnrow = lnrow+1

oSheet.Cells(lnrow,1).value = "Month"
oSheet.Cells(lnrow,2).value = "<= 2 Days"
oSheet.Cells(lnrow,3).value = "3-10 Days"
oSheet.Cells(lnrow,4).value = "11-15 Days"
oSheet.Cells(lnrow,5).value = "16-20 Days"
oSheet.Cells(lnrow,6).value = "21-25 Days"
oSheet.Cells(lnrow,7).value = "26-30 Days"
oSheet.Cells(lnrow,8).value = ">30 Days"

SELECT curReim3
GO TOP 
lnrow = lnrow+1
SCAN 
	osheet.Cells(lnRow,1).value = months
	osheet.Cells(lnRow,2).value = d1
	osheet.Cells(lnRow,3).value = d2
	osheet.Cells(lnRow,4).value = d3
	osheet.Cells(lnRow,5).value = d4
	osheet.Cells(lnRow,6).value = d6
	osheet.Cells(lnRow,7).value = d7
	lnrow = lnrow + 1
ENDSCAN 	

lnRow = lnrow + 5
osheet.Cells(lnrow,1) = "Reimbursement Claim(Assess date -> Return date)"
lnrow = lnrow+1

oSheet.Cells(lnrow,1).value = "Month"
oSheet.Cells(lnrow,2).value = "<= 2 Days"
oSheet.Cells(lnrow,3).value = "3-10 Days"
oSheet.Cells(lnrow,4).value = "11-15 Days"
oSheet.Cells(lnrow,5).value = "16-20 Days"
oSheet.Cells(lnrow,6).value = "21-25 Days"
oSheet.Cells(lnrow,7).value = "26-30 Days"
oSheet.Cells(lnrow,8).value = ">30 Days"

SELECT curReim4
GO TOP 
lnrow = lnrow+1
SCAN 
	osheet.Cells(lnRow,1).value = months
	osheet.Cells(lnRow,2).value = d1
	osheet.Cells(lnRow,3).value = d2
	osheet.Cells(lnRow,4).value = d3
	osheet.Cells(lnRow,5).value = d4
	osheet.Cells(lnRow,6).value = d6
	osheet.Cells(lnRow,7).value = d7
	lnrow = lnrow + 1
ENDSCAN 	



oWorkBook.Saveas(lcFile)
oExcel.quit