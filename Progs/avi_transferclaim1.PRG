CLOSE ALL 
SET MULTILOCKS ON 
USE ? IN 0 ALIAS aviclaim
USE cims!claim IN 0
USE cims!claim_line IN 0
USE cims!notify_period IN 0
USE cims!notify_period_items IN 0
USE cims!notify_period_lines IN 0
USE cims!notify_period_fee IN 0
*
=CURSORSETPROP("Buffering",5,"claim")
=CURSORSETPROP("Buffering",5,"claim_line")
*
SELECT aviclaim
*DO WHILE !EOF()
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	SCATTER MEMVAR 
	*
	SELECT aggregate FROM cims!plan WHERE plan_id = m.plan_id INTO ARRAY laPlan
	m.aggregate = IIF(_TALLY = 0, 0, laPlan[1])
	m.service_type = IIF(TTOD(m.discharge) - TTOD(m.admit) > 0 , "IPD", "OPD")
	m.cause_type = IIF(ctype = "SP", "SC", "CC")
	*
	IF SEEK(m.claimno, "claim", "claim_no")
		m.notify_no = claim.notify_no
		m.notify_date = claim.notify_date
		m.claim_id = claim.claim_id
	ELSE 
		m.notify_no = newdateno("notify", DATETIME(), "H")
		m.notify_date = DATETIME()
		m.claim_id = SUBSTR(m.notify_no, 3,10)
	ENDIF 		
	*
	APPEND BLANK IN claim
	REPLACE fundcode WITH "AVI", ;
		notify_no WITH m.notify_no, ;
		notify_date WITH m.notify_date, ;
		policy_holder WITH m.pol_holder, ;
		policy_no WITH m.nric, ;
		client_name WITH m.claimant, ;
		effective WITH m.effective, ;
		expried WITH m.expiry, ;
		cause_type WITH m.cause_type, ;
		claim_no WITH m.claimno, ;
		prov_id WITH "99999999", ;
		prov_name WITH "OTHER", ;
		admis_date WITH m.admit, ;
		disc_date WITH m.discharge, ;
		scharge WITH m.charge, ;
		sbenfpaid WITH m.paid, ;
		result WITH "HC", ;
		return_date WITH DATE(), ;
		fnote WITH "ข้อมูลจาก Aviva", ;
		claim_with WITH "H", ;
		customer_id WITH m.cust_id, ;
		plan WITH m.plan, ;
		plan_id WITH m.plan_id, ;
		deduc WITH m.deductible, ;
		aggregate WITH m.aggregate, ;
		service_type WITH m.service_type, ;
		claim_id WITH m.claim_id, ;
		claim_date WITH m.notify_date, ;
		l_user WITH "VACHARA", ;
		l_update WITH DATETIME() IN claim 
	*
	INSERT INTO cims!claim_line (notify_no, claim_id, cat_id, cat_code, description, benf_cover, benefit, benefit_paid, scharge, spaid, copayment, l_user, l_update) ;
	VALUES (m.notify_no, m.claim_id, "AVIHS0001", "MED001", "ค่ารักษาพยาบาล", m.aggregate, m.aggregate, 0, m.charge, m.paid, 0, "VACHARA", DATETIME())
	*
	DO SaveDisability
	*
	SELECT aviclaim
	SKIP
*ENDDO 
SELECT claim
BROWSE
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