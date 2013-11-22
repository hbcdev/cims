SELECT Update_paid_claim.notify_no, Update_paid_claim.notify_dat,;
  Update_paid_claim.claim_no, Update_paid_claim.claim_type,;
  Update_paid_claim.policy_no, Update_paid_claim.plan,;
  Update_paid_claim.client_nam, Update_paid_claim.effective,;
  Update_paid_claim.expried, Update_paid_claim.prov_name,;
  Update_paid_claim.admis_date, Update_paid_claim.disc_date,;
  Update_paid_claim.illness1, Update_paid_claim.descriptio,;
  Update_paid_claim.indi_admit, Update_paid_claim.treatment,;  
  Update_paid_claim.fcharge, Update_paid_claim.fdiscount,;
  Update_paid_claim.fbenfpaid, Update_paid_claim.fnopaid,;
  Update_paid_claim.fremain, Update_paid_claim.fnote,;
  Update_paid_claim.scharge, Update_paid_claim.sdiscount,;
  Update_paid_claim.sbenfpaid, Update_paid_claim.snopaid,;
  Update_paid_claim.sremain, Update_paid_claim.assessor_d,;
  Update_paid_claim.snote, Update_paid_claim.consult,Update_paid_claim.exgratia,;
  Update_paid_claim.anote, Update_paid_claim.result,;
  Claim_settlement.description, Update_paid_claim.return_dat,;
  Update_paid_claim.pvno, Update_paid_claim.paid_date,;
  Update_paid_claim.paid_to, Update_paid_claim.chqno,;
  Update_paid_claim.agent_code, Update_paid_claim.agent,;
  Update_paid_claim.agency, Update_paid_claim.pdays;
 FROM  update_paid_claim LEFT OUTER JOIN cims!claim_settlement ;
   ON  Update_paid_claim.result = Claim_settlement.code;
  ORDER BY Update_paid_claim.result, Update_paid_claim.pdays ; 
 INTO TABLE (gcSaveTo+"update_claim_result1.dbf")
 
