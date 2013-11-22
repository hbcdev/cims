SELECT Name,SUM(IIF(Claim_Type=2,fCharge,0)) A,SUM(IIF(Claim_Type=2,fbenfpaid,0)) B, ;
	SUM(IIF(Claim_Type=1,fCharge,0)) D,SUM(IIF(Claim_Type=1,fbenfpaid,0)) E ;
FROM Rollclaim GROUP BY Name ORDER BY Name INTO cursor Temp1
*
REPORT FORM charge PREVIEW
*
USE IN Temp1