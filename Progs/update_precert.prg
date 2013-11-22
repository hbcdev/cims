DIMENSION laComment[8,1]
laComment[1] = "Patient benefit for admission"
laComment[2] = "Policy expired"
laComment[3] = "Non health rider"
laComment[4] = "Exclusion"
laComment[5] = "Reimbursement"
laComment[6] = "Unnessessary admit."
laComment[7] = "Other"
laComment[8] = "Denied (Paid to Hospital)"
*************
* Precert Report
SELECT Notify.notify_no, Notify.notify_date,;
  Notify.service_type AS type, Notify.policy_no, Notify.policy_name,;
  Notify.client_name, Notify.plan, Notify.effective, Notify.expried,;
  Notify.prov_name, Notify.admis_date, Notify.basic_diag, ;
  IIF(Notify.comment = 0, "", laComment[Notify.comment]) AS comment,;
  Notify.note2ins, Notify.status, Notify.illness, notify.concurrent_note AS concurrent, notify_pending.description AS status_txt ;
 FROM  cims!Notify LEFT JOIN cims!notify_pending ;
 ON Notify.status = Notify_pending.pending_code ;
 WHERE Notify.fundcode = gcFundCode ;
   AND TTOD(Notify.notify_date) >= gdStartDate ;
   AND Notify_pending.type = 1 ;
  INTO TABLE (gcSaveTo+"update_precert.dbf")
