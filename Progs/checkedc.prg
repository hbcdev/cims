SET EXCLUSIVE off  
SET SAFETY OFF 
SET TALK OFF 
set date to dmy 

lcDSNLess="driver={SQL Server Native Client 10.0};server=192.168.100.9;Trusted_Connection=Yes;Database=CimsDB"
nConn = Sqlstringconnect(lcDSNLess)
if nConn = -1
	lcMessage = "Check EDC Error: Cannot Connect SQL Server at "+ttoc(datetime())
	do sendsms
	return 
endif 

lcSql = "SELECT nii, max(apprvcode) AS apprvcode, max(transdate) AS transdate FROM cimsdb.dbo.edctransaction GROUP BY nii"
lnSql = sqlexec(nConn, lcSql,"edc")
if lnSql = 1	
	select edc
	scan
		lcFile = "\\dragon-data\hips\data\nii"+alltrim(iif(isnull(nii), "", nii))+".txt"
		if file(lcFile)
			lcNii = FILETOSTR(lcFile)
			lcOldApprv = left(lcNii,6)
			ldOldTransDate = ctot(substr(lcNii,at('|',lcnii)+1))
			ldEstTransDate = ctot(substr(lcNii,at('|',lcnii)+1))+(iif(nii = '150', 10, 5)*60)

			lcMessage = "NII :"+edc.nii +;
				"\n Approval Code: "+edc.apprvcode+chr(13) +;
				"\n Old Connect Date : "+TTOC(ldOldTransDate)+;				
				"\n Estimate Connect Date : "+TTOC(ldEstTransDate)+;
				"\n Last Connect Date : "+TTOC(edc.transdate)
			lcEdcText =  ttoc(datetime())+"|"+edc.nii +"|"+edc.apprvcode+"|"+lcOldApprv+"|"+ ttoc(edc.transdate) + "|" + ttoc(ldOldTransDate) + "|" + ttoc(ldEstTransDate)+chr(13)
			=strtofile(lcEdcText, "\\dragon-data\hips\data\edc.txt",1)			
			
			lnDiff = datetime() - edc.transdate
			if lnDiff < 150
				if upper(os()) = "WINDOWS 6.02"
					?lcEdcText
				else 	
					do sendsms
				endif 	
			endif 	
			
			lcSaveNii = edc.apprvcode+"|"+ttoc(edc.transdate)			
			=STRTOFILE(lcSaveNii, lcFile,0)
		endif	
	endscan
	use in edc
	=sqldisconnect(nConn)	
else
	lcMessage = "Check EDC Error: Cannot Connect SQL Server at "+ttoc(datetime())
	do sendsms
endif
**********************************
PROCEDURE sendSms

*!* Thai Bulk SMS

mobile = "0814257663"
usern = "0814257663"
passwords = "370651"
msgs = lcMessage
sender1 = "HBC"
force1 = "standard"
senddate=RIGHT(STR(YEAR(DATE()),4),2)++STRTRAN(STR(MONTH(DATE()),2)," ","0")+STRTRAN(STR(DAY(DATE()),2)," ","0")+STRTRAN(STR(HOUR(DATETIME()),2), " ", "0")+STRTRAN(STR(MINUTE(DATETIME()),2), " ", "0")+"20532"

oXMLHTTP = CREATEOBJECT("MSXML2.ServerXMLHTTP.4.0")
oXMLHTTP.open("POST", "http://www.thaibulksms.com/sms_api.php",.F.)
oXMLHTTP.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=tis-620")
strData = "username=" + usern + "&password=" + passwords + "&msisdn=" + mobile + "&message=" + msgs + "&sender=" + sender1 + "&force=" + force1

oXMLHTTP.setRequestHeader("Content-Length", Len(strData))
oXMLHTTP.setRequestHeader("Connection", "close")
oXMLHTTP.send(strData)
strReturn = oXMLHTTP.responseText
oXMLHTTP = null
lcStatus = SUBSTR(strReturn, AT("<Status>", strReturn)+8, 1)
=STRTOFILE(strreturn, "\\192.168.100.3\HBC Host\sms.txt",1)