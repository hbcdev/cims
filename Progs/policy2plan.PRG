PARAMETERS tcFundcode, tcOldPol, tcNewPol

IF !USED("policy2plan")
	USE cims!policy2plan IN 0 
ENDIF 
SELECT * ;
FROM cims!policy2plan ;
WHERE fundcode = tcFundCode ;
	AND policy_no = tcOldPol ;
INTO CURSOR curOldPol
IF _TALLY = 0
	RETURN 
ENDIF 		

SELECT curOldPol
SCAN 
	SCATTER MEMVAR
	m.policy_no = tcNewPol
	m.eff_date = DATETIME(YEAR(m.eff_date)+1, MONTH(m.eff_date), DAY(m.eff_date), 00, 00)	
	m.exp_date = DATETIME(YEAR(m.exp_date)+1, MONTH(m.exp_date), DAY(m.exp_date), 00, 00)
	INSERT INTO cims!policy2plan FROM MEMVAR 
ENDSCAN 
USE IN curOldPol