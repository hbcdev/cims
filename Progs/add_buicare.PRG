LOCAL  lcTable
CLOSE ALL
SET EXCLUSIVE OFF 
SET MULTILOCKS ON 
IF FILE("bui_err.txt")
	DELETE FILE bui_err.txt
ENDIF 	
***************************************************
gcDataPath = "\\dragon1\hips\data\"
lcError = ""
lcfundCode = "BUI"
lcTable = GETFILE("DBF", "Enter File To Add")
IF EMPTY(lcTable)
	RETURN
ENDIF
******************************
OPEN DATABASE \\dragon1\hips\data\cims
USE member IN 0
USE plan IN 0
USE dependants IN 0
USE (lcTable) IN 0 ALIAS memb
=CURSORSETPROP("Buffering",5,"dependants")
***********************************
SELECT memb
*
lcPlanID = ""
SELECT memb
IF !SEEK("BUI"+policy_no, "member", "policy_no")
	lcPolicyGrp = fullname
	SCATTER FIELDS policy_no, eff_date, exp_date, old_pol MEMVAR 
	INSERT INTO cims!member (fund_id, tpacode, customer_type, policy_no, policy_name, effective, expiry, agent, renew) ;
		VALUES (10, "BUI", "T", m.policy_no, lcPolicyGrp, eff_date, exp_date, old_pol, renew)
ENDIF 
************************
SELECT memb
SCAN
	IF LEFT(plan,5) = "41338"
		WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
		****************************
		IF SEEK(plan, "plan", "title")	
			lcPlanID = IIF(EMPTY(plan.same_as), plan.plan_id, plan.same_as)
			lcPlan = ALLTRIM(plan.description)
		ELSE 
			lcPlanID = ""
			lnPlan = ""	
		ENDIF 	
		*************************
		IF !SEEK("BUI"+policy_no, "member", "policy_no")
			lcPolicyGrp = fullname
			SCATTER FIELDS policy_no, eff_date, exp_date, old_pol MEMVAR 
			INSERT INTO cims!member (fund_id, tpacode, customer_type, policy_no, policy_name, effective, expiry, cause1, renew) ;
				VALUES (10, "BUI", "T", m.policy_no, lcPolicyGrp, eff_date, exp_date, old_pol, renew)
		ENDIF 
		*****************************************************
		lcPersonNo = "BUI"+policy_no+STR(n_no)
		IF !SEEK(lcPersonNo, "dependants", "person_no")
			APPEND BLANK IN dependants
		ENDIF 	
		REPLACE dependants.fundcode WITH lcFundCode,;
			dependants.policy_no WITH policy_no,;
			dependants.person_no WITH n_no,;
			dependants.client_no WITH cust_id, ;
			dependants.name WITH LTRIM(fullname),;
			dependants.plan WITH lcPlan,;
			dependants.plan_id WITH lcPlanID,;
			dependants.effective WITH Eff_date,;
			dependants.expired WITH Exp_date,;
			dependants.age WITH age,;
			dependants.sex WITH ICASE(sex = "Y", "M", sex = "N", "F", sex), ;
			dependants.cause1 WITH old_pol, ;
			dependants.renew WITH renew, ;
			dependants.notation WITH IIF(EMPTY(old_pol), "", "ต่ออายุจากกรมธรรม์เลขที่ "+ALLTRIM(old_pol)), ;
			dependants.l_user WITH UPPER(ALLTRIM(SUBSTR(SYS(0), AT("#", SYS(0))+1))),;
			dependants.l_update WITH DATETIME()
	ENDIF 		
ENDSCAN
	
USE IN memb
SELECT  dependants
