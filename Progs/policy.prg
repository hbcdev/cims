SELECT m.Product A,COUNT(*)B,SUM(IIF(C.Claim_Type=1,1,0))C,SUM(IIF(C.Claim_Type=2,1,0))e ;
FROM Rollmember m,RollClaim C ;
WHERE m.Customer_i = c.Customer_i ;
GROUP BY A ORDER BY A INTO cursor Temp2

REPORT FORM policy PREVIEW