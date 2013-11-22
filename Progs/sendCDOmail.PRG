PARAMETERS tcFrom, tcTo, tcSubject, tcBody, tcAttachFile

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
IF EMPTY(tcAttachFile)
	tcAttachFile = GETFILE()
ENDIF 	
IF EMPTY(tcFrom) OR EMPTY(tcTo) OR EMPTY(tcSubject) OR EMPTY(tcBody)
	=MESSAGEBOX("Cannot Send Mail")
	RETURN 
ENDIF 	
**********
TRY
	LOCAL lcSchema, loConfig, loMsg, loError, lcErr
	lcErr = ""
	lcSchema = "http://schemas.microsoft.com/cdo/configuration/"
	loConfig = CREATEOBJECT("CDO.Configuration")
	WITH loConfig.FIELDS
	    .ITEM(lcSchema + "smtpserver") = "smtp.issp.co.th"
	    .ITEM(lcSchema + "smtpserverport") = 25 &&465 && ? 587
	    .ITEM(lcSchema + "sendusing") = 2
	    .ITEM(lcSchema + "smtpauthenticate") = .T.
	    .ITEM(lcSchema + "smtpusessl") = .F.
	    .ITEM(lcSchema + "sendusername") = "hbc01@issp.co.th"
	    .ITEM(lcSchema + "sendpassword") = "y6365555"
	    .UPDATE
	ENDWITH
	SUSPEND 
	loMsg = CREATEOBJECT ("CDO.Message")
	loMsg.Configuration = loConfig
	loMsg.FROM = tcFrom
	loMsg.TO = tcTo
	loMsg.Subject = tcSubject
	loMsg.TextBody = tcBody
	IF !EMPTY(tcAttachFile)
		IF FILE(tcAttachFile)
			loMsg.AddAttachment  &tcAttachFile
		ENDIF 	
	ENDIF 	
	loMsg.Send()
CATCH TO loError
	lcErr = [Error: ] + STR(loError.ERRORNO) + CHR(13) + ;
		[Line: ] + STR(loError.LINENO) + CHR(13) + ;
   		[Message: ] + loError.MESSAGE
FINALLY
	RELEASE loConfig, loMsg
	STORE .NULL. TO loConfig, loMsg
	IF EMPTY(lcErr)
		MESSAGEBOX("Message send sucess", 64, "Send Mail")
	ELSE
		MESSAGEBOX(lcErr, 16 , "Error")
	ENDIF
ENDTRY