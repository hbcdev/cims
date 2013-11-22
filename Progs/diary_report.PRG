PARAMETERS tcFundCode, tdStartDate, tdEndDate
IF EMPTY(tcFundCode) AND EMPTY(tdStartDate) AND EMPTY(tdEndDate)
	RETURN 
ENDIF 
	
SELECT IIF(Claim.result = "P5", "I", IIF(Claim.result = "W5", "F", IIF(Claim.result = "W6", "U", LEFT(Claim.result,1)))) AS clm_status, ;
	IIF(Claim.claim_with = "A",  "P", Claim.claim_with) AS claim_with, ;
	Claim.notify_no, Claim.notify_date, Claim.service_type, Claim.cause_type, ;
	Claim.policy_no, Claim.policy_holder, Claim.family_no, Claim.plan, Claim.client_name, Claim.effective, Claim.expried, ;
	Claim.visit AS ds_no, Claim.visit_no AS claimitem, Claim.indication_admit, Claim.diag_plan, Claim.acc_date, ;
	Claim.prov_name, Claim.admis_date, Claim.disc_date, Claim.illness1, Claim.illness2, Claim.illness3, ;
	Claim_line.cat_code, Claim_line.description, IIF(Claim.result = "W5", Claim_line.fadmis, Claim_line.sadmis) AS admit, ;
	IIF(Claim.result = "W5", Claim_line.fcharge, Claim_line.scharge) AS charge, ;
	IIF(Claim.result = "W5", Claim_line.fdiscount, Claim_line.sdiscount) AS discount, ;
	IIF(Claim.result = "W5", Claim_line.fpaid+Claim_line.deduc, Claim_line.spaid+Claim_line.dpaid) AS paid, ;
	IIF(Claim.result = "W5", Claim_line.fremain, Claim_line.sremain) AS overpaid, ;
	IIF(Claim.result = "W5", Claim_line.exgratia, Claim_line.apaid) AS exgratia, ;
	IIF(Claim.result = "W5", Claim_line.nopaid, Claim_line.snoncover) AS nopaid, ;
	Claim_line.total_fee AS fee, Claim.hb_cover, Claim.hb_act, Claim.hb_app, ;
	Claim.result, Claim.snote, Claim.note2ins, Claim.ref_date, Claim.return_date ;
	FROM  cims!Claim INNER JOIN cims!Claim_line ;
	ON Claim.notify_no = Claim_line.notify_no ;
	WHERE Claim.fundcode = tcFundCode ;
		 AND result = "W";
	ORDER BY 2, 1 ;
	INTO CURSOR curClaim
