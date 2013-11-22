lcFile = "\\hbcnt\apps\report\kta\kta paid claim status\update_paid_claim"+STRTRAN(DTOC(DATE()), "/", "_")
******************
*SELECT Claim.notify_no, Claim.notify_date, Claim.claim_no,;
*  Claim.claim_type, Claim.policy_no, Claim.plan, Claim.client_name,;
*  Claim.effective, Claim.expried, Claim.prov_name, Claim.admis_date,;
*  Claim.disc_date, Claim.illness1, Claim.illness2, Claim.fcharge,;
*  Claim.fdiscount, Claim.fbenfpaid, Claim.fnopaid, Claim.fremain,;
*  Claim.fnote, Claim.scharge, Claim.sdiscount, Claim.sbenfpaid,;
*  Claim.snopaid, Claim.sremain, Claim.snote, Claim.exgratia, Claim.anote,;
*  Claim.result, Claim.return_date, Claim.pvno, Claim.paid_date,;
*  Claim.paid_to, Claim.chqno;
* FROM cims!claim;
* WHERE Claim.fundcode = "KTA" ;
*   AND LEFT(result,1) <> "C" ;
* ORDER BY Claim.result, plan, policy_no ;
* INTO CURSOR upclaim
* IF _TALLY = 0
* 	RETURN 
* ENDIF 

USE "\\hbcnt\apps\report\kta\kta paid claim status\update_paid_claim" ALIAS upclaim 
o = CREATEOBJECT("Excel.Application")
oBook = o.Workbooks.Add()
SELECT upclaim
lnFields = AFIELDS()
DO WHILE !EOF()
	 lcProd = LEFT(plan,2)
	 lcResult = LEFT(result,1)
	 *******************
	 DO CASE 
	 CASE lcresult = "A" 
	 	lcStatus = "Paid"
	 CASE lcresult = "P" 
	 	lcStatus = "Paid"
	 CASE lcresult = "D" 
	 	lcStatus = "Denied"
	 CASE lcresult = "W" 
	 	lcStatus = "Wait"
	ENDCASE  
	******************* 
	 oSheet = oBook.Add()
	 oSheet.Name = lcProd+"-"+lcStatus
	 ********
	FOR i = 1 TO lnFields
		oSheet.Cells(1,i) = FIELD(i)
	ENDFOR	 
	******************************	 
	 lnrow = 2
	 DO WHILE lcprod = LEFT(plan,2) AND lcresult = LEFT(result,1) AND !EOF() 
		WAIT WINDOW STR(RECNO(),5)+"Records." NOWAIT 
		FOR i = 1 TO FCOUNT()
			lcField = FIELD(i)
			lcValue = &lcField
			IF !EMPTY(lcValue)
				oSheet.Cells(lnRow,i) = lcValue
			ENDIF
		ENDFOR
		lnRow = lnRow + 1
		 SKIP 
	ENDDO 	 	
ENDDO
oWorkBook.SaveAs(lcFile)
oExcel.Visible = .F.
oExcel.Quit
WAIT WINDOW " Transfer Sucess ......" TIMEOUT 5