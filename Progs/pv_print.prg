LPARAMETER tcFundcode, tcPvNo
IF PARAMETER() = 0
	RETURN
ENDIF	
#INCLUDE include\cims.h
LOCAL lnRetVal,;
	cClaimID,;
	aTo[4,1],;
	aBY[3,1],;
	aPaidType[7,1],;
	lcRetVal,;
	lnOpt,;
	lnArea,;
	lnType,;
	lnPrintTo,;
	lcCustType

lnArea = SELECT()
lnPrintTo = 0
aTo[1] = "Health Fund"
aTo[3] = "Client"
aTo[2] = "Agent"
aTo[4] = "Hospital"
***************
aBy[1] = "Hand"
aBy[2] = "Mail"
aBy[3] = "Other"
**********************************
aPaidType[1] = "Crossed Cheque"
aPaidType[2] = "Draft"
aPaidType[3] = "Cash"
aPaidType[4] = "Direct Debit"
aPaidType[5] = "A/C Payee Only"
aPaidType[6] = "Cash Cheque"
aPaidType[7] = "Direct Credit"
**********************************
lnPrintTo = oApp.DoformRetVal("printTo")
IF lnPrintto <> 0
	lnPrintTo = 2
ENDIF
***************	
SELECT Pv.fundcode, Pv.pv_no, Pv.pv_date, Pv.policy_no, Pv.client_name,IIF(Pv.wt = 0, 0, Pv.total*(Pv.wt/100)) AS wt,;
  Pv.paid_to, Pv.paid_type, Pv.send_to, Pv.send_by, Pv.notes, Pv.prepared_by, Pv.virified_by, Pv.approved_by, Pv.total,;
  Pv_notify.notify_no, Pv_notify.name, Pv_notify.amount AS benfpaid,  Pv_notify.remarks,;
  Pv_notify.admit, Pv_notify.prov_name, Pv_notify.claim_id,Pv_notify.year_visit;
FROM FORCE cims!Pv LEFT JOIN cims!pv_notify;
   ON  Pv.pv_no = Pv_notify.pv_no AND;
   	Pv.fundcode = Pv_notify.fundcode;	
WHERE Pv.fundcode = tcFundCode AND;
	Pv.pv_no = tcPvno;
INTO CURSOR pvNotify
IF _TALLY = 0
	=MESSAGEBOX("ไม่พบใบสำคัญจ่าย เลขที่ "+tcPvno, 0, "พิมพ์ ใบสำคัญจ่าย")
ELSE	
	SELECT A.pv_no, A.pv_date, A.policy_no, A.client_name,;
	  A.paid_to, A.paid_type, A.send_to, A.send_by, A.total,;
	  A.notes, A.prepared_by, A.virified_by, A.approved_by,;
	  A.notify_no, A.benfpaid,  A.remarks, A.name,;
	  A.admit, A.prov_name, A.claim_id,A.year_visit,A.wt,;
	  B.chq_no , B.chq_date, B.bank, B.amount, B.chq_detail;
	FROM FORCE pvNotify A LEFT JOIN cims!pv_cheque B;
	   ON  A.pv_no = B.pv_no AND;
	   	A.fundcode = B.fundcode;
	INTO CURSOR pvForm
	IF _TALLY = 0 	
 		=MESSAGEBOX("ไม่พบรายการรับเช็ค ของ ใบสำคัญจ่าย เลขที่ "+tcPvno, 0, "พิมพ์ ใบสำคัญจ่าย")
 		RETURN
 	ENDIF	
	lnLine = 0
	lnType = 0
	lcCustType = "I"
	cPvNo = pvForm.pv_no
	cClaimID = pvform.claim_id
	SCATTER MEMVAR
	WAIT WINDOW "Print PV No. "+pvform.pv_no NOWAIT
	***********************************
	IF SEEK(pvForm.claim_id, "claim", "claim_id")
		lnType = claim.claim_type
		lcCustType = claim.claim_with
	ENDIF
	***********************************
	IF INLIST(lcCustType, "A", "P")
	ELSE
		IF lnType <> 0
			DO CASE
			CASE INLIST(lnType ,2, 5)
				lcReport = "pvIPD"
			CASE INLIST(lnType ,1, 3,4)
				lcReport = "pvOPD"
			ENDCASE
		ENDIF	
	ENDIF
	**********************************	
	DO CASE
	CASE  lnPrintTo = 2
		IF INLIST(lcCustType, "A", "T")
			REPORT FORM (gcReportPath+"pvGrpForm")  PREVIEW NOCONSOLE
		ELSE
			REPORT FORM (gcReportPath+"pv_Form") PREVIEW NOCONSOLE
		ENDIF
		*****************************	
		IF INLIST(lcCustType, "G", "I", "H")
			lnOpt = MESSAGEBOX("ต้องการให้แสดง ใบสรุปฯ+สำเนา กด Yes"+CR+" แสดงใบสรุปฯ กด No"+CR+" ยกเลิก กด Cancel", MB_YESNOCANCEL+MB_DEFBUTTON2, TITLE_LOC)
			DO CASE
			CASE lnOpt = IDYES
				REPORT FORM ("report\"+lcReport) PREVIEW NOCONSOLE
				REPORT FORM ("report\"+lcReport+"1") PREVIEW NOCONSOLE
			CASE lnOpt = IDNO
				REPORT FORM ("report\"+lcReport) PREVIEW NOCONSOLE
			ENDCASE
		ENDIF	
	CASE  lnPrintTo = 1
		IF INLIST(lcCustType, "A", "T")
			REPORT FORM (gcReportPath+"pvGrpForm")  TO PRINTER NOCONSOLE
		ELSE
			REPORT FORM (gcReportPath+"pv_Form")  TO PRINTER NOCONSOLE
		ENDIF
		*****************************	
		IF NOT INLIST(lcCustType, "I", "G", "H")
			IF MESSAGEBOX("ต้องการให้พิมพ์ ใบสรุปฯ หรือไม่ ?", MB_YESNO, TITLE_LOC) = IDYES
				REPORT FORM ("report\"+lcReport) TO PRINTER NOCONSOLE
				REPORT FORM ("report\"+lcReport+"1") TO PRINTER NOCONSOLE
			ENDIF
		ENDIF	
	ENDCASE
ENDIF
******************
IF USED("pvform")
	USE IN pvForm
ENDIF	
IF USED("pvnotify")
	USE IN pvnotify
ENDIF	
SELECT (lnArea)