LPARAMETER tnFundID, tdDate, tnTo
LOCAL lnArea
IF PARAMETER() = 0
	WAIT WINDOW "Please enter Parameter Befoe" NOWAIT
	RETURN
ENDIF
****************************
#INCLUDE "include\cims.h"
*

SELECT Notify_log.summit, Notify_log.fund_id, Notify_log.customer_id,;
  Notify_log.policy_no, Notify_log.claim_no, Notify_log.page,;
  Notify_log.notify_no, Notify_log.status, Notify_log.l_user, Notify_log.l_update,;
  ALLTRIM(Member.name)+" "+ ALLTRIM(Member.surname) AS name,;
  Member.product, Member.effective, Member.expiry;
 FROM  cims!Member INNER JOIN cims!notify_log ;
   ON  Member.tpacode + Member.customer_id = Notify_log.customer_id;
 WHERE Notify_log.fund_id = tnFundID AND;
  Notify_log.summit = tdDate AND;
  Notify_log.l_user = gcUserName;
 ORDER BY Notify_log.summit;
 INTO CURSOR log
 ***********
 lnArea = SELECT()
 IF USED("log")
	IF EOF("log")
		=MESSAGEBOX("ไม่พบ รายการเคลมปกติ ที่รับเข้าในวันที่ : "+DTOC(tdDate), MB_OK, TITLE_LOC)
		RETURN
	ENDIF
	SELECT log
	DO CASE
	CASE tnTo = 1
		IF PRINTSTATUS()
			REPORT FORM report\Notify_receive NOCONSOLE TO PRINT
		ENDIF	
	CASE tnTo = 2
		REPORT FORM report\Notify_receive PREVIEW NOCONSOLE
	CASE tnTo = 3
		lcPath = INPUTBOX("Save To")
		DO progs\trans2Excel WITH ALIAS(), lcPath	
	ENDCASE	
	USE IN log
ELSE
	=MESSAGEBOX("ไม่พบ รายการเคลมปกติ ที่รับเข้าในวันที่ : "+DTOC(tdDate), MB_OK, TITLE_LOC)
ENDIF
SELECT (lnArea)