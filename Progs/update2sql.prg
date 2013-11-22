SET MULTILOCKS ON 
SET DELETED ON 
CLOSE ALL 
*
*!*	SELECT tpacode, policy_no, customer_id, customer_type, product, plan_id, ;
*!*		overall_limit, natid, title, name, surname, sex, birth_date, age, fax, mobile, ;
*!*		policy_date, effective, expiry, premium, exclusion, status, hb_limit, quotation, cardno ;
*!*	FROM cims!member ;
*!*	WHERE tpacode = "SMG" AND adddate Between {^2009-11-30} AND {^2009-11-30} ;
*!*	INTO CURSOR curMember
*!*	*
*!*	IF _TALLY = 0
*!*		RETURN 
*!*	ENDIF 
*
SELECT 0

PUBLIC goCAADO as CursorAdapter 

goCAADO = CREATEOBJECT('caADO')
BROWSE 
   
DEFINE CLASS caADO AS CursorAdapter
	oConn = NULL
	oRS = NULL
	Alias = "MemberADO"
	DataSourceType = "ADO"
	SelectCmd = "SELECT " + ;
	   "tpacode, policy_no, customer_id, customer_type, product, plan_id "+;
	   "overall_limit, cardno, title, name, surname, natid"+;
	   "FROM Member WHERE tpacode = 'SMG'"
	KeyFieldList = "tpacode, policy_no"
	UpdatableFieldList = ;
	   "Tpacode, Policy_no, Customer_id, Customer_type, Product, Plan_id "+;
	   "Overall_limit, Cardno, Title, Name, Surname, Natid"
	UpdateNameList = ;
		"Tpacode Member.Tpacode, "+;
		"Policy_no Member.Policy_no, "+;
		"Customer_id Member.Customer_id, "+;
		"Customer_type Member.Customer_type, "+;
		"Product Member.Product, "+;
		"Plan_id Member.Plan_id, "+;
		"Overall_limit Member.Overall_limit, "+;
		"Cardno Member.Cardno, "+;
		"Title Member.Title"+;
		"Name Member.Name, "+;
		"Surname Member.Surname, "+;
		"Natid Member.Natid"
	Tables = "Member"
	   
   
	 FUNCTION Init()    
		This.DataSource = this.oRS
		This.oRS.ActiveConnection = this.oConn			
		This.CursorFill()
	 ENDFUNC

	FUNCTION oConn_Access() as ADODB.Connection 
	     LOCAL loConn as ADODB.Connection 
	     IF VARTYPE(this.oConn)<>"O" THEN 
		      this.oConn = NULL
	     		loConn = NEWOBJECT("ADODB.Connection")
	     		IF VARTYPE(loConn)="O" THEN 
		  		loConn.ConnectionString = ;
					"Provider=SQLNCLI.1;Persist Security Info=True;"+;
					"User ID=direct2hbc_in_th_admin2;Password=0409;"+;
					"Initial Catalog=direct2hbc_in_th_cims;Data Source=direct2hbc.in.th"	         
	       		loConn.OPEN()
	       		this.oConn = loConn
	       	ENDIF 
	     ENDIF 
	     RETURN this.oConn
	ENDFUNC 
	FUNCTION oRS_Access() as ADODB.RecordSet
		LOCAL loRS as ADODB.RecordSet
	     	IF VARTYPE(this.oRS)<>"O" THEN 
	      	this.oRS = NULL
	      	loRS = NEWOBJECT("ADODB.Recordset")
	       	IF VARTYPE(loRS)="O" THEN 
	       		loRs.CursorType = 3  && adOpenStatic 
	       		loRs.CursorLocation = 3  && adUseClient 
	       		loRs.LockType = 3  && adLockOptimistic 	
		         this.oRS = loRS
		       ENDIF 
	     ENDIF 
	     RETURN this.oRS
	ENDFUNC
	
	PROTECTED PROCEDURE AutogenerateSQL_Assign
	LPARAMETERS tlAuto
	IF TYPE("tlAuto") <> "L"
		tlAuto = .F.
	ENDIF 
	IF tlAuto	
		This.UpdateCmdDataSourceType ="ADO"		
		This.UpdateCmdDataSource = this.oRS
		This.DeleteCmdDataSourceType ="ADO"
		This.DeleteCmdDataSource = this.oRs
		This.InsertCmdDataSourceType ="ADO"
		This.InsertCmdDataSource = this.oRs
		This.UpdateCmd = "UPDATE member SET"+;
			"Customer_id = ?curMember.Customer_Id, "+;
			"Customer_type = ?curMember.Customer_Type"+;
			"Product = ?curMember.Product, "+;
			"Plan_id = ?curMember.Plan_id, "+;
			"Overall_limit = ?curMember.Overall_limit, "+;
			"Cardno = ?curMember.Cardno, "+;
			"Title = ?curMember.Title"+;
			"Name = ?curMember.Name, "+;
			"Surname = ?curMember.Surname, "+;
			"Natid = ?curMember.Natid " +;
			"WHERE Tpacode = ?curMember.Tpacode AND Policy_no = ?curMember.Policy_no"
		This.InsertCmd = "INSERT INTO Member ("+;
			"Tpacode, "+;
			"Policy_no, "+;
			"Customer_id, "+;
			"Customer_type, "+;
			"Product , "+;
			"Plan_id , "+;
			"Overall_limit, "+;
			"Cardno, "+;
			"Title"+;
			"Name, "+;
			"Surname, "+;
			"Natid)"+;
			"VALUE ("+;
			"?curMember.Tpacode, "+;
			"?curMember.Policy_no, "+;
			"?curMember.Customer_Id, "+;
			"?curMember.Customer_Type"+;
			"?curMember.Product, "+;
			"?curMember.Plan_id, "+;
			"?curMember.Overall_limit, "+;
			"?curMember.Cardno, "+;
			"?curMember.Title"+;
			"?curMember.Name, "+;
			"?curMember.Surname, "+;
			"?curMember.Natid)"
		This.DeleteCmd = "DELETE FROM member WHERE Tpacode = ?curMember.Tpacode AND Policy_no = ?curMember.Policy_no"
	ENDIF 	
	ENDPROC 	
ENDDEFINE	
