CLOSE ALL
OPEN DATA CIMS
***** Table setup for PA CLAIM *****
CREATE TABLE 'CIMS03.DBF' NAME 'PACLAIM' (NOTIFY_NO C(10) NOT NULL, ;
                    NOTIFY_DATE T NOT NULL, ;
                    CLAIM_ID C(10) NOT NULL, ;
                    CLAIM_DATE T NOT NULL, ;
                    CLAIM_WITH C(4) NOT NULL, ;
                    DOC_DATE T NOT NULL, ;
                    TYPE_CLAIM N(1, 0) NOT NULL, ;
                    CLAIM_TYPE N(1, 0) NOT NULL, ;
                    CAUSE C(60) NOT NULL, ;
                    FOLLOWUP C(10) NOT NULL, ;
                    VISIT_NO I NOT NULL, ;
                    VISIT I NOT NULL, ;
                    FUNDCODE C(3) NOT NULL, ;
                    CUSTOMER_ID C(10) NOT NULL, ;
                    POLICY_NO C(30) NOT NULL, ;
                    POLICY_HOLDER C(50) NOT NULL, ;
                    FAMILY_NO I NOT NULL, ;
                    PERSON_NO I NOT NULL, ;
                    PLAN C(20) NOT NULL, ;
                    CLIENT_NAME C(50) NOT NULL, ;
                    EFFECTIVE T NOT NULL, ;
                    EXPRIED T NOT NULL, ;
                    PLAN_ID C(8) NOT NULL, ;
                    CLAIM_NO C(15) NOT NULL, ;
                    REFNO C(10) NOT NULL, ;
                    REF_DATE T NOT NULL, ;
                    PROV_ID C(8) NOT NULL, ;
                    PROV_NAME C(50) NOT NULL, ;
                    PROV_CLASS C(1) NOT NULL, ;
                    ADMIS_DATE T NOT NULL, ;
                    DISC_DATE T NOT NULL, ;
                    AN_NO C(10) NOT NULL, ;
                    HN_NO C(10) NOT NULL, ;
                    INDICATION_ADMIT M NOT NULL, ;
                    DOCTOR_NOTE M NOT NULL, ;
                    ATTENDING C(50) NOT NULL, ;
                    CONSULTANTS C(50) NOT NULL, ;
                    DIAG_PLAN M NOT NULL, ;
                    ILLNESS1 C(8) NOT NULL, ;
                    ILLNESS2 C(8) NOT NULL, ;
                    ILLNESS3 C(8) NOT NULL, ;
                    DRG C(8) NOT NULL, ;
                    ICD9_1 C(8) NOT NULL, ;
                    ICD9_2 C(8) NOT NULL, ;
                    ICD9_3 C(8) NOT NULL, ;
                    SENDER C(30) NOT NULL, ;
                    PROV_DEP C(30) NOT NULL, ;
                    BENF_COVER Y NOT NULL, ;
                    FDAY I NOT NULL, ;
                    FCHARGE Y NOT NULL, ;
                    FDISCOUNT Y NOT NULL, ;
                    FBENFPAID Y NOT NULL, ;
                    FREMAIN Y NOT NULL, ;
                    FNOTE M NOT NULL, ;
                    SDAY I NOT NULL, ;
                    SCHARGE Y NOT NULL, ;
                    SDISCOUNT Y NOT NULL, ;
                    SBENFPAID Y NOT NULL, ;
                    SREMAIN Y NOT NULL, ;
                    SNOTE M NOT NULL, ;
                    ADAY I NOT NULL, ;
                    ABENFPAID Y NOT NULL, ;
                    AREMAIN Y NOT NULL, ;
                    EXGRATIA Y NOT NULL, ;
                    ANOTE M NOT NULL, ;
                    FAX_BY C(8) NOT NULL, ;
                    FAX_DATE T NOT NULL, ;
                    NURSE C(8) NOT NULL, ;
                    ASSESSOR_BY C(8) NOT NULL, ;
                    ASSESSOR_DATE T NOT NULL, ;
                    AUDIT_BY C(8) NOT NULL, ;
                    AUDIT_DATE T NOT NULL, ;
                    RESULT C(4) NOT NULL, ;
                    RETURN_DATE D NOT NULL, ;
                    PVNO C(10) NOT NULL, ;
                    PAID_DATE D NOT NULL, ;
                    PAID_TO C(30) NOT NULL, ;
                    CHQNO C(10) NOT NULL, ;
                    BANK C(3) NOT NULL, ;
                    PAYMENT_TYPE N(1, 0) NOT NULL, ;
                    STATUS C(3) NOT NULL, ;
                    CANCEL L NOT NULL, ;
                    PROV_PENDING C(2) NOT NULL, ;
                    INV_PAGE I NOT NULL, ;
                    NOTIFY_STATUS I NOT NULL, ;
                    NOTE2INS M NOT NULL, ;
                    L_USER C(8) NOT NULL, ;
                    L_UPDATE T NOT NULL)

***** Create each index for CLAIM *****
SET COLLATE TO 'MACHINE'
INDEX ON CLAIM_DATE TAG CLAIM_DATE
INDEX ON CUSTOMER_ID TAG CUSTOMER_I
INDEX ON DOC_DATE TAG DOC_DATE
ALTER TABLE 'PACLAIM' ADD PRIMARY KEY CLAIM_ID TAG CLAIM_ID
INDEX ON NOTIFY_NO TAG NOTIFY_NO
INDEX ON LEFT(CUSTOMER_ID,3)+POLICY_NO TAG POLICY_NO
INDEX ON FUNDCODE+POLICY_NO+STR(FAMILY_NO) TAG PERSON_NO
INDEX ON VISIT_NO TAG VISIT_NO
INDEX ON FOLLOWUP TAG FOLLOWUP
INDEX ON CLAIM_TYPE TAG CLAIM_TYPE
INDEX ON POLICY_NO TAG POLICY
INDEX ON FUNDCODE TAG FUNDCODE
INDEX ON ILLNESS2 TAG ILLNESS2
INDEX ON ILLNESS1 TAG ILLNESS1
INDEX ON DRG TAG DRG
INDEX ON NOTIFY_DATE TAG NOTIFY_DAT
INDEX ON RESULT TAG RESULT
INDEX ON RETURN_DATE TAG RETURN_DAT
INDEX ON PVNO TAG PVNO
INDEX ON PROV_PENDING TAG PROV_PENDI
INDEX ON PROV_CLASS TAG PROV_CLASS
INDEX ON PROV_ID TAG PROV_ID
INDEX ON REF_DATE TAG REF_DATE
INDEX ON PLAN_ID TAG PLAN_ID
INDEX ON EXPRIED TAG EXPRIED
INDEX ON EFFECTIVE TAG EFFECTIVE
INDEX ON PLAN TAG PLAN
INDEX ON TYPE_CLAIM TAG TYPE_CLAIM
INDEX ON ADMIS_DATE TAG ADMIS_DATE
INDEX ON POLICY_NO+TTOC(ADMIS_DATE) TAG P_ADMIT
INDEX ON NOTIFY_NO+POLICY_NO TAG P_NOTIFY

***** Change properties for CLAIM *****
DBSETPROP('PACLAIM.CLAIM_WITH', 'Field', 'Comment', "claim with health or accident")
DBSETPROP('PACLAIM.VISIT_NO', 'Field', 'Comment', "จำนวนครั้งที่เข้ารักษา แบ่งตาม claim type")
DBSETPROP('PACLAIM.PLAN', 'Field', 'Comment', "แผนความคุ้มครอง")
DBSETPROP('PACLAIM.BENF_COVER', 'Field', 'Comment', "Benefit cover for this claim if this claim is in between disability. it contain benefit balance")
DBSETPROP('PACLAIM.EXGRATIA', 'Field', 'Comment', "สินไหมกรุณา")
DBSETPROP('PACLAIM.RETURN_DATE', 'Field', 'Comment', "วันที่ส่งเอกสารกลับ บ. ประกัน")
DBSETPROP('PACLAIM.PROV_PENDING', 'Field', 'Comment', "provider pending code")
CREATE TRIGGER ON 'PACLAIM' FOR DELETE AS __ri_delete_claim()
ENDFUNC

CREATE TABLE 'CIMS031.DBF' NAME 'PACLAIM_LINE' (NOTIFY_NO C(10) NOT NULL, ;
                         CLAIM_ID C(10) NOT NULL, ;
                         CAT_ID C(10) NOT NULL, ;
                         CAT_CODE C(10) NOT NULL, ;
                         DESCRIPTION C(40) NOT NULL, ;
                         SERVICE_TYPE C(1) NOT NULL, ;
                         SERV_COVER N(3, 0) NOT NULL, ;
                         BENF_COVER Y NOT NULL, ;
                         SERVICE_USED N(3, 0) NOT NULL, ;
                         BENEFIT_PAID Y NOT NULL, ;
                         FADMIS N(3, 0) NOT NULL, ;
                         FCHARGE Y NOT NULL, ;
                         FDISCOUNT N(12, 2) NOT NULL, ;
                         FSERVICE N(3, 0) NOT NULL, ;
                         FPAID Y NOT NULL, ;
                         FREMAIN Y NOT NULL, ;
                         SADMIS N(3, 0) NOT NULL, ;
                         SSERVICE N(12, 2) NOT NULL, ;
                         SCHARGE Y NOT NULL, ;
                         SDISCOUNT N(12, 2) NOT NULL, ;
                         SPAID Y NOT NULL, ;
                         SREMAIN Y NOT NULL, ;
                         AADMIS N(3, 0) NOT NULL, ;
                         APAID Y NOT NULL, ;
                         AREMAIN Y NOT NULL, ;
                         TOTAL_FEE N(6, 2) NOT NULL, ;
                         DUEFOLLOWUP D NOT NULL, ;
                         DUEPERIOD D NOT NULL, ;
                         FEE L NOT NULL, ;
                         ITEM_GRP C(30) NOT NULL, ;
                         GROUP C(2) NOT NULL, ;
                         SUBSERVICE N(3, 0) NOT NULL, ;
                         SUBPAID Y NOT NULL, ;
                         EXGRATIA Y NOT NULL, ;
                         FNOTE C(250) NOT NULL, ;
                         SNOTE C(250) NOT NULL, ;
                         ANOTE C(250) NOT NULL, ;
                         L_USER C(8) NOT NULL, ;
                         L_UPDATE T NOT NULL)

***** Create each index for CLAIM_LINE *****
SET COLLATE TO 'MACHINE'
INDEX ON CLAIM_ID TAG CLAIM_ID
INDEX ON CAT_ID TAG CAT_ID
INDEX ON NOTIFY_NO TAG NOTIFY_NO
ALTER TABLE 'PACLAIM_LINE' ADD PRIMARY KEY CLAIM_ID+CAT_ID TAG CLAIM_CAT
INDEX ON GROUP TAG GROUP
INDEX ON ITEM_GRP TAG ITEM_GRP
INDEX ON CAT_CODE TAG CAT_CODE

***** Change properties for CLAIM_LINE *****
DBSETPROP('PACLAIM_LINE', 'Table', 'Comment', "ตาราง เก็บ รายละเอียดค่าใช้จ่ายตามแผน")
CREATE TRIGGER ON 'PACLAIM_LINE' FOR DELETE AS __ri_delete_claim_line()
ENDFUNC
********************

FUNCTION MakeTable_CLAIM_LINE_ITEMS
***** Table setup for CLAIM_LINE_ITEMS *****
CREATE TABLE 'CIMS032.DBF' NAME 'PACLAIM_LINE_ITEMS' (NOTIFY_NO C(10) NOT NULL, ;
                               CLAIM_ID C(10) NOT NULL, ;
                               CAT_ID C(10) NOT NULL, ;
                               ITEM_CODE C(8) NOT NULL, ;
                               DOS D NOT NULL, ;
                               ADMIS N(3, 0) NOT NULL, ;
                               CHARGE Y NOT NULL, ;
                               DISCOUNT Y NOT NULL, ;
                               BENF_PAID Y NOT NULL, ;
                               CLIENT_PAID Y NOT NULL, ;
                               ABUSE N(1, 0) NOT NULL, ;
                               EXGRATIA Y NOT NULL, ;
                               COMMENT C(250) NOT NULL, ;
                               FEE_RATE N(6, 2) NOT NULL, ;
                               L_USER C(8) NOT NULL, ;
                               L_UPDATE T NOT NULL)

***** Create each index for CLAIM_LINE_ITEMS *****
SET COLLATE TO 'MACHINE'
INDEX ON ITEM_CODE TAG ITEM_CODE
INDEX ON CLAIM_ID TAG CLAIM_ID
INDEX ON CAT_ID TAG CAT_ID
INDEX ON CLAIM_ID+CAT_ID TAG CLAIM_CAT
ALTER TABLE 'PACLAIM_LINE_ITEMS' ADD PRIMARY KEY CLAIM_ID+CAT_ID+ITEM_CODE TAG CAT_ITEM
INDEX ON NOTIFY_NO TAG NOTIFY_NO

***** Change properties for CLAIM_LINE_ITEMS *****
DBSETPROP('PACLAIM_LINE_ITEMS', 'Table', 'Comment', "ตาราง เก็บ รายละเอียดย่อยของ แผน ")
ENDFUNC
