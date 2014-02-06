DEFINE CLASS QueryWS AS Session OLEPUBLIC

	cStartPath = " "

	FUNCTION INIT()
		SET RESOURCE OFF 
		SET REPROCESS TO 2 SECONDS 
		SET CPDIALOG OFF 
		SET DELETED ON 
		SET EXACT OFF 
		SET SAFETY OFF 
		SET EXCLUSIVE OFF 
		
		This.cStartPath = ADDBS(JUSTPATH(Application.ServerName))
		SET PATH TO (This.cStartPath)		
 	ENDFUNC 
	
	FUNCTION  GetFunds() AS String
		LOCAL loXMLAdapter AS XMLAdapter
		LOCAL lcXMLFunds AS String 
		
		loXMLAdapter = CREATEOBJECT("XMLAdapter")
		
		OPEN DATABASE d:\hips\data\cims.dbc
		
		SELECT fundcode, name, thainame ;
		FROM cims!fund ;
		WHERE EMPTY(date_off) ;
		INTO CURSOR curFunds
		
		loXMLAdapter.AddTableSchema("curFunds")
		loXMLAdapter.UTF8Encoded = .T. 
		loXMLAdapter.ToXML("lcXMLFunds")
		
		CLOSE DATABASES ALL 
		
		RETURN lcXMLFunds
	
	FUNCTION MemberByFundCode(tcFundCode AS String) AS String 
   	
		LOCAL loXMLAdapter AS XMLAdapter
		LOCAL lcXMLMembers AS String

	       loXMLAdapter = CREATEOBJECT("XMLAdapter")
            
      		OPEN DATABASE d:\hips\data\cims.dbc
      		
             SELECT tpacode, policy_no, name, surname, product AS plan, effective, expiry, status ;
	      FROM cims!member ;
	      WHERE member.tpacode = tcFundCode ;
	      INTO CURSOR curMembers      

	      loXMLAdapter.AddTableSchema("curMembers")
	      loXMLAdapter.UTF8Encoded = .T.
	      loXMLAdapter.ToXML("lcXMLMembers")
	
	      CLOSE DATABASES ALL

	      RETURN lcXMLMembers
	ENDFUNC    

	FUNCTION MemberByFundCode(tcFundCode As String) AS String
		
	   LOCAL loXMLAdapter AS XMLAdapter
	   LOCAL lcXMLPolicys AS String

	   loXMLAdapter = CREATEOBJECT("XMLAdapter")
	   	   
 		OPEN DATABASE d:\hips\data\cims.dbc
	   
	   SELECT tpacode, policy_no, policy_name, name, surname, product AS plan, effective, expiry, status ;
	   FROM cims!member ;
	   WHERE member.tpacode = tcFundCode ;
	   INTO CURSOR curPolicys      

	   loXMLAdapter.AddTableSchema("curPolicys")
	   loXMLAdapter.UTF8Encoded = .T.
	   loXMLAdapter.ToXML("lcXMLPolicys")

	   CLOSE DATABASES ALL

	   RETURN lcXMLPolicys
	   
	ENDFUNC 

	FUNCTION MemberByPolicyNo(tcFundCode As String, tcPolicyNo AS String) AS String
		
	   LOCAL loXMLAdapter AS XMLAdapter
	   LOCAL lcXMLPolicys AS String

	   loXMLAdapter = CREATEOBJECT("XMLAdapter")
	   	   
 		OPEN DATABASE d:\hips\data\cims.dbc
	   
	   SELECT tpacode, policy_no, name, surname, product AS plan, effective, expiry, status ;
	   FROM cims!member ;
	   WHERE member.tpacode = tcFundCode ;
	   		AND member.policy_no = tcPolicyNo ;	
	   INTO CURSOR curPolicys      

	   loXMLAdapter.AddTableSchema("curPolicys")
	   loXMLAdapter.UTF8Encoded = .T.
	   loXMLAdapter.ToXML("lcXMLPolicys")

	   CLOSE DATABASES ALL

	   RETURN lcXMLPolicys
	   
	ENDFUNC 
	   
	FUNCTION MemberByName(tcFundCode AS String, tcName AS String) AS String
		
	   LOCAL loXMLAdapter AS XMLAdapter
	   LOCAL lcXMLPolicys AS String

	   loXMLAdapter = CREATEOBJECT("XMLAdapter")
	   tcName = ALLTRIM(tcName)+"%"
	   
      		OPEN DATABASE d:\hips\data\cims.dbc

	   
	   SELECT tpacode, policy_no, name, surname, product AS plan, effective, expiry, status ;
	   FROM cims!member ;
	   WHERE member.tpacode = tcFundCode ;
	   		AND member.name Like tcName ;	
	   INTO CURSOR curPolicys      

	   loXMLAdapter.AddTableSchema("curPolicys")
	   loXMLAdapter.UTF8Encoded = .T.
	   loXMLAdapter.ToXML("lcXMLPolicys")

	   CLOSE DATABASES ALL

	   RETURN lcXMLPolicys
	ENDFUNC 

	FUNCTION MemberBySurname(tcFundCode AS String, tcSurName AS String) AS String
		
	   LOCAL loXMLAdapter AS XMLAdapter
	   LOCAL lcXMLPolicys AS String

	   loXMLAdapter = CREATEOBJECT("XMLAdapter")
	   tcSurName = ALLTRIM(tcSurName)+"%"
	   
      		OPEN DATABASE d:\hips\data\cims.dbc
	   
	   SELECT tpacode, policy_no, name, surname, product AS plan, effective, expiry, status ;
	   FROM cims!member ;
	   WHERE member.tpacode = tcFundCode ;
	   		AND member.surname Like tcSurName ;	
	   INTO CURSOR curPolicys      

	   loXMLAdapter.AddTableSchema("curPolicys")
	   loXMLAdapter.UTF8Encoded = .T.
	   loXMLAdapter.ToXML("lcXMLPolicys")

	   CLOSE DATABASES ALL

	   RETURN lcXMLPolicys
	ENDFUNC 

	FUNCTION MemberByFullName(tcFundCode AS String, tcPolicyNo AS String, tcName AS String) AS String
		
	    LOCAL loXMLAdapter AS XMLAdapter
	   LOCAL lcXMLPolicys AS String

	    loXMLAdapter = CREATEOBJECT("XMLAdapter")
	       
      		OPEN DATABASE d:\hips\data\cims.dbc
	       
	    SELECT tpacode, policy_no, name, surname, product AS plan, effective, expiry, status ;
	    FROM cims!member ;
	    WHERE member.tpacode = tcFundCode ;
	    		AND member.policy_no = tcPolicyNo ;	
	    		AND member.name = tcFullName ;	
	    INTO CURSOR curPolicys      

	    loXMLAdapter.AddTableSchema("curPolicys")
	    loXMLAdapter.UTF8Encoded = .T.
	    loXMLAdapter.ToXML("lcXMLPolicys")

	    CLOSE DATABASES ALL

	    RETURN lcXMLPolicys
	   
	ENDFUNC    

	FUNCTION ClientByPolicyNo(tcFundCode AS String, tcPolicyNo AS String) AS String
		
	    LOCAL loXMLAdapter AS XMLAdapter
	   LOCAL lcXMLPolicys AS String

	    loXMLAdapter = CREATEOBJECT("XMLAdapter")
	       
      		OPEN DATABASE d:\hips\data\cims.dbc
	       
	    SELECT fundcode, policy_no, person_no, client_no, name, surname, plan, effective, expired ;
	    FROM cims!dependants ;
	    WHERE dependants.fundcode = tcFundCode ;
	    		AND dependants.policy_no = tcPolicyNo ;	
	    INTO CURSOR curPolicys      

	    loXMLAdapter.AddTableSchema("curPolicys")
	    loXMLAdapter.UTF8Encoded = .T.
	    loXMLAdapter.ToXML("lcXMLPolicys")

	    CLOSE DATABASES ALL

	    RETURN lcXMLPolicys
	   
	ENDFUNC    
	
	FUNCTION ClientByPersonNo(tcFundCode AS String, tcPolicyNo AS String, tcPersonNo AS Integer) AS String
		
	    LOCAL loXMLAdapter AS XMLAdapter
	   LOCAL lcXMLPolicys AS String

	    loXMLAdapter = CREATEOBJECT("XMLAdapter")
	       
      		OPEN DATABASE d:\hips\data\cims.dbc
	       
	    SELECT fundcode, policy_no, person_no, client_no, name, surname, plan, effective, expired ;
	    FROM cims!dependants ;
	    WHERE dependants.fundcode = tcFundCode ;
	    		AND dependants.policy_no = tcPolicyNo ;
	    		AND dependants.person_no = tcPersonNo ;	
	    INTO CURSOR curPolicys      

	    loXMLAdapter.AddTableSchema("curPolicys")
	    loXMLAdapter.UTF8Encoded = .T.
	    loXMLAdapter.ToXML("lcXMLPolicys")

	    CLOSE DATABASES ALL

	    RETURN lcXMLPolicys
	   
	ENDFUNC    

	FUNCTION ClientByClientNo(tcFundCode AS String, tcPolicyNo AS String, tcClientNo AS String) AS String
		
	    LOCAL loXMLAdapter AS XMLAdapter
	   LOCAL lcXMLPolicys AS String

	    loXMLAdapter = CREATEOBJECT("XMLAdapter")
	       
	          		OPEN DATABASE d:\hips\data\cims.dbc
	       
	    SELECT fundcode, policy_no, person_no, client_no, name, surname, plan, effective, expired ;
	    FROM cims!dependants ;
	    WHERE dependants.fundcode = tcFundCode ;
	    		AND dependants.policy_no = tcPolicyNo ;
	    		AND dependants.client_no = tcClientNo ;	
	    INTO CURSOR curPolicys      

	    loXMLAdapter.AddTableSchema("curPolicys")
	    loXMLAdapter.UTF8Encoded = .T.
	    loXMLAdapter.ToXML("lcXMLPolicys")

	    CLOSE DATABASES ALL

	    RETURN lcXMLPolicys
	   
	ENDFUNC    
	
	FUNCTION ClaimByPolicyNo(tcFundCode AS String, tcPolicyNo AS String) AS String
		
	    LOCAL loXMLAdapter AS XMLAdapter
	    LOCAL lcXMLClaims AS String

	    loXMLAdapter = CREATEOBJECT("XMLAdapter")
	       
	          		OPEN DATABASE d:\hips\data\cims.dbc
	       
	    SELECT notify_no, claim_date, service_type, cause_type, prov_name, admis_date, disc_date, indication_admit, diag_plan, note2ins, ;
	    	IIF(EMPTY(fax_by), scharge, fcharge) AS charge, IIF(EMPTY(fax_by), sbenfpaid, fbenfpaid) AS paid, result, return_date ;
	    FROM cims!claim ;
	    WHERE claim.fundcode = tcFundCode ;
	    		AND claim.policy_no = tcPolicyNo ;
	    INTO CURSOR curClaims

	    loXMLAdapter.AddTableSchema("curClaims")
	    loXMLAdapter.UTF8Encoded = .T.
	    loXMLAdapter.ToXML("lcXMLClaims")

	    CLOSE DATABASES ALL

	    RETURN lcXMLClaims
	   
	ENDFUNC    
	
	FUNCTION ClaimLineByNotifyNo(tcNotifyNo AS String) AS String
		
	    LOCAL loXMLAdapter AS XMLAdapter
	    LOCAL lcXMLClaimLines AS String

	    loXMLAdapter = CREATEOBJECT("XMLAdapter")
	       
	          		OPEN DATABASE d:\hips\data\cims.dbc
	       
	    SELECT description, service_type, serv_cover, benf_cover, IIF(EMPTY(fcharge), scharge - sdiscount, fcharge-fdiscont) AS charge, ;
	    	IIF(EMPTY(fpaid), spaid, fpaid) AS paid, benefit ;
	    FROM cims!claim_line ;
	    WHERE claim.notify_no = tcNotifyNo ;
	    INTO CURSOR curClaimLines

	    loXMLAdapter.AddTableSchema("curClaimLiness")
	    loXMLAdapter.UTF8Encoded = .T.
	    loXMLAdapter.ToXML("lcXMLClaimLineLines")

	    CLOSE DATABASES ALL

	    RETURN lcXMLClaimLines
	   
	ENDFUNC    
	
enddefine

DEFINE CLASS ShowCustomers AS Session OLEPUBLIC
   PROCEDURE CustomersInGermany AS String
      LOCAL loXMLAdapter AS XMLAdapter
      LOCAL lcXMLCustomers AS String

      loXMLAdapter = CREATEOBJECT("XMLAdapter")
      
      OPEN DATABASE "C:\Program Files\Microsoft Visual FoxPro 9\" ;
        + "Samples\Northwind\northwind.dbc"

      USE customers
      SELECT * ;
        FROM customers ;
        WHERE country LIKE "Germany%" ;
        INTO CURSOR curCustomers

      loXMLAdapter.AddTableSchema("curCustomers")
      loXMLAdapter.UTF8Encoded = .T.
      loXMLAdapter.ToXML("lcXMLCustomers")

      CLOSE DATABASES ALL

      RETURN lcXMLCustomers
   ENDPROC
ENDDEFINE


