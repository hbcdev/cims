SELECT Pv.fundcode, Pv.pv_no, Pv.pv_date, Pv.total, Pv.total*(Pv.wt/100) AS wt,;
	Pv_notify.prov_id, Pv_notify.prov_name;	
 FROM  cims!pv LEFT JOIN  cims!pv_notify;
   ON  Pv.fundcode+Pv.pv_no = Pv_notify.fundcode+Pv_notify.pv_no;
 WHERE Pv.fundcode = gcfundcode;
   AND Pv.pv_date BETWEEN gdstartdate AND gdenddate;
   AND Pv.send_to = 4;
 ORDER BY 3, 6;   
INTO CURSOR pvWt
IF _TALLY = 0
	RETURN
ENDIF
