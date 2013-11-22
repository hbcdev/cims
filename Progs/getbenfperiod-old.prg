LPARAMETER tcFundCode, tcPolicyNo, tnPersonNo, tdAdmit, tcFollowTo
IF EMPTY(tcFollowTo)
	tcFollowTo = ""
ENDIF 	
IF TYPE("tcFundCode") = "L" AND TYPE("tcPolicyNo") = "L" AND TYPE("tdAdmit") = "L"
	RETURN .F.
ENDIF
SET ENGINEBEHAVIOR 70
*****************
* tcCustID = Client ID for seek period in notify_period
*Return .T. = มีการเลือก notify no
*Return ,F. = ไม่เลือก notify no ให้ใช้ตารางผลประโยชน์แทน
*****************
LOCAL lnArea,;
	lcPolicyNo,;
	lcNotifyNo,;
	lnRecNo,;
	llRetVal,;
	loForm

lnArea = SELECT()
lnRecNo = RECNO()
****************************************
lcNotifyNo = ""
cFundCode = tcFundCode
cPolicyNo = tcPolicyNo
nPersonNo = IIF(TYPE("tnPersonNo") = "L", 0, tnPersonNo)
dDue = tdAdmit
cNotifyNo = claim.notify_no
lcService = claim.service_type
lcCause = claim.cause_type
ldAccDate = claim.acc_date
**********************************
IF tnPersonNo = 0
	lcPolicyNo = tcFundcode + tcPolicyNo
	IF SEEK(lcPolicyNo, "notify_period","policy_no")
		DO FORM form\cims02_period WITH lcService, tcFollowTo, tdAdmit, cFundCode, lcCause TO lcNotifyNo
	ENDIF
ELSE
	lcPolicyNo = tcFundcode + tcPolicyNo+STR(tnPersonNo)
	IF SEEK(lcPolicyNo, "notify_period","person_no")
		DO FORM form\cims02_period WITH lcService, tcFollowTo, tdAdmit, cFundCode, lcCause TO lcNotifyNo
	ENDIF
ENDIF
****************************
llRetVal = .F.
IF !EMPTY(lcNotifyNO)
	lcFollowUp = lcNotifyNo
	IF !SEEK(lcNotifyNo, "notify_period", "notify_no")
		IF SEEK(lcNotifyNo, "notify_period_lines", "not_no")
			lcFollowUp = notify_period_lines.notify_no
		ENDIF 
	ENDIF 		
	********************************************
	SELECT A.notify_no, A.due,	A.visit_no, ;
		A.type AS claim_type, ;
		TTOD(A.admis_date) AS admis_date, ;
		TTOD(A.disc_date) AS disc_date, ;
		A.excl_type AS ds_no, A.acc_date, ;
		A.diags, A.endfollowup, A.benefit AS benfpaid, ;
		B.cat_id, B.cat_code, B.description, B.stdcode, ;
		SUM(B.serv_used) AS service_used, ;
		SUM(B.subservice) AS subservice, ;
		SUM(B.benefit) AS benf_paid, ;
		SUM(B.subpaid) AS subpaid, ;
		B.serv_cover, B.benf_cover, B.oon_cover, ;
		B.per, B.item_grp, B.fee, SUM(B.fee_rate) AS fee_rate, B.group ;
	FROM cims!notify_period A INNER JOIN cims!notify_period_items B ;
		ON A.notify_no = B.notify_no ;
	GROUP BY B.cat_id ;
	ORDER BY B.group ;
	WHERE A.notify_no = lcFollowUp AND LEN(ALLTRIM(B.group)) = 1 ;
	INTO CURSOR curPeriodLines
	*
	IF RECCOUNT("curPeriodLines") = 0
		SELECT A.notify_no, A.due,	A.visit_no, ;
			A.type AS claim_type, ;
			TTOD(A.admis_date) AS admis_date, ;
			TTOD(A.disc_date) AS disc_date, ;
			A.excl_type AS ds_no, A.acc_date, ;
			A.diags, A.endfollowup, A.benefit AS benfpaid, ;
			B.cat_id, B.cat_code, B.description, B.stdcode, ;
			SUM(B.serv_used) AS service_used, ;
			SUM(B.subservice) AS subservice, ;
			SUM(B.benefit) AS benf_paid, ;
			SUM(B.subpaid) AS subpaid, ;
			B.serv_cover, B.benf_cover, B.oon_cover, ;
			B.per, B.item_grp, B.fee, SUM(B.fee_rate) AS fee_rate, B.group ;
		FROM cims!notify_period A INNER JOIN cims!notify_period_items B ;
		  ON A.notify_no = B.notify_no ;
		GROUP BY B.cat_id ;
		ORDER BY B.group ;
		WHERE A.notify_no = lcFollowUp ;
		INTO CURSOR curPeriodLines
	ENDIF 
	
	IF RECCOUNT("curPeriodLines") = 0
		llRetVal = .F.
	ELSE 	
		SELECT notify_no, due, visit_no, claim_type, admis_date, disc_date, diags, endfollowup, acc_date, ds_no, ;
			cat_id, cat_code, description, stdcode, ;
			service_used+subservice AS service_used, benfpaid, ;
			benf_paid+subpaid AS benf_paid, ;
			benf_cover As benefit, ;
			oon_cover AS benfcover, ;
			IIF(per $ "VD", serv_cover - (service_used+subservice), serv_cover)  AS serv_cover, ;
			IIF(per $ "MYFV", benf_cover - (benf_paid+subpaid), benf_cover) AS benf_cover, ;
			IIF(per $ "MYFV", oon_cover - (benf_paid+subpaid), oon_cover) AS oon_cover, ;
			per, item_grp, fee, fee_rate, group ;
			FROM curPeriodLines ;
			INTO CURSOR period_Line
		IF RECCOUNT("period_line") > 0
			llRetVal = .T.
		ENDIF	
	ENDIF 	
ENDIF
IF USED("curPeriodLines")
	USE IN curPeriodLines
ENDIF 
SELECT (lnArea)
IF lnRecNo <> 0 AND lnRecNo <= RECCOUNT()
	GO lnRecNo
ENDIF
SET ENGINEBEHAVIOR 90
RETURN llRetVal