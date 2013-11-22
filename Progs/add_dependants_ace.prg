LOCAL  lcTable
******************
CLOSE ALL
OPEN DATABASE \\dragon\hips\data\cims.dbc
lcFundCode = "ACE"
lcTable = GETFILE("DBF", "Enter ACE Group Member File To Add/Update")
IF EMPTY(lcTable)
	RETURN
ENDIF
lcFile = STRTRAN(lcTable, ".DBF", ".TXT")
IF FILE(lcFile)
	DELETE FILE &lcFile
ENDIF 
SET MULTILOCKS ON 
*************************	
USE cims!plan IN 0
USE cims!policy2plan IN 0
USE cims!dependants IN 0
USE (lcTable) IN 0 ALIAS memb
=CURSORSETPROP("Buffering",5,"dependants")
lnNew = 0
lnNew1 = 0
ldAddDate = {}
SELECT memb
SCAN
	WAIT WINDOW name NOWAIT 
	lcPolNo = IIF(LEN(policy_no) < 30, policy_no+SPACE(30-LEN(policy_no)), policy_no)
	lcClient = IIF(LEN(cert_no) < 20, cert_no+SPACE(20-LEN(cert_no)), cert_no)
	lcClientNo = lcFundCode+lcPolNo+lcClient+plan
	IF !SEEK(lcClientNo, "dependants", "clientplan")
		APPEND BLANK IN dependants
		lnNew = lnNew + 1
		ldAddDate = DATE()
		lnPersonNo = Getpersonno(lcFundCode, lcPolNo)+lnNew
		=STRTOFILE("Add "+ALLTRIM(policy_no)+" "+ALLTRIM(cert_no)+" "+ALLTRIM(name)+" "+ALLTRIM(surname)+" "+plan+CHR(13), lcFile, 1)
	ELSE 
		lnPersonNo = dependants.person_no
		ldAddDate = dependants.adddate
		=STRTOFILE("Update "+ALLTRIM(policy_no)+" "+ALLTRIM(cert_no)+" "+ALLTRIM(name)+" "+ALLTRIM(surname)+" "+plan+CHR(13), lcFile, 1)
	ENDIF
	*****************************************************************
	lcPlan = "ACE" + policy_no + IIF(LEN(ALLTRIM(plan)) < 20, ALLTRIM(plan)+SPACE(20-LEN(ALLTRIM(plan))), ALLTRIM(plan))
	IF SEEK(lcPlan, "policy2plan", "pol_plan")
		lcPlanID = policy2plan.plan_id
	ELSE 
		lcPlanID = ""	
	ENDIF 	
*!*		IF SEEK(lcPlan, "plan", "plan")
*!*			lcPlanID = plan.plan_id
*!*			lcPlanID = IIF(policy_no = "G0000001" AND lcPlanID = "ACE0729", "ACE0899", lcPlanID)
*!*			lcPlanID = IIF(policy_no = "G0000001" AND lcPlanID = "ACE0728", "ACE0900", lcPlanID)
*!*			lcPlanID = IIF(policy_no = "G0000102" AND lcPlanID = "ACE0729", "ACE0899", lcPlanID)
*!*			lcPlanID = IIF(policy_no = "G0000102" AND lcPlanID = "ACE0728", "ACE0900", lcPlanID)
*!*			lcPlanID = IIF(policy_no = "G0000005" AND lcPlanID = "ACE0729", "ACE0802", lcPlanID)						
*!*		ELSE 
*!*			lcPlanID = ""	
*!*		ENDIF 
	*****************************************************************
	ldEff = IIF(member_eff > policy_iss, member_eff, policy_iss)	
	ldExp =  IIF(member_exp < pol_exp, member_exp,  pol_exp)
	ldExp = IIF(ldExp < ldEff, pol_exp, ldExp)
	ldPolStart = IIF(EMPTY(dependants.policy_start), tdate2e(member_eff), IIF(TTOD(dependants.policy_start) > member_eff, tdate2e(member_eff), dependants.policy_start))	
	*****************************************************************
	REPLACE dependants.fundcode WITH lcFundCode, ;
		dependants.policy_no WITH policy_no, ;
		dependants.person_no WITH lnPersonNo, ;
		dependants.client_no WITH cert_no, ;
		dependants.title WITH title, ;
		dependants.name WITH name, ;
		dependants.surname WITH surname, ;
		dependants.plan WITH ALLTRIM(plan), ;
		dependants.plan_id WITH lcPlanID, ;
		dependants.policy_date WITH Tdate2E(member_eff), ;
		dependants.effective WITH Tdate2E(ldEff), ;
		dependants.expired WITH Tdate2e(ldExp), ;
		dependants.policy_start WITH ldPolStart, ;
		dependants.policy_end WITH Tdate2e(member_exp), ;
		dependants.dob WITH IIF(EMPTY(dob), dependants.dob, dob), ;
	 	dependants.sex WITH sex, ;
		dependants.nat_id WITH IIF(EMPTY(id_no), dependants.nat_id, id_no), ;
		dependants.employee WITH employee, ;
		dependants.premium WITH prem_opd+prem_ipd, ;
		dependants.address WITH "", ;
		dependants.cause4 WITH TRANSFORM(prem_ipd, "99999"), ;
		dependants.cause5 WITH TRANSFORM(prem_opd, "99999"), ;	
		dependants.name1 WITH remark, ;	
		dependants.adddate WITH IIF(EMPTY(ldAddDate), dependants.adddate, ldAddDate), ;
		dependants.l_user WITH "VACHARA", ;
		dependants.l_update WITH DATETIME()
ENDSCAN		
USE IN memb
SELECT dependants

FUNCTION tdate2e(tdDate)
IF YEAR(tdDate) > 2500
	ldDate = DATETIME(YEAR(tdDate)-543, MONTH(tdDate), DAY(tdDate), 00, 00)
ELSE 
	ldDate = DTOT(tdDate)
ENDIF 
RETURN ldDate
	






