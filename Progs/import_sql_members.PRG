PARAMETERS tcPolicyNo
IF EMPTY(tcPolicyNo)
	RETURN 
ENDIF 	
*
gcUserName = UPPER(ALLTRIM(SUBSTR(ID(),AT("#",ID())+1)))
lcDbf = ALLTRIM(tcPolicyNo)
SELECT * FROM cims!members WHERE policy_no = tcPolicyNo INTO CURSOR curSmgPolicy READWRITE 
IF _TALLY = 0
	RETURN 
ENDIF 
*
SET DELETED ON 
lnConn = SQLCONNECT("CimsDB")
IF lnConn <=0
	=MESSAGEBOX("Cannot connect to SQL Server Please Contact Database Administrator",0)
	RETURN 
ENDIF
IF !USED("card2natid")
	USE cims!card2natid IN 0
ENDIF 	
***************************
SET MULTILOCKS ON 
?"Import Policy No "+tcPolicyNo
STORE 0 TO lnNew, lnSmgNew, lnUpdate, lnDup
lcDupFile = "ERROR_"+tcPolicyNo

SELECT curSmgPolicy
GO TOP 
lnMemberExist = checkExistMember(adddate)
IF lnMemberExist > 0
	IF MESSAGEBOX("มีการนำเข้าข้อมูลของวันที่ "+DTOC(adddate)+" จำนวน "+TRANSFORM(lnMemberExist, "@Z 999,999")+;
		" รายเข้า SQL Server แล้ว ต้องการนำเข้าเพิ่มเติมหรือไม่",4+32+256,"Info") = 7
		RETURN 
	ENDIF 	
ENDIF 
IF lnMemberExist = -1
	=MESSAGEBOX("ไม่สามารถเชื่อมต่อกับ SQL Server กรุณาแจ้ง Admin",0,"SMG Convert")
	RETURN 
ENDIF 
**********************	
STORE 0 TO lnNew, lnUpdate, lnError, lnDup
SELECT curSmgPolicy
GO TOP 
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 	
	IF checkMember("SMG",policy_no, family_no, no_of_pers)
		lnDup = lnDup + 1
		DELETE 
	ELSE 		
		SCATTER MEMO MEMVAR 
		lcPolicyId = ""
		IF InsertToSQL() = 1
			lnSmgNew = lnSmgNew + 1
		ENDIF 	
		*
		IF insertToMember() = 1
			lnNew = lnNew + 1
			IF m.package = "PADEBIT"
				DO updateDebitCard WITH m.cardno, m.policy_no, m.natid, m.effective, lcPolicyId
			ENDIF 	
		ELSE 
			lnError = lnError + 1	
			lcError = ALLTRIM(m.cardno)+","+ALLTRIM(m.policy_no)+","+ALLTRIM(m.product)+CHR(13)
			=STRTOFILE(lcError, "ERROR_"+ALLTRIM(tcPolicyNo)+".txt",1)
		ENDIF 
	ENDIF 		
ENDSCAN
lcMessage = "SQL Update: "+TRANSFORM(lnUpdate, "@Z 999,999") +CHR(13)+;
	"SQL New: "+TRANSFORM(lnNew, "@Z 999,999") +CHR(13)+;
	"SQL Error: "+TRANSFORM(lnError, "@Z 999,999") +CHR(13)+;		
	"SQL Dup: "+TRANSFORM(lnDup, "@Z 999,999") +CHR(13)+;				
	"SMG New: "+TRANSFORM(lnSmgNew, "@Z 999,999") +CHR(13)+;	
	"Total: "+TRANSFORM(RECCOUNT(), "@Z 999,999") +CHR(13)	
=MESSAGEBOX(lcMessage,0,"SMG Convert")
IF lndup > 0
	SET DELETED OFF 
	BROWSE FOR DELETED()
	COPY TO (lcDupfile) FOR DELETED() TYPE DELIMITED WITH CHARACTER ";" 
	SET DELETED ON 
ENDIF
************************************
FUNCTION InsertToSQL

STORE {} to m.selldate
STORE "PA" TO m.subclass
STORE 1 TO m.productno, m.locationno, m.itemno
STORE "" TO lcStatus, lcOldPol, m.projgroup, m.sellbranch, m.lotno,  m.personno, m.idno, m.creditcardno, ;
	m.datato, m.oldpolicyno, m.filename
lcSQL = "INSERT INTO [cimsdb].[dbo].[smg_member] (policy_no, plancover, cust_id, title, name, surname, sex, birthday, age, " + ;
	"address1, address2, address3, address4, country, postcode, telephone, policy_date, eff_date, exp_date, agent, agency, " + ;
	"medical, premium, refno, reportdate, projcode, personcode, projgroup, sellbranch, selldate, lotno, subclass, personno, "+;
	"idno, creditcardno, datato, insured, grouptype, productno, locationno, itemno, status, oldpolicyno, plan_id, cardid, filename, quono, 	l_update) "+ ;
	"VALUES (?m.policy_no, ?m.product, ?m.natid, ?m.title, ?m.name, ?m.surname, ?m.sex, ?m.birth_date, ?m.age, "+;
		"?m.h_addr1, ?m.h_addr2,?h_city, ?m.h_province, ?m.h_postcode, ?m.h_country, ?m.h_phone, ?m.policy_date, ?m.effective, ?m.expiry, ?m.agent, ?m.agentcy, " + ;
		"?m.overall_limit, ?m.premium, ?m.quotation, ?m.adddate, ?m.package, ?m.family_no, ?m.projgroup, ?m.sellbranch, ?m.selldate, ?m.lotno, ?m.subclass, ?m.personno, "+;
		"?m.idno, ?m.creditcardno, ?m.datato, ?m.policy_group, ?m.customer_type, ?m.productno, ?m.locationno, ?m.itemno, ?m.polstatus, ?m.oldpolicyno, ?m.plan_id, ?m.cardno, "+ ;
		"?filename, ?quotation, ?m.l_update)"
	
=SQLSETPROP(lnConn,"Transactions", 2) && Manual transaction	
lnSucess = SQLEXEC(lnConn, (lcSql))	
IF lnSucess < 0
	= SQLROLLBACK(lnConn) && Rollback insert record
ELSE
	= SQLCOMMIT(lnConn)  && Commit the changes
ENDIF
= SQLSETPROP(lnConn, 'Transactions', 1)  && Auto transactions

RETURN lnSucess	
************************************
FUNCTION insertToMember

lcPolicyId = ""
lcSql = "INSERT INTO [cimsdb].[dbo].[member] ([policy_no], [plan], [natid], [title], [name], [surname], [sex], [birth_date], [age], [h_addr1], [h_addr2], "+ ;
	"[h_city], [h_province], [h_country], [h_postcode], [h_phone], [policy_date], [effective], [expiry], [agent], [agency], [me_cover], [premium], "+ ;
	"[adddate], [customer_id], [package], [branch_code], [l_submit], [no_of_pers], [policy_name], [polstatus], [old_policyno], [plan_id], [cardno], "+ ;
	"[quotation], [l_update], [fund_id], [fundcode], [customer_type], [effective_y], [expried_y], [l_user]) " + ;
	"VALUES (?m.policy_no, ?m.product, ?m.natid, ?m.title, ?m.name, ?m.surname, ?m.sex, ?m.birth_date, ?m.age, ?m.h_addr1, ?m.h_addr2, " + ;
	"?m.h_city, ?m.h_province, ?m.h_country, ?m.h_postcode, ?m.h_phone, ?m.policy_date, ?m.effective, ?m.expiry, ?m.agent, ?m.agentcy, ?m.overall_limit, ?m.premium, " + ;
	"?m.adddate, ?m.customer_id, ?m.package, ?m.branch_code, ?m.l_submit, ?m.no_of_pers, ?m.policy_name, ?m.polstatus, ?m.old_policyno, ?m.plan_id, ?m.cardno, " +;
	"?m.quotation, ?m.l_update, ?m.fund_id, ?m.tpacode, ?m.customer_type, ?m.effective_y, ?m.expried_y, ?l_user)"

=SQLSETPROP(lnConn,"Transactions", 2) && Manual transaction
lnSucess = SQLEXEC(lnConn, (lcSql))	
=SQLEXEC(lnConn, "SELECT SCOPE_IDENTITY()", "policyid")
lcPolicyId = policyid.exp
*
IF lnSucess < 0
	= SQLROLLBACK(lnConn) && Rollback insert record
ELSE
	= SQLCOMMIT(lnConn)  && Commit the changes
ENDIF
= SQLSETPROP(lnConn, 'Transactions', 1)  && Auto transactions

RETURN lnSucess
*****************************************************************
FUNCTION updateToMember

lnFundId = 24
lcFundCode = "SMG"
lcCustID = ALLTRIM(STR(laData[27]))
lcCustType = IIF(laData[29]="PHP", "I", "P")
lcPolStatus = ""
ltExpY = IIF(laData[28]="PADEBIT", DATETIME(YEAR(GOMONTH(laData[19],2)), MONTH(GOMONTH(laData[19],2)),1, 12, 00)-86400, NULL)
lcSql = "UPDATE [cimsdb].[dbo].[member] SET [policy_no] = ?laData[1], [plan] = ?laData[2], [natid] = ?laData[3], "+;
	"[title] = ?laData[4], [name] = ?laData[5], [surname] = ?laData[6], [sex] = ?laData[7], [birth_date] = ?laData[8], "+;
	"[age] = ?laData[9], [h_addr1] = ?laData[10], [h_addr2] = ?laData[11], [h_city] = ?laData[12], [h_province] = ?laData[13], "+;
	"[h_country] = ?laData[14], [h_postcode] = ?laData[15], [h_phone] = ?laData[16], [policy_date] = ?laData[17], [effective] = ?laData[18], "+;
	"[expiry] = ?laData[19], [agent] = ?laData[20], [agency] = ?laData[21], [me_cover] = ?laData[22], [premium] = ?laData[23], "+ ;
	"[adddate] = ?laData[25], [customer_id] = ?lcCustID, [package] = ?laData[28], [branch_code] = ?laData[29], [l_submit] = ?laData[30], "+;
	"[no_of_pers] = ?laData[33], [policy_name] = ?laData[37], [polstatus] = ?laData[42], [old_policyno] = ?laData[43], [plan_id] = ?laData[44], "+;
	[cardno] = ?laData[45], [quotation] = ?laData[47], [l_update] = ?laData[48], [customer_type] = ?lcCustType, [effective_y] = ?laData[18], [expried_y] = ?ltExpY "+;
	"WHERE policy_no = ?laData[1] AND customer_id = ?lcCustID"

=SQLSETPROP(lnConn,"Transactions", 2) && Manual transaction	
lnSucess = SQLEXEC(lnConn, (lcSql))	
IF lnSucess < 0
	= SQLROLLBACK(lnConn) && Rollback insert record
ELSE
	= SQLCOMMIT(lnConn)  && Commit the changes
ENDIF
= SQLSETPROP(lnConn, 'Transactions', 1)  && Auto transactions

RETURN lnSucess	
*****************************************************************
PROCEDURE updateDebitCard
PARAMETERS tcCardNo, tcPolicyNo, tcNatID, ttEffDate, tcPolicyId
*
tcPolicyID = IIF(ISNULL(tcPolicyId), "", tcPolicyID)
IF SEEK(tcCardno, "card2natid", "cardno")
	?tcCardno
	REPLACE card2natid.policy_no WITH tcPolicyNo, ;
		card2natid.policyid WITH tcPolicyId
ELSE 
	INSERT INTO card2natid (fundcode, cardno, policy_no, natid, issuedate, expdate, policyid, l_update) ;
		VALUES ("SMG", tcCardNo, tcPolicyNo, tcNatID, ttEffDate, {}, tcPolicyId, DATETIME())
ENDIF
***********************************************************************************
FUNCTION checkExistMember(tdDate)
WAIT WINDOW "ตรวจสอบมีการนำเข้าข้อมูลของวันที่ "+DTOC(tdDate) NOWAIT 
lnSelect = SELECT()
lcDate = STR(YEAR(tdDate),4)+"-"+STRTRAN(STR(MONTH(tdDate),2), " ", "0")+"-"+STRTRAN(STR(DAY(tdDate),2)," ", "0")
lcSQL = "SELECT [adddate], COUNT(*) AS amount FROM [cimsdb].[dbo].[member] WHERE [adddate] = ?lcDate GROUP BY [adddate]"
lnSucess = SQLEXEC(lnConn, (lcSQL), "curAddMember")
lnCount = 0
IF lnSucess > 0
	IF USED("curAddMember")
		lnCount = curAddMember.amount
	ENDIF 	
ELSE 
	lnCount = -1
ENDIF 
WAIT CLEAR 
USE IN curAddMember
SELECT (lnSelect)
RETURN lnCount	
***********************************************************************************
FUNCTION checkMember(tcFundcode, tcPolicyNo, tnPersonCode, tnPersonNo)

IF EMPTY(tcFundCode) AND EMPTY(tcPolicyNo) AND EMPTY(tnPersonCode) AND EMPTY(tnPersonNo)
	RETURN .T.
ENDIF 	
*	
llRetVal = .T.
lnSelect = SELECT()
lcPersonCode = ALLTRIM(STR(tnPersonCode))

lcSQL = "SELECT [policyid] FROM [cimsdb].[dbo].[member] WHERE [fundcode] = ?tcFundCode AND [policy_no] = ?tcPolicyNo "+;
	"AND [customer_id] = ?lcPersonCode"
lnSucess = SQLEXEC(lnConn, (lcSQL), "curExist")
IF lnSucess > 0
	IF USED("curExist")
		IF RECCOUNT("curExist") = 0
			llRetVal = .F.
		ENDIF 	
	ENDIF 	
ENDIF 
WAIT CLEAR 
USE IN curExist
SELECT (lnSelect)
RETURN llRetVal