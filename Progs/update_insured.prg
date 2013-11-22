LOCAL lcTable,lcFundcode

lcFundCode = INPUTBOX("Enter Fund Code", "Summit")
IF EMPTY(lcFundCode)
	RETURN
ENDIF
lcTable = GETFILE("DBF", "Enter Source To update")
IF EMPTY(lcTable)
	RETURN
ENDIF
CLOSE ALL
USE (lcTable) IN 0 ALIAS src
USE cims!member IN 0
SELECT src
SCAN
	IF SEEK(lcFundCode+policy_no, "member", "policy_no")
		WAIT WINDOW "Update Policy "+member.policy_no NOWAIT
		REPLACE  member.insure WITH insure,;
			member.premium WITH permium
	ENDIF 
ENDSCAN
			 