LPARAMETER tcrvNo
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
	lcCustType

lnArea = SELECT()
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
	SELECT rv.rv_no, rv.rv_date, rv.policy_no, rv.client_name,;
	  rv.paid_to, rv.paid_type, rv.send_to, rv.send_by,;
	  rv.notes, rv.prepared_by, rv.virified_by, rv.approved_by,;
	  rv_lines.notify_no, rv_lines.amount AS benfpaid,  rv_lines.remarks,;
	  rv_lines.admit, rv_lines.prov_name, rv_lines.claim_id,rv_lines.year_visit;
	FROM FORCE cims!rv LEFT JOIN cims!rv_lines;
	   ON  rv.rv_no = rv_lines.rv_no;
	WHERE rv.rv_no = tcrvno;
	INTO CURSOR rvNotify
	IF _TALLY = 0
 		=MESSAGEBOX("ไม่พบใบสำคัญจ่าย เลขที่ "+tcrvno, 0, "พิมพ์ ใบสำคัญรับ")
 	ELSE	
		SELECT A.rv_no, A.rv_date, A.policy_no, A.client_name,;
		  A.paid_to, A.paid_type, A.send_to, A.send_by,;
		  A.notes, A.prepared_by, A.virified_by, A.approved_by,;
		  A.notify_no, A.benfpaid,  A.remarks,;
		  A.admit, A.prov_name, A.claim_id,A.year_visit,;
		  B.chq_no , B.chq_date, B.bank, B.amount, B.chq_detail;
		FROM FORCE rvNotify A LEFT JOIN cims!rv_cheque B;
		   ON  A.rv_no = B.rv_no;
		INTO CURSOR rvForm
		IF _TALLY = 0 	
	 		=MESSAGEBOX("ไม่พบรายการรับเช็ค ของ ใบสำคัญรับ เลขที่ "+tcrvno, 0, "พิมพ์ ใบสำคัญรับ")
	 		RETURN
	 	ENDIF	
		lnLine = 0
		lnType = 0
		lcCustType = "I"
		crvNo = rvForm.rv_no
		cClaimID = rvform.claim_id
		SCATTER MEMVAR
		WAIT WINDOW "Print rv No. "+rvform.rv_no NOWAIT
		***********************************
		IF SEEK(rvForm.claim_id, "claim", "claim_id")
			lnType = claim.claim_type
			lcCustType = claim.claim_with
		ENDIF
		***********************************
		IF INLIST(lcCustType, "A", "P")
			=MESSAGEBOX("อยู่ระหว่างการเขียนอยู่ กรุณารอสักครู่ ",MB_OK,"Wait")
		ELSE
			IF lnType <> 0
				DO CASE
				CASE INLIST(lnType ,2, 5)
					lcReport = "rvIPD"
				CASE INLIST(lnType ,1, 3,4)
					lcReport = "rvOPD"
				ENDCASE
			ENDIF	
		ENDIF	
		DO CASE
		CASE  lnPrintTo = 2 
			REPORT FORM (gcReportPath+"rvForm")  PREVIEW NOCONSOLE
		CASE  lnPrintTo = 1
			REPORT FORM (gcReportPath+"rvForm") TO PRINTER NOCONSOLE
		ENDCASE
	ENDIF
ENDIF
******************
IF USED("rvform")
	USE IN rvForm
ENDIF	
SELECT (lnArea)