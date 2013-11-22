LPARAMETER tcClaimID
IF PARAMETER() = 0
	RETURN
ENDIF
#INCLUDE "INCLUDE\CIMS.H"
LOCAL lnPrintTo,;
	llClose,;
	lnArea
lnArea = SELECT()	
**	
m.NonCover = ""
IF INLIST(claim.claim_with, "A", "P")
	SELECT Claim.notify_no, Claim.fundcode, Claim.policy_no, Claim.client_name, Claim.plan, Claim.refno AS inv_no, ;
	 IIF(Claim.fundcode = "CIG", Claim.policy_date, Claim.effective) AS effective, Claim.inv_page, ;
	 Claim.expried, Claim.claim_type, Claim.benf_cover, Claim.benf_cover AS benefit, Claim.deduc_paid, Claim.illness1, Claim.illness2, Claim.illness3, ;
	 Claim.prov_id, Claim.prov_name, Claim.admis_date, Claim.disc_date, Claim.claim_with, Claim.snote, Claim.note2ins, ;
	 Claim.hb_act, Claim.hb_app, Claim.hb_note, Claim.tr_acno, Claim.tr_name, Claim.tr_bank, ;
	 Claim.an_no, Claim.hn_no, Claim.scharge, Claim.sbenfpaid, Claim.sdiscount, Claim.snopaid, Claim.exgratia, Claim.abenfpaid, ;
	 Claim.sremain, Claim.claim_id, Claim.assessor_by, Claim.Audit_by, Claim.dpaid, ;
	 Claim.customer_id, Claim.claim_date, Claim.assessor_date, Claim.Audit_date ;
	 FROM  FORCE cims!claim ;
	 WHERE Claim.notify_no = tcClaimID ;
	 INTO CURSOR faxclaim
	 ****************************************************
	 IF SEEK(tcClaimID, "claim_line_items", "notify_no")
	 	SELECT claim_line_items
		DO WHILE notify_no = tcClaimID AND !EOF()
			IF !EMPTY(snote)
				m.NonCover = m.NonCover+ALLTRIM(std_code)+" "+ALLTRIM(snote)+", "
			ENDIF 	
			SKIP 
		ENDDO
	 ENDIF 
	 **************************************************** 
ELSE
	SELECT Claim.notify_no, Claim.fundcode, Claim.policy_no, Claim.client_name, Claim.plan, Claim.refno AS inv_no, Claim.policy_date, ;
	  IIF(Claim.fundcode = "CIG", Claim.policy_date, Claim.effective) AS effective,  Claim.inv_page, ;	
	  Claim.expried, Claim.prov_id, Claim.prov_name, Claim.admis_date, Claim.disc_date, Claim.claim_with, ;
	  Claim.hb_act, Claim.hb_app, Claim.hb_note, Claim.tr_acno, Claim.tr_name, Claim.tr_bank, ;
	  Claim.an_no, Claim.hn_no, Claim.illness1, Claim.illness2, Claim.illness3, Claim_line.cat_code, Claim_line.description, Claim_line.benf_cover, ;
	  Claim_line.benefit, Claim_line.service_type, Claim_line.sadmis, Claim_line.scharge, Claim_line.sdiscount, Claim_line.snoncover, ;
	  Claim_line.benefit * Claim_line.copayment AS copay, ;
	  Claim_line.apaid, Claim_line.spaid, Claim_line.sremain, Claim_line.total_fee, Claim.claim_id, Claim_line.dpaid, Claim_line.deduc, ;
	  Claim.assessor_by, Claim.Audit_by, Claim.assessor_date, Claim.Audit_date, ;	   
	  Claim.customer_id, Claim.claim_date, Claim.snote, Claim.note2ins, Claim.result, Claim.abenfpaid ;
	 FROM  cims!claim INNER JOIN cims!claim_line ;
	   ON  Claim.notify_no = Claim_line.notify_no ;
	 WHERE Claim.notify_no = tcClaimID ;
	 INTO CURSOR faxclaim
	 ****************************************************
	 IF SEEK(tcClaimID, "claim_line", "notify_no")
	 	SELECT claim_line
		DO WHILE notify_no = tcClaimID AND !EOF()
			IF !EMPTY(snote)
				m.NonCover = m.NonCover+" "+ALLTRIM(snote)+", "
			ENDIF 	
			SKIP 
		ENDDO
	 ENDIF 
	 **************************************************** 
ENDIF 
SELECT faxclaim
GO TOP 
IF RECCOUNT() = 0
	=MESSAGEBOX("‰¡Ëæ∫ „∫ √ÿª¬Õ¥§Ë“„™È®Ë“¬ ‡≈¢∑’Ë "+tcClaimID, MB_OK, TITLE_LOC)
ELSE	
	m.prov_addr = ""
	m.prov_phone = ""
	m.prov_fax = ""
	m.Prov_acc = ""
 	m.prov_pay = ""
 	m.prov_acno = ""
 	m.prov_acc = ""
 	m.prov_bank = ""
	m.prov_addr = ""	
	IF !USED("provider")
		USE cims!provider IN 0
	 	llClose = .T.
	ENDIF	
	 IF SEEK(faxclaim.prov_id, "provider", "prov_id")
	 	m.prov_name = provider.name
	 	m.prov_phone = provider.phone
	 	m.prov_fax = provider.fax
	 	m.prov_pay = provider.payment
	 	m.prov_acno = provider.account_no
	 	m.prov_acc = ALLTRIM(provider.acc_name)
	 	m.prov_bank = provider.bank
		m.prov_addr = ALLTRIM(Provider.addr_1)+" "+ALLTRIM(Provider.addr_2)+" "+ALLTRIM(Provider.province)+" "+ALLTRIM(Provider.city)+" "+ALLTRIM(Provider.postcode)
	ENDIF
	IF llClose
		USE IN provider
	ENDIF
	IF faxclaim.inv_page <> 2
	 	m.prov_acno = faxclaim.tr_acno
	 	m.prov_acc = ALLTRIM(faxclaim.tr_name)	
	 	m.prov_bank = faxclaim.tr_bank
	ENDIF 	
	******************
	m.icd10 = ""
	m.icd102 = ""
	m.icd103 = ""
	IF !USED("icd10")
		USE cims!icd10 IN 0
	 	llClose = .T.
	ENDIF		
	IF SEEK(faxclaim.illness1, "icd10", "code")
		m.icd10 = ALLTRIM(icd10.description)
	ENDIF
	IF !EMPTY(faxclaim.illness2)
		IF SEEK(faxclaim.illness2, "icd10", "code")
			m.icd102 = ALLTRIM(icd10.description)
		ENDIF
	ENDIF 	
	IF !EMPTY(faxclaim.illness3)
		IF SEEK(faxclaim.illness3, "icd10", "code")
			m.icd103 = ALLTRIM(icd10.description)
		ENDIF 	
	ENDIF
	IF llClose
		USE IN icd10
	ENDIF
	******************* 
	m.fundname = ""
	IF ! USED("fund")
		USE cims!fund IN 0
	 	llClose = .T.
	ENDIF
	IF SEEK(faxclaim.fundcode, "fund", "fundcode")
		m.fundname = fund.thainame
		m.telservice = ALLTRIM(fund.phone)
	ENDIF
	IF llClose
		USE IN fund
	ENDIF
	lnPrintTo = oApp.DoFormRetVal("printto")
	IF INLIST(faxclaim.claim_with, "A", "P")
		lcReport = gcReportPath+"pa_assess"
	ELSE
		IF faxclaim.result = "AI"
			lcReport = gcReportPath+"assessclaim2"
		ELSE 	
			IF faxclaim.copay > 0
				lcReport = gcReportPath+"assessclaim_copayment"
			ELSE 	
				lcReport = gcReportPath+"assessclaim"
			ENDIF 	
		ENDIF 		
	ENDIF	 
	SET PRINTER TO DEFAULT
	DO CASE
	CASE lnPrintTo = 1
		REPORT FORM (lcReport) TO PRINTER NOCONSOLE
	CASE lnPrintTo = 2
		REPORT FORM (lcReport) PREVIEW NOCONSOLE
	CASE lnPrintTo = 3
	CASE tnPrintTo = 4
		m.hosp_fax = ""
		SET PRINTER TO NAME \\dragon-edc\fax
		REPORT FORM (lcReport) TO PRINTER NOCONSOLE
		SET PRINTER TO DEFAULT		
	ENDCASE
ENDIF
IF USED("faxclaim")
	USE IN faxclaim
ENDIF	
SELECT (lnArea)