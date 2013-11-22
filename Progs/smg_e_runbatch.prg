PARAMETERS tcLotNo
*!*	tdStartDate, tdEndDate, tdPayDate, tnType
*!*	IF EMPTY(tdStartDate) AND EMPTY(tdEndDate) AND EMPTY(tdPayDate) AND EMPTY(tnType) AND !INLIST(tnType, 1, 2)
*!*		RETURN 
*!*	ENDIF 	
IF EMPTY(tcLotNo)
	RETURN 
ENDIF 	

CLOSE ALL 
lcOldDir = SYS(5)+SYS(2003)
*
gcFundCode = "SMG"
gdPayDate = CTOD(STRTRAN(SUBSTR(tcLotNo, 3, 8), "-", "/")) &&tdPayDate
gcSaveTo = "D:\report\"
*
SELECT claim.notify_no, claim.policy_no, claim.plan, claim.expried, claim.acc_date, claim.claim_date, claim.prov_id, claim.prov_name, ;
	firstchr(claim.prov_name) AS "first", claim.sbenfpaid, members.effective_y, members.expiry, claim.paid_date, claim.pvno AS pv_no, claim.pvdate, ;
	claim.lotno, claim.batchno, claim.result, ICASE(claim.inv_page = 1, "R", "C") AS ctype ;
FROM cims!claim LEFT JOIN cims!members ;
	ON claim.fundcode+claim.policy_no = members.tpacode+members.policy_no ;
WHERE claim.lotno = tcLotNo ;
ORDER BY claim.result, 5, claim.prov_name, claim.notify_no ;
INTO CURSOR curClaim
IF _TALLY = 0
	RETURN 
ENDIF 	
*
*WHERE acc_date < effective_y OR acc_date < expiry 
lnRunNo = 1
DO CASE 
CASE INLIST(LEFT(tcLotNo, 1), "R", "E")
	SELECT * FROM curClaim ;
	ORDER BY paid_date, pv_no, notify_no ;
	INTO CURSOR curR
	IF _TALLY = 0
		RETURN 
	ENDIF 
	*
	SELECT curR
	GO TOP 
	DO WHILE !EOF()
		ldPaidDate = paid_date
		lcBatchNo = ICASE(LEFT(tcLotNo,1)="R", "R9", "R8")+SUBSTR(DTOS(DATE()),3,4)+STRTRAN(STR(lnRunNo,2)," ","0")
		DO WHILE paid_date = ldPaidDate AND !EOF()
			WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
			IF SEEK(notify_no, "claim", "notify_no")
				REPLACE claim.batchno WITH lcBatchNo, ;
					claim.paytoac WITH "0652469561"
			ENDIF 
			SKIP 
		ENDDO 	
		lnRunNo = lnRunNo+1
	ENDDO 
CASE INLIST(LEFT(tcLotNo, 1), "C", "D")
	SELECT * FROM curClaim ;
	ORDER BY first, prov_name, notify_no ;
	INTO CURSOR curC
	IF _TALLY = 0
		RETURN 
	ENDIF 
	*
	SELECT curC
	GO TOP 
	DO WHILE !EOF()
		lcProvID = prov_id
		lcBatchNo = ICASE(LEFT(tcLotNo,1)="C", "C9", "C8")+SUBSTR(DTOS(DATE()),3,4)+STRTRAN(STR(lnRunNo,2)," ","0")
		DO WHILE prov_id = lcProvID AND !EOF()
			WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
			IF SEEK(notify_no, "claim", "notify_no")
				REPLACE claim.batchno WITH lcBatchNo, ;
					claim.paytoac WITH "0652469561"
			ENDIF 
			SKIP 
		ENDDO 	
		lnRunNo = lnRunNo + 1
	ENDDO 
	=STRTOFILE(STR(lnRunNo,2),"d:\hips\data\smg_error.txt",0)
ENDCASE 	
*

PROCEDURE genLot
lcLotNo = ALLTRIM(m.lotno)
SELECT claim.notify_no, claim.notify_date, claim.policy_no, claim.family_no, claim.client_name, ;
	claim.claim_no, claim.effective, claim.expried, claim.plan, claim.acc_date, ;
	claim.admis_date, claim.disc_date, claim.service_type, ;
	claim.policy_no AS cust_id, claim.prov_name,  claim.cardno, ;
	claim.illness1, claim.result, claim.scharge, claim.sdiscount, claim.sbenfpaid, ;
	claim.abenfpaid, claim.snote, claim.return_date, claim.note2ins, claim.paid_date, ;
	claim.tr_acno, claim.tr_name, claim.tr_bank, claim.tr_banch, ;
	claim.lotno, claim.batchno, claim.insurepaydate ;
FROM cims!claim ;
WHERE claim.fundcode = gcFundCode ;
	AND claim.lotno = lcLotNo ;
ORDER BY claim.lotno, claim.batchno ;
INTO CURSOR curClaimList
*
IF _TALLY = 0
	=MESSAGEBOX("‰¡Ëæ∫¢ÈÕ¡Ÿ≈µ“¡ LotNo. "+lcLotNo, 0)
ELSE 	
*
ldPayDate = gdPayDate
lcPath = "D:\report\SMG\"+ALLTRIM(lcLotNo)  &&ADDBS(ALLTRIM(thisform.txtSaveTo.Value))
*
IF !DIRECTORY(lcPath)
	MKDIR &lcPath
ENDIF
*
lcClmHead = "JCNGA_" + STRTRAN(lcLotNo, "-", "")
lcClmDetail = "JANGAD_" + STRTRAN(lcLotNo, "-", "")
*
CREATE TABLE (ADDBS(lcPath)+lcClmHead) FREE ;
(dfclaimno C(15), class C(2), subclass C(4), lossplace C(100), lossdate D, losstime C(8), notifyno C(20), cntxbrcode N(3), cntxid I, notifydate D, ;
notifytime C(8), causeoflos I, exportdate D, dfpolicyno C(20), insurednam C(100), fullname C(100), effective D, expiry D, batchno C(25), ;
lotno C(15), paydate D, referencen C(25), policygen C(20), personcode I, personno I, groupdata C(10), remark C(100), status C(1), ;
upusercode C(10), updatedate D, updatetime C(8))
*	
CREATE TABLE (ADDBS(lcPath)+lcClmDetail) FREE ;
(dfclaimno C(15), seq N(3), cntxbrcode C(3), cntxid C(15), personcode I, production N(1), locationno N(1), itemno N(1), fullname C(100), ;
effective D, expiry D, lossdate D, admitdate D, leavedate D, hospital C(100), opdflag C(1), disbrcode C(3), diseaseid C(10), disease C(100), ;
paydate D, payamt N(20,2), bill N(20,2), payinsure D, lotno C(15), payeeid N(10), payeebrcod C(3), paymenttyp C(2), crosstype C(1), ;
payeename C(100), contactby C(1), bankaccno C(15), accname C(100), bankbranch C(100), remark C(200), batchno C(25))
*	
*
SELECT curClaimList
SCAN 	
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	DO gendata
ENDSCAN
*
lcExpPath = ADDBS(lcPath)+"Renew"
IF !DIRECTORY(lcExpPath)
	MD &lcExpPath
ENDIF 
lcNoExpPath = ADDBS(lcPath)+"Not_Renew"
IF !DIRECTORY(lcNoExpPath)
	MD &lcNoExpPath
ENDIF 

SELECT (lcClmHead)
COPY TO (ADDBS(lcExpPath) + lcClmHead + ".txt") TYPE DELIMITED WITH CHARACTER "|" FOR batchno = "E"
COPY TO (ADDBS(lcExpPath) +  lcClmHead + ".xls") TYPE XLS FOR batchno = "E"	
COPY TO (ADDBS(lcNoExpPath) + lcClmHead + ".txt") TYPE DELIMITED WITH CHARACTER "|" FOR batchno = "D"
COPY TO (ADDBS(lcNoExpPath) +  lcClmHead + ".xls") TYPE XLS FOR batchno = "D"	
*
SELECT (lcClmDetail)
COPY TO (ADDBS(lcExpPath) + lcClmDetail + ".txt") TYPE DELIMITED WITH CHARACTER "|" FIELDS EXCEPT batchno FOR batchno = "E" 
COPY TO (ADDBS(lcExpPath) +  lcClmDetail + ".xls") FIELDS EXCEPT batchno TYPE XLS FOR batchno = "E"	
COPY TO (ADDBS(lcNoExpPath) + lcClmDetail + ".txt") FIELDS EXCEPT batchno TYPE DELIMITED WITH CHARACTER "|" FOR batchno = "D"
COPY TO (ADDBS(lcNoExpPath) +  lcClmDetail + ".xls") FIELDS EXCEPT batchno TYPE XLS FOR batchno = "D"	
****************************************************
PROCEDURE genData

lcIcd10 = ALLTRIM(curClaimList.illness1)
lcIcd10 = IIF(LEN(lcIcd10) > 4, LEFT(lcIcd10,4), lcIcd10)
SELECT name, thainame FROM cims!icd10thai WHERE code = lcIcd10 INTO CURSOR curIcdThai
*
IF LEFT(curClaimList.policy_no,1) = "2" AND AT("-", curClaimList.policy_no) <> 0
	lcPolicyNo = LEFT(curClaimList.policy_no, AT("-", curClaimList.policy_no)-1)
ELSE 
	lcPolicyNo = curClaimList.policy_no
ENDIF 		
*
SELECT policy_no, personcode, personno ;
FROM d:\hips\data\smg_policy ;
WHERE refno = LEFT(lcPolicyNo,20) ;
INTO ARRAY laSmg
IF _TALLY > 0
	m.refno = lcPolicyNo
	m.policy_no = laSmg[1]
	m.personcode = VAL(laSmg[2])
	m.personno = VAL(laSmg[3])
ELSE 
	m.refno = lcPolicyNo
	m.policy_no = ""
	m.personcode = 0
	m.personno = 0
ENDIF 	
*
lchbc = STR(18 + (2010 - YEAR(DATE())),2)
m.itemno = IIF(curClaimList.plan = "PA1", 2, IIF(LEFT(curClaimList.policy_no, 1) = "5", 1, 0))
***************************************
IF SEEK(curClaimList.notify_no, "claim", "notify_no")
	REPLACE claim.lotno WITH m.lotno, claim.insurepaydate WITH ldPayDate
ENDIF 
**********	
SELECT (lcClmHead)
APPEND BLANK 
REPLACE dfclaimno WITH IIF(LEN(ALLTRIM(curClaimList.notify_no)) = 10, STUFF(curClaimList.notify_no, 1, 2, lcHbc), STUFF(curClaimList.notify_no, 1, 4, lcHbc)), ;
class WITH "MI", ;
subclass WITH "PA", ;
lossplace WITH curClaimList.prov_name, ;
lossdate WITH TTOD(curClaimList.acc_date), ;
losstime WITH TIME(curClaimList.acc_date), ;
notifydate WITH curClaimList.notify_date, ;
notifytime WITH TIME(curClaimList.notify_date), ;
causeoflos WITH 35, ;
exportdate WITH DATE(), ;
dfpolicyno WITH m.policy_no, ;
insurednam WITH curClaimList.client_name, ;
fullname WITH curClaimList.client_name, ;
effective WITH curClaimList.effective, ;
expiry WITH curClaimList.expried, ;
batchno WITH curClaimList.batchno, ;
lotno WITH m.lotNo, ;
paydate WITH  ldPayDate, ;
referencen WITH m.refno, ;
policygen WITH m.policy_no, ;
personcode WITH m.personcode, ;
personno WITH m.personno, ;
remark WITH ALLTRIM(curClaimList.snote)
*
SELECT (lcClmDetail)
APPEND BLANK 
REPLACE dfclaimno WITH IIF(LEN(ALLTRIM(curClaimList.notify_no)) = 10, STUFF(curClaimList.notify_no, 1, 2, lcHbc), STUFF(curClaimList.notify_no, 1, 4, lcHbc)), ;
seq WITH 1 , ;
personcode WITH m.personcode, ;
production WITH 1, ;
locationno WITH 1, ;
itemno WITH m.itemno , ;
fullname WITH curClaimList.client_name, ;
effective WITH curClaimList.effective, ;
expiry WITH curClaimList.expried, ;
lossdate WITH TTOD(curClaimList.acc_date), ;
admitdate WITH TTOD(curClaimList.admis_date), ;
leavedate WITH TTOD(curClaimList.disc_date), ;
hospital WITH curClaimList.prov_name, ;
opdflag WITH IIF(curClaimList.service_type = "IPD", "IPD", "OPD"), ;
disbrcode WITH "000", ;
diseaseid WITH LEFT(curClaimList.illness1, 3), ;
disease WITH IIF(EMPTY(curIcdThai.thainame), curIcdThai.name, curIcdThai.thainame), ;
paydate WITH ldPayDate, ;
payamt WITH curClaimList.sbenfpaid + curClaimList.abenfpaid, ;
bill WITH curClaimList.scharge - curClaimList.sdiscount, ;
payinsure WITH curClaimList.paid_date, ;
lotno WITH m.lotno, ;
batchno WITH curClaimList.batchno, ;
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
