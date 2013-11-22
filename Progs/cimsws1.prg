DEFINE CLASS QueryWS AS Session OLEPUBLIC

  cimsdb = "d:\hips\data\cims.dbc"	

   PROCEDURE MemberByFullName AS String
   	LPARAMETERS tcFundCode, tcPolicyNo, tcName
   	
      LOCAL loXMLAdapter AS XMLAdapter
      LOCAL lcXMLMembers AS String

      loXMLAdapter = CREATEOBJECT("XMLAdapter")
      
      OPEN DATABASE (CIMSDB)
      
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
   ENDPROC
   
ENDDEFINE