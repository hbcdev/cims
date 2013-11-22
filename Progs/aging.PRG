SELECT LEFT(plan,2) plan, ;
	(return_date-TTOD(notify_date))-holidays(TTOD(notify_date), return_date) AS amt_time, COUNT(*) ;
FROM cims!claim ;
WHERE fundcode = gcFundCode ;
	AND TTOD(notify_date) BETWEEN gdStartDate AND gdEndDate ;
	AND INLIST(LEFT(result,1), "P", "D") ;
	AND result <> "P5" ;
	AND EMPTY(unclean) ;
	AND INLIST(claim_with, "I", "P") ;
GROUP BY 1, 2 ;
ORDER BY 1, 2 ;
INTO DBF (ADDBS(gcTemp)+"aging")
