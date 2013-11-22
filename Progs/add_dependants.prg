PARAMETERS lcFundCode
LOCAL  lcTable
IF EMPTY(lcFundcode)
	RETURN
ENDIF
***************
CLOSE ALL
lcTable = GETFILE("DBF", "Enter File To Add")
IF EMPTY(lcTable)
	RETURN
ENDIF
USE cims!dependants IN 0
USE (lcTable) IN 0 ALIAS memb
SELECT memb
SCAN
	WAIT WINDOW name NOWAIT 
	lcPersonNo = lcfundCode+policy_no+STR(no)
	IF !SEEK(lcPersonNo, "dependants", "person_no")
		APPEND BLANK IN dependants
	ENDIF
	REPLACE dependants.fundcode WITH lcFundCode,;
		dependants.policy_no WITH policy_no,;
		dependants.person_no WITH no,;
		dependants.client_no WITH cust_id,;
		dependants.title WITH title,;
		dependants.name WITH name,;
		dependants.surname WITH surname,;
		dependants.plan WITH plan,;
		dependants.plan_id WITH plan_id,;
		dependants.effective WITH effective,;
		dependants.expired WITH expiry,;
		dependants.dob WITH dob,;
		dependants.sex WITH sex,;
		dependants.age WITH age,;
		dependants.premium WITH premium,;
		dependants.medical WITH medical,;
		dependants.status WITH "A",;
		dependants.l_update WITH DATETIME()
ENDSCAN		
USE IN memb
