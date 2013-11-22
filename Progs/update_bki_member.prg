CLOSE ALL 
SET MULTILOCKS ON 

USE cims!dependants IN A
USE cims!plan IN B
USE cims!member IN C

=CURSORSETPROP("Buffering", 5, "member")
=CURSORSETPROP("Buffering", 5, "dependants")
********************************
SET DEFAULT TO ?

lnAmountFiles = ADIR(laBki, "*.DBF")
FOR lnFile = 1 TO lnAmountFiles
	DO UpdateData WITH laBki[lnFile, 1]
ENDFOR 		

PROCEDURE UpdateData
PARAMETERS tcDbf
IF EMPTY(tcDbf)
	RETURN 
ENDIF 	

SELECT D
?tcDbf
USE (tcDbf) ALIAS bkiData
********************
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	SCATTER MEMVAR 	
	lcFleetSeq = "BKI"+policy_no+STR(fleet_seq)+plan
	IF SEEK(lcFleetSeq, "dependants", "fleet_plan")
		m.person_no = dependants.person_no
		IF m.cancel_flg = "C"
			m.status = m.cancel_flg
			m.expdate = m.effdate							
		ENDIF 	
	ELSE 
		***************************
		lcPolNo = "BKI"+m.policy_no
		IF SEEK(lcPolNo, "member", "policy_no")
			REPLACE member.insure WITH member.insure + 1
			m.person_no = member.insure
		ELSE 
			APPEND BLANK IN member
			REPLACE member.fund_id WITH 3, member.tpacode WITH "BKI", ;
				member.policy_group WITH m.policy_no, ;
				member.policy_name WITH m.cus_name, ;
				member.policy_no WITH m.policy_no, ;
				member.name WITH m.cus_name, ;
				member.customer_type WITH "T", ;
				member.customer_id WITH m.cus_code, ;
				member.effective_y WITH m.effdate, ;
				member.effective WITH m.effdate, ;
				member.expiry WITH m.expdate, ;
				member.policy_date WITH m.effdate				
			m.person_no = 1
		ENDIF 
		***********************************
		APPEND BLANK IN dependants
		REPLACE dependants.adddate WITH DATE()
	ENDIF 	
	********************
	IF SEEK("BKI"+m.plan, "plan", "plan")
		m.plan_id = IIF(EMPTY(plan.same_as), plan.plan_id, plan.same_as)
	ELSE 
		m.plan_id = ""
	ENDIF 		
	********************	
	REPLACE dependants.fundcode WITH "BKI", ;
		dependants.policy_no WITH m.policy_no, ;
		dependants.person_no WITH m.fleet_seq ;
		dependants.suffix WITH m.fam_sts, ;		
		dependants.client_no WITH m.cust_id, ;
		dependants.title WITH m.title, ;
		dependants.name WITH m.name, ;
		dependants.surname WITH m.surname, ;
		dependants.plan WITH m.plan, ;
		dependants.plan_id WITH m.plan_id, ;
		dependants.effective WITH m.effdate, ;
		dependants.expired WITH m.expdate, ;
		dependants.dob WITH m.dob, ;
		dependants.sex WITH m.sex, ;
		dependants.age WITH m.age, ;
		dependants.premium WITH m.premium, ;
		dependants.exclusion WITH m.exclusion, ;
		dependants.fleet_seq WITH m.fleet_seq, ;
		dependants.fam_seq WITH m.fam_seq, ;
		dependants.sub_seq WITH m.sub_seq, ;		
		dependants.cus_code WITH m.cus_code, ;
		dependants.cus_name WITH m.cus_name, ;
		dependants.unique_no WITH m.unique_no, ;		
		dependants.status WITH IIF(m.cancel_flg = "C", m.cancel_flg, m.pol_status), ;
		dependants.employee WITH IIF(m.sub_seq = 0, "Y", "N"), ;
		dependants.endosno WITH m.endos, ;
		dependants.acno WITH "2080051515", ;
		dependants.acname WITH "สหกรณ์ออมทรัพย์การไฟฟ้าฝ่ายผลิตแห่งประเทศไทย จำกัด", ;
		dependants.acbank_code WITH "002", ;
		dependants.acbank WITH "ธนาคารกรุงเทพจำกัด (มหาชน)  ", ;
		dependants.acbranch WITH "บางกรวย", ;
		dependants.acbranch_code WITH "208", ;
		dependants.payee_addr1 WITH "การไฟฟ้าฝ่ายผลิตแห่งประเทศไทย จำกัด    ", ;
		dependants.payee_addr2 WITH "53 หมู่ 2 ถนนจรัญสนิทวงศ์ ตำบลบางกรวย อำเภอบางกรวย จังหวัดนนทบุรี" , ;
		dependants.payee_jw_code WITH "23", ;
		dependants.payee_zip_code WITH "11130", ;
		dependants.payee_tel WITH "024365911", ;
		dependants.l_user WITH "VACHARA", ;
		dependants.l_update WITH DATETIME()
ENDSCAN 	
