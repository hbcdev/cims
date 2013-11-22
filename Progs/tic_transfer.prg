CLOSE ALL 
datapath = "D:\hips\data\"
gcFundCode = "TIM"
lcSaveTo = "D:\report\tic\"
lcDbf = "E4770"+TTOC(DATETIME(),1)+".TXT"
*
SELECT claim.notify_no, claim.notify_date, claim.service_type, claim.cause_type, claim.visit_no, claim.policy_no, claim.cardno, claim.customer_id, ;
	claim.client_name, claim.prov_id, claim.prov_name, claim.acc_date, claim.illness1, claim.indication_admit, claim.diag_plan, claim.note2ins, claim.sbenfpaid, ;
	claim.doc_fee, claim.paid_to, claim.admis_date, member.title, claim.result, claim.lotno ,claim.batchno, IIF(EMPTY(claim.followup), claim.notify_no, claim.followup) AS followup  ;
FROM cims!claim INNER JOIN cims!member ;
	ON claim.fundcode = member.tpacode ;
		AND claim.policy_no = member.policy_no ;
WHERE claim.fundcode = gcFundCode ;
	AND lotno IN ("T_12-04-12", "T_20-04-12", "T_27-04-12") ;
	AND result NOT LIKE "C%" ;
ORDER BY 25, 1 ;
INTO CURSOR curTransfer
IF _TALLY = 0 
	RETURN 
ENDIF 	
*
CREATE CURSOR curEstimate (datafile C(1), mainclass C(1), agentno N(7,0), agentbranch C(3), typeclaim C(1), claimtype C(3), time I, referenceno C(25), notifydate D, ;
	claimno C(25), policyno C(30), cardno C(25), occurdate D, occurtime C(8), paidtype C(250), paidamt N(13,2), paidother N(13,2), hospcode C(25), hospname C(200), custid C(20), title C(30), ;
	name C(50), surname C(100), address C(250), district C(100), province C(100), postcode C(5), accaddr C(250), coverdesc C(200), cewdesc C(200), indication C(250), ;
	treatment C(250), paidtime I, illcode C(25), illname C(100), paidtypecode C(20), paidname C(160), paiddes C(60), paidtypeacc C(250), remark C(250), polcover C(1), result C(250))
*
SELECT curTransfer
DO WHILE !EOF()
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 99,999") NOWAIT
	m.paidname = client_name
	m.paiddes = ""	
	IF INLIST(result, "P5", "P61")
		SELECT acc_name, ALLTRIM(account_no)+" "+ALLTRIM(bank)+"/"+ALLTRIM(addr_1)+" "+ALLTRIM(province)+" "+ALLTRIM(city)+" "+postcode AS paiddes ;
		FROM cims!provider WHERE prov_id = curTransfer.prov_id INTO ARRAY laProvider
		IF _TALLY > 0
			m.paidname = laProvider[1]
			m.paiddes = laProvider[2]
		ENDIF 	
	ENDIF
	* 
	ltAccDate = IIF(EMPTY(acc_date), admis_date, acc_date)
	*
	m.datafile = "E"
	m.mainclass = "P"
	m.agentno = 4770
	m.agentbranch = "001"
	m.typeclaim = IIF(cause_type = "ILL", "1", "2")
	m.claimtype = IIF(service_type = "DAY", "IPD", IIF(service_type = "FWP", "OPD", service_type))
	m.time = visit_no
	m.referenceno = "REF/"+notify_no	
	m.notifydate = TTOD(notify_date)
	m.policyno = LEFT(policy_no,AT("_", policy_no)-1)
	m.cardno = cardno
	m.occurdate = TTOD(ltAccDate)
	m.occurtime = STRTRAN(STR(HOUR(ltAccDate),2)," ","0")+":"+STRTRAN(STR(MINUTE(ltAccDate),2)," ","0")+":"+STRTRAN(STR(SEC(ltAccDate),2)," ","0")
	m.paidtime = 1
	m.paidtype = "ค่าสินไหม"
	m.paidamt = sbenfpaid
	m.hospcode = prov_id
	m.hospname = STRTRAN(prov_name, "(A)", "")
	m.custid = customer_id
	m.title = title
	m.name = ALLTRIM(SUBSTR(client_name, 1, AT(" ", client_name)))
	m.surname = ALLTRIM(SUBSTR(client_name, AT(" ", client_name)))
	m.coverdesc = "ค่ารักษา"
	m.indication = ALLTRIM(STRTRAN(STRTRAN(indication_admit, CHR(13), " "), CHR(10), " "))
	m.treatment = ALLTRIM(STRTRAN(STRTRAN(diag_plan, CHR(13), " "), CHR(10), " "))
	m.illcode = illness1
	m.illname = GetIcd10Text(illness1)
	m.illname = ALLTRIM(STRTRAN(m.illname, CHR(13)," "))
	m.paidtypecode = ICASE(result = "P1", "Insured", "Hospital")
	m.paidtypeacc = ICASE(result = "A11", "โอนเข้าบัญชี", "")
	m.polcover = IIF(result = "D", "N", "Y")
	m.remark = ALLTRIM(STRTRAN(STRTRAN(note2ins, CHR(13)," "), CHR(10), " "))
	m.paidother = 0	
	*
	lcFollowup = followup
	m.paidamt = 0
	DO WHILE followup = lcFollowup AND !EOF()	
		WAIT WINDOW TRANSFORM(RECNO(), "@Z 99,999") NOWAIT
		m.paidamt = m.paidamt + sbenfpaid
		SKIP 
	ENDDO 			
	*	
	INSERT INTO curEstimate FROM MEMVAR 
	*
	IF doc_fee <> 0
		m.paidtype = "ค่าขอประวัติ"
		m.paidother = doc_fee	
		INSERT INTO curEstimate FROM MEMVAR 	
	ENDIF 	
ENDDO


*
lcTitle = "datafile|mainclass|agentno|agentbranch|typeclaim|claimtype|time|referenceno|notifydate|claimno|policyno|"+;
	"cardno|occurdate|occurtime|paidtype|paidamt|paidother|hospcode|hospname|custid|title|name|surname|address|"+;
	"district|province|postcode|accaddr|coverdesc|cewdesc|indication|treatment|paidtime|illcode|illname|paidtypecode|"+;
	"paidname|paiddes|paidtypeacc|remark|polcover|result"+CHR(13)

SET SAFETY OFF 
SELECT curEstimate
COPY TO (lcDbf) TYPE DELIMITED WITH CHARACTER "|"
ctemp = FILETOSTR(lcDbf)
STRTOFILE(lcTitle + cTemp, lcDbf)
SET SAFETY ON 