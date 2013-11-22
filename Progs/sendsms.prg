CLEAR 
*!*Apply Mail
*!*	mobile = "0814257663"
*!*	username = "vacharaa"
*!*	passwords = "vach0409"
*!*	langs = "T"
*!*	msgs = "CIGNA:วันที่่ 06/10/52 เวลา 14.00 น. คุณมีนัดทำฟันที่ทันตกรรมมายเด้นท์ สาขา 1 แจ้งรหัส:SC00012"

*!* Thai Bulk SMS
mobile = "0814257663"
usern = "0814257663"
passwords = "370651"
langs = "T"
msgs = "CIGNA:วันที่่ 06/10/52 เวลา 14.00 น. คุณมีนัดทำฟันที่ทันตกรรมมายเด้นท์ สาขา 1 แจ้งรหัส:SC00012"
sender1 = "SMS"
senddate="091004095020532"



oXMLHTTP = CREATEOBJECT("MSXML2.ServerXMLHTTP.4.0")
*oXMLHTTP.open("POST", "http://smsgateway.applymail.com/api/send_long.php",.F.)
oXMLHTTP.open("POST", "http://www.thaibulksms.com/sms_api.php",.F.)
oXMLHTTP.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=tis-620")
*strData = "msisdn=" + mobile + "&user=" + username + "&pass=" + passwords + "&lang=" + langs + "&msg=" + msgs
strData = "username=" + usern + "&password=" + passwords + "&msisdn=" + mobile + "&message=" + msgs + "&sender=" + sender1 + "&ScheduledDelivery=" + senddate

?strdata

oXMLHTTP.setRequestHeader("Content-Length", Len(strData))
oXMLHTTP.setRequestHeader("Connection", "close")
oXMLHTTP.send(strData)
strReturn = oXMLHTTP.responseText
oXMLHTTP = null


IF SUBSTR(strReturn, AT("<Status>", strReturn)+8, 1) = "1"
	=MESSAGEBOX("ส่งข้อความให้หมายเลข "+mobile+" เรียบร้อยแล้ว", 0)
ENDIF 	
=STRTOFILE(strreturn, "sms.txt")


