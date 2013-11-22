PARAMETERS tcFundCode, tdStartDate, tdEndDate, tnClaimBy, tcSaveTo

IF EMPTY(tcFundCode) AND EMPTY(tdStartDate) AND EMPTY(tdEndDate) AND EMPTY(tnClaimBy)
	RETURN 
ENDIF 	

lcOrder = IIF(tnClaimBy = 2, "7", "4")+", claim.notify_no"

SET PROCEDURE TO progs\utility
SELECT claim.notify_no, claim.policy_no, claim.client_name, claim.service_type, claim.prov_name, claim.admis_date, claim.paid_to, claim.indication_admit, claim.disc_date, claim.scharge, ;
	claim.sdiscount, claim.snopaid, claim.sbenfpaid, claim.deduc_paid, claim.copayment, claim.snote, claim.currency_rate, claim.refno, claim.ref_date, claim.sday, claim.sremain, claim.diag_plan, ;
	claim.illness1, claim.illness2, claim.currency_type, claim.currency_rate AS fxrate, claim.result, claim.return_date, claim.note2ins, IIF(EMPTY(provider.engname), provider.name, provider.engname) AS hospname ;	
FROM cims!claim INNER JOIN cims!provider ;
	ON claim.prov_id = provider.prov_id ;
WHERE claim.fundcode = tcFundCode ;
	AND claim.inv_page = tnClaimBy ;	
	AND claim.result <> "C" ;
	AND claim.return_date BETWEEN tdStartDate AND tdEndDate ;
ORDER BY &lcOrder ;	
INTO CURSOR curAviClaim

IF _TALLY = 0
	=MESSAGEBOX("No data found for this period", 0, "Warning")
	RETURN 
ENDIF 
*	
SELECT curAviClaim
loExcel = CREATEOBJECT("Excel.Application")
loWorkBook = loExcel.Workbooks.ADD()
loWorkSheet = loWorkBook.WorkSheets(1)
WITH loWorkSheet
	.Cells(1,1).Value = "Claim Summary for Paid to Client"
	.Cells(1,22).Value = "Return Date:"
	.Cells(1,23).Value = DTOC(tdStartDate)+" - "+DTOC(tdEndDate)
	.Cells(3,1).Value = "Notify No"	
	.Cells(3,2).Value = "Receive Date"
	.Cells(3,3).Value = "Policy No"
	.Cells(3,4).Value = "Client Name"
	.Cells(3,5).Value = "Hospital"
	.Cells(3,6).Value = "Service From Date"
	.Cells(3,7).Value = "Service Thru Date"
	.Cells(3,8).Value = "ICD 10 #1"
	.Cells(3,9).Value = "ICD 10 #2"
	.Cells(3,10).Value = "Hospital Charges"
	.Cells(3,11).Value = "Hospital Discount"
	.Cells(3,12).Value = "Non Coverd"
	.Cells(3,13).Value = "Deductible"
	.Cells(3,14).Value = "Copayment/Non Payable"
	.Cells(3,15).Value = "Total Amount Payable"
	.Cells(3,16).Value = "Invoice no"
	.Cells(3,17).Value = "Claim Type"
	.Cells(3,18).Value = "Currency code"
	.Cells(3,19).Value = "FX Rate"
	.Cells(3,20).Value = "(THB) Total Amount Payable"
	.Cells(3,21).Value = "Comments"
	.Cells(3,22).Value = "Indication Admit"
	.Cells(3,23).Value = "Treatment Note"
	.Cells(3,24).Value = "Paid To"	
	.Cells(3,25).Value = "Paid Date"
	.Cells(3,26).Value = "Cheque No"
	.Cells(3,27).Value = "Bank"	
	.Columns("A:I").ColumnWidth = 20
	.Columns("D:E").ColumnWidth = 30
	.Columns("U:X").ColumnWidth = 50	
	.Columns("Y:AA").ColumnWidth = 20	
 	.Columns("J:O").NumberFormat = "#,##0.00"
 	.Columns("S:T").NumberFormat = "#,##0.00"
ENDWITH 	
lnRows = 4
DO CASE 
CASE tnClaimBy = 1
	lcFile = 	"Claim_Client_of_"+DTOS(tdStartDate)+"_"+DTOS(tdEndDate)
	DO WHILE !EOF()
		WITH loWorkSheet
			.Cells(lnRows,1).Value = [']+ALLTRIM(notify_no)
			.Cells(lnRows,2).Value = ref_date
			.Cells(lnRows,3).Value = ALLTRIM(policy_no)
			.Cells(lnRows,4).Value = ALLTRIM(client_name)
			.Cells(lnRows,5).Value = ALLTRIM(hospname)
			.Cells(lnRows,6).Value = admis_date
			.Cells(lnRows,7).Value = disc_date
			.Cells(lnRows,8).Value = illness1
			.Cells(lnRows,9).Value = illness2
			.Cells(lnRows,10).Value = scharge
			.Cells(lnRows,11).Value = sdiscount
			.Cells(lnRows,12).Value = snopaid
			.Cells(lnRows,13).Value = deduc_paid
			.Cells(lnRows,14).Value = sremain
			.Cells(lnRows,15).Value = sbenfpaid
			.Cells(lnRows,16).Value = ALLTRIM(refno)
			.Cells(lnRows,17).Value = service_type
			.Cells(lnRows,18).Value = currency_type
			.Cells(lnRows,19).Value = fxrate
			.Cells(lnRows,20).Value = IIF(fxrate = 0 AND (EMPTY(currency_type) OR currency_type ="THB"), sbenfpaid, CEILING(sbefpaid*fxrate))
			.Cells(lnRows,21).Value = ALLTRIM(snote)+" "+ALLTRIM(note2ins)
			.Cells(lnRows,22).Value = ALLTRIM(indication_admit)
			.Cells(lnRows,23).Value = ALLTRIM(diag_plan)
			.Cells(lnRows,24).Value = ALLTRIM(paid_to)
		ENDWITH 	
		lnRows = lnRows+1
		SKIP 
	ENDDO 
CASE tnClaimBy = 2
	lcFile = 	"Claim_Hospital_of_"+DTOS(tdStartDate)+"_"+DTOS(tdEndDate)	
	DO WHILE !EOF()
		WITH loWorkSheet
			.Cells(lnRows,1).Value = [']+ALLTRIM(notify_no)
			.Cells(lnRows,2).Value = ref_date
			.Cells(lnRows,3).Value = ALLTRIM(policy_no)
			.Cells(lnRows,4).Value = ALLTRIM(client_name)
			.Cells(lnRows,5).Value = ALLTRIM(hospname)
			.Cells(lnRows,6).Value = admis_date
			.Cells(lnRows,7).Value = disc_date
			.Cells(lnRows,8).Value = illness1
			.Cells(lnRows,9).Value = illness2
			.Cells(lnRows,10).Value = scharge
			.Cells(lnRows,11).Value = sdiscount
			.Cells(lnRows,12).Value = snopaid
			.Cells(lnRows,13).Value = deduc_paid
			.Cells(lnRows,14).Value = sremain
			.Cells(lnRows,15).Value = sbenfpaid
			.Cells(lnRows,16).Value = refno
			.Cells(lnRows,17).Value = service_type
			.Cells(lnRows,18).Value = currency_type
			.Cells(lnRows,19).Value = fxrate
			.Cells(lnRows,20).Value = IIF(fxrate = 0 AND (EMPTY(currency_type) OR currency_type ="THB"), sbenfpaid, CEILING(sbefpaid*fxrate))
			.Cells(lnRows,21).Value = ALLTRIM(snote)+" "+ALLTRIM(note2ins)
			.Cells(lnRows,22).Value = ALLTRIM(indication_admit)
			.Cells(lnRows,23).Value = ALLTRIM(diag_plan)
			.Cells(lnRows,24).Value = ALLTRIM(paid_to)
		ENDWITH 	
		lnRows = lnRows+1
		SKIP 
	ENDDO 
ENDCASE 	
lcXlsFile = ADDBS(tcSaveTo)+lcFile
loWorkBook.SaveAS(lcXlsFile)
loExcel.quit

