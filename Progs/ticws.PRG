PARAMETERS tcLogin, tcPassword, tcInsName, tcPolicyNo, tcIDCard

LOCAL loWS_TIC_HBC AS "XML Web Service"
* LOCAL loWS_TIC_HBC AS "MSSOAP.SoapClient30"
* Do not remove or alter following line. It is used to support IntelliSense for your XML Web service.
*__VFPWSDef__: loWS_TIC_HBC = http://203.147.42.37/tichbc/ws_tic_hbc.asmx?wsdl , WS_TIC_HBC , WS_TIC_HBCSoap
LOCAL loException, lcErrorMsg, loWSHandler
TRY
	loWSHandler = NEWOBJECT("WSHandler",IIF(VERSION(2)=0,"",HOME()+"FFC\")+"_ws3client.vcx")
	loWS_TIC_HBC = loWSHandler.SetupClient("http://203.147.42.37/tichbc/ws_tic_hbc.asmx?wsdl", "WS_TIC_HBC", "WS_TIC_HBCSoap")
	* Call your XML Web service here.  ex: leResult = loWS_TIC_HBC.SomeMethod()
	leResult = loWS_TIC_HBC.TICGetInquiryDS(tcLogin, tcPassword, tcInsName, tcPolicyNo, tcIDCard)
	SUSPEND 	
	IF !EMPTY(leResult)
		XMLTOCURSOR(leResult, "Inquiry")	
	ENDIF 		
	leResult = loWS_TIC_HBC.TICGetItemDetail(tcLogin, tcPassword, tcPolSerial, tcInsName, tcActDate)
	IF !EMPTY(leResult)
		XMLTOCURSOR(leResult, "Itemdetail")	
	ENDIF 		
	leResult = loWS_TIC_HBC.TICGetPolicyDetail(tcLogin, tcPassword, tcPolSerial, tcActDate)
	IF !EMPTY(leResult)
		XMLTOCURSOR(leResult, "poldetail")	
	ENDIF 
	leResult = loWS_TIC_HBC.TICGetSIDetail(tcLogin, tcPassword, tcPolSerial, tcItemNo, tcActDate)
	IF !EMPTY(leResult)
		XMLTOCURSOR(leResult, "SIdetail")	
	ENDIF 		
CATCH TO loException
	lcErrorMsg="Error: "+TRANSFORM(loException.Errorno)+" - "+loException.Message
	DO CASE
	CASE VARTYPE(loWS_TIC_HBC)#"O"
		* Handle SOAP error connecting to web service
	CASE !EMPTY(loWS_TIC_HBC.FaultCode)
		* Handle SOAP error calling method
		lcErrorMsg=lcErrorMsg+CHR(13)+loWS_TIC_HBC.Detail
	OTHERWISE
		* Handle other error
	ENDCASE
	* Use for debugging purposes
	MESSAGEBOX(lcErrorMsg)
FINALLY
ENDTRY

