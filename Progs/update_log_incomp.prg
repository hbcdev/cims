SELECT Notify_log.notify_no, Notify_log.summit, Notify_log.policy_no,;
  Notify_log.client_name, Notify_log.plan, Notify_log.effective,;
  Notify_log.expried, Notify_log.acc_date, Notify_log.prov_name,;
  Notify_log.admis_date, Notify_log.indication_admit, Notify_log.agent,;
  Notify_log.agency, Notify_log.mail_date, Notify_log.diags_note, Notify_log.note ;
 FROM cims!notify_log;
 WHERE Notify_log.fundcode = gcFundCode ;
   AND Notify_log.summit >= gdStartDate;
   AND EMPTY(Notify_log.diags_note) = .F.;
 INTO TABLE (gcSaveTo+"update_log.dbf")
