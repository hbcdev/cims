DEFINE CLASS cims AS Session OLEPUBLIC 
	cDatabase = "g:\hips\data\cims.dbc"
	OPEN DATABASE (cDatabase)
FUNCTION GetClient(tcFundCode, tcPolicyNo, tnPersonNo)
	SELECT * ;
	FROM cims!member;
	WHERE tpacode = tcFundCode;
		AND policy_no = tcPolicyNo;
		AND family_no = tnPersonNo;
	INTO CURSOR curMember
RETURN _TALLY
*****************************
FUNCTION GetClientAll(tcFundCode)
	SELECT * ;
	FROM cims!member;
	WHERE tpacode = tcFundCode;
		AND policy_no = tcPolicyNo;
		AND family_no = tnPersonNo;
	INTO CURSOR curClientAll
RETURN _TALLY
