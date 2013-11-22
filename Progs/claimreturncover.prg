#INCLUDE "INCLUDE\cims.h"
PUBLIC gcFundCode, gdStartDate, gdEndDate, ;
	gnOption, gcSaveTo

STORE DATE() TO gdStartDate, gdEndDate
gcFundCode = ""
gnOption = 2
gcSaveTo = ADDBS(gcTemp)
gcResult = "P1"

m.lotno = ""
m.batchno = ""

DO FORM form\dialyReportOption
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	=MESSAGEBOX("กรุณาเลือก บริษัทประกันภัยที่ต้องการให้จัดทำรายงานประจำวันด้วย ", MB_OK,"Dialy Report")
	RETURN
ENDIF	
*
SET REPORTBEHAVIOR 90
*
IF LEN(ALLTRIM(gcResult)) = 2
	SELECT fund.thainame AS fundname, claim.prov_name, claim.policy_no, claim.notify_no, claim.notify_date, claim.client_name, claim.service_type, ;
		claim.admis_date, claim.disc_date, claim.scharge, claim.sdiscount, claim.snopaid, claim.sbenfpaid, claim.snote, ;
		claim.indication_admit, claim.result, claim.diag_plan, claim.tr_acno, claim.tr_name, claim.paid_date, ;
		claim.lotno, claim.batchno, claim.insurepaydate ;
	FROM cims!claim LEFT JOIN cims!fund ;
		ON claim.fundcode = fund.fundcode ;
	WHERE claim.fundcode= gcFundCode AND claim.return_date Between gdStartDate AND gdEndDate AND claim.result= gcResult ;
	ORDER BY claim.return_date ;
	INTO CURSOR curCredit	
	*
	IF _TALLY = 0
		=MESSAGEBOX("ไม่พบข้อมูลเคลมสำหรับส่งกลับในช่วงวันที่ "+DTOC(gdStartDate)+ " ถึง วันที่ " +DTOC(gdEndDate)), 0, "คำเตือน")		
	ELSE 	
		DO CASE 
		CASE gnOption = 1
			REPORT FORM (ADDBS(gcReportPath)+"Claim_Reim_Return") TO PRINTER PROMPT 
		CASE gnOption = 2
			REPORT FORM (ADDBS(gcReportPath)+"Claim_Reim_Return") PREVIEW 
		CASE gnOption = 3
		ENDCASE 
	ENDIF 	
ELSE 
	IF RIGHT(ALLTRIM(gcResult), 1) = "1"
		SELECT fund.thainame AS fundname, claim.prov_name, claim.policy_no, claim.notify_no, claim.notify_date, claim.client_name, claim.service_type, ;
			claim.admis_date, claim.disc_date, claim.scharge, claim.sdiscount, claim.snopaid, claim.sbenfpaid, claim.snote, ;
			claim.indication_admit, claim.result, claim.diag_plan, claim.tr_acno, claim.tr_name, claim.paid_date, ;
			claim.lotno, claim.batchno, claim.insurepaydate ;		
		FROM cims!claim LEFT JOIN cims!fund ;
			ON claim.fundcode = fund.fundcode ;
		WHERE claim.fundcode= gcFundCode AND claim.return_date Between gdStartDate AND gdEndDate AND claim.result= gcResult ;
		ORDER BY claim.paid_date ;
		INTO CURSOR curCredit	
		*
		IF _TALLY = 0
			=MESSAGEBOX("ไม่พบข้อมูลเคลมสำหรับส่งกลับในช่วงวันที่ "+DTOC(gdStartDate)+ " ถึง วันที่ " +DTOC(gdEndDate)), 0, "คำเตือน")		
		ELSE 		
			DO CASE 
			CASE gnOption = 1
				REPORT FORM (ADDBS(gcReportPath)+"Claim_Reimb_Return") TO PRINTER PROMPT 
			CASE gnOption = 2
				REPORT FORM (ADDBS(gcReportPath)+"Claim_Reimb_Return") PREVIEW
			CASE gnOption = 3
			ENDCASE 
		ENDIF 	
	ELSE 	
		SELECT fund.thainame AS fundname, claim.prov_name, claim.policy_no, claim.notify_no, claim.notify_date, claim.client_name, claim.service_type, ;
			claim.admis_date, claim.disc_date, claim.scharge, claim.sdiscount, claim.snopaid, claim.sbenfpaid, claim.snote, ;
			claim.indication_admit, claim.result, claim.diag_plan, claim.tr_acno, claim.tr_name, claim.paid_date, ;
			claim.lotno, claim.batchno, claim.insurepaydate ;		
		FROM cims!claim LEFT JOIN cims!fund ;
			ON claim.fundcode = fund.fundcode ;
		WHERE claim.fundcode= gcFundCode AND claim.return_date Between gdStartDate AND gdEndDate AND claim.result= gcResult ;
		ORDER BY claim.prov_name ;
		INTO CURSOR curCredit	
		*
		IF _TALLY = 0
			=MESSAGEBOX("ไม่พบข้อมูลเคลมสำหรับส่งกลับในช่วงวันที่ "+DTOC(gdStartDate)+ " ถึง วันที่ " +DTOC(gdEndDate)), 0, "คำเตือน")		
		ELSE 		
			DO CASE 
			CASE gnOption = 1
				REPORT FORM (ADDBS(gcReportPath)+"Claim_Credit_Return") TO PRINTER PROMPT 
			CASE gnOption = 2
				REPORT FORM (ADDBS(gcReportPath)+"Claim_Credit_Return") PREVIEW
			CASE gnOption = 3
			ENDCASE 
		ENDIF 	
	ENDIF 	
ENDIF 
SET REPORTBEHAVIOR 80