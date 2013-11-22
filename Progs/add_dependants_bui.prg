LOCAL  lcTable
CLOSE ALL
SET EXCLUSIVE OFF 
***************************************************
gcDataPath = "g:\hips\data\"
lcError = ""
lcfundCode = "BUI"
lcCover = ADDBS(gcDataPath)+"bui_coverage"
lcPattern = ADDBS(gcDataPath)+"bui_pattern"
lcTable = GETFILE("DBF", "Enter File To Add")
IF EMPTY(lcTable)
	RETURN
ENDIF
IF !FILE(lcCover+".DBF")
	RETURN 
ENDIF 	
******************************
USE cims!plan IN 0
USE cims!dependants IN 0
USE cims!member IN 0
USE (lcCover) IN 0 ALIAS coverage
USE (lcTable) IN 0 ALIAS memb
*********************************************************
SELECT memb
IF !SEEK("BUI"+policy_no, "member", "policy_no")
	lcPolicyGrp = INPUTBOX("ชื่อบริษัทผู้เอาประกัน ", "ไม่พบกรมธรรม์นี้ ")
ENDIF 
***********************************
SCAN
	WAIT WINDOW name NOWAIT 
	lcPlan = LEFT(plan,10)
	lcPlanID = ""
	IF LEFT(plan,1) = "4"
		IF SEEK(LEFT(plan,10), "coverage", "i_coverage")
			lcPlan = coverage.c_coverage
		ENDIF 
	ENDIF 			
	******************************************************
	IF SEEK(LEFT(plan,10), "plan", "title")
		IF EMPTY(plan.same_as)
			lcPlanID = plan.plan_id
		ELSE 
			lcPlanID = plan.same_as
		ENDIF 		
	ELSE 
		IF AT(ALLTRIM(plan),lcError) = 0
			lcError = lcError+ALLTRIM(plan)+CHR(13)
		ENDIF 	
		=STRTOFILE(ALLTRIM(plan)+CHR(13), "bui_error.txt", 1)
	ENDIF 		 
	*****************************************************
	lcPersonNo = lcFundCode+policyno+STR(no)
	IF !SEEK(lcPersonNo, "dependants", "person_no")
		APPEND BLANK IN dependants
	ENDIF 	
	REPLACE dependants.fundcode WITH lcFundCode,;
		dependants.policy_no WITH policyno,;
		dependants.person_no WITH no,;
		dependants.name WITH name,;
		dependants.plan WITH lcPlan,;
		dependants.i_plan WITH plan,;
		dependants.plan_id WITH lcPlanID,;
		dependants.effective WITH effective,;
		dependants.expired WITH expired,;
		dependants.l_user WITH UPPER(ALLTRIM(SUBSTR(SYS(0), AT("#", SYS(0))+1))),;
		dependants.l_update WITH DATETIME()
ENDSCAN
IF !EMPTY(lcError)
	=STRTOFILE(lcError, "bui_err.txt")
ENDIF
IF FILE("bui_err.txt")
	MODIFY FILE bui_err.txt
ENDIF 	
USE IN memb
