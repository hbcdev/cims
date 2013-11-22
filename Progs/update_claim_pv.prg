SELECT Update_claim_result1.notify_no, Update_claim_result1.notify_dat,;
  Update_claim_result1.claim_no, Update_claim_result1.claim_type,;
  Update_claim_result1.policy_no, Update_claim_result1.plan,;
  Update_claim_result1.client_nam, Update_claim_result1.effective,;
  Update_claim_result1.expried, Update_claim_result1.prov_name,;
  Update_claim_result1.admis_date, Update_claim_result1.disc_date,;
  Update_claim_result1.illness1, Update_claim_result1.descriptio,;
  Update_claim_result1.indi_admit, Update_claim_result1.treatment,;    
  Update_claim_result1.fcharge, Update_claim_result1.fdiscount,;
  Update_claim_result1.fbenfpaid, Update_claim_result1.fnopaid,;
  Update_claim_result1.fremain, Update_claim_result1.fnote,;
  Update_claim_result1.scharge, Update_claim_result1.sdiscount,;
  Update_claim_result1.sbenfpaid, Update_claim_result1.snopaid,;
  Update_claim_result1.sremain, Update_claim_result1.assessor_d,;
  Update_claim_result1.snote, Update_claim_result1.consult,Update_claim_result1.exgratia,;
  Update_claim_result1.anote, Update_claim_result1.result,;
  Update_claim_result1.descripti2, Update_claim_result1.return_dat,;
  Update_claim_result1.pvno, Update_claim_result1.paid_date,;
  Update_claim_result1.paid_to, Update_claim_result1.chqno, update_pv.draftno, ;
  Update_claim_result1.agent_code, Update_claim_result1.agent,;
  Update_claim_result1.agency;
 FROM  Update_claim_result1 LEFT OUTER JOIN update_pv ;
   ON  Update_claim_result1.pvno = update_pv.pv_no ;
 INTO TABLE (gcSaveTo+"update_claim_result.dbf")
 