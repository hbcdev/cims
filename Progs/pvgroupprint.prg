LPARAMETER tcPvNo
IF PARAMETER() = 0
	tcPvNo = ""
ENDIF	
#INCLUDE include\cims.h
SET CLASS TO class\notify
LOCAL lnRetVal,;
	cClaimID,;
	aTo[4,1],;
	aBY[3,1],;
	lcRetVal,;
	loForm,;
	lnArea,;
	llClosed

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
loForm = CREATEOBJECT("printbyno")
IF TYPE("loForm") == "O"
	loForm.txtStart.Value = tcPvNo
	loForm.cmgPrint.Command1.Caption = "Pre\<view"
	loForm.Show
	lcRetVal = loForm.uRetVal
	loForm.Release
ELSE
	RETURN
ENDIF		
IF EMPTY(lcRetVal) OR LEN(lcRetVal) < 11
	RETURN
ENDIF
**********************
IF !USED("pv_cheque")
	USE cims!pv_cheque IN 0
	llClosed = .T.
ENDIF	
************************************
lcFundCode = LEFT(lcRetVal,3)
lcPrintTo = RIGHT(lcRetVal,2)
lcPrintTo = LEFT(lcPrintTo,1)
lcOption = RIGHT(lcPrintTo,1)
IF LEN(lcRetVal) = 25
	lcStart = SUBSTR(lcRetVal,4,10)
	lcEnd = SUBSTR(lcRetVal,14,10)
ELSE
	IF TYPE(LEFT(lcRetVal,1)) = "N"
		IF LEN(lcRetVal) = 11
			lcStart = SUBSTR(lcRetVal,1,10)
			lcEnd = lcStart
		ELSE	
			lcStart = SUBSTR(lcRetVal,1,10)
			lcEnd = SUBSTR(lcRetVal,11,10)
		ENDIF		
	ELSE
		lcStart = SUBSTR(lcRetVal,4,10)
		lcEnd = lcStart
	ENDIF	
ENDIF
**************************************
FOR i = VAL(lcStart) TO VAL(lcEnd)
	SELECT Pv.pv_no, Pv.pv_date, Pv.policy_no, Pv.client_name,;
	  Pv.paid_to, Pv.paid_type, Pv.send_to, Pv.send_by,;
	  Pv.notes, Pv.prepared_by, Pv.virified_by, Pv.approved_by,;
	  Pv_notify.notify_no, Pv_notify.amount AS benfpaid,  Pv_notify.remarks,;
	  Pv_notify.admit, Pv_notify.prov_name, Pv_notify.claim_id,Pv_notify.year_visit,;
	  Pv_cheque.chq_no AS chq_no, Pv_cheque.chq_date AS chq_date,;
	  Pv_cheque.bank AS bank, Pv_cheque.amount AS amount, Pv_cheque.chq_detail AS chq_detail;
	FROM FORCE cims!Pv LEFT JOIN cims!pv_notify;
	   ON  Pv.pv_no = Pv_notify.pv_no;
	ORDER BY pv.pv_no;
	WHERE Pv.pv_no = STR(i,10) AND;
		pv.pv_no = pv_cheque.pv_no;
	INTO CURSOR pvForm
	IF _TALLY = 0
 		=MESSAGEBOX("ไม่พบใบสำคัญจ่าย เลขที่ "+STR(i,10), MB_OK, "พิมพ์ ใบสำคัญจ่าย")
 	ELSE	
		lnLine = 0
		cClaimID = ""
		lnType = 0
		cPvNo = pvForm.pv_no
		***********************************
		IF SEEK(pvForm.claim_id, "claim", "claim_id")
			lnType = claim.claim_type
		ENDIF
		***********************************
		lcReport = ""
		IF lnType <> 0
			IF lnType = 2
				lcReport = "pvIPD"
			ELSE
				lcReport = "pvOPD"
			ENDIF
		ENDIF	
		IF !EMPTY(lcReport)
			DO CASE
			CASE lcOption = "1"
				DO CASE
				CASE  lcPrintTo = "1"
					REPORT FORM report\pvForm  PREVIEW NOCONSOLE
				CASE  lcPrintTo = "2"
					REPORT FORM report\pvForm TO PRINTER NOCONSOLE
				ENDCASE
			CASE lcOption = "2"
				DO CASE
				CASE  lcPrintTo = "1"
					REPORT FORM ("report\"+lcReport) PREVIEW NOCONSOLE
				CASE  lcPrintTo = "2"
					REPORT FORM ("report\"+lcReport) TO PRINTER NOCONSOLE
					REPORT FORM ("report\"+lcReport+"1") TO PRINTER NOCONSOLE
				ENDCASE
			CASE lcOption = "3"
				DO CASE
				CASE  lcPrintTo = "1"
					REPORT FORM report\pvForm  PREVIEW NOCONSOLE
					IF MESSAGEBOX("ต้องการให้แสดง ใบสรุปฯ หรือไม่ ?", MB_YESNO, TITLE_LOC) = IDYES
						REPORT FORM ("report\"+lcReport) PREVIEW NOCONSOLE
					ENDIF
				CASE  lcPrintTo = "2"
					REPORT FORM report\pvForm TO PRINTER NOCONSOLE
					IF MESSAGEBOX("ต้องการให้พิมพ์ ใบสรุปฯ หรือไม่ ?", MB_YESNO, TITLE_LOC) = IDYES
						REPORT FORM ("report\"+lcReport) TO PRINTER NOCONSOLE
						REPORT FORM ("report\"+lcReport+"1") TO PRINTER NOCONSOLE
					ENDIF
				ENDCASE
			ENDCASE	
		ENDIF
	ENDIF
	USE IN pvform
ENDFOR
******************
IF USED("pvform")
	USE IN pvForm
ENDIF	
IF llClosed AND USED("pv_cheque")
	USE IN pv_cheque
ENDIF	
SELECT (lnArea)