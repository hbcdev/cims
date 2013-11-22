SET DELE ON
SELECT *;
FROM cims!wt;
WHERE wt_no BETWEEN gcStartNo AND gcEndNo;
	AND total <> 0;
	AND tax <> 0;
ORDER BY wt_no;
INTO CURSOR wtReport1
SELECT wt_no, wt_date, fund_taxid, paid_to, address, prov_taxid, total, wt, tax, ;
	IIF(MOD(RECNO(),10) = 0, INT(RECNO()/10), INT(RECNO()/10)+1) as page ;
FROM wtreport1 ;
INTO CURSOR wtreport	
SELECT wtReport