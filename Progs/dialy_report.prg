PARAMETER tcFundCode, tdStart, tdEnd, tnOutPut
IF PARAMETER() = 0
	RETURN
ENDIF
***************************	
#INCLUDE "INCLUDE\cims.h"
PUBLIC gcFundcode,;
	gdStartDate,;
	gdEndDate,;
	gnTotalPrecert,;
	gnTotalFaxclaim,;
	gnTotalReturn,;
	gnTotalDenied
*	 
IF EMPTY(tcFundCode)
	=MESSAGEBOX("กรุณาเลือก บริษัทประกันภัยที่ต้องการให้จัดทำรายงานประจำวันด้วย ", MB_OK,"Dialy Report")
	RETURN
ENDIF	
gcFundCode = tcFundCode
gdStart = IIF(EMPTY(tdStart), DATE(), tdStart)
gdEnd = IIF(EMPTY(tdEnd), DATE(), tdEnd)
gtStart = DATETIME(YEAR(gdStart), MONTH(gdStart), DAY(gdStart), 00, 00, 00)
gtEnd = DATETIME(YEAR(gdEnd), MONTH(gdEnd), DAY(gdEnd), 23, 59, 00)
**************************************************************************************************
IF tnOutput = 3
	oExcel = CREATEOBJECT("Excel.Application")
	oWorkBook = oExcel.Workbooks.ADD()
	lnSheet = 1
ENDIF 

*
DIMENSION laComment[7,1]
laComment[1] = "Patient benefit for admission"
laComment[2] = "Policy expired"
laComment[3] = "Non health rider"
laComment[4] = "Exclusion"
laComment[5] = "Reimbursement"
laComment[6] = "Unnessessary admit."
laComment[7] = "Other"
*********************************
SET SAFE OFF
SET TALK ON
*************
* Precert Report
SELECT Notify.notify_no, Notify.notify_date,;
  Notify.service_type AS type, Notify.policy_no, Notify.policy_name,;
  Notify.client_name, Notify.plan, Notify.effective, Notify.expried,;
  Notify.prov_name, Notify.admis_date, Notify.basic_diag, ;
  IIF(Notify.comment = 0, "", laComment[Notify.comment]) AS comment,;
  Notify.note2ins, Notify.status, Notify.illness;
 FROM  cims!Notify;
 WHERE Notify.fundcode = gcfundcode;
   AND Notify.notify_date BETWEEN gtstart AND gtend;
 INTO CURSOR Precert_dai
gnTotalPrecert = _TALLY
 IF gnTotalPrecert > 0
 	DO CASE 
 	CASE tnOutPut = 1
		REPORT FORM (gcReportPath+"daily_precert.frx") TO PRINTER PROMPT NOCONSOLE
 	CASE tnOutPut = 2
		REPORT FORM (gcReportPath+"daily_precert.frx") PREVIEW NOCONSOLE
 	CASE tnOutPut = 3
	ENDCASE  
ENDIF	
******************
IF MESSAGEBOX("พิมพ์ ใบสรุป Fax Claim", MB_YESNO, TITLE_LOC) = IDYES
	*Faxclaim
	SELECT Claim.notify_no, Claim.notify_date, Claim.claim_type, Claim.service_type,;
	  Claim.policy_no, Claim.policy_holder, Claim.plan, Claim.client_name,;
	  Claim.prov_name, Claim.admis_date, Claim.disc_date, Claim.illness1,;
	  Claim.illness2, Claim.illness3, Claim.fcharge, Claim.fdiscount,;
	  Claim.fbenfpaid, Claim.fremain AS overpaid, Claim.exgratia, Claim.result,;
	  Claim.snote, Claim.note2ins;
	 FROM  cims!claim ;
	 WHERE Claim.fundcode = gcfundcode;
	   AND Claim.fax_date BETWEEN gtstart AND gtend;
	   AND Claim.fcharge <> 0;
	 INTO CURSOR Faxclaim_da
	gnTotalFaxclaim = _TALLY
	IF gnTotalFaxclaim > 0 
	 	DO CASE 
 		CASE tnOutPut = 1
			REPORT FORM (gcReportPath+"daily_faxclaim") TO PRINTER PROMPT NOCONSOLE
 		CASE tnOutPut = 2
			REPORT FORM (gcReportPath+"daily_faxclaim") PREVIEW NOCONSOLE
	 	CASE tnOutPut = 3
		ENDCASE  
	ENDIF
ENDIF 	
***********************	
IF MESSAGEBOX("พิมพ์ ใบสรุป Return Claim", MB_YESNO, TITLE_LOC) = IDYES
	*Return Claim
	SELECT Claim.notify_no, Claim.claim_no, Claim.policy_no, Claim.service_type,;
	  Claim.admis_date, Claim.policy_holder, Claim.client_name, Claim.illness1,;
	  Claim.sbenfpaid, Notify_log.page, Claim.return_date, Claim.claim_type,;
	  Claim.result, Claim.doc_date, Claim.plan, Claim.prov_name, Claim.disc_date,;
	  Claim.illness2, Claim.scharge, Claim.sremain, Claim.exgratia, Claim.snote,;
	  Claim.notify_date, Claim.note2ins;
	 FROM  cims!claim RIGHT OUTER JOIN cims!notify_log ;
	   ON  Claim.notify_no = Notify_log.notify_no;
	 WHERE Notify_log.fundcode = gcfundcode;
	   AND Claim.return_date BETWEEN gdstart AND gdend;
	   AND Claim.return_date <= gdend;
	 ORDER BY Claim.result, Claim.notify_no;
	 INTO CURSOR Returnclaim
	gnTotalReturn = _TALLY
	 IF gnTotalReturn > 0
	 	DO CASE 
 		CASE tnOutPut = 1
			REPORT FORM (gcReportPath+"daily_returnclaim") TO PRINTER PROMPT NOCONSOLE
 		CASE tnOutPut = 2
			REPORT FORM (gcReportPath+"daily_returnclaim") PREVIEW NOCONSOLE
	 	CASE tnOutPut = 3
		ENDCASE  
	ENDIF	
ENDIF 	
**************************
IF MESSAGEBOX("พิมพ์ ใบสรุป Denied Claim", MB_YESNO, TITLE_LOC) = IDYES
	*Denied Claim
	SELECT Claim.notify_no, Claim.notify_date, Claim.claim_no,;
	  Claim.policy_no, Claim.admis_date, Claim.policy_holder, Claim.service_type,;
	  Claim.client_name, Claim.illness1, Claim.sbenfpaid, Notify_log.page,;
	  Claim.return_date, Claim.claim_type, Claim.result, Claim.plan,;
	  Claim.effective, Claim.expried, Claim.doc_date, Claim.prov_name,;
	  Claim.disc_date, Claim.illness2, Claim.scharge, Claim.sremain, Claim.snote,;
	  Claim.exgratia, Claim.note2ins;
	 FROM  cims!claim RIGHT OUTER JOIN cims!notify_log ;
	   ON  Claim.notify_no = Notify_log.notify_no;
	 WHERE Notify_log.fundcode = gcfundcode;
	   AND Notify_log.summit >= gdstart;
	   AND Notify_log.summit <= gdend;
	   AND LEFT(Claim.result,1) = "D";
	 ORDER BY Claim.result, Claim.notify_no;
	 INTO CURSOR Daily_denie
	 gnTotalDenied = _TALLY
	 IF gnTotalDenied > 0
	 	DO CASE 
 		CASE tnOutPut = 1
			REPORT FORM (gcReportPath+"daily_deniedclaim") TO PRINTER PROMPT NOCONSOLE
 		CASE tnOutPut = 2
			REPORT FORM (gcReportPath+"daily_deniedclaim") PREVIEW NOCONSOLE
	 	CASE tnOutPut = 3
		ENDCASE  
	ENDIF	
ENDIF 	
REPORT FORM (gcReportPath+"dialy_summary.frx") PREVIEW NOCONSOLE
SET TALK OFF


PROCEDURE GenXLS
PARAMETERS tcAlias, tcSheetName


oSheet = oWorkBook.WorkSheets(lnSheet)
oSheet.Name = tcSheetName




SELECT tcAlias



