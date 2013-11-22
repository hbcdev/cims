SELECT pay.policy_no, MAX(pay.period) FROM d:\hips\data\bki_073_payment pay GROUP BY 1 INTO CURSOR curMaxPeriod

SELECT curMaxPeriod.policy_no, ALLTRIM(member.name)+" "+ALLTRIM(member.surname) AS insure, curMaxPeriod.max_period, ;
	member.product AS plan, member.effective, member.expiry, member.polstatus, member.adjcancel AS canceldate, member.package, member.age ;
FROM curMaxPeriod INNER JOIN cims!member ;
	ON curMaxPeriod.policy_no = member.policy_no ;
INTO CURSOR curbki
*
SELECT pay.policy_no, pay.period, pay.premium, pay.paiddate FROM d:\hips\data\bki_073_payment pay WHERE !EMPTY(paiddate) INTO CURSOR curpay

SELECT curbki.*, curpay.premium, curpay.period, curpay.paiddate FROM curbki INNER JOIN curpay ON curbki.policy_no = curpay.policy_no INTO CURSOR curFeeData

SELECT curFeeData.*, (12/curFeeData.max_period)*curFeeData.period AS month_cover, GOMONTH(curFeeData.effective, (12/curFeeData.max_period)*curFeeData.period) AS expdate ;
FROM curFeeData ;
INTO CURSOR curFee1

SELECT policy_no, insure, plan, age, max_period, effective, expiry, polstatus, canceldate, premium, MAX(month_cover) AS month_cover, MAX(period) AS period ;
FROM curfee1 ;
GROUP BY policy_no, insure, plan, age, max_period, effective, expiry, polstatus, canceldate, premium ;
INTO CURSOR curfee2

SELECT curfee2.policy_no, curfee2.insure, curfee2.age, curfee2.plan, curfee2.effective, curfee2.expiry, curfee2.polstatus, curfee2.canceldate, ;
curfee2.max_period, curfee2.premium, curfee2.month_cover, curfee2.period, GOMONTH(curFee2.effective, (12/curFee2.max_period)*curFee2.period) AS expdate ;
FROM curfee2 ORDER BY curfee2.effective ;
INTO CURSOR curfee

lcFile =  STR(YEAR(GOMONTH(DATE(),-1)),4)+"-"+STRTRAN(STR(MONTH(GOMONTH(DATE(),-1)),2)," ", "0")+"_BKI_Fee"
COPY TO ("d:\report\bki\"+lcFile) TYPE XL5 
BROWSE 
