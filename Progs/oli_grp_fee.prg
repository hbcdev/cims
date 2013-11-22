gtStartDate = {^2005-06-01}
gtEndDate = {^2005-06-30}

SELECT person_no AS cerno, name, surname, plan, premium, ;
	TTOD(effective) AS eff_date, TTOD(expired) AS exp_date, ;
	IIF(MONTH(l_update) > MONTH(gdEndDate), "N", "I") AS status ;
FROM cims!dependants ;
WHERE fundcode = "OLI" ;
INTO CURSOR _curMember
*
SELECT cerno, name, surname, plan, premium, eff_date, exp_date, status, ;
	IIF(eff_date >= gtStartDate AND eff_date <= gtEndDate, eff_date, IIF(eff_date <= gtStartDate AND exp_date >= gtStartDate, gtStartDate, {})) AS eff, ;
	IIF(exp_date >= gtEndDate, gtEndDate, IIF(exp_date >= gtStartDate AND exp_date <= gtEndDate, exp_date, {})) AS exp ;
 FROM _curMember ;
INTO CURSOR _curMemb1
*
SELECT cerno, name, surname, plan, premium, eff_date, exp_date, status, eff, exp, ;
	IIF(EMPTY(eff), 0, 1) AS counts, (exp-eff)+1 AS days ;
FROM _curMemb1 ;
INTO CURSOR _curMemb2
	
	
	

