*CUT-N-PASTE the code below into a prg and run it from within VFP*

PUBLIC oForm, oForm2

oForm = CREATEOBJECT("clsChat",1)
oForm.visible = .t.

oForm2 = CREATEOBJECT("clsChat",2)
oForm2.visible = .t.

READ EVENTS

Store Null to oForm, oForm2
Release oForm, oForm2

DEFINE CLASS clschat AS form

    Top = 0
    Left = 0
    Height = 268
    Width = 376
    DoCreate = .T.
    Caption = "VFP CHAT"
    Name = "clschat"

    ADD OBJECT txtchatname AS textbox WITH ;
        Height = 23, ;
        Left = 216, ;
        Top = 12, ;
        Width = 132, ;
        Name = "txtChatname"

    ADD OBJECT edtchat AS editbox WITH ;
        Height = 134, ;
        Left = 24, ;
        ReadOnly = .T., ;
        Top = 48, ;
        Width = 324, ;
        DisabledBackColor = RGB(255,255,255), ;
        DisabledForeColor = RGB(0,0,0), ;
        Name = "edtChat"
        
    ADD OBJECT txtmessage AS textbox WITH ;
        Height = 23, ;
        Left = 84, ;
        Top = 194, ;
        Width = 264, ;
        Name = "txtMessage"

    ADD OBJECT command1 AS commandbutton WITH ;
        Top = 221, ;
        Left = 298, ;
        Height = 25, ;
        Width = 50, ;
        Caption = "Send", ;
        Name = "Command1"

    ADD OBJECT winsock1 AS WSControl 

    ADD OBJECT label2 AS label WITH ;
        AutoSize = .T., ;
        BackStyle = 0, ;
        Caption = "MESSAGE", ;
        Height = 17, ;
        Left = 24, ;
        Top = 197, ;
        Width = 59, ;
        Name = "Label2"

    ADD OBJECT label1 AS label WITH ;
        AutoSize = .T., ;
        BackStyle = 0, ;
        Caption = "CHAT NAME", ;
        Height = 17, ;
        Left = 144, ;
        Top = 15, ;
        Width = 70, ;
        Name = "Label1"

    PROCEDURE Init
        LPARAMETERS plForm
        IF plform = 1
            thisform.winsock1.object.bind(1234)
            thisform.txtChatname.value = "likestochat"
        ELSE
            thisform.winsock1.object.bind(1235)
            thisform.txtChatname.value = "sirchatalot"
            thisform.AutoCenter = .t. &&So they don't overlap
        ENDIF
        thisform.txtMessage.setfocus()
    ENDPROC

    Procedure Destroy
       ThisForm.RemoveObject('WinSock1')
    EndProc

    PROCEDURE Unload
        CLEAR events
    ENDPROC

    PROCEDURE txtmessage.KeyPress
        LPARAMETERS nKeyCode, nShiftAltCtrl
        IF nKeycode = 13 AND nShiftAltCtrl = 0
            IF !EMPTY(thisform.txtMessage.value)
                thisform.command1.Click()
            ENDIF
        ENDIF
    ENDPROC

    PROCEDURE command1.Click
        LOCAL sChatName, sMessageSent
        WITH thisform
            sChatName = ALLTRIM(thisform.txtChatname.value)
            sMessageSent = sChatName +" says:   " + ALLTRIM(thisform.txtMessage.value)
            WITH .winsock1.object
                .RemotePort = 1235
                .RemoteHost = "127.0.0.1"
                .SendData(sMessageSent)
                .RemotePort = 1234
                .RemoteHost = "127.0.0.1"
                .SendData(sMessageSent)
            ENDWITH
        .txtMessage.value = ""
        endwith
    ENDPROC

ENDDEFINE

Define Class WSControl As OleControl
        OleClass='MSWinsock.Winsock.1'
        Top = 228
        Left = 24
        Height = 100
        Width = 100
        Name = "winsock1"

    PROCEDURE Init
        this.object.Protocol = 1
    ENDPROC
    
    PROCEDURE DataArrival
        LPARAMETERS bytestotal
        sMessage = SPACE(bytestotal)
        thisform.winsock1.object.GetData(@sMessage)
        thisform.edtChat.Value = thisform.edtChat.Value + sMessage + CHR(13)
    ENDPROC

Enddefine