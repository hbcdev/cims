SET DELETED ON 
lnConn = gnConn &&SQLCONNECT("CimsDB")
IF lnConn <=0
	=MESSAGEBOX("Cannot connect to SQL Server Please Contact Database Administrator",0)
	RETURN 
ENDIF
lcSourceFile = GETFILE("TXT")
*
IF !USED("card2natid")
	USE cims!card2natid IN 0
ENDIF 	
***************************
SET MULTILOCKS ON 
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
*
lcNoNatFile = ADDBS(JUSTPATH(lcSourceFile))+"ERROR_NATID_"+JUSTFNAME(lcSourceFile)
lcN1File = ADDBS(JUSTPATH(lcSourceFile))+"ERROR_N1_"+JUSTFNAME(lcSourceFile)
lcDupFile = ADDBS(JUSTPATH(lcSourceFile))+"ERROR_"+JUSTFNAME(lcSourceFile)
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
SELECT 0	
lnSelect = SELECT()
CREATE TABLE (lcDbf) FREE (Policy_no V(30), Plan V(30), Cust_id V(20), Title V(20), Name V(40), Surname V(40), sex C(1), dob D, age I, ;
	address1 V(40), address2 V(40), address3 V(40), address4 V(40), country V(40), postcode C(5), telephone V(30), ;
	pol_date T, Eff_date T, Exp_date T, agent V(20), agency V(20), medical Y, netpremium Y, refno V(30), ;
	reportdate D, projcode V(20), personcode I, projgrp V(30), sellbr C(4), selldate D, lotno V(20), ;
	subclass V(20), personno I, idno V(20), creditcard V(20), datato V(20), insured V(60), grouptype C(1), ;
	prodno I, locno I, itemno I, polstatus C(1), oldPolno V(30), plan_id C(8), cardid V(25), filename V(80), quono V(30), l_update T)
*
?lcSourceFile
STORE 0 TO lnNew, lnSmgNew, lnUpdate, lnDup
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 2 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 999,999")+"/"+TRANSFORM(lnLines, "@Z 999,999") AT 25, 45 NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts - 1
		laData[j] = STRTRAN(IIF(AT(";",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(";",lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')		
		DO CASE 
		CASE INLIST(j , 8, 17, 18, 19, 25, 30)
			laData[j] = IIF(ISNULL(laData[j]), {}, laData[j])
			IF EMPTY(laData[j])
				laData[j] = {}
			ENDIF 	
			IF TYPE("laData[j]") = "C"
				laData[j] = CTOD(laData[j])
			ENDIF 				
			IF INLIST(j, 17, 18, 19)
				IF EMPTY(laData[j])
					laData[j] = {}
				ELSE 	
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 16, 00)
				ENDIF 	
			ENDIF 	
		CASE INLIST(j ,9, 22, 23, 27, 33, 39, 40, 41)
			laData[j] = VAL(STRTRAN(laData[j], ",", ""))
		CASE j = 28
			IF laData[28] = "PADEBIT"
				laData[17] = DATETIME(YEAR(laData[17]), MONTH(laData[17]), DAY(laData[17]), 12, 00)
				laData[18] = DATETIME(YEAR(laData[18]), MONTH(laData[18]), DAY(laData[18]), 12, 00)
				laData[19] = DATETIME(YEAR(laData[19]), MONTH(laData[19]), DAY(laData[19]), 12, 00)
			ENDIF
		CASE j = 33	
			IF EMPTY(laData[26])
				laData[24] = ALLTRIM(laData[24])+"-"+STRTRAN(STR(VAL(laData[33]), 4), " ", "0")
			ENDIF 
		ENDCASE
		IF AT(";",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	*
	DO CASE 
	case laData[28] = "PASUPER"
		laData[17] = DATETIME(YEAR(laData[17]), MONTH(laData[17]), DAY(laData[17]), 12, 00)
		laData[18] = DATETIME(YEAR(laData[18]), MONTH(laData[18]), DAY(laData[18]), 12, 00)
		laData[19] = DATETIME(YEAR(laData[19]), MONTH(laData[19]), DAY(laData[19]), 12, 00)
		laData[44] = "SMG1878" 	
		laData[45] = getdebitcard(laData[43], laData[35])
		****************************
		* Check N+1
		IF !EMPTY(ALLTRIM(laData[43]))
			IF checkN1("SMG", laData[43], laData[18])
				lcN1Error = laData[45]+"|"+laData[1]+"|"+TTOC(laData[18])+"|"+TTOC(laData[19])+CHR(13)
				=STRTOFILE(lcN1Error, lcN1File, 1)
			ENDIF 
		ENDIF 		
	CASE laData[28] = "PADEBIT"
		laData[17] = DATETIME(YEAR(laData[17]), MONTH(laData[17]), DAY(laData[17]), 12, 00)
		laData[18] = DATETIME(YEAR(laData[18]), MONTH(laData[18]), DAY(laData[18]), 12, 00)
		laData[19] = DATETIME(YEAR(laData[19]), MONTH(laData[19]), DAY(laData[19]), 12, 00)
		***************************	
		DO CASE 
		CASE laData[22] = 5000
			laData[44] = "SMG1050" 	
		CASE laData[22] = 25000
			laData[44] = "SMG1051" 	
		OTHERWISE 
			laData[44] = "SMG1050"
		ENDCASE	
		laData[45] = getdebitcard(laData[43], laData[35])
		****************************
		* Check N+1
		IF !EMPTY(ALLTRIM(laData[43]))
			IF checkN1("SMG", laData[43], laData[18])
				lcN1Error = laData[45]+"|"+laData[1]+"|"+TTOC(laData[18])+"|"+TTOC(laData[19])+CHR(13)
				=STRTOFILE(lcN1Error, lcN1File, 1)
			ENDIF 
		ENDIF 	
	CASE laData[28] = "PAHLIFE"
		DO CASE 
		CASE  INLIST(laData[2], "PAHLIFE(3แสน)", "PAHLIFE (1,400) 3แสน", "PAHLIFE (4,000) 3แสน", "PAHLIFE (6,370) 3แสน")
			laData[44] = "SMG1498"
		CASE  INLIST(laData[2], "PAHLIFE(5แสน)","PAHLIFE (1,900) 5แสน", "PAHLIFE (5,440) 5แสน", "PAHLIFE (8,650) 5แสน")			
			laData[44] = "SMG1499"
		CASE  INLIST(laData[2], "PAHLIFE(1ล้าน)", "PAHLIFE (3,200) 1ล้าน", "PAHLIFE (9,150) 1ล้าน", "PAHLIFE (14,560) 1ล้าน")			
			laData[44] = "SMG1750"
		CASE  INLIST(laData[2], "PAHLIFE(3ล้าน)", "PAHLIFE (8,200) 3ล้าน", "PAHLIFE (22,880) 3ล้าน", "PAHLIFE (36,400) 3ล้าน")
			laData[44] = "SMG1751"
		CASE  INLIST(laData[2], "PAHLIFE(5ล้าน)", "PAHLIFE (10,900) 5ล้าน", "PAHLIFE (31,180) 5ล้าน", "PAHLIFE (49,600) 5ล้าน")
			laData[44] = "SMG1752"
		OTHERWISE 
			laData[44] = "SMG1753"			
		ENDCASE 	
		laData[45] = STRTRAN(ALLTRIM(laData[24]), "-", "")		
	CASE laData[28] = "PAH"
		DO CASE 
		CASE laData[22] = 50000
			laData[44] = "SMG1440" 	
		CASE laData[22] = 100000
			laData[44] = "SMG1441" 	
		CASE laData[22] = 300000
			IF "3" $ laData[2]
				laData[44] = "SMG1442" 	
			ELSE 	
				laData[44] = "SMG1443" 	
			ENDIF
		OTHERWISE 
			laData[44] = "SMG1440"
		ENDCASE 	
		laData[45] = STRTRAN(ALLTRIM(laData[24]), "-", "")
	CASE laData[28] = "PA กลุ่ม"	
		laData[44] = "SMG1444"	
		laData[45] = STRTRAN(ALLTRIM(laData[24]), "-", "") + ALLTRIM(laData[34])
	CASE UPPER(laData[28]) = "MYFAMILYPA"
		IF laData[2] = "MyFamilyPAChild"
			laData[44] = "SMG1679"
		ELSE 
			laData[44] = "SMG1678"		
		ENDIF 		
		laData[45] = STRTRAN(ALLTRIM(laData[24]), "-", "")
	OTHERWISE 	
		lcPlanId = getPlanID("SMG", laData[2])
		IF ISNULL(lcPlanId)		
			laData[44] = ""
		ELSE 
			laData[44] = lcPlanId
		ENDIF 	
		laData[45] = STRTRAN(ALLTRIM(laData[24]), "-", "")
	ENDCASE 
	laData[2] = IIF(AT("/", laData[2]) <> 0, LEFT(laData[2], AT("/", laData[2])-3), laData[2])
	laData[45] = IIF(INLIST(laData[38],"G", "S"), STRTRAN(ALLTRIM(laData[24]), "-", "") + ALLTRIM(laData[34]), laData[45])
	laData[46] = JUSTFNAME(DBF())
	laData[47] = laData[24]	
	laData[48] = DATETIME()
	laData[37] = IIF(laData[28] = "PADEBIT", ALLTRIM(laData[5])+" "+ALLTRIM(laData[6]), laData[37])
	************************************************
	INSERT INTO (lcdbf) FROM ARRAY laData
	*
	IF checkSmgMember("SMG", policy_no, personcode, personno)
		lnDup = lnDup + 1
		DELETE 
	ENDIF 
ENDFOR 
lcMessage = "SQL New: "+TRANSFORM(RECCOUNT(lnSelect) - lnDup, "@Z 999,999") +CHR(13)+;
	"SQL Dup: "+TRANSFORM(lnDup, "@Z 999,999") +CHR(13)+;				
	"Total: "+TRANSFORM(RECCOUNT(lnSelect), "@Z 999,999") +CHR(13)	
=MESSAGEBOX(lcMessage,0,"SMG Convert")
*
SELECT (lnSelect)
BROWSE 
*
IF lndup > 0
	SET DELETED OFF 
	BROWSE FOR DELETED() TITLE "ข้อมูลที่มีในระบบแล้ว"
	COPY TO (lcDupfile) FOR DELETED() TYPE DELIMITED WITH CHARACTER ";" 
	SET DELETED ON 
ENDIF 		
*
IF MESSAGEBOX("ต้องการให้นำเข้า SQL Server หรือไม่",4+32+256,"Info") = 6
	GO TOP 
	lnMemberExist = checkExistMember(reportdate)
	IF lnMemberExist > 0
		IF MESSAGEBOX("มีการนำเข้าข้อมูลของวันที่ "+DTOC(reportdate)+" จำนวน "+TRANSFORM(lnMemberExist, "@Z 999,999")+;
			" รายเข้า SQL Server แล้ว ต้องการนำเข้าเพิ่มเติมหรือไม่",4+32+256,"Info") = 7
			RETURN 
		ENDIF 	
	ENDIF 
	IF lnMemberExist = -1
		=MESSAGEBOX("ไม่สามารถเชื่อมต่อกับ SQL Server กรุณาแจ้ง Admin",0,"SMG Convert")
		RETURN 
	ENDIF 
	**********************	
	STORE 0 TO lnNew, lnUpdate, lnError, lnDup, lnNoNatID
	SCAN 
		WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 	
		IF checkSmgMember("SMG",policy_no,personcode,personno)
			lnDup = lnDup + 1
			DELETE 
		ELSE 		
			if empty(cust_id)
				lnNoNatID = lnNoNatID + 1
			endif	
			********************************				
			SCATTER TO laData	
			lcPolicyId = ""
			IF InsertSmgToSQL() = 1
				lnSmgNew = lnSmgNew + 1
			ENDIF 	
			*
			IF insertSmgToMember() = 1
				lnNew = lnNew + 1
				IF laData[28] = "PADEBIT"
					DO updateDebitCard WITH laData[45], laData[1], laData[3], laData[18], lcPolicyId && cardno, policy_no, natid, eff_Date
				ENDIF 	
			ELSE 
				lnError = lnError + 1	
				lcError = ALLTRIM(laData[45])+","+ALLTRIM(laData[1])+","+ALLTRIM(laData[3])+CHR(13)
				=STRTOFILE(lcError, STRTRAN(lcDbf,".DBF","_error.txt"),1)
			ENDIF 
		ENDIF 		
	ENDSCAN
	lcMessage = "Member Update: "+TRANSFORM(lnUpdate, "@Z 999,999") +CHR(13)+;
		"Member New: "+TRANSFORM(lnNew, "@Z 999,999") +CHR(13)+;
		"Member Error: "+TRANSFORM(lnError, "@Z 999,999") +CHR(13)+;		
		"Member Dup: "+TRANSFORM(lnDup, "@Z 999,999") +CHR(13)+;				
		"SMG New: "+TRANSFORM(lnSmgNew, "@Z 999,999") +CHR(13)+;	
		"No Nat ID: "+TRANSFORM(lnNoNatId, "@Z 999,999") +CHR(13)+;	
		"Total: "+TRANSFORM(RECCOUNT(lnSelect), "@Z 999,999") +CHR(13)	
	=MESSAGEBOX(lcMessage,0,"SMG Convert")
	
	if lnNoNatId > 0
		BROWSE FOR empty(cust_id) title "No Nat Id"
		COPY TO (lcNoNatFile) FOR empty(cust_id) TYPE DELIMITED WITH CHARACTER ";" 
	endif 		
	
	IF lndup > 0
		SET DELETED OFF 
		BROWSE FOR DELETED() title "Dupicate Policy" 
		COPY TO (lcDupfile) FOR DELETED() TYPE DELIMITED WITH CHARACTER ";" 
		SET DELETED ON 
	ENDIF 	
ENDIF
************************************
FUNCTION getPlanId(tcFundcode, tcPlan)

IF EMPTY(tcFundCode) AND EMPTY(tcPlan)
	RETURN null
ENDIF 
lcRetVal = null
SELECT IIF(EMPTY(same_as), plan_id, same_as) ;
FROM cims!plan ;
WHERE plan_id = tcFundCode ;
	AND title = ALLTRIM(tcPlan) ;
INTO ARRAY laPlanID
IF _TALLY > 0
	lcRetVal = laPlanID[1]
ENDIF 
RETURN lcRetVal
*
************************************
FUNCTION InsertSmgToSQL

lcSQL = "INSERT INTO [cimsdb].[dbo].[smg_member] (policy_no, plancover, cust_id, title, name, surname, sex, birthday, age, " + ;
	"address1, address2, address3, address4, country, postcode, telephone, policy_date, eff_date, exp_date, agent, agency, " + ;
	"medical, premium, refno, reportdate, projcode, personcode, projgroup, sellbranch, selldate, lotno, subclass, personno, idno, creditcardno, " + ;
	"datato, insured, grouptype, productno, locationno, itemno, status, oldpolicyno, plan_id, cardid, filename, quono, 	l_update) "+ ;
	"VALUES (?laData[1], ?laData[2], ?laData[3], ?laData[4], ?laData[5], ?laData[6], ?laData[7], ?laData[8], ?laData[9], ?laData[10], ?laData[11], " + ;
	"?laData[12], ?laData[13], ?laData[14], ?laData[15], ?laData[16], ?laData[17], ?laData[18], ?laData[19], ?laData[20], ?laData[21], ?laData[22], " + ;
	"?laData[23], ?laData[24], ?laData[25], ?laData[26], ?laData[27], ?laData[28], ?laData[29], ?laData[30], ?laData[31], ?laData[32], ?laData[33], "+ ;
	"?laData[34], ?laData[35], ?laData[36], ?laData[37], ?laData[38], ?laData[39], ?laData[40], ?laData[41], ?laData[42], ?laData[43], ?laData[44], " + ;
	"?laData[45], ?laData[46], ?laData[47], ?laData[48])"
	
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
FUNCTION insertSmgToMember

lnFundId = 24
lcFundCode = "SMG"
lcCustID = ALLTRIM(STR(laData[27]))
lcCustType = IIF(laData[29]="PHP", "I", "P")
lcPolStatus = ""
lcPolicyId = ""
ltExpY = IIF(laData[28]="PADEBIT", DATETIME(YEAR(GOMONTH(laData[19],2)), MONTH(GOMONTH(laData[19],2)),1, 12, 00)-86400, laData[19])
lcSql = "INSERT INTO [cimsdb].[dbo].[member] ([policy_no], [plan], [natid], [title], [name], [surname], [sex], [birth_date], [age], [h_addr1], [h_addr2], "+ ;
	"[h_city], [h_province], [h_country], [h_postcode], [h_phone], [policy_date], [effective], [expiry], [agent], [agency], [me_cover], [premium], "+ ;
	"[adddate], [customer_id], [package], [branch_code], [l_submit], [no_of_pers], [policy_name], [polstatus], [old_policyno], [plan_id], [cardno], "+ ;
	"[quotation], [l_update], [fund_id], [fundcode], [customer_type], [effective_y], [expried_y], [l_user]) " + ;
	"VALUES (?laData[1], ?laData[2], ?laData[3], ?laData[4], ?laData[5], ?laData[6], ?laData[7], ?laData[8], ?laData[9], ?laData[10], ?laData[11], " + ;
	"?laData[12], ?laData[13], ?laData[14], ?laData[15], ?laData[16], ?laData[17], ?laData[18], ?laData[19], ?laData[20], ?laData[21], ?laData[22], ?laData[23], " + ;
	"?laData[25], ?lcCustID, ?laData[28], ?laData[29], ?laData[30], ?laData[33], ?laData[37], ?lcPolStatus, ?laData[43], ?laData[44], ?laData[45], " +;
	"?laData[47], ?laData[48], ?lnFundId, ?lcFundCode, ?lcCustType, ?laData[18], ?ltExpY, ?gcUserName)"

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
FUNCTION updateSmgToMember

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
	"[cardno] = ?laData[45], [quotation] = ?laData[47], [l_update] = ?laData[48], [customer_type] = ?lcCustType, [effective_y] = ?laData[18], [expried_y] = ?ltExpY "+;
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
SELECT (lnSelect)
RETURN lnCount	
***********************************************************************************
FUNCTION checkSmgMember(tcFundcode, tcPolicyNo, tnPersonCode, tnPersonNo)

IF EMPTY(tcFundCode) AND EMPTY(tcPolicyNo) AND EMPTY(tnPersonCode) AND EMPTY(tnPersonNo)
	RETURN .T.
ENDIF 	
*	
llRetVal = .T.
lnSelect = SELECT()
lcPersonCode = ALLTRIM(STR(tnPersonCode))

lcSQL = "SELECT [policyid] FROM [cimsdb].[dbo].[member] WHERE [fundcode] = ?tcFundCode AND [policy_no] = ?tcPolicyNo "+;
	"AND [customer_id] = ?lcPersonCode AND no_of_pers = ?tnPersonNo"
lnSucess = SQLEXEC(lnConn, (lcSQL), "curExist")
IF lnSucess > 0
	IF USED("curExist")
		IF RECCOUNT("curExist") = 0
			llRetVal = .F.
		ENDIF 	
		USE IN curExist		
	ENDIF 	
ENDIF 
WAIT CLEAR 
SELECT (lnSelect)
RETURN llRetVal
************************************************************************
function getDebitCard(tcPolicyNo, tcCardNo)

* if have old policy no use it to find card no is not x char and last 4 digit match to this card no when not replace it to this policy
lcCardNo = getCardNo(tcPolicyNo)			
if empty(lcCardNo) 
	lcCardNo = tcCardNo
else
	if substr(lcCardNo,13,4) <> substr(tcCardNo,13,4)
		lcCardNo = tcCardNo
	endif
endif 	
return lcCardNo