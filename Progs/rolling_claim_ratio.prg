SELECT A.product, SUM(A.premday*A.daycover) gpe;
FROM rollmember A ;
GROUP BY A.product;
INTO CURSOR pe
*
SELECT A.product, SUM(B.fbenfpaid) ci;
FROM rollmember A, rollclaim B;
WHERE A.customer_i = B.customer_i;
GROUP BY A.product;
INTO CURSOR ci

*SELECT A.product, A.prem_earned, B.claim_incurred,;
*	B.claim_incurred/A.prem_earned AS gcr,;
*	(A.prem_earned*.65)/B.claim_incurred AS ncr;
*FROM p_earned A, clm_ratio B;
*WHERE A.product = B.product;
*ORDER BY A.product;
*INTO CURSOR rcr

REPORT FORM rolling_claim_ratio PREVIEW