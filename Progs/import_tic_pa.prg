lnHandle = SQLCONNECT("tic pa member")
IF lnHandle = 0
	WAIT WINDOW "cannot connect to ODBC" NOWAIT 
	RETURN 
ENDIF 

= SQLSETPROP(lnHandle, 'asynchronous', .F.)
IF !USED("pamas")
	= SQLEXEC(lnHandle, "SELECT * FROM papolmas WHERE  Papolmas.product_cd IS NOT NULL ORDER BY Papolmas.policy_no", 'pamas')
ENDIF 
IF !USED("paitems")	
	= SQLEXEC(lnHandle, "SELECT * FROM paitem ", 'paitems')
	SELECT paitems
	INDEX on pol_serial TAG pol_serial
ENDIF 	
*
lcSaveTo = GETDIR()
lcSaveTo = IIF(EMPTY(lcSaveTo), SYS(2003), lcSaveto)
lcDbf = "TIC_PA_ Member_"+STRTRAN(DTOC(DATE()), "/", "")
SELECT 0
CREATE TABLE (ADDBS(lcSaveTo)+lcDbf) FREE (branch_cod C(20), province c(40), policy_no c(30), policy_hol C(40), ;
	plan C(20), first_year D, eff_date D, exp_date D, cust_id C(20), natid C(20), title C(20), name C(40), middle C(40), ;
	surname c(40), sex C(1), dob D, age I, address1 C(40), address2 c(40), address3 C(40), address4 C(40), postcode C(5), premium Y, medical Y, renew I, ;
	exclusion C(40), pay_mode C(10), old_plan c(20), old_prem Y, adjust_dat D, adjust_pre Y, payer C(40), agent_code C(40), agent_name c(40), ;
	agent_addr C(40), agency C(40), agency_na1 c(40), agency_add c(40), card C(1), credit Y, Agent_id c(10))
*
SELECT pamas
SET FILTER TO INLIST(product_cd, "D-lite", "X-cite")
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 99,999") NOWAIT 
	m.branch_cod = intm_branch
	m.province = chw_desc
	m.policy_no = ALLTRIM(policy_no)
	m.policy_hol = ins_name
	m.plan = product_cd
	m.eff_date = effect_dt
	m.exp_date = expiry_dt
	*m.title = ALLTRIM(LEFT(ins_name, AT(" ", ins_name)))
	*m.name = ALLTRIM(LEFT(SUBSTR(ins_name, AT(" ", ins_name)+1), AT(" ", SUBSTR(ins_name, AT(" ", ins_name)+1))))	
	*m.surname = ALLTRIM(SUBSTR(SUBSTR(ins_name, AT(" ", ins_name)+1),AT(" ", SUBSTR(ins_name, AT(" ", ins_name)+1))))
	m.address1 = addr1
	m.address2 = addr2
	m.address3 = addr3
	m.address4 = amp_desc
	m.postcode = postcode
	m.renew = renew_srl
	m.agent_code = intm_card
	m.agent_name = intm_name
	m.agency = prod_brn
	m.agency_na1 = prod_name
	m.pol_serial = pol_serial
	IF SEEK(pol_serial, "paitems", "pol_serial")
		SELECT paitems
		DO WHILE m.pol_serial = pol_serial AND !EOF()
			m.policy_no = ALLTRIM(pamas.policy_no)+"-"+ALLTRIM(STR(item_no))
			m.name = life_name
			*=DELTITLE(life_name)
			*m.surname = SUBSTR(m.name, AT(" ", m.name)+1)
			*m.name = LEFT(m.name, AT(" ", m.name))
			m.cust_id = IIF(ISNULL(paitems.life_ic), "", paitems.life_ic)
			m.natid = IIF(ISNULL(paitems.life_ic), "", paitems.life_ic)
			m.dob = IIF(ISNULL(paitems.life_dob), {}, paitems.life_dob)
			m.sex = IIF(ISNULL(paitems.life_sex), "", paitems.life_sex)
			m.age = IIF(ISNULL(paitems.life_age), 0, paitems.life_age)
			m.premium = IIF(ISNULL(paitems.med_prmm), 0, paitems.med_prmm)
			m.medical = IIF(ISNULL(paitems.med_si), 0, paitems.med_si)
			INSERT INTO (ADDBS(lcSaveTo)+lcDbf) FROM MEMVAR  						
			SKIP IN paitems
		ENDDO 	
	ENDIF
	SELECT pamas
ENDSCAN 		