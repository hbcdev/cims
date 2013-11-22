LPARAMETER tcClaimID, tnPrintTo
IF PARAMETER() < 2
	RETURN
ENDIF
#INCLUDE "include\cims.h"
**************************
m.NonCover = ""
IF INLIST(claim.claim_with, "A", "P")
	SELECT Claim.notify_no, Claim.policy_no, Claim.client_name, Claim.plan, Claim.fundcode, ;
	 Claim.effective, Claim.expried, Claim.claim_type, Claim.benf_cover, Claim.deduc_paid, ;
	 Claim.prov_id, Claim.prov_name, Claim.admis_date, Claim.disc_date, Claim.claim_with, ;
	 Claim.hb_act, Claim.hb_app, Claim.hb_note, ;
	 Claim.an_no, Claim.hn_no, Claim.fcharge AS charge, Claim.fbenfpaid AS paid, claim.fdiscount AS discount, Claim.dpaid, ;
	 Claim.fremain AS over, Claim.exgratia, Claim.fnopaid, Claim.fax_audit AS audit_by, Claim.external_note AS snote, Claim.note2ins, ;
	 Claim.claim_id, Claim.fax_by, Claim.customer_id, Claim.claim_date, Claim.fax_date, Claim.timein, Claim.timeout, Claim.docin, Claim.docout  ;
	 FROM  FORCE cims!claim;
	 WHERE Claim.notify_no = tcClaimID;
	 INTO CURSOR faxclaim
	 ****************************************************
	 IF SEEK(tcClaimID, "claim_line_items", "notify_no")
	 	SELECT claim_line_items
		DO WHILE notify_no = tcClaimID AND !EOF()
			IF !EMPTY(fnote)
				m.NonCover = m.NonCover+ALLTRIM(std_code)+" "+ALLTRIM(fnote)+", "
			ENDIF 	
			SKIP 
		ENDDO
	ENDIF 
	m.Noncover = LEFT(ALLTRIM(m.Noncover), LEN(ALLTRIM(m.noncover))-1)
	**************************************************** 
ELSE
	IF !SEEK(tcClaimID, "claim", "notify_no") AND !SEEK(tcClaimID, "claim_line", "notify_no")
		=MESSAGEBOX("ไม่พบ รายการเคลม เลขที่ "+tcClaimID, MB_OK)
		RETURN
	ENDIF	
	SELECT Claim.notify_no, Claim.policy_no, Claim.client_name, Claim.plan, Claim.fundcode, ;
	  Claim.effective, Claim.expried, Claim.claim_type, Claim.benf_cover, Claim.deduc_paid, ;
	  Claim.prov_id, Claim.prov_name, Claim.admis_date, Claim.disc_date, Claim.claim_with, ;
	  Claim.hb_act, Claim.hb_app, Claim.hb_note, ;
	  Claim.an_no, Claim.hn_no, Claim.fcharge AS charge, Claim.fbenfpaid AS paid, claim.fdiscount AS discount, Claim.fremain AS over, ;
	  Claim_line.description, Claim_line.service_type, Claim_line.fadmis, Claim_line.fcharge,Claim_line.fdiscount, Claim_line.nopaid, Claim_line.cat_code, ;
	  Claim_line.exgratia, Claim_line.fpaid, Claim_line.fremain, Claim_line.deduc, Claim_line.dpaid, Claim_line.total_fee, Claim_line.benefit * Claim_line.copayment AS copay, ;
	  Claim.claim_id, Claim.fax_audit, Claim.fax_by, Claim.customer_id, Claim.claim_date, Claim.fax_date, Claim.audit_by, Claim.external_note AS snote, ;
	  Claim.timein, Claim.timeout, Claim.docin, Claim.docout  ;
	 FROM  FORCE cims!claim LEFT JOIN cims!claim_line;
	 	ON Claim.notify_no = Claim_line.notify_no;
	 WHERE Claim.notify_no = tcClaimID;
	 INTO CURSOR faxclaim
	 ****************************************************
	 IF SEEK(tcClaimID, "claim_line", "notify_no")
	 	SELECT claim_line
		DO WHILE notify_no = tcClaimID AND !EOF()
			IF !EMPTY(fnote)
				m.NonCover = m.NonCover+ALLTRIM(fnote)+", "
			ENDIF 	
			SKIP 
		ENDDO
	ENDIF 
	m.Noncover = LEFT(ALLTRIM(m.Noncover), LEN(ALLTRIM(m.noncover))-1)
	**************************************************** 
ENDIF	 
******************* 
LOCAL llClose
IF USED("faxclaim")
	SELECT faxclaim
	GO TOP
	IF EOF()
		=MESSAGEBOX("ไม่พบ ใบสรุปยอดค่าใช้จ่าย เลขที่ "+tcClaimID, MB_OK, TITLE_LOC)
		RETURN
	ENDIF
	****************************
	m.hosp_fax = ""
	m.prov_addr = ""
	 IF !USED("provider")
 		USE cims!provider IN 0
	 	llClose = .T.
	 ENDIF
	 IF SEEK(faxclaim.prov_id, "provider", "prov_id")
	 	m.prov_name = provider.name
	 	m.prov_phone = provider.phone
	 	m.prov_fax = provider.fax
		m.prov_addr = ALLTRIM(Provider.addr_1)+" "+ALLTRIM(Provider.addr_2)+" "+ALLTRIM(Provider.province)+" "+ALLTRIM(Provider.city)+" "+ALLTRIM(Provider.postcode)
	ENDIF
	IF llClose
		USE IN provider
	ENDIF
	******************
	m.fundname = ""
	m.telservice = ""
	IF ! USED("fund")
		USE cims!fund IN 0
	 	llClose = .T.
	ENDIF
	IF SEEK(faxclaim.fundcode, "fund", "fundcode")
		m.fundname = ALLTRIM(fund.thainame)
		m.telservice = ALLTRIM(fund.phone)
	ENDIF
	IF llClose
		USE IN fund
	ENDIF
	IF faxclaim.deduc_paid <> 0
		DO CASE
		CASE tnPrintTo = 1
			REPORT FORM (gcReportPath+"fed_faxclaim") TO PRINTER NOCONSOLE
		CASE tnPrintTo = 2
			REPORT FORM (gcReportPath+"fed_faxclaim") PREVIEW NOCONSOLE
		CASE tnPrintTo = 3
		ENDCASE		
	ELSE
		IF INLIST(faxclaim.claim_with, "A", "P")
			lcReport = gcReportPath+"pa_fax"
		ELSE
			IF faxclaim.copay > 0
				lcReport = gcReportPath+"faxclaim_copayment"
			ELSE 
				IF faxclaim.policy_no = "00/2006-H0000444-NZH"
					lcReport = gcReportPath+"faxclaim80"
				ELSE 	
					lcReport = gcReportPath+"faxclaim"
				ENDIF 	
			ENDIF 	
		ENDIF	 	
		***********************************************************************************************
		SET PRINTER TO DEFAULT		
		DO CASE
		CASE tnPrintTo = 1
			REPORT FORM (lcReport) TO PRINTER NOCONSOLE
		CASE tnPrintTo = 2
			REPORT FORM (lcReport) PREVIEW NOCONSOLE
		CASE tnPrintTo = 3
		CASE tnPrintTo = 4
			SET PRINTER TO NAME  \\dragon-edc\fax
			IF PRINTSTATUS()
				REPORT FORM (lcReport) TO PRINTER NOCONSOLE
			ELSE 
				=MESSAGEBOX("Fax Offline",0,"Error")	
			ENDIF 	
			SET PRINTER TO DEFAULT
		ENDCASE
	ENDIF	
	IF USED("faxclaim")
		USE IN faxclaim
	ENDIF	
ENDIF
****************************