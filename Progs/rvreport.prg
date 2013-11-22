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
lcFundCode = LEFT(lcRetVal,3)
lcPrintTo = RIGHT(lcRetVal,1)
lcStart = CTOD(SUBSTR(lcRetVal,4,10))
lcEnd = CTOD(SUBSTR(lcRetVal,14,10))
*************************	
SELECT rv.rv_no, rv.rv_date, rv.policy_no, rv.client_name, rv_lines.admit,;
  rv_lines.prov_name, rv_lines.amount, rv.paid_type, rv.send_to,;
  rv.send_by, rv.notes, rv_lines.notify_no, rv_cheque.chq_no,;
  rv_cheque.chq_date, rv.paid_to, rv_lines.remarks;
 FROM  cims!rv LEFT OUTER JOIN cims!rv_lines;
    LEFT OUTER JOIN cims!rv_Cheque ;
   ON  rv_lines.rv_no = rv_cheque.rv_no ;
   ON  rv.rv_no = rv_lines.rv_no;
 WHERE LEFT(rv.customer_id,3) = lcFundCode AND ;
	 	rv.rv_date >= lcStart AND rv_date <= lcEnd;
 INTO CURSOR rvreport
IF _TALLY > 0
	SELECT rvreport
	DO CASE
	CASE lcPrintTo = "1"
		REPORT FORM (gcReportPath+"rvreport") TO PRINTER PROMPT PREVIEW NOCONSOLE
	CASE lcPrintTo = "2"
		REPORT FORM (gcReportPath+"rvreport") TO PRINTER PROMPT NOCONSOLE
	CASE lcPrintTo = "3"
		lcFileName = "rv_"+STRTRAN(SUBSTR(lcRetVal,4,10)+"_"+SUBSTR(lcRetVal,14,10), "/", "")
		EXPORT TO PUTFILE("Save To File Name:", lcFileName, "XLS") TYPE XL5
	ENDCASE
ELSE
	=MESSAGEBOX("ไม่พบ ใบสำคัญรับ เลขที่ "+lcStart+" ถึง " +lcEnd, MB_OK, "Error")
ENDIF