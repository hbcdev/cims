SET SAFETY ON 
gdStartDate = DATE(YEAR(DATE()), 1, 1) 
gcFundCode = "ACE"
gcSaveTo = "\\DRAGON1\Report\ACE\"
lcDate = ALLTRIM(STR(DAY(DATE())))+"_"+ALLTRIM(CMONTH(DATE()))+"_"+ALLTRIM(STR(YEAR(DATE())))
WAIT WINDOW "Wait for process....." NOWAIT 
DO progs\update_claim_status
DO progs\update_claim_result
DO progs\update_log_incomp
DO progs\update_precert
*
USE IN update_paid_claim
USE IN update_claim_result1
USE IN update_precert
USE IN update_log
*
oExcel = CREATEOBJECT("Excel.Application")
oBook = oExcel.workBooks.Add("\\dragon1\report\ace\template\ace update claim template")
oBook.RefreshAll
lcExcelCover = ADDBS(gcSaveTo)+STRTRAN(DTOC(DATE()), "/", "-")+"_"+gcFundCode+"_Claim_Update_As_of "+lcDate
oBook.SaveAs(lcExcelCover)
oExcel.Quit
*
IF !FILE(lcExcelCover+".XLS")
	=MESSAGEBOX("ไม่พบไฟล์ที่ต้องการให้ส่งเมล์ ",0+48,"Update Claim to Healthfund")
	RETURN 
ENDIF 	
*
lcFrom = "edp@hbc.co.th"
lcTo = "vacharaa@hbc.co.th"
lcSubject = "ACE Claim Update as of "+ lcDate
DO progs\SendCdoMail WITH  lcFrom, lcTo, lcSubject, lcExcelCover

=MESSAGEBOX("Update sucess")