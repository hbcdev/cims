SET MULTILOCKS ON 
SET DELETED ON 
   
DEFINE CLASS caADO AS CursorAdapter
	oConn = NULL
	oRS = NULL
	Alias = "caMember"
	DataSourceType = "ADO"
	SelectCmd = "select * from member where tpacode = ?this.cFundCode and policy_no = ?this.cPolicyNo"
	KeyFieldList = "tpacode, policy_no"
	UpdatableFieldList = ;
		"access_lvl, acname, acno, adddate, address, adj_permium_date, adj_plan_date, adjcancel, adjlapse, "+;
		"adjrefund, adjrein, age, agency_name, agent, agent_addr1, agent_addr2, agent_addr3, agent_addr4, "+;
		"agent_addr5, agent_addr6, agent_name, agent_phone, agent_postcode, agent_province, agentcy, "+;
		"bankcode, bankname, birth_date, branch_code, brcode, brname, canceldate, cancelexp, cardno, "+;
		"cause1, cause10, cause11, cause12, cause2, cause3, cause4, cause5, cause6, cause7, cause8, cause9, "+;
		"contact_name, contact_phone, customer_id, customer_type, duty, effective, effective_y, employee, end_serial, "+;
		"exclusion, expiry, expried_y, family_no, fax, fund_id, h_addr1, h_addr2, h_city, h_country, h_phone, h_postcode, "+;
		"h_province, hb_cover, hb_limit, infonote, insure, l_addr1, l_addr2, l_city, l_country, l_postcode, l_submit, l_update, l_user, "+;
		"lapsedate, lastpaid, mail_address, middlename, mobile, name, natid, no_of_pers, notation, occupn_class, occupn_code, "+;
		"old_occupn_code, old_policyno, oldeffective, oldexpiry, oldperiumn, oldplan, overall_limit, package, pay_fr, pay_mode, "+;
		"pay_seq, pay_status, payee, plan_id, policy_date, policy_end, policy_group, policy_name, policy_no, policy_start, polstatus, "+;
		"premium, product, quotation, refunddate, reindate, renew, replace_date, sex, start_date, status, surname, "+;
		"title, tpacode, wk_phone"	
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
		This.AddProperty("cFundCode",NULL)
		This.AddProperty("cPolicyNo",NULL)
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
					'Provider=SQLNCLI10.1;Integrated Security=SSPI;'+;
					'Persist Security Info=False;User ID="";'+;
					'Initial Catalog=Cims;Data Source=(local)'
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
			"Customer_id = ?m.Customer_Id, "+;
			"Customer_type = ?m.Customer_Type"+;
			"Product = ?m.Product, "+;
			"Plan_id = ?m.Plan_id, "+;
			"Overall_limit = ?m.Overall_limit, "+;
			"Cardno = ?m.Cardno, "+;
			"Title = ?m.Title"+;
			"Name = ?m.Name, "+;
			"Surname = ?m.Surname, "+;
			"Natid = ?m.Natid " +;
			"WHERE Tpacode = ?m.Tpacode AND Policy_no = ?m.Policy_no"
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
			"?m.Tpacode, "+;
			"?m.Policy_no, "+;
			"?m.Customer_Id, "+;
			"?m.Customer_Type"+;
			"?m.Product, "+;
			"?m.Plan_id, "+;
			"?m.Overall_limit, "+;
			"?m.Cardno, "+;
			"?m.Title"+;
			"?m.Name, "+;
			"?m.Surname, "+;
			"?m.Natid)"
		This.DeleteCmd = "DELETE FROM member WHERE Tpacode = ?curMember.Tpacode AND Policy_no = ?m.Policy_no"
	ENDIF 	
	ENDPROC 	
ENDDEFINE	
