PARAMETERS tcLogin, tcPassword, tcInsName, tcPolicyNo, tcIDCard
SET PROCEDURE TO progs\utility

LOCAL loException, lcErrorMsg, loWSHandler, llError
LOCAL loWS AS "MSSOAP.SoapClient30"
loWS = CREATEOBJECT("MSSOAP.soapClient30")

lcUrl = "http://203.147.42.40/tichbc/ws_tic_hbc.asmx?wsdl"
loException = NULL  
llError = .f.

TRY 
	loWS.MSSoapInit(lcUrl)
CATCH TO loException
	llError = .t.
ENDTRY 

IF llError
	? "Unable to load WSDL file from " + lcUrl
	RETURN 
ENDIF 

loException = null 
TRY 
	loResult = loWS.TicGetInquiryDS(tcLogin, tcPassword, tcInsName, tcPolicyNo, tcIDCard)
CATCH TO loException
	llError = .t.
ENDTRY 

IF (loWS.FaultCode # "")		
	?loWS.FaultString 
	RETURN 
ENDIF 

IF !ISNULL(loException)
	?loException.Message
	?loException.ErrorNo
	RETURN 
ENDIF 

loDOM = loResult.item(0).parentNode
lcXML = loDOM.Xml

LOCAL oXA AS XMLAdapter
oXA = CREATEOBJECT("XMLAdapter")
oXA.LoadXML(lcXML, .F., .T.)

IF USED("PolInquiry")
	USE IN polinquiry
ENDIF 

oXA.TABLES[1].TOCURSOR(.F., "PolInquiry")

IF RECCOUNT("PolInquiry") = 0
	RETURN 
ENDIF 
	
lcPolSerial = ALLTRIM(polinquiry.pol_serial)	
lcInsName = ALLTRIM(polinquiry.ins_name)

loException = null 
TRY 
	loResult = loWS.TicGetPolicyDetailDS(tcLogin, tcPassword, lcPolSerial)
CATCH TO loException
	llError = .t.
ENDTRY 

IF (loWS.FaultCode # "")		
	?loWS.FaultString 
	RETURN 
ENDIF 

IF !ISNULL(loException)
	?loException.Message
	?loException.ErrorNo
	RETURN 
ENDIF 

IF USED("poldetail")
	USE IN poldetail
ENDIF 	

loDOM = loResult.item(0).parentNode
lcXML = loDOM.Xml
oXA.LoadXML(lcXML, .F., .T.)
oXA.TABLES[1].TOCURSOR(.F., "PolDetail")

** Get Item Detail
loException = null 
TRY 
	loResult = loWS.TicGetItemDetailDS(tcLogin, tcPassword, lcPolSerial, lcInsName)
CATCH TO loException
	llError = .t.
ENDTRY 

IF (loWS.FaultCode # "")		
	?loWS.FaultString 
	RETURN 
ENDIF 

IF !ISNULL(loException)
	?loException.Message
	?loException.ErrorNo
	RETURN 
ENDIF 

IF USED("polItem")
	USE IN polItem
ENDIF 	

loDOM = loResult.item(0).parentNode
lcXML = loDOM.Xml
oXA.LoadXML(lcXML, .F., .T.)
oXA.TABLES[1].TOCURSOR(.F., "PolItem")

IF !USED("politem")
	RETURN 
ENDIF 

IF RECCOUNT("politem") = 0
	RETURN 
ENDIF 

lcItemNo = polItem.item_no
?lcitemNo

** Get Item Detail
loException = null 
TRY 
	loResult = loWS.TicGetSIDetailDS(tcLogin, tcPassword, lcPolSerial, lcItemNo)
CATCH TO loException
	llError = .t.
ENDTRY 

IF (loWS.FaultCode # "")		
	?loWS.FaultString 
	RETURN 
ENDIF 

IF !ISNULL(loException)
	?loException.Message
	?loException.ErrorNo
	RETURN 
ENDIF 

IF USED("polSiItem")
	USE IN polSiItem
ENDIF 	

loDOM = loResult.item(0).parentNode
lcXML = loDOM.Xml
oXA.LoadXML(lcXML, .F., .T.)
oXA.TABLES[1].TOCURSOR(.F., "PolSIitem")

IF !USED("polsiitem")
	RETURN 
ENDIF 

IF RECCOUNT("polsiitem") = 0
	RETURN 
ENDIF 
SELECT polsiitem
GO 2
**********************************
IF USED("PolInquiry") AND USED("poldetail") AND USED("politem") AND USED("polsiitem")
	lcTitle = ""
	m.tpacode = "TIC"
	m.customer_type = "P"
	m.policy_no = polinquiry.policy_no
	m.policy_name = deltitle(polinquiry.ins_name)
	m.name = ALLTRIM(LEFT(m.policy_name, AT(" ", m.policy_name)))
	m.surname = ALLTRIM(substr(m.policy_name, AT(" ", m.policy_name)))
	m.product = UPPER(poldetail.product_cd)
	m.effective = RIGHT(poldetail.effect_dt,2)+"/"+SUBSTR(poldetail.effect_dt, 5,2)+"/"+LEFT(poldetail.effect_dt,2)
	m.expiry = RIGHT(poldetail.expiry_dt,2)+"/"+SUBSTR(poldetail.expiry_dt, 5,2)+"/"+LEFT(poldetail.expiry_dt,2)
	m.h_addr1 = poldetail.address
	m.customer_id = politem.life_ic
	m.natid = politem.life_ic
	m.sex = politem.life_sex
	m.dob = CTOD(RIGHT(poldetail.expiry_dt,2)+"/"+SUBSTR(poldetail.expiry_dt, 5,2)+"/"+LEFT(poldetail.expiry_dt,2))
	m.age = politem.life_age
	m.overall_limit = polsiitem.si_price	
	SUSPEND 
ELSE 
	MESSAGEBOX("ไม่สามารถทำการเชื่อมต่อกับ Server ของ ไทยประกันภัย", 0, "Error")
	RETURN 
ENDIF 	
		 			