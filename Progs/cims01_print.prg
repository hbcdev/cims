LPARAMETER tcNotifyNo
IF PARAMETER() = 0
	RETURN
ENDIF
****************************
#INCLUDE "include\cims.h"
LOCAL laTreatre[2],;
	laService[8],;
	laComment[8]
***
laTreatre[1] = "Illness"
laTreatre[2] = "Accident"
********************************
laService[1] = "OPD"
laService[2] = "IPD"
laService[3] = "Emergency"
laService[4] = "Minor Surgery"
laService[5] = "OPD FollowUp"
laService[6] = "Maternity"
laService[7] = "Referral"
laService[8] = "High Cost"

m.hosp_fax = ""
********************************
laComment[1] = "Patient benefit for admission"
laComment[2] = "Policy expired"
laComment[3] = "Non health rider"
laComment[4] = "Exclusion"
laComment[5] = "Reimbursement"
laComment[6] = "Unnessessary admit."
laComment[7] = "Other"
laComment[8] = "Denied Claim"
******************************
SELECT Notify.notify_no, Notify.notify_date, Notify.service_type, Notify.cause_type, ;
  Notify.notify_type, Notify.treatment_type, Notify.policy_no, Notify.customer_id, Notify.fund_id, ;
  Notify.client_name, Notify.plan, Notify.effective, Notify.expried, Notify.policy_date, ;
  Notify.prov_id, Notify.prov_name, ;
  Notify.hn_no, Notify.an_no, Notify.admis_date, Notify.acc_date AS prov_sender, Notify.illness, ;
  Notify.basic_diag, Notify.treatre_plan, Notify.comment, Notify.notify_notes, ;
  Notify.note2ins, Notify.record_by, Notify.record_date, ;
  ALLTRIM(Provider.addr_1)+" "+ALLTRIM(Provider.addr_2)+" "+ALLTRIM(Provider.province)+" "+ALLTRIM(Provider.city)+" "+ALLTRIM(Provider.postcode) AS prov_addr;
 FROM FORCE cims!Notify INNER JOIN cims!provider;
 	ON Notify.prov_id = Provider.prov_id;
 WHERE Notify.notify_no = tcNotifyNO;
 INTO CURSOR percert
 IF USED("percert")
	 SELECT percert
	 IF EOF()
		=MESSAGEBOX("‰¡Ëæ∫ „∫√—∫·®Èß ‡≈¢∑’Ë "+tcNotifyNO, MB_OK, TITLE_LOC)	
		RETURN
	ENDIF	 
	 m.type = IIF(SEEK(service_type, "service_type", "shortname"), service_type.service_desc, "")
	 m.treatment = IIF(INLIST(treatment_type, 1, 2) , laTreatre[treatment_type], "")
	 m.comment = IIF(comment <> 0, laComment[comment], "")
	 m.record_by = RETUSERNAME(record_by)
	 ********************************
	m.fundname = ""
	IF USED("fund")
		IF SEEK(percert.fund_id, "fund", "fund_id")
			m.fundname = fund.thainame
		ENDIF
	ENDIF
	lnPrintTo = oApp.DoFormRetVal("printto")
	SELECT percert
	GO TOP
	**************************************
	SET PRINTER TO DEFAULT
	DO CASE
	CASE lnPrintTo = 1
		REPORT FORM (gcReportPath+"notify") TO PRINTER NOCONSOLE
	CASE lnPrintTo = 2
		REPORT FORM (gcReportPath+"notify") PREVIEW NOCONSOLE
	CASE lnPrintTo = 3
	CASE lnPrintTo = 4
		*m.hosp_fax = INPUTBOX("Hospital Fax Number")		
		SET PRINTER TO NAME \\dragon-edc\fax
		REPORT FORM (gcReportPath+"notify") TO PRINTER NOCONSOLE	
	ENDCASE		
	USE IN percert
ELSE
	=MESSAGEBOX("‰¡Ëæ∫ „∫√—∫·®Èß ‡≈¢∑’Ë "+tcNotifyNO, MB_OK, TITLE_LOC)	
ENDIF