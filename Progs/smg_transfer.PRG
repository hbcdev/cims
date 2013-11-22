lcOldDir = SYS(5)+SYS(2003)
lnDay = IIF(DAY(DATE()) > 15, 1, 16)
*
gcFundCode = "SMG"
gdEndDate = DATE() 
gdStartDate = gdEndDate - 15
gnOption = 1
gdSendDate = DATE(YEAR(DATE()), MONTH(DATE())+IIF(lnDay = 1, 1, 0), lnDay)
gdPayDate = gdSendDate + (10 + holidays(gdSendDate, gdSendDate+10))
gcSaveTo = ADDBS(gcTemp)+gcFundCode+"\"
DO FORM form\SMG_Return_Data
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
*
SELECT claim.notify_no, claim.notify_date, claim.policy_no, claim.family_no, claim.client_name, claim.service_type, ;
	claim.claim_no, claim.effective, claim.expried, claim.plan, claim.acc_date, claim.admis_date, claim.disc_date, ;
	STRTRAN(claim.customer_id, "SMG", "") AS cust_id, claim.prov_name,  ;
	claim.illness1, claim.result, claim.scharge, claim.sdiscount, claim.sbenfpaid, ;
	claim.snote, claim.return_date, claim.note2ins, claim.paid_date, ;
	claim.tr_acno, claim.tr_name, claim.tr_bank, claim.tr_banch, ;
	pv.pv_no, pv.pv_date, pv.tr_date ;
FROM cims!claim INNER JOIN cims!pv ;
	ON claim.pvno = pv.pv_no ;
WHERE claim.fundcode = gcFundCode AND pv.pv_date BETWEEN gdStartDate AND gdEndDate ;
ORDER BY pv.pv_no ;
INTO CURSOR curClaimReturn

IF _TALLY = 0
	RETURN 
ENDIF 	
**************************
*
* Create Reimbuest Data file
WAIT WINDOW "Generate Reimbuest Data File" NOWAIT 

SELECT * FROM curClaimReturn WHERE result = "P61" ORDER BY tr_date, pv_no INTO CURSOR curClaimList

IF _TALLY = 0
	RETURN 
ENDIF 
lcPath = ADDBS(gcSaveTo)
m.paydate = gdPayDate
m.lotno = "R_" + STRTRAN(STR(DAY(gdSendDate), 2), " ", "0") + STRTRAN(STR(MONTH(gdSendDate), 2), " ", "0") + STRTRAN(STR(YEAR(gdSendDate), 4), " ", "0")
lcClmHead = "JCNGA_" + m.lotno
lcClmDetail = "JANGAD_" + m.lotno
**********************
DO CreateTable
**********************
SELECT curClaimList
DO WHILE !EOF()
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 99,999") NOWAIT 
	ldPaidDate = tr_date
	m.batchno = "R"+SUBSTR(newdateno("R", gdSendDate), 3)
	DO WHILE tr_date = ldPaidDate AND !EOF()
		**********
		DO GenData
		**********
		SELECT curClaimList
		IF SEEK(notify_no, "claim", "notify_no")
			REPLACE claim.batchno WITH m.batchno, claim.lotno WITH m.lotno, claim.insurepaydate WITH m.paydate
		ENDIF 
		SKIP 
	ENDDO 
ENDDO
*
SELECT (lcClmHead)
COPY TO (lcPath+lcClmHead) TYPE DELIMITED WITH CHARACTER "|"
SELECT (lcClmDetail)
COPY TO (lcPath+lcClmDetail) TYPE DELIMITED WITH CHARACTER "|"
*
**************************
*
* Create Credit Data file
*
WAIT WINDOW "Generate Credit Data File" NOWAIT 

SELECT * FROM curClaimReturn WHERE result = "P62" ORDER BY prov_name, pv_no INTO CURSOR curClaimList

IF _TALLY = 0
	RETURN 
ENDIF 
m.paydate = DATE() + (10 + holidays(DATE(), DATE()+10))
m.lotno = "C_" + STRTRAN(STR(DAY(gdSendDate), 2), " ", "0") + STRTRAN(STR(MONTH(gdSendDate), 2), " ", "0") + STRTRAN(STR(YEAR(gdSendDate), 4), " ", "0")
lcClmHead = "JCNGA_" + m.lotno
lcClmDetail = "JANGAD_" + m.lotno
**********************
DO CreateTable
**********************
SELECT curClaimList
DO WHILE !EOF()
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 99,999") NOWAIT 
	lcProvName = prov_name
	m.batchno = "C"+SUBSTR(newdateno("C", gdSendDate), 3)
	DO WHILE prov_name = lcProvName AND !EOF()
		**********
		DO GenData
		**********
		SELECT curClaimList
		IF SEEK(notify_no, "claim", "notify_no")
			REPLACE claim.batchno WITH m.batchno, claim.lotno WITH m.lotno, claim.insurepaydate WITH m.paydate
		ENDIF 
		SKIP 
	ENDDO 
ENDDO
*
SELECT (lcClmHead)
COPY TO (lcPath+lcClmHead) TYPE DELIMITED WITH CHARACTER "|"
SELECT (lcClmDetail)
COPY TO (lcPath+lcClmDetail) TYPE DELIMITED WITH CHARACTER "|"
*
**************************
*
* Create Denied & Rejust Data file
*
WAIT WINDOW "Generate Denied Data File" NOWAIT

SELECT claim.notify_no, claim.notify_date, claim.policy_no, claim.family_no, claim.client_name, claim.service_type, ;
	claim.claim_no, claim.effective, claim.expried, claim.plan, claim.acc_date, claim.admis_date, claim.disc_date, ;
	STRTRAN(claim.customer_id, "SMG", "") AS cust_id, claim.prov_name,  ;
	claim.illness1, claim.result, claim.scharge, claim.sdiscount, claim.sbenfpaid, ;
	claim.snote, claim.return_date, claim.note2ins, claim.paid_date, ;
	claim.tr_acno, claim.tr_name, claim.tr_bank, claim.tr_banch ;
FROM cims!claim ;
WHERE claim.fundcode = gcFundCode ;
	AND return_date BETWEEN gdStartDate AND gdEndDate ;
	AND INLIST(LEFT(result, 1), "D", "R") ;
ORDER BY return_date, notify_no ;
INTO CURSOR curClaimList

IF _TALLY = 0
	RETURN 
ENDIF 

m.paydate = {}
m.lotno = "D_" + STRTRAN(STR(DAY(gdSendDate), 2), " ", "0") + STRTRAN(STR(MONTH(gdSendDate), 2), " ", "0") + STRTRAN(STR(YEAR(gdSendDate), 4), " ", "0")
lcClmHead = "JCNGA_" + m.lotno
lcClmDetail = "JANGAD_" + m.lotno
**********************
DO CreateTable
**********************
SELECT curClaimList
DO WHILE !EOF()
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 99,999") NOWAIT 
	ldReturnDate = return_date
	m.batchno = "D"+SUBSTR(newdateno("D", gdSendDate), 3)
	DO WHILE return_date = ldReturnDate AND !EOF()
		**********
		DO GenData
		**********
		SELECT curClaimList
		IF SEEK(notify_no, "claim", "notify_no")
			REPLACE claim.batchno WITH m.batchno, claim.lotno WITH m.lotno, claim.insurepaydate WITH m.paydate
		ENDIF 
		SKIP 
	ENDDO 
ENDDO
*
SELECT (lcClmHead)
COPY TO (lcPath+lcClmHead) TYPE DELIMITED WITH CHARACTER "|"
SELECT (lcClmDetail)
COPY TO (lcPath+lcClmDetail) TYPE DELIMITED WITH CHARACTER "|"
*
******************************
PROCEDURE CreateTable
*
CREATE TABLE (lcPath+lcClmHead) FREE ;
(dfclaimno C(15), class C(2), subclass C(4), lossplace C(100), lossdate D, losstime C(8), notifyno C(20), cntxbrcode N(3), cntxid I, notifydate D, ;
notifytime C(8), causeoflos I, exportdate D, dfpolicyno C(20), insurednam C(100), fullname C(100), effective D, expiry D, batchno C(25), ;
lotno C(15), paydate D, referencen C(25), policygen C(10), personcode C(10), personno C(10), groupdata C(10), remark C(100), status C(1), ;
upusercode C(10), updatedate D, updatetime C(8))
*	
CREATE TABLE (lcPath+lcClmDetail) FREE ;	
(dfclaimno C(15), seq N(3), cntxbrcode C(3), cntxid C(15), personcode C(10), production N(1), locationno N(1), itemno N(1), fullname C(100), ;
effective D, expiry D, lossdate D, admitdate D, leavedate D, hospital C(100), opdflag C(1), disbrcode C(3), diseaseid C(10), disease C(100), ;
paydate D, payamt N(20,2), bill N(20,2), payinsure D, lotno C(15), payeeid N(10), payeebrcod C(3), paymenttyp C(2), crosstype C(1), ;
payeename C(100), contactby C(1), bankaccno C(15), accname C(100), bankbranch C(100), remark C(100))
*
*************************
*
PROCEDURE GenData

SELECT name, thainame FROM cims!icd10thai WHERE code = curClaimList.illness1 INTO CURSOR curIcdThai
***************************************
SELECT (lcClmHead)
APPEND BLANK 
REPLACE dfclaimno WITH curClaimList.notify_no, ;
class WITH "MI", ;
subclass WITH "PA", ;
lossplace WITH curClaimList.prov_name, ;
lossdate WITH TTOD(curClaimList.acc_date), ;
losstime WITH TIME(curClaimList.acc_date), ;
notifydate WITH curClaimList.notify_date, ;
notifytime WITH TIME(curClaimList.notify_date), ;
causeoflos WITH 35, ;
exportdate WITH DATE(), ;
dfpolicyno WITH curClaimList.policy_no, ;
insurednam WITH curClaimList.client_name, ;
fullname WITH curClaimList.client_name, ;
effective WITH curClaimList.effective, ;
expiry WITH curClaimList.expried, ;
batchno WITH m.batchno, ;
lotno WITH m.lotno, ;
paydate WITH  m.paydate, ;
referencen WITH curClaimList.cust_id, ;
remark WITH ALLTRIM(curClaimList.snote)
*
*
SELECT (lcClmDetail)
APPEND BLANK 
REPLACE dfclaimno WITH curClaimList.notify_no, ;
seq WITH 1 , ;
personcode WITH "", ;
production WITH 1, ;
locationno WITH 1, ;
itemno WITH 1 , ;
fullname WITH curClaimList.client_name, ;
effective WITH curClaimList.effective, ;
expiry WITH curClaimList.expried, ;
lossdate WITH TTOD(curClaimList.acc_date), ;
admitdate WITH TTOD(curClaimList.admis_date), ;
leavedate WITH TTOD(curClaimList.disc_date), ;
hospital WITH curClaimList.prov_name, ;
opdflag WITH IIF(curClaimList.service_type = "IPD", "IPD", "OPD"), ;
disbrcode WITH "000", ;
diseaseid WITH curClaimList.illness1, ;
disease WITH IIF(EMPTY(curIcdThai.thainame), curIcdThai.name, curIcdThai.thainame), ;
paydate WITH m.paydate, ;
payamt WITH curClaimList.sbenfpaid, ;
bill WITH curClaimList.scharge - curClaimList.sdiscount, ;
payinsure WITH curClaimList.paid_date, ;
lotno WITH m.lotno, ;
payeeid WITH 1007051, ;
payeebrcod WITH "000", ;
paymenttyp WITH "Cq", ;
crosstype WITH "A", ;
payeename WITH "∫√‘…—∑ ‡Œ≈∑Ï ‡∫ππ‘ø‘∑ §Õπ´—≈·∑Èπ Ï ®”°—¥", ;
contactby WITH "t", ;
bankaccno WITH "0652469561", ;
accname WITH "∫√‘…—∑ ‡Œ≈∑Ï ‡∫ππ‘ø‘∑ §Õπ´—≈·∑Èπ Ï ®”°—¥", ;
bankbranch WITH "", ;
remark WITH ALLTRIM(curClaimList.snote)