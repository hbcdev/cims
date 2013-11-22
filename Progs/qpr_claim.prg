SET TALK ON
*
SELECT Claim.refno, Claim.notify_no, Claim.notify_date, Claim.policy_no,;
  Claim.claim_type, Claim.type_claim, Claim.admis_date, Claim.disc_date,;
  TTOD(Claim.disc_date)-TTOD(Claim.admis_date) AS total_date,;
  Claim.fnote, Claim.illness1, Claim.doctor_note, Claim_line.cat_code,;
  Claim_line.fadmis, Claim_line.fcharge, Claim_line.fpaid,;
  Claim_line.fcharge-Claim_line.fpaid AS over_paid, Claim_line.fnote,;
  Claim.customer_id, Claim.prov_id;
 FROM  cims!claim LEFT OUTER JOIN cims!claim_line ;
   ON  Claim.claim_id = Claim_line.claim_id;
 WHERE TTOD(Claim.notify_date) >= {^ 2000-05-18};
   AND LEFT(Claim.customer_id,3) = "SEI";
 ORDER BY Claim.notify_no;
 INTO CURSOR Claim_a
********************************************
IF USED("claim_a")
	SELECT claim_a.*, notify.prov_name, notify.basic_diag, notify.comment. notify.status;
	FROM Claim_a LEFT OUTER JOIN cims!notify;
		ON claim_a.notify_no = notify.notify_no ;
	INTO CURSOR Claim_b
ENDIF		
	
IF USED("claim_b")
	SELECT A.* ,  ALLTRIM(B.name)+" "+ALLTRIM(B.surname) AS name, B.product, B.pay_fr;
	FROM claim_b A LEFT OUTER JOIN cims!member B;
		ON A.customer_id = B.tpacode+B.customer_id ;
	INTO CURSOR Claim_c
ENDIF		
SET TALK OFF