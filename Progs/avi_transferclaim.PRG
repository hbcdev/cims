CLOSE ALL 
SET MULTILOCKS ON 
SET PROCEDURE TO progs\utility
USE ? IN 0 ALIAS aviclaim
USE cims!claim IN 0
USE cims!claim_line IN 0
USE cims!notify_period IN 0
USE cims!notify_period_items IN 0
USE cims!notify_period_lines IN 0
USE cims!notify_period_fee IN 0
USE cims!member IN 0
*
=CURSORSETPROP("Buffering",5,"claim")
=CURSORSETPROP("Buffering",5,"claim_line")
*!*	=CURSORSETPROP("Buffering",5,"notify_period")
*!*	=CURSORSETPROP("Buffering",5,"notify_period_items")
*!*	=CURSORSETPROP("Buffering",5,"notify_period_lines")
*!*	=CURSORSETPROP("Buffering",5,"notify_period_fee")
*
gcUserName = "VACHARA"

SELECT aviclaim
DO WHILE !EOF()
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	IF EMPTY(policy_no)
		SKIP 
	ENDIF 	
	SCATTER MEMVAR 			
	SELECT policy_no, admis_date ;
	FROM cims!claim ;
	WHERE fundcode = "AVI" ;
		AND policy_no = m.policy_no ;
		AND TTOD(admit) = TTOD(admis_date) ;
	INTO ARRAY laClaim
	IF _TALLY <> 0
		SKIP 
	ENDIF 		
	*	
	SELECT age, birth_date ;
	FROM cims!member ;
	WHERE tpacode = "AVI" ;
		AND policy_no = m.policy_no ;
	INTO ARRAY laMember
	IF _TALLY = 0
		m.age = 0
		m.dob = {}
	ELSE 	
		m.age = laMember[1]
		m.dob = laMember[2]
	ENDIF 	
	*********************************
	SELECT aggregate FROM cims!plan WHERE plan_id = m.plan_id INTO ARRAY laPlan
	m.aggregate = IIF(_TALLY = 0, 0, laPlan[1])
	*
	m.notify_no = newdateno("notify", DATETIME(), "H")
	m.notify_date = DATETIME()
	m.claim_id = SUBSTR(m.notify_no, 3,10)
	*
	APPEND BLANK IN claim
	REPLACE fundcode WITH "AVI", ;
		inv_page WITH 1, ;
		notify_no WITH m.notify_no, ;
		notify_date WITH {^2010-10-31}, ;
		policy_holder WITH m.pol_holder, ;
		policy_no WITH m.policy_no, ;
		client_no WITH m.groupno, ;
		client_name WITH m.clientname,  ;
		effective WITH m.effective, ;
		expried WITH m.expiry, ;
		cause_type WITH m.benftype, ;
		illness1 WITH m.icd10, ;
		prov_id WITH IIF(EMPTY(m.prov_id), "99999999", m.prov_id), ;
		prov_name WITH m.provname, ;
		admis_date WITH m.admit, ;
		disc_date WITH m.discharge, ;
		charge WITH m.charge, ;
		scharge WITH m.charge, ;
		sbenfpaid WITH m.paid, ;
		result WITH IIF(m.benftype = "NP", "D1", "P1"), ;
		return_date WITH {^2010-10-31}, ;
		snote WITH m.diagcode, ;
		fnote WITH m.remarks, ;
		claim_with WITH "H", ;
		customer_id WITH m.cust_id, ;
		plan WITH m.plan, ;
		plan_id WITH m.plan_id, ;
		deduc WITH m.deductible, ;
		deduc_paid WITH m.deduc, ;
		copayment WITH m.copayment, ;
		aggregate WITH m.aggregate, ;
		benf_cover WITH m.aggregate, ;
		service_type WITH IIF(TTOD(m.discharge) - TTOD(m.admit) > 0 , "IPD", "OPD"), ;
		claim_type WITH IIF(TTOD(m.discharge) - TTOD(m.admit) > 0 , 2, 1), ;
		type_claim WITH ICASE(m.benftype = "CC", 17, m.benftype = "SC", 18, m.benftype = "NP", 17, 0), ;
		claim_id WITH m.claim_id, ;
		claim_date WITH m.notify_date, ;
		dob WITH m.dob, ;
		age WITH m.age, ;
		currency_type WITH m.currencyc, ;
		l_user WITH "VACHARA", ;
		l_update WITH DATETIME() IN claim 
	*
	INSERT INTO cims!claim_line (notify_no, claim_id, cat_id, cat_code, description, benf_cover, benefit, benefit_paid, scharge, spaid, deduc, deductible, copayment, l_user, l_update) ;
	VALUES (m.notify_no, m.claim_id, "AVIHS0001", "MED001", "Medical Expense", m.aggregate, m.aggregate, 0, m.charge, m.paid, m.deduc, m.deductible, 0, "VACHARA", DATETIME())
	*
	*DO SaveDisability
	*
	SELECT aviclaim
	REPLACE notify_no WITH m.notify_no
	SKIP
ENDDO 
*SELECT claim
*BROWSE
***************************************************
PROCEDURE SaveDisability
*
SELECT claim

WAIT WINDOW "Please Wait  for process IPD period time .. " NOWAIT
IF EMPTY(claim.followup)
	DO SavePaPeriod WITH claim.notify_no, claim.expried
ELSE						
	DO SavePaPeriod WITH claim.followup, claim.expried
ENDIF	
WAIT CLEAR
*
*********************************************************
PROCEDURE addtomember

USE cims!member IN 0
=CURSORSETPROP("Buffering", 5, "member")

SELECT a.policy_no, a.claimant, a.nric, COUNT(*) ;
FROM "D:\My Documents\Health Fund\Aviva\Claim Data\NP100802.dbf" a ;
GROUP BY 1, 2, 3 ;
INTO CURSOR curclaims

SCAN 
	SCATTER MEMVAR 
	SELECT DISTINCT policy_name, policy_date, effective, expiry, product, plan_id ;
	FROM cims!member ;
	WHERE policy_group = m.policy_no ;
	INTO ARRAY laMember
	IF _TALLY > 0
		m.name = ALLTRIM(LEFT(m.claimant, AT(" ", m.claimant)))
		m.surname = ALLTRIM(SUBSTR(m.claimant, AT(" ", m.claimant)))
		INSERT INTO cims!member (policy_group, policy_name, policy_no, product, plan_id, policy_date, effective, expiry, middlename, name, surname) ;
			VALUES (m.policy_no, laMember[1], m.nric, laMember[5], laMember[6], m.claimant, m.name, m.surname)			 
	ENDIF 
ENDSCAN 	
USE IN curclaims

********************************************************
* Function for query member from member table
* Return cursor name when parameter not equal in list return null
FUNCTION SeekMember(tcFundCode, tcPolicyNo, tcProduct, tcCardNo)

IF EMPTY(tcFundCode) AND EMPTY(tcPolicyNo) AND EMPTY(tcProduct) AND EMPTY(tcCardNo)
	RETURN NULL
ENDIF 
	