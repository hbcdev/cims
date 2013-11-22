*SET PROCEDURE TO progs\utility

IF !USED("DataMaster")
	USE (GETFILE("DBF", "Master File")) IN 0 ALIAS DataMaster
ENDIF 
IF !USED("DataDetail")	
	USE (GETFILE("DBF", "Detail File")) IN 0 ALIAS DataDetail
ENDIF 	
*
SELECT outs_id, not_sts, not_no, revision, reg_date, not_date, followup, cus_code, cus_name, fleet_seq, pol_no, app_no, id_no, sub_seq, fam_seq, ;
		title, name, surname, eff_date, exp_date, plan, type_clm, clm_type, acc_date, admit, disc, hosp_amt, benf_covr, non_cover, benf_paid, ;
		exgratia, over_benf, hosp_code, hosp_name, ill_name, icd10_1, icd10_2, icd10_3, clm_pstat, ret_date, indication, treatment, remark, ;
		pay_mode, payee_name, paye_addr1, paye_addr2, payee_jw, payee_zip, payee_tel, bank_code, bank_br, bank_accno, bki_clm_no ;
FROM DataMaster ;
INTO CURSOR curbki

SELECT curBki
COPY TO ARRAY laDataMas
SELECT DataDetail
COPY TO ARRAY laDataDet
*********************
LOCAL loException, lcErrorMsg, loWSHandler, llError
LOCAL lcXml as String 
LOCAL loWS AS "MSSOAP.SoapClient30"
loWS = CREATEOBJECT("MSSOAP.SoapClient30")
*
SUSPEND 
*
lcSeqNo = "HBC200900001"
lcUserName = "Claimoutsrc"
lcPassword = "ClmOutSrcP@ssw0rd"
lcUrl = "http://bkiextra.bki.co.th/ClaimOutSrcService/services/SendClmOutSrcdata/wsdl/SendClmOutSrcdata.wsdl"
loException = NULL  
llError = .f.
TRY 
	loWS.MSSoapInit(lcUrl)
	
*!*		LOCAL loMasXA AS XMLAdapter

*!*		loMasXA = CREATEOBJECT("XMLAdapter") 
*!*		loMasXA.UTF8Encoded = .T. 
*!*		loMasXA.AddTableSchema("curbki")
*!*		loMasXA.IsDiffgram = .T. 
*!*		lcMasXML = ""
*!*		loMasXA.ToXML("lcMasXML",,.F.,.T.,.T.)
*!*		 
*!*		*** Convert the XML into a NodeList
*!*		loMasDOM = CREATEOBJECT("MSXML2.DomDocument")
*!*		loMasDom.LoadXML(lcMasXML)
*!*		loMasNodeList = loMasDom.DocumentElement.ChildNodes()
*!*		
*!*		LOCAL loDetXA as XMLAdapter 
*!*		
*!*		loDetXA = CREATEOBJECT("XMLAdapter")
*!*		loDetXA.UTF8Encoded = .T. 
*!*		loDetXA.AddTableSchema("DataDetail")
*!*		loDetXA.IsDiffgram = .T. 
*!*		lcDetXML = ""
*!*		loDetXA.ToXML("lcDetXML",,.F.,.T.,.T.)

*!*		*** Convert the XML into a NodeList
*!*		loDetDOM = CREATEOBJECT("MSXML2.DomDocument")
*!*		loDetDom.LoadXML(lcDetXML)
*!*		loDetNodeList = loDetDom.DocumentElement.ChildNodes() 
	
	*** Retrieve BkiMaster  - returns DataSet returned as NodeList
	loException  = null
	llError = .F.
	 
	TRY 
	   *** Pass the NodeList as the DataSet parameter
	   llResult = loWS.sendClmOutSrcdataService(lcSeqNo, lcUserName, lcPassword, laDataMas, laDataDet)
	CATCH TO loException
	   llError = .F.
	ENDTRY 
	
	*** Always check for errors
	IF !ISNULL(loException)
	   lcError = loWS.FaultString
	   if EMPTY(lcError)
	      lcError = loException.Message
	   ENDIF
	   ? lcError
	   ? loException.ErrorNo
	   RETURN
	ENDIF 
	*** Print the reslt - .t. or .f.
	? llResult
	RETURN
CATCH TO loException
	llError = .T.
ENDTRY 

IF llError
   lcError = loWS.FaultString
   if EMPTY(lcError)
      lcError = loException.Message
   ENDIF
   ? lcError
   ? loException.ErrorNo
   RETURN
ELSE 
ENDIF 





	
	
	
	
	
