******beg code*******
loMail = NEWOBJECT("Cdo2000", "Cdo2000.prg")
WITH loMail
     .cServer = "smtp.gmail.com"
     .nServerPort = 465
     .lUseSSL = .T.
     .nAuthenticate = 1
     .cUserName = "yourname@gmail.com"
     .cPassword = "yourpassword"
     .cFrom = "yourname@gmail.com"
     .cTo = "yourname@hotmail.com,yourname@gmail.com"
     .cSubject = "Teat Gmail SMTP server Attachment"
     .cTextBody = "This is a text body." + CHR(13) + CHR(10) + ;
               "TEST SEND PICTURE"
     _file=GETFILE()
      .cAttachment = (_file)
ENDWITH

? IIF( loMail.Send() > 0, loMail.Geterror(1), "Email sent.")
******end code*******



********cdo2000.prg*************
#DEFINE cdoSendPassword "http://schemas.microsoft.com/cdo/configuration/sendpassword"
#DEFINE cdoSendUserName "http://schemas.microsoft.com/cdo/configuration/sendusername"
#DEFINE cdoSendUsingMethod "http://schemas.microsoft.com/cdo/configuration/sendusing"
#DEFINE cdoSMTPAuthenticate "http://schemas.microsoft.com/cdo/configuration/smtpauthenticate"
#DEFINE cdoSMTPConnectionTimeout "http://schemas.microsoft.com/cdo/configuration/smtpconnectiontimeout"
#DEFINE cdoSMTPServer "http://schemas.microsoft.com/cdo/configuration/smtpserver"
#DEFINE cdoSMTPServerPort "http://schemas.microsoft.com/cdo/configuration/smtpserverport"
#DEFINE cdoSMTPUseSSL "http://schemas.microsoft.com/cdo/configuration/smtpusessl"
#DEFINE cdoURLGetLatestVersion "http://schemas.microsoft.com/cdo/configuration/urlgetlatestversion"
#DEFINE cdoAnonymous 0     && Perform no authentication (anonymous)
#DEFINE cdoBasic 1     && Use the basic (clear text) authentication mechanism.
#DEFINE cdoSendUsingPort 2     && Send the message using the SMTP protocol over the network.
#DEFINE cdoXMailer "urn:schemas:mailheader:x-mailer"

DEFINE CLASS cdo2000 AS Custom

     PROTECTED oErrors 
     oErrors = Null

     && Message attributes
     PROTECTED oMsg
     oMsg = Null
     cFrom = ""
     cReplyTo = ""
     cTo = ""
     cCC = ""
     cBCC = ""
     cAttachment = ""

     cSubject = ""
     cHtmlBody = ""
     cTextBody = ""
     cHtmlBodyUrl = ""

     && Configuration object fields values
     PROTECTED oCfg
     oCfg = Null
     cServer = ""
     nServerPort = 25
     && Use SSL connection
     lUseSSL = .F.
     nConnectionTimeout = 30               && Default 30 sec's
     nAuthenticate = cdoAnonymous
     cUserName = ""
     cPassword = ""
     && Do not use cache for cHtmlBodyUrl
     lURLGetLatestVersion = .T.

     && Optional. Creates your own X-MAILER field in the header
     PROTECTED cXMailer
     cXMailer = "VFP CDO 2000(CDOSYS) mailer Ver 1.0 2008"

     PROTECTED PROCEDURE Init
          && Create error collection
          This.oErrors = CREATEOBJECT("Collection")
     ENDPROC

     && Send message
     PROCEDURE Send

          WITH This
               .ClearErrors()
               .oCfg = CREATEOBJECT("CDO.Configuration")
               .oMsg = CREATEOBJECT("CDO.Message")
               .oMsg.Configuration = This.oCfg
          ENDWITH      

          && Fill message attributes
          LOCAL lnind, laList[1], loHeader, laDummy[1]

          IF This.SetConfiguration() > 0
               RETURN This.GetErrorCount()
          ENDIF

          IF EMPTY(This.cFrom)
               This.AddError("ERROR : From is Empty.")
          ENDIF
          IF EMPTY(This.cSubject)
               This.AddError("ERROR : Subject is Empty.")
          ENDIF

          IF EMPTY(This.cTo) AND EMPTY(This.cCC) AND EMPTY(cBCC)
               This.AddError("ERROR : To,CC and BCC all are Empty.")
          ENDIF

          IF This.GetErrorCount() > 0
               RETURN This.GetErrorCount()
          ENDIF

          This.SetHeader()

          WITH This.oMsg

               .From     = This.cFrom
               .ReplyTo = This.cReplyTo

               .To       = This.cTo
               .CC       = This.cCC
               .BCC      = This.cBCC
               .Subject = This.cSubject

               && Create HTML body from external HTML (file, URL)
               IF NOT EMPTY(This.cHtmlBodyUrl)
                    .CreateMHTMLBody(This.cHtmlBodyUrl)
               ENDIF

               && Send HTML body. Creates TextBody as well
               IF NOT EMPTY(This.cHtmlBody)
                    .HtmlBody = This.cHtmlBody
               ENDIF

               && Send Text body. Could be different from HtmlBody, if any
               IF NOT EMPTY(This.cTextBody)
                    .TextBody = This.cTextBody
               ENDIF

               && Process attachments
               IF NOT EMPTY(This.cAttachment)
                    && Accepts comma, semicolon 
                    FOR lnind=1 TO ALINES(laList, This.cAttachment, [,], [;])
                         lcAttachment = ALLTRIM(laList[lnind])
                         && Ignore empty values
                         IF EMPTY(laList[lnind])
                              LOOP
                         ENDIF

                         && Make sure that attachment exists
                         IF ADIR(laDummy, lcAttachment) = 0
                              This.AddError("ERROR: Attacment not Found - " + lcAttachment)
                         ELSE
                              && The full path is required.
                              IF      UPPER(lcAttachment) <> UPPER(FULLPATH(lcAttachment))
                                   lcAttachment = FULLPATH(lcAttachment)
                              ENDIF
                              .AddAttachment(lcAttachment)
                         ENDIF
                    ENDFOR
               ENDIF

          ENDWITH

          IF This.GetErrorCount() > 0
               RETURN This.GetErrorCount()
          ENDIF

          TRY
               This.oMsg.Send()
          CATCH TO oErr
               This.AddOneError("SEND ERROR: ", oErr.ErrorNo, oErr.procedure, oErr.LineNo)
          ENDTRY

          RETURN This.GetErrorCount()

     ENDPROC

     && Clear error collection
     PROCEDURE ClearErrors()
          RETURN This.oErrors.Remove(-1)
     ENDPROC

     && Return # of errors in the error collection
     PROCEDURE GetErrorCount
          RETURN This.oErrors.Count
     ENDPROC

     && Return error by index
     PROCEDURE GetError(tnErrorno)
          IF     tnErrorno <= This.GetErrorCount()
               RETURN This.oErrors.Item(tnErrorno)
          ELSE
               RETURN Null
          ENDIF
     ENDPROC

     && Populate configuration object
     PROTECTED PROCEDURE SetConfiguration

          && Validate supplied configuration values
          IF EMPTY(This.cServer)
               This.AddError("ERROR: SMTP Server isn't specified.")
          ENDIF
          IF NOT INLIST(This.nAuthenticate, cdoAnonymous, cdoBasic)
               This.AddError("ERROR: Invalid Authentication protocol ")
          ENDIF
          IF This.nAuthenticate = cdoBasic ;
                    AND (EMPTY(This.cUserName) OR EMPTY(This.cPassword))
               This.AddError("ERROR: User name/Password is required for basic authentication")
          ENDIF

          IF      This.GetErrorCount() > 0
               RETURN This.GetErrorCount()
          ENDIF

          WITH This.oCfg.Fields

               && Send using SMTP server
               .Item(cdoSendUsingMethod)            = cdoSendUsingPort
               .Item(cdoSMTPServer)                  = This.cServer
               .Item(cdoSMTPServerPort)               = This.nServerPort
               .Item(cdoSMTPConnectionTimeout)           = This.nConnectionTimeout

               .Item(cdoSMTPAuthenticate)            = This.nAuthenticate
               IF This.nAuthenticate = cdoBasic
                    .Item(cdoSendUserName)                = This.cUserName
                    .Item(cdoSendPassword)                = This.cPassword
               ENDIF
               .Item(cdoURLGetLatestVersion)             = This.lURLGetLatestVersion
               .Item(cdoSMTPUseSSL)                     = This.lUseSSL

               .Update()
          ENDWITH

          RETURN This.GetErrorCount()

     ENDPROC

     &&----------------------------------------------------
     && Add message to the error collection
     PROTECTED PROCEDURE AddError(tcErrorMsg)
          RETURN This.oErrors.Add(tcErrorMsg)
     ENDPROC

     &&----------------------------------------------------
     && Format an error message and add to the error collection
     PROTECTED PROCEDURE AddOneError(tcPrefix, tnError, tcMethod, tnLine )
          LOCAL lcErrorMsg, laList[1]
          IF INLIST(tnError, 1427,1429)
               AERROR(laList)
               lcErrorMsg = TRANSFORM(laList[7], "@0") + ;
                    " " + laList[4] + " " + laList[3]
          ELSE
               lcErrorMsg = MESSAGE()
          ENDIF
          This.AddError(tcPrefix + ":" + TRANSFORM(tnError) + " # " + ;
               tcMethod + " # " + TRANSFORM(tnLine) + " # " + lcErrorMsg)
          RETURN This.oErrors.Count
     ENDPROC

     &&----------------------------------------------------
     && Simple Error handler. Adds VFP error to the objects error collection
     PROTECTED PROCEDURE Error(tnError, tcMethod, tnLine)
          &&!*               This.AddError("VFP Error: " + TRANSFORM(tnError) + " # " + ;
          &&!*                    tcMethod + " # " + TRANSFORM(tnLine) + " # " + MESSAGE())
          This.AddOneError("ERROR: ", tnError, tcMethod, tnLine )
          RETURN This.oErrors.Count
     ENDPROC

     &&-------------------------------------------------------
     && Set mail header fields, if necessary. For now sets X-MAILER, if specified
     PROTECTED PROCEDURE SetHeader
          LOCAL loHeader
          IF NOT EMPTY(This.cXMailer)
               loHeader = This.oMsg.Fields
               WITH loHeader
                    .Item(cdoXMailer) = This.cXMailer
                    .Update()
               ENDWITH
          ENDIF
     ENDPROC

ENDDEFINE
*********************