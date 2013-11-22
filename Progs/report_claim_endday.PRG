gcUserName = "CHANUNTI"
gtStartDate = {^2011-06-16 00:00}
gtEndDate = {^2011-06-16 23:59}
*
SELECT result, COUNT(*) AS cnt ;
FROM cims!claim ;
WHERE (assessor_by = gcUserName AND assessor_date BETWEEN gtStartDate AND gtEndDate) ;
	OR (fax_by = gcUserName AND fax_date BETWEEN gtStartDate AND gtEndDate) ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR curAssess
*
SELECT record_by, COUNT(*) AS cnt ;
FROM cims!notify ;
WHERE record_by = gcUserName AND record_date BETWEEN gtStartDate AND gtEndDate ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR curNotify
*
SELECT record_by, COUNT(*) AS cnt ;
FROM cims!notify_log ;
WHERE record_by = gcUserName AND record_date BETWEEN gtStartDate AND gtEndDate ;
GROUP BY 1 ;
ORDER BY 1 ;
INTO CURSOR curLog



