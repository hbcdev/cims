gdStartDate = DATE(YEAR(DATE()), 1, 1) 
gcFundCode = "KTA"
gcSaveTo = "\\DRAGON1\Report\KTA\KTA Paid Claim Status\"
WAIT WINDOW "Wait for process....." NOWAIT 
DO update_claim_status
DO update_claim_result
DO update_pv
DO update_claim_pv
DO update_log_incomp
DO update_precert
=MESSAGEBOX("Update sucess")