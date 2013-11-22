PARAMETERS tdStartDate, tdEndDate
CLEAR 
SELECT tpacode, policy_no, customer_id, customer_type, product, plan_id, ;
	overall_limit, natid, title, name, surname, sex, birth_date, age, ;
	policy_date, effective, expiry, exclusion, status ;
FROM cims!member ;
WHERE tpacode = "SMG" AND adddate BETWEEN tdStartDate AND tdEndDate ;
INTO CURSOR curMember
*
IF _TALLY = 0
	RETURN 
ENDIF 
**************************************************************************
cConn = SQLStringConnect("DRIVER=SQL Server;SERVER=direct2hbc.in.th;UID=direct2hbc_in_th_admin2;PWD=0409;DATABASE=direct2hbc_in_th_cims")

SELECT curMember
SCAN 
	SELECT curMember	
	?? TRANSFORM(RECNO(), "@Z 999,999")+"/"+TRANSFORM(RECCOUNT(), "@Z 999,999")  AT 80,50
	SCATTER MEMVAR 		
	lnRetVal = SQLEXEC(cConn, [EXEC SP_INS_UP_DEL_MEMBER ?m.tpacode, ?m.policy_no, ?m.customer_type, ?m.customer_id, ?m.title, ?m.name, ?m.surname, ?m.plan_id, ?m.product, ?m.effective, ?m.expiry, ?m.natid, ?m.overall_limit, ?m.status])
	IF lnRetVal < 1
		SUSPEND 
	ENDIF 	
ENDSCAN 
=SQLDISCONNECT(cConn)





PROCEDURE update


lcInsertCmd = "INSERT INTO Member ("+;
	"[tpacode], policy_no, customer_id, customer_type, product, plan_id, "+;
	"overall_limit, natid, title, [name], surname, sex, birth_date, age, fax, mobile, "+;
	"policy_date, effective, expiry, premium, exclusion, status, hb_limit, quotation, cardno) "+;
	"VALUE ("+;
	"curMember.Tpacode, "+;
	"curMember.Policy_no, "+;
	"curMember.Customer_Id, "+;
	"curMember.Customer_type, "+;
	"curMember.Product, "+;
	"curMember.Plan_Id, "+;
	"curMember.Overall_Limit, "+;
	"curMember.Natid, "+;
	"curMember.Title, "+;
	"curMember.Name, "+;
	"curMember.Surname, "+;
	"curMember.Sex, "+;
	"curMember.Birth_date, "+;
	"curMember.Age, "+;
	"curMember.Fax, "+;
	"curMember.Mobile, "+;
	"curMember.Policy_date, "+;
	"curMember.Effective, "+;
	"curMember.Expiry, "+;
	"curMember.Premium, "+;
	"curMember.Exclusion, "+;
	"curMember.Status, "+;
	"curMember.Hb_Limit, "+;
	"curMember.Quotation, "+; 
	"curMember.Cardno)"


lcUpdateCmd = "UPDATE Member SET "+;
	"Customer_id = ?curMember.Customer_Id, "+;
	"Customer_type = ?curMember.Customer_type, "+;
	"Product = ?curMember.Product, "+;
	"Plan_id = ?curMember.Plan_Id, "+;
	"Overall_Limit = ?curMember.Overall_Limit, "+;
	"Natid = ?curMember.Natid, "+;
	"Title = ?curMember.Title, "+;
	"Name = ?curMember.Name, "+;
	"Surname = ?curMember.Surname, "+;
	"Sex = ?curMember.Sex, "+;
	"Birth_date = ?curMember.Birth_date, "+;
	"Age = ?curMember.Age, "+;
	"Fax = ?curMember.Fax, "+;
	"Mobile = ?curMember.Mobile, "+;
	"Policy_date = ?curMember.Policy_date, "+;
	"Effective = ?curMember.Effective, "+;
	"Expiry = ?curMember.Expiry, "+;
	"Premium = ?curMember.Premium, "+;
	"Exclusion = ?curMember.Exclusion, "+;
	"Status = ?curMember.Status, "+;
	"Hb_Limit = ?curMember.Hb_Limit, "+;
	"Quotation = ?curMember.Quotation, "+;
	"CardNo = ?curMember.CardNo"+;
	"WHERE Tpacode = ?curMember.tpacode AND Policy_no = ?curMember.policy_no"
