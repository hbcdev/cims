OPEN DATABASE ?

CREATE TABLE (ADDBS(JUSTPATH(DBC()))+"EDC02") NAME claimpayment (notify_no C(10) NULL, transdate T NULL, mid C(15) NULL, ;
	 tid C(8) NULL , cardno C(30) NULL , fundcode C(3) NULL , policy_no C(30) NULL , client_name C(60) NULL , plan C(20) NULL , ;
	 plan_id C(8) NULL , effdate T NULL , expdate T NULL , accdate T NULL , prov_id C(8) NULL , prov_name C(50) NULL , medical Y NULL , ;
	 opdcover Y NULL, charge Y NULL , paid Y NULL , apprv C(6) NULL)
	
INDEX on notify_no TAG notify_no
INDEX on mid TAG mid
INDEX on cardno TAG cardno
INDEX on fundcode TAG fundcode
INDEX on policy_no TAG policy_no
INDEX on plan TAG plan
INDEX on plan_id TAG plan_id	
	
	