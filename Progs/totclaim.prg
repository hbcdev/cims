SELECT SUM(IIF(Claim_Type=2,1,0))one,SUM(IIF(Claim_Type=1,1,0))Three,;
	SUM(IIF(INLIST(Claim_Type,1,2),1,0)) Five FROM Rollclaim INTO CURSOR Temp1
SELECT Name,SUM(IIF(Claim_Type=2,1,0)) A,SUM(IIF(Claim_Type=1,1,0))C,; 
SUM(IIF(INLIST(Claim_Type,1,2),1,0))E ;
FROM Rollclaim GROUP BY Name ORDER BY Name INTO cursor Temp2

REPORT FORM totclaim PREVIEW