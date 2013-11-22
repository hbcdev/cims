PARAMETERS tcPolicyNo, tdEffDAte, tdExpDate, tdVoidDate

IF !USED("member")
	USE cims!member ORDER policy
ENDIF 

IF SEEK(tcPolicyNo)
	SCATTER MEMO MEMVAR
	REPLACE status WITH "C", adj_plan_date WITH tdVoidDate
	*
	m.effective = tdEffDate
	m.expiry = tdExpDate
	m.cause11 = ""
	m.cause12 = ""
	APPEND BLANK 
	GATHER MEMO MEMVAR 
ENDIF 	
	 
		

