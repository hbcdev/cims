PARAMETERS tcFrom, tcTo, tcSubject, tcBody, tcAttachment
*
IF EMPTY(tcFrom)
	tcFrom = INPUTBOX("Mail From:","Send Mail")
ENDIF 	
IF EMPTY(tcTo)
	tcTo = INPUTBOX("Mail To:","Send Mail")
ENDIF 	
IF EMPTY(tcSubject)
	tcSubject = INPUTBOX("Mail Subject:","Send Mail")
ENDIF 	
IF EMPTY(tcBody)
	tcBody = INPUTBOX("Mail Message:","Send Mail")
ENDIF 	
IF EMPTY(tcAttachment)
	tcAttachment = GETFILE()
ENDIF 	
IF EMPTY(tcFrom) OR EMPTY(tcTo) OR EMPTY(tcSubject) OR EMPTY(tcBody)
	=MESSAGEBOX("Cannot Send Mail")
	RETURN 
ENDIF 	
**************************
local sMailServer
local iMailServerPort
local sUserName
local sPassword
local oSMTP
local oMessage
sMailServer = "smtp.issp.co.th"  		&&   "mail.YourServer.com"               && NOTE:  Set to your Own Value
iMailServerPort = 25					&& NOTE:  Already set to default value
sUserName = "hbc01@issp.co.th"	&& NOTE:  Set to your Own Value
sPassword = "y6365555"				&& NOTE:  Set to your Own Value

oSMTP=CREATEOBJECT("SmtpWizard.SmtpWizardCtrl2")
*?oSMTP.Version
oSMTP.UnlockSmtpWizard("YourSerialNumber") && Your own serial# eliminates the eval popup window
oSMTP.FailOnRecipientErrors=.t.
*oSMTP.TimeOut=60000
oSMTP.UseSecurePasswordAuthentication=.t.  && IF YOU DONT USE LOGIN USER NAME AND PASSWORD, SET TO FALSE
oSMTP.UseESMTP=.t.
oSMTP.MailServerPort=iMailServerPort
oSMTP.MailServer=sMailServer


&&*--- Connect
IF oSMTP.Connect(sUserName,sPassword)
	IF oSMTP.LoggedInWithESMTP
		?'ESMTP'
	ENDIF 
	IF oSMTP.LoginWasSecure
		?'Login was secure'
	ELSE
		?'Unsecure login'
	ENDIF 
	oMessage = CREATEOBJECT("SmtpWizard.SMTPMessage2")
	oMessage.fieldFROM = tcFrom  && NOTE:  Set to your Own Value
	oMessage.AddTORecipient (tcTo)     && NOTE:  Set to your Own Value
	*oMessage.AddTORecipient ("User2","User2@User2Domain.com")     && NOTE:  Set to your Own Value
	*oMessage.AddCCRecipient ("User3","User3@User3Domain.com")     && NOTE:  Set to your Own Value
	*oMessage.AddBCCRecipient("User4","User4@User4Domain.com")    && NOTE:  Set to your Own Value
	oMessage.fieldSubject = tcSubject
	oMessage.MessageBody = tcBody
	IF !EMPTY(tcAttachment)
		oMessage.AddAttachmentByFileName(tcAttachment)
	ENDIF 	
	&&*-- sending message
	IF oSMTP.SendMessage(oMessage, 1)	
		MessageBox('Message sent successfully')
	ELSE 
		MessageBox('Error: '+oSMTP.LastErrorDescription)
	ENDIF
	oSMTP.Disconnect
ELSE 	
	MessageBox(oSMTP.LastErrorDescription)
ENDIF 