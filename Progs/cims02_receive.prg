LPARAMETER tdDate, tnTo
LOCAL lnArea
IF PARAMETER() = 0
	WAIT WINDOW "Please enter Parameter Befoe" NOWAIT
	RETURN
ENDIF
****************************
#INCLUDE "include\cims.h"
*
SELECT Claim.notify_no, Claim.refno, Claim.ref_date, Claim.status, Claim.l_user, Claim.l_update,;
	 ALLTRIM(Member.name)+" "+ ALLTRIM(Member.surname) AS name,;
	 Member.product, Member.effective, Member.expiry;
FROM  cims!Member INNER JOIN cims!Claim;
   ON  Member.tpacode + Member.customer_id = Claim.customer_id;
WHERE Claim.ref_date = tdDate AND EMPTY(doc_date);
INTO CURSOR rLog
***********
 lnArea = SELECT()
 IF USED("rlog")
	SELECT rlog
	IF EOF()
		=MESSAGEBOX("ไม่พบ รายการรับวางบิล ที่รับเข้าในวันที่ : "+DTOC(tdDate), MB_OK, TITLE_LOC)
		RETURN
	ENDIF
	DO CASE
	CASE tnTo = 1
		REPORT FORM report\invoice_receive NOCONSOLE TO PRINT
	CASE tnTo = 2
		REPORT FORM report\invoice_receive PREVIEW NOCONSOLE
	ENDCASE	
	USE IN rlog
ELSE
	=MESSAGEBOX("ไม่พบ รายการรับวางบิล ที่รับเข้าในวันที่ : "+DTOC(tdDate), MB_OK, TITLE_LOC)
ENDIF
SELECT (lnArea)