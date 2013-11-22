LPARAMETER tcProvID, tdDate, tnTo, tcUser
LOCAL lnArea
IF PARAMETER() = 0
	WAIT WINDOW "Please enter Parameter Befoe" NOWAIT
	RETURN
ENDIF
****************************
#INCLUDE "include\cims.h"
lnArea = SELECT()
*
SELECT Claim.notify_no, Claim.refno, Claim.fundcode, Claim.policy_no,;
	Claim.ref_date, Claim.status, Claim.inv_page, Claim.l_user, Claim.l_update,;
	Claim.prov_id, Claim.Prov_name, Claim.client_name, Claim.plan, Claim.effective, Claim.expried;
FROM  cims!Claim;
ORDER BY prov_id;
WHERE  Claim.prov_id = tcProvID;
	AND TTOD(Claim.ref_date) = tdDate;
	AND Claim.inv_user = tcUser;
INTO CURSOR rLog
IF _TALLY > 0
	DO CASE
	CASE tnTo = 1
		REPORT FORM (gcReportPath+"invoice_receive") NOCONSOLE TO PRINTER PROMPT 
	CASE tnTo = 2
		REPORT FORM (gcReportPath+"invoice_receive")  PREVIEW NOCONSOLE
	ENDCASE	
ELSE
	=MESSAGEBOX("ไม่พบ รายการรับวางบิล ที่รับเข้าในวันที่ : "+DTOC(tdDate), MB_OK, TITLE_LOC)
ENDIF
USE IN rlog
SELECT (lnArea)