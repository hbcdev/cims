#INCLUDE "include\cims.h"
LOCAL lcFundCode,;
	lcStart,;
	lcEnd,;
	lcPrintto,;
	lcRetVal

	
lcRetVal = oApp.DoFormRetVal("dateentry")
IF EMPTY(lcRetVal)
	RETURN
ENDIF
**
lcFundCode = LEFT(lcRetVal,3)
lcPrintTo = RIGHT(lcRetVal,1)
lcStart = CTOD(SUBSTR(lcRetVal,4,10))
lcEnd = CTOD(SUBSTR(lcRetVal,14,10))
*************************
SELECT pv.policy_no, pv_notify.notify_no, pv_date, ;
	ALLTRIM(pv.chqno)+IIF(EMPTY(pv.chqno1), "", ", "+pv.chqno1)+IIF(EMPTY(pv.chqno2), "", ", "+pv.chqno2)+IIF(EMPTY(pv.chqno3), "", ", "+pv.chqno3)+IIF(EMPTY(pv.chqno4), "", ", "+pv.chqno4) AS chqno, ;
	pv.pv_no, pv.client_name, pv.paid_to, IIF(pv_notify.claim_type = 1, pv_notify.amount, 0) AS opd_paid, ;
	IIF(pv_notify.claim_type # 1, pv_notify.amount, 0) AS ipd_paid, pv_notify.amount, ;
	pv.chqdate, Pv.tr_acno, Pv.tr_accname, Pv.tr_bank, Pv.tr_branch, Pv.tr_date, ;
	Pv_notify.remarks ;
 FROM  cims!pv LEFT OUTER JOIN cims!pv_notify ;
   ON  Pv.pv_no = Pv_notify.pv_no ;
 WHERE pv.fundcode = lcFundCode ;
 	AND pv.pv_date BETWEEN lcStart AND lcEnd ;
 INTO CURSOR Pvreport
IF _TALLY > 0
	SELECT pvreport
	DO CASE
	CASE lcPrintTo = "1"
		REPORT FORM (gcReportPath+"pvreport") TO PRINTER PROMPT NOCONSOLE
	CASE lcPrintTo = "2"
		REPORT FORM (gcReportPath+"pvreport") TO PRINTER PROMPT PREVIEW NOCONSOLE
	CASE lcPrintTo = "3"
		lcFileName = "PV_Report_"+STRTRAN(SUBSTR(lcRetVal,4,10)+"_"+SUBSTR(lcRetVal,14,10), "/", "")
		EXPORT TO PUTFILE("Save To File Name:", lcFileName, "XLS") TYPE XL5
		*********
		IF MESSAGEBOX("ต้องการให้พิมพ์สรุปรายการโอนเข้าบัญชื กด Yes",4+32+256, "Print") = IDYES
			lcFileName = "PV_Transfer_"+STRTRAN(SUBSTR(lcRetVal,4,10)+"_"+SUBSTR(lcRetVal,14,10), "/", "")
			EXPORT TO PUTFILE("Save To File Name:", lcFileName, "XLS") TYPE XL5 ;
				FIELDS pv_no, pv_date, notify_no, policy_no, client_name, chqno, chqdate, amount, tax, paid, ;
					tr_date, tr_acno, tr_accname, tr_bank, tr_branch, paid_to
		ENDIF 			
	ENDCASE
ELSE
	=MESSAGEBOX("ไม่พบ Payment Vouncher เลขที่ "+lcStart+" ถึง " +lcEnd, MB_OK, "Error")
ENDIF