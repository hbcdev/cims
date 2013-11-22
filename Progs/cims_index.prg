SET SAFETY OFF 

OPEN DATABASE d:\hips\data\cims.DBC EXCLUSIVE
VALIDATE DATABASE RECOVER 
*
USE cims!member EXCLUSIVE 
?DBF()
DELETE TAG ALL 
INDEX ON FUND_ID TAG FUND_ID
INDEX ON PLAN_ID TAG PLAN_ID
INDEX ON TPACODE+POLICY_NO TAG POLICY_NO
INDEX ON BRANCH_CODE TAG BRANCH_COD
INDEX ON PACKAGE TAG PACKAGE
INDEX ON POLICY_NO TAG POLICY
INDEX ON TPACODE TAG TPACODE
INDEX ON EFFECTIVE TAG EFFECTIVE
INDEX ON EXPIRY TAG EXPIRY
INDEX ON AGENT TAG AGENT
INDEX ON SURNAME TAG SURNAME
INDEX ON NAME TAG FIRSTNAME
INDEX ON ALLTRIM(STR(FUND_ID))+ALLTRIM(NAME)+" "+ALLTRIM(SURNAME) TAG NAME
INDEX ON TPACODE+ALLTRIM(NAME)+ALLTRIM(SURNAME) TAG FULLNAME
INDEX ON PRODUCT TAG PRODUCT
INDEX ON TPACODE+POLICY_NO+ALLTRIM(PRODUCT) TAG POL_PLAN
INDEX ON POLICY_NAME TAG POLICY_NAM
INDEX ON NATID TAG NATID
INDEX ON CUSTOMER_TYPE TAG CUSTTYPE
INDEX ON TPACODE+CUSTOMER_ID TAG CUSTOMER_I
INDEX ON TPACODE+CUSTOMER_ID+POLICY_NO TAG CUSTPOLICY
INDEX ON QUOTATION TAG QUOTATION
INDEX ON TPACODE+QUOTATION+ALLTRIM(NAME)+" "+ALLTRIM(SURNAME)+PRODUCT TAG QUO_NAME_P
INDEX ON TPACODE+QUOTATION+ALLTRIM(NAME)+ALLTRIM(SURNAME) TAG QUO_NAME
INDEX ON CUSTOMER_ID TAG CUSTID
INDEX ON TPACODE+CUSTOMER_ID+PRODUCT TAG CUST_PLAN
INDEX ON TPACODE+POLICY_NO+ALLTRIM(NAME)+ALLTRIM(SURNAME)+PRODUCT TAG NAME_PLAN
INDEX ON TPACODE+OLD_POLICYNO TAG OLD_POL
INDEX ON CARDNO TAG CARDNO
INDEX ON POLICY_GROUP TAG POLICY_GRO
INDEX ON TPACODE+POLICY_GROUP+ALLTRIM(NAME)+" "+ALLTRIM(SURNAME) TAG PGRP_NAME
*
USE cims!claim EXCLUSIVE 
?DBF()
DELETE TAG ALL 
INDEX ON CLAIM_DATE TAG CLAIM_DATE
INDEX ON DOC_DATE TAG DOC_DATE
INDEX ON FUNDCODE+POLICY_NO+STR(FAMILY_NO) TAG PERSON_NO
INDEX ON VISIT_NO TAG VISIT_NO
INDEX ON POLICY_NO TAG POLICY
INDEX ON FUNDCODE TAG FUNDCODE
INDEX ON ILLNESS2 TAG ILLNESS2
INDEX ON ILLNESS1 TAG ILLNESS1
INDEX ON NOTIFY_DATE TAG NOTIFY_DAT
INDEX ON RESULT TAG RESULT
INDEX ON RETURN_DATE TAG RETURN_DAT
INDEX ON PROV_PENDING TAG PROV_PENDI
INDEX ON PROV_CLASS TAG PROV_CLASS
INDEX ON REF_DATE TAG REF_DATE
INDEX ON EXPRIED TAG EXPRIED
INDEX ON EFFECTIVE TAG EFFECTIVE
INDEX ON FUNDCODE+POLICY_NO TAG POLICY_NO
INDEX ON ADMIS_DATE TAG ADMIS_DATE
INDEX ON ACC_DATE TAG ACC_DATE
INDEX ON FUNDCODE+POLICY_NO+CLIENT_NAME TAG POL_NAME
INDEX ON MAIL_DATE TAG MAIL_DATE
INDEX ON EXGRATIA_BY TAG EXGRATIA_B
INDEX ON PVNO TAG PVNO
INDEX ON AUDIT_DATE TAG AUDIT_DATE
INDEX ON ASSESSOR_DATE TAG ASSESSOR_D
INDEX ON FAX_DATE TAG FAX_DATE
INDEX ON PROV_NAME TAG PROV_NAME
INDEX ON PROV_ID TAG PROV_ID
INDEX ON PLAN_ID TAG PLAN_ID
INDEX ON CLIENT_NO TAG CLIENT_NO
INDEX ON PLAN TAG PLAN
INDEX ON CAUSE_TYPE TAG CAUSE_TYPE
INDEX ON SERVICE_TYPE TAG SERVICE_TY
INDEX ON CLAIM_TYPE TAG CLAIM_TYPE
INDEX ON TYPE_CLAIM TAG TYPE_CLAIM
INDEX ON CLAIM_ID TAG CLAIM_ID
INDEX ON AUDIT_BY TAG AUDIT_BY
INDEX ON ASSESSOR_BY TAG ASSESSOR_B
INDEX ON FAX_BY TAG FAX_BY
INDEX ON CLAIM_NO TAG CLAIM_NO
INDEX ON FUNDCODE+QUOTATION+ALLTRIM(CLIENT_NAME)+PLAN TAG QUO_NAME_P
INDEX ON FUNDCODE+QUOTATION+ALLTRIM(CLIENT_NAME) TAG QUO_NAME
INDEX ON FUNDCODE+QUOTATION TAG QUOTATION
INDEX ON CUSTOMER_ID TAG CUSTOMER_I
INDEX ON LOTNO TAG LOTNO
INDEX ON BATCHNO TAG BATCHNO
INDEX ON NOTIFY_NO TAG NOTIFY_NO
INDEX ON FOLLOWUP TAG FOLLOWUP
*
USE cims!claim_line EXCLUSIVE 
?DBF()
DELETE TAG ALL 
INDEX ON CAT_CODE TAG CAT_CODE
INDEX ON CLAIM_ID TAG CLAIM_ID
INDEX ON CLAIM_ID+CAT_ID TAG CLAIM_CAT
INDEX ON NOTIFY_NO TAG NOTIFY_NO
*
USE cims!claim_items EXCLUSIVE 
?DBF()
INDEX ON CLAIM_ID TAG CLAIM_ID
INDEX ON CAT_ID TAG CAT_ID
INDEX ON ITEM_CODE TAG ITEM_CODE
INDEX ON CAT_CODE TAG CAT_CODE
INDEX ON CLAIM_ID+CAT_ID TAG CLAIM_CAT
INDEX ON CLAIM_ID+CAT_ID+ITEM_CODE TAG CAT_ITEM
INDEX ON NOTIFY_NO TAG NOTIFY_NO
INDEX ON NOTIFY_NO+CAT_ID TAG NOT_CATID
INDEX ON NOTIFY_NO+CAT_ID+ITEM_CODE TAG NOT_ITEM
*
USE cims!claim_item_icd9 EXCLUSIVE 
?DBF()
INDEX ON CAT_ID TAG CAT_ID
INDEX ON CLAIM_ID TAG CLAIM_ID
INDEX ON ITEM_CODE TAG ITEM_CODE
INDEX ON ICD9 TAG ICD9
INDEX ON CLAIM_ID+CAT_ID+ITEM_CODE TAG CAT_ITEM
INDEX ON CLAIM_ID+CAT_ID TAG CLAIM_CAT
INDEX ON NOTIFY_NO TAG NOTIFY_NO
INDEX ON NOTIFY_NO+CAT_ID TAG NOT_CATID
*
USE cims!notify EXCLUSIVE 
?DBF()
DELETE TAG ALL 
INDEX ON FUND_ID TAG FUND_ID
INDEX ON ILLNESS TAG ILLNESS
INDEX ON ADMIS_DATE TAG ADMIS_DATE
INDEX ON POLICY_NO TAG POLICY
INDEX ON RECIEVE_DATE TAG RECIEVE_DA
INDEX ON STR(FUND_ID)+POLICY_NO+STR(FAMILY_NO)+STR(PERSON_NO) TAG POLICY_GRP
INDEX ON FUNDCODE TAG FUNDCODE
INDEX ON PROV_ID TAG PROV_ID
INDEX ON EXGRATIA_BY TAG EXGRATIA_B
INDEX ON ACC_DATE TAG ACC_DATE
INDEX ON FUNDCODE+POLICY_NO+STR(FAMILY_NO)+PROV_ID+TTOC(ADMIS_DATE) TAG ADMIT
INDEX ON FUNDCODE+CLIENT_NAME TAG NAME
INDEX ON FUNDCODE+POLICY_NO+CLIENT_NAME TAG POL_NAME
INDEX ON CUSTOMER_ID TAG CUSTOMER_I
INDEX ON LEFT(CUSTOMER_ID,3)+POLICY_NO TAG POLICY_NO
INDEX ON NOTIFY_NO TAG NO
*
USE cims!notify_period EXCLUSIVE 
?DBF()
INDEX ON DUE TAG DUE
INDEX ON DIAGS TAG DIAGS
INDEX ON DRG TAG DRG
INDEX ON FUNDCODE TAG FUNDCODE
INDEX ON FUNDCODE+POLICY_NO TAG POLICY_NO
INDEX ON FUNDCODE+POLICY_NO+STR(FAMILY_NO) TAG PERSON_NO
INDEX ON CUSTOMER_ID TAG CUSTOMER_I
INDEX ON CUSTOMER_ID+DTOC(DUE) TAG CUSTDUE
INDEX ON NOTIFY_NO TAG NOTIFY_NO
*
USE cims!notify_period_items EXCLUSIVE 
?DBF()
INDEX ON NOTIFY_NO TAG NOTIFY_NO
INDEX ON NOTIFY_NO+CAT_ID TAG NOTIFY_CAT
*
USE cims!notify_period_lines EXCLUSIVE 
?DBF()
INDEX ON CLAIM_ID TAG CLAIM_ID
INDEX ON NOT_NO TAG NOT_NO
INDEX ON NOTIFY_NO TAG NOTIFY_NO
INDEX ON NOTIFY_NO+CLAIM_ID TAG NOTIFY_CLM
INDEX ON NOTIFY_NO+NOT_NO TAG FW_NO
INDEX ON NOTIFY_NO+DTOC(ADMIT) TAG NOT_ADMIT
