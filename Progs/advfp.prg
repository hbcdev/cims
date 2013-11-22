
*****************************************************************
*** Written by:
*** Jose Enrique Llopis - futura@lobocom.es +34-629564331
*** www.futuracenter.com
*****************************************************************


*!*	Software configuration needed:

*!*	* API's used
*!*	CDOSYS - Only requires Windows 2000/XP/2003
*!*	CDOEX - Requires Exchange
*!*	CDOEXM - Requires Exchange

*!*	Of course you must have in a active directory environment.


*!*	SAMPLE:  

*!*	DOMAIN:  oficinas.redcam.es
*!*	OU    :  NUEVOS
*!*	lcDNI = Identification number of user



*!*	? NewAccount( "oficinas.redcam.es", "", "NUEVOS",lcDNI, lcDNI,;
*!*			lcDisplay, lcName,lcLastName,lcDepartment,lcPhoneNumber, ;
*!*			lcPosition, lcenterprise, lcOfficeName )

*!*	? AddUserToGroup("oficinas.redcam.es","","NUEVOS",lcDNI,"oficinas.redcam.es","",lcOU,lcGroupName)




#Define UF_NORMAL_ACCOUNT    0x0200
#Define ADS_UF_DONT_EXPIRE_PASSWD  0x1000


*** time to kick off users
DEFINE CLASS cRelojito AS Timer

	Enabled 	= .T.
	Interval 	= 5000
	
	PROCEDURE TIMER
	
		*** If you creates a flag file, routine stops
		IF FILE("UPDATING.FLAG")
			ON SHUTDOWN QUIT
			CLEAR ALL
			CLOSE ALL
			QUIT
		ENDIF
	ENDPROC
	
ENDDEFINE





**** Clase OlePublic
DEFINE CLASS AdmFuncs AS CUSTOM OLEPUBLIC



	ADD OBJECT PROTECTED Relojito as cRelojito
	




	******************************************************************************
	*** Creates a new account
	******************************************************************************
	FUNCTION NewAccount
	******************************************************************************
	LPARAMETERS 	lcDominio, lcDomainFolder, lcOrgUnit,lcObjectName, lcLoginName,;
					strDisplayName,strFirstName, strLastName,strOffice,strTelephoneNumber,;
					strTitle, strCompany, strDepartment, lcPassword, lcAlias


		*** Set Environment
		SetSets()
		**** ON ERROR do errhand

		domain 				= ALLTRIM(lcDominio)
		LDAPDomainString 	= SplitDomain(domain)


		#define UF_NORMAL_ACCOUNT    0x0200

		glYaExiste = .F.


		TRY
			oUserAcct = GetObject("WinNT://" + domain + "/" + ALLTRIM(lcObjectName) + ",user")
		CATCH TO oErr
		ENDTRY
		

		IF VARTYPE( oUserAcct ) # "O"
									
			** lcPassword = LEFT(ALLTRIM(lcObjectName),4)

			*** returns a reference to the container object
			lcLDAPString = "LDAP://"
			IF !EMPTY(lcDomainFolder)
				lcLDAPString = lcLDAPString + "CN=" + ALLTRIM(lcDomainFolder)+","
			ENDIF

			IF !EMPTY(lcOrgUnit)
				lcLDAPString = lcLDAPString + "OU=" + ALLTRIM(lcOrgUnit)+","
			ENDIF
						
			lcLDAPString = lcLDAPString + LDAPDomainString
										
			*** objContainer = GETOBJECT("LDAP://"+"CN="+ALLTRIM(lcDomainFolder)+","+LDAPDomainString)
			TRY
				objContainer = GETOBJECT(lcLDAPString)
			CATCH TO oErr
			ENDTRY
			
			
			IF VARTYPE(objContainer) <> "O"
				RETURN 100
			ENDIF
			
			objUser = objcontainer.Create("User","CN="+ALLTRIM(lcObjectName))
			IF VARTYPE(objUser) <> "O"
				RETURN 110
			ENDIF
			
			objUser.Put("sAMAccountName",ALLTRIM(lcLoginName))    && Account max length 20 bytes
	 		objUser.Put("userPrincipalName",ALLTRIM(lcLoginName)+"@"+ALLTRIM(lcDominio))
	 		
			objUser.Put("DisplayName",ALLTRIM(strDisplayName) )
			IF !EMPTY(strTelephoneNumber)
				objUser.Put("telephoneNumber",ALLTRIM(strTelephoneNumber) )
			ENDIF
			
			IF !EMPTY(strTitle)
				objUser.Put("Title",ALLTRIM(strTitle) )
			ENDIF
			
			*** Iniciales
			lcStr = LEFT(strFirstName,1)+LEFT(strLastName,1)
			lnPosicion = AT(" ",ALLTRIM(strLastName))
			IF lnPosicion > 0 AND lnPosicion < LEN(strLastNAme)
				lcStr = lcStr + SUBSTR(strLastName,lnPosicion+1,1)
			ENDIF	
			
			IF NOT EMPTY(lcStr)
				objUser.Put("initials",lcStr)
			ENDIF
			
			IF !EMPTY(strFirstName)
				objUser.Put("givenName",ALLTRIM(strFirstName))
			ENDIF
			
			IF NOT EMPTY(strLastName)
				objUser.Put("sn",ALLTRIM(strLastName))
			ENDIF
			
			IF !EMPTY(strOffice)
				objUser.Put("physicalDeliveryOfficeName",ALLTRIM(strOffice))
			ENDIF
			
			IF EMPTY(strCompany)
				strCompany = "CAM"
			ENDIF
			objUser.Put("company",ALLTRIM(strCompany))
			
			IF !EMPTY(strDepartment)
				objUser.Put("Department",ALLTRIM(strDepartment))
			ENDIF
			
			IF EMPTY(strDisplayName)
				strDisplayName = ALLTRIM(lcLoginName)
			ENDIF
			objUser.Put("Description",ALLTRIM(strDisplayName))
			

*!*				*** Compone el alias de Exchange / Usuario de correo   
*!*	 			*!* lcmailNickname = lcAlias
*!*				lcmailNickname = MakeAlias(strFirstName,strLastName)
*!*				lcmailNickname = LOWER(lcmailNickname)
*!*	 			objUser.Put("mailNickname",lcmailNickname )		&& Alias de exchange

			*** Compose Exchange alias = email account
			*** lcmailNickname = MakeAlias(strFirstName,strLastName)
			lcMailNickName = Componealias( lcObjectName )
			IF EMPTY(lcmailNickname)
				lcMailNickName = MakeAlias(strFirstName,strLastName)
			ENDIF
			lcmailNickname = LOWER(lcmailNickname)

			IF EMPTY(lcmailNickname)
				lcMailNickName = "datos_erroneos"
			ENDIF

 			objUser.Put("mailNickname",lcmailNickname )		&& Exchange alias

			llSuccess = .T.
			TRY	
				*** saves the information
				objUser.SetInfo
			CATCH TO oErr
				llSuccess = .F.
			ENDTRY
			
			
			IF llSuccess = .F.
				RETURN -50
			ENDIF
			
			
			*** Once the object is created, we can set more properties

			objUser.AccountDisabled = .F.
			
			
			llSuccess = .T.
			TRY
				objUser.SetInfo
			CATCH TO oErr
				llSuccess = .F.
			ENDTRY
			
			IF llSuccess = .F.
				RETURN -50
			ENDIF
			
				

			**** RETURN 0
		ELSE
			&& the object exists
			RETURN -1
		ENDIF


		
		*** Now will go to create the email data to this account
		lcCDOString = ;
			"CN=SRVMAIL3-Usr-01,CN=First Storage Group,CN=InformationStore,CN=SRVMAIL3,CN=Servers,"+;
			"CN=RED,CN=Administrative Groups,CN=CAM,CN=Microsoft Exchange,CN=Services,"+;
			"CN=Configuration,DC=redcam,DC=es"

		objMailBox = objUser
		objMailBox.CreateMailBox( lcCDOString )
		objUser.AccountDisabled = .F.


		llSuccess = .T.
		TRY
			objUser.SetInfo
		CATCH TO oErr
			llSuccess = .F.
		ENDTRY
		
		
		IF llSuccess = .F.
			RETURN -50
		ENDIF
		


		*** objUser.Put("userAccountControl", "0020" )
		objUser.userAccountControl = 65536

		objUser.SetPassword( lcPassword )
		
		
		llSuccess = .T.
		TRY
			objUser.SetInfo
		CATCH TO oErr
			llSuccess = .F.
		ENDTRY
		
		IF llSuccess = .F.
			RETURN -50
		ENDIF
		


	RETURN 0	
		
		
	ENDFUNC

	******************************************************************************
	**** Returns information abount an account
	******************************************************************************
	FUNCTION AccountInfo
	******************************************************************************
	LPARAMETERS lcDominio, lcDomainFolder, lcOrgUnit, lcAccount

		*** Set Environment
		SetSets()
		
		*** ON ERROR do errhand

		LDAPDomainString 	= SplitDomain(ALLTRIM(lcDominio))

		*** Devuelve una referencia al objeto person
		lcLDAPString = "LDAP://CN="+ALLTRIM(lcAccount) + ","

		IF !EMPTY(lcDomainFolder)
			lcLDAPString = lcLDAPString + "CN=" + ALLTRIM(lcDomainFolder)+","
		ENDIF

		IF !EMPTY(lcOrgUnit)
			lcLDAPString = lcLDAPString + "OU=" + ALLTRIM(lcOrgUnit)+","
		ENDIF
						
		lcLDAPString = lcLDAPString + LDAPDomainString
		
		TRY
			objPerson = GETOBJECT(lcLDAPString)
		CATCH TO oErr
		ENDTRY

		** objPerson = GETOBJECT("LDAP://CN="+ALLTRIM(lcAccount)+",CN="+lcDomainFolder+","+LDAPDomainString)

		IF VARTYPE(objPerson) <> "O"
			RETURN -1
		ENDIF

		CREATE CURSOR tmpReturnData ;
			( ;
				SamAccountName C(200),;
				UserPrincipalName C(200) NULL,;
				DisplayName C(200) NULL,;
				TelephoneNumber C(200) NULL,;
				Title C(200) NULL,;
				Initials C(200) NULL,;
				GivenName C(200) NULL,;
				sn C(200) NULL,;
				PhysicalDeliveryOfficeName C(200) NULL,;
				Company C(200) NULL,;
				Description C(200) NULL,;
				FirstName C(200) NULL,;
				LastName C(200) NULL)
				
		INSERT INTO tmpReturnData ;
			( ;
				SamAccountName ,;
				UserPrincipalName ,;
				DisplayName ,;
				TelephoneNumber ,;
				Title ,;
				Initials ,;
				GivenName ,;
				sn ,;
				PhysicalDeliveryOfficeName ,;
				Company ,;
				Description ,;
				FirstName ,;
				LastName  ) ;
		VALUES ;
			( ;
			objPerson.SamAccountName, ;
			objPerson.UserPrincipalName, ;
			objPerson.DisplayName, ;
			objPerson.TelephoneNumber, ;
			objPerson.Title, ;
			objPerson.Initials, ;
			objPerson.GivenName, ;
			objPerson.sn, ;
			objPerson.PhysicalDeliveryOfficeName, ;
			objPerson.Company, ;
			objPerson.Description, ;
			objPerson.FirstName, ;
			objPerson.LastName ;
		)


		CURSORTOXML("tmpReturnData", "tmpData.xml",1,512) 


		SELECT tmpReturnData
		USE


		RELEASE objPerson

		RETURN FILETOSTR("tmpData.xml")


	ENDFUNC



	******************************************************************************
	**** Adds a user to a group
	******************************************************************************
	FUNCTION AddUserToGroup
	******************************************************************************
	LPARAMETERS lcDominio,lcDomainFolder, lcOrgUnit, lcAccount, lcDominio2, lcDomainFolder2,lcOrgUnit2, lcGroup

	LOCAL llSuccess

		*** Set Environment
		SetSets()
		
		*** ON ERROR do errhand



		*** Object person ***
		LDAPDomainString 	= SplitDomain(ALLTRIM(lcDominio))

		lcLDAPString = "LDAP://CN="+ALLTRIM(lcAccount)+","		
		
		IF !EMPTY(lcDomainFolder)
			lcLDAPString = lcLDAPString + "CN="+lcDomainFolder+","
		ENDIF
		
		IF !EMPTY(lcOrgUnit)
			lcLDAPString = lcLDAPString + "OU="+lcOrgUnit+","
		ENDIF
		
		lcLDAPString = lcLDAPString + LDAPDomainString
		
		TRY
			objPerson = GETOBJECT(lcLDAPString)
		CATCH TO oErr
		ENDTRY
		

		IF VARTYPE(objPerson) <> "O"
			RETURN -1
		ENDIF


		*** Object group ***
		LDAPDomainString 	= SplitDomain(ALLTRIM(lcDominio2))

		lcLDAPString	= "LDAP://CN="+ALLTRIM(lcGroup)+","
		
		IF !EMPTY(lcDomainFolder2)
			lcLDAPString = lcLDAPString + "CN="+lcDomainFolder2+","
		ENDIF
		
		IF !EMPTY(lcOrgUnit2)
			lcLDAPString = lcLDAPString + "OU="+lcOrgUnit2+","
		ENDIF

		lcLDAPString = lcLDAPString + LDAPDomainString

		objGroup = GETOBJECT(lcLDAPString)


		IF VARTYPE(objGroup) <> "O"
			RETURN -1
		ENDIF

		llSuccess = .T.
		TRY
			lcADSPath = objPerson.adsPath
			objGroup.Add( objPerson.adsPath )
			objGroup.SetInfo
		CATCH TO oErr
			llSuccess = .F.
		ENDTRY
		
		IF llSuccess = .F.
			RETURN -1
		ENDIF
		
		RETURN 0

	ENDFUNC


	******************************************************************************
	**** removes a user form a group
	******************************************************************************
	FUNCTION RemoveUserFromGroup
	******************************************************************************
	LPARAMETERS lcDominio,lcDomainFolder, lcOrgUnit, lcAccount, lcDominio2, lcDomainFolder2, lcOrgUnit2, lcGroup

	LOCAL llSuccess

		*** Set Environment
		SetSets()
		
		*** ON ERROR do errhand


		*** Object person ***
		LDAPDomainString 	= SplitDomain(ALLTRIM(lcDominio))

		lcLDAPString = "LDAP://CN="+ALLTRIM(lcAccount)+","		
		
		IF !EMPTY(lcDomainFolder)
			lcLDAPString = lcLDAPString + "CN="+lcDomainFolder+","
		ENDIF
		
		IF !EMPTY(lcOrgUnit)
			lcLDAPString = lcLDAPString + "OU="+lcOrgUnit+","
		ENDIF
		
		lcLDAPString = lcLDAPString + LDAPDomainString
		
		TRY
			objPerson = GETOBJECT(lcLDAPString)
		CATCH TO oErr
		ENDTRY
		

		IF VARTYPE(objPerson) <> "O"
			RETURN -1
		ENDIF


		*** Object group ***
		LDAPDomainString 	= SplitDomain(ALLTRIM(lcDominio2))

		lcLDAPString	= "LDAP://CN="+ALLTRIM(lcGroup)+","
		
		IF !EMPTY(lcDomainFolder2)
			lcLDAPString = lcLDAPString + "CN="+lcDomainFolder2+","
		ENDIF
		
		IF !EMPTY(lcOrgUnit2)
			lcLDAPString = lcLDAPString + "OU="+lcOrgUnit2+","
		ENDIF

		lcLDAPString = lcLDAPString + LDAPDomainString

		objGroup = GETOBJECT(lcLDAPString)


		IF VARTYPE(objGroup) <> "O"
			RETURN -1
		ENDIF


		llSuccess = .T.
		TRY
			lcADSPath = objPerson.adsPath
			objGroup.Remove( objPerson.adsPath )
			objGroup.SetInfo
		CATCH TO oErr
			llSuccess = .F.
		ENDTRY
		

		IF llSuccess = .F.
			RETURN -1
		ENDIF
		
		RETURN 0

	ENDFUNC


	******************************************************************************
	*** changes password of a user
	******************************************************************************
	FUNCTION ChangePassword
	******************************************************************************
	LPARAMETERS 	lcDominio, lcDomainFolder, lcOrgUnit, lcLoginName,lcPassword

		LOCAL llSuccess

		SetSets()
		
		*** Gestión de errores
		*** ON ERROR do errhand


		*** Gets a reference to the person object
		LDAPDomainString 	= SplitDomain(ALLTRIM(lcDominio))

		lcLDAPString = "LDAP://CN="+ALLTRIM(lcLoginName)+","
		
		IF !EMPTY(lcDomainFolder)
			lcLDAPString = lcLDAPString + "CN=" + lcDomainFolder + ","
		ENDIF
		
		IF !EMPTY(lcOrgUnit)
			lcLDAPString = lcLDAPString + "OU=" + lcOrgUnit + ","
		ENDIF
		
		lcLDAPString = lcLDAPString + LDAPDomainString
		
		TRY
			objPerson = GETOBJECT(lcLDAPString)
		CATCH TO oErr
		ENDTRY

		IF VARTYPE(objPerson) <> "O"
			RETURN -1
		ENDIF
		
		
		llSuccess = .T.
		TRY 
			objPerson.SetPassword( lcPassword )
			objPerson.SetInfo
		CATCH TO oErr
			llSuccess = .F.
		ENDTRY
		

		RELEASE objPerson


		IF llSuccess = .F.
			RETURN -1
		ENDIF
		RETURN 0


	ENDFUNC



	******************************************************************************
	*** Resets the password to the first 4 digist of login name
	******************************************************************************
	FUNCTION ResetPassword
	******************************************************************************
	LPARAMETERS 	lcDominio, lcDomainFolder, lcOrgUnit, lcLoginName


		LOCAL lcDNI
		
		*** Set Environment
		SetSets()
		
		*** Gestión de errores
		*** ON ERROR do errhand


		lcDNI = lcLoginName
		
		DO WHILE LEFT(lcDNI,1) = "0"
			lcDNI = SUBSTR(lcDNI,2)
		ENDDO

		lcPassword = LEFT(ALLTRIM(lcDNI),4)
		
		lnReturn = This.ChangePassword( lcDominio, lcDomainFolder, lcOrgUnit, lcLoginName, lcPassword)


		RETURN lnReturn

		
	ENDFUNC
	
	
	
	
	
	******************************************************************************
	*** disables an account 
	******************************************************************************
	FUNCTION DisableAccount
	******************************************************************************
	LPARAMETERS 	lcDominio, lcDomainFolder, lcOrgUnit, lcLoginName

		*** Set Environment
		SetSets()
		
		*** ON ERROR do errhand

		*** Gets a reference to the person object
		LDAPDomainString 	= SplitDomain(ALLTRIM(lcDominio))

		lcLDAPString = "LDAP://CN="+ALLTRIM(lcLoginName)+","
		
		IF !EMPTY(lcDomainFolder)
			lcLDAPString = lcLDAPString + "CN=" + lcDomainFolder + ","
		ENDIF
		
		IF !EMPTY(lcOrgUnit)
			lcLDAPString = lcLDAPString + "OU=" + lcOrgUnit + ","
		ENDIF
		
		lcLDAPString = lcLDAPString + LDAPDomainString
		
		TRY
			objPerson = GETOBJECT(lcLDAPString)
		CATCH TO oErr
		ENDTRY

		IF VARTYPE(objPerson) <> "O"
			RETURN -1
		ENDIF


		llSuccess = .T.
		TRY
			objPerson.AccountDisabled = .T.
			objPerson.SetInfo
		CATCH TO oErr
			llSuccess = .F.
		ENDTRY
		
		RELEASE objPerson
		
		IF llSuccess = .F.
			RETURN -1
		ENDIF
		

		RETURN 0

	ENDFUNC	
		
	******************************************************************************
	*** Modify an account
	******************************************************************************
	FUNCTION UpdateAccount
	******************************************************************************
	LPARAMETERS 	lcDominio, lcDomainFolder, lcOrgUnit, lcLoginName,strDisplayName,;
					strFirstName, strLastName,strOffice,strTelephoneNumber,strTitle, ;
					strCompany, strDepartment, lcAlias


		*** Set Environment
		SetSets()
		
		*** Gestión de errores
		*** ON ERROR do errhand

		*** Consigue una referencia al objeto persona
		LDAPDomainString 	= SplitDomain(ALLTRIM(lcDominio))

		lcLDAPString = "LDAP://CN="+ALLTRIM(lcLoginName)+","
			
		
		IF !EMPTY(lcDomainFolder)
			lcLDAPString = lcLDAPString + "CN=" + lcDomainFolder + ","
		ENDIF
		
		IF !EMPTY(lcOrgUnit)
			lcLDAPString = lcLDAPString + "OU=" + lcOrgUnit + ","
		ENDIF
		
		lcLDAPString = lcLDAPString + LDAPDomainString

		*** "Parche" para el REDCAM
		lcLDAPString = "LDAP://CN="+ALLTRIM(lcLoginName)+",CN=Recipients,CN=RED,CN=Users,DC=redcam,DC=es"


		TRY
			objPerson = GETOBJECT(lcLDAPString)
		CATCH TO oErr
		ENDTRY
		

		IF VARTYPE(objPerson) <> "O"
			RETURN -1
		ENDIF


		IF !EMPTY(lcLoginName)
			objPerson.Put("sAMAccountName",ALLTRIM(lcLoginName))    && Account max length 20 bytes
	 		objPerson.Put("userPrincipalName",ALLTRIM(lcLoginName))
		ENDIF

		IF !EMPTY(lcAlias)
	 		objPerson.Put("mailNickname",ALLTRIM(lcAlias))		&& Alias de exchange, que formará la dirección de correo
	 	ENDIF
	 	
		IF !EMPTY( strDisplayName )
			objPerson.Put("DisplayName",ALLTRIM(strDisplayName))
		ENDIF
		
		IF !EMPTY(strTelephoneNumber)
			objPerson.Put("telephoneNumber",ALLTRIM(strTelephoneNumber))
		ENDIF
		
		IF !EMPTY(strTitle)
			objPerson.Put("Title",ALLTRIM(strTitle))
		ENDIF
		
		
		lcStr = LEFT(strFirstName,1)+LEFT(strLastName,1)
		lnPosicion = AT(" ",ALLTRIM(strLastName))
		IF lnPosicion > 0 AND lnPosicion < LEN(strLastNAme)
			lcStr = lcStr + SUBSTR(strLastName,lnPosicion+1,1)
		ENDIF				
		
		IF !EMPTY(lcStr)
			objPerson.Put("initials",lcStr)
		ENDIF
		
		IF !EMPTY(strFirstName)
			objPerson.Put("givenName",ALLTRIM(strFirstName))
		ENDIF
		
		IF !EMPTY(strLastName)
			objPerson.Put("sn",ALLTRIM(strLastName))
		ENDIF
		
		IF !EMPTY(strOffice)
			objPerson.Put("physicalDeliveryOfficeName",ALLTRIM(strOffice))
		ENDIF
		
		IF !EMPTY(strCompany)
			objPerson.Put("company",ALLTRIM(strCompany))
		ENDIF
		
		IF !EMPTY(strDepartment)
			objPerson.Put("Department",ALLTRIM(strDepartment))
		ENDIF
		
		IF !EMPTY(strDisplayName)
			objPerson.Put("Description",ALLTRIM(strDisplayName))
		ENDIF

		objPerson.Put("extensionAttribute5","PRUEBACORREO")


		
		llSuccess = .T.
		TRY
			*** Saves the information
			objPerson.SetInfo
		CATCH TO oErr
			llSuccess = .F.
		ENDTRY
		

		RELEASE objPerson
		
		
		IF llSuccess = .F.
			RETURN -1
		ENDIF
		
		RETURN 0
	
	ENDFUNC


	******************************************************************************
	*** enables an user account
	******************************************************************************
	FUNCTION EnableAccount
	******************************************************************************
	LPARAMETERS 	lcDominio, lcDomainFolder, lcOrgUnit, lcLoginName

		*** Set Environment
		SetSets()
		
		*** ON ERROR do errhand

		*** Gets a reference to the person object
		LDAPDomainString 	= SplitDomain(ALLTRIM(lcDominio))

		lcLDAPString = "LDAP://CN="+ALLTRIM(lcLoginName)+","
		
		IF !EMPTY(lcDomainFolder)
			lcLDAPString = lcLDAPString + "CN=" + lcDomainFolder + ","
		ENDIF
		
		IF !EMPTY(lcOrgUnit)
			lcLDAPString = lcLDAPString + "OU=" + lcOrgUnit + ","
		ENDIF
		
		lcLDAPString = lcLDAPString + LDAPDomainString
		
		TRY
			objPerson = GETOBJECT(lcLDAPString)
		CATCH TO oErr
		ENDTRY

		IF VARTYPE(objPerson) <> "O"
			RETURN -1
		ENDIF


		llSuccess = .T.
		TRY
			objPerson.AccountDisabled = .F.
			objPerson.SetInfo
		CATCH TO oErr
			llSuccess = .F.
		ENDTRY

		RELEASE objPerson


		IF llSuccess = .F.
			RETURN -1
		ENDIF
		
		RETURN 0


	ENDFUNC	



**************************************************************************
*** Looks if the user exists
**************************************************************************

	FUNCTION UserExists
	LPARAMETERS lcDominio,lcLoginName

		*** ON ERROR do errhand


		*** Set Environment
		SetSets()


		domain = ALLTRIM(lcDominio)

		TRY
			oUserAcct = GetObject("WinNT://" + domain + "/" + ALLTRIM(lcLoginName) + ",user")
		CATCH TO oErr
		ENDTRY


		IF VARTYPE(oUserAcct) = "O"
			RELEASE oUserAcct
			RETURN 0
		ELSE
			RETURN -1
		ENDIF


	ENDFUNC



	***************************************
	**** Returns library version
	***************************************
	FUNCTION Version
	
	
		lcBanner = 	"V.1.4 - by Pepe Llopis - futura@lobocom.es +34-629564331"
		    		
		
		RETURN lcBanner
	
	
	ENDFUNC


	**************************************************************************
	*** Looks for an user alias
	**************************************************************************
	FUNCTION BuscaAlias
		LPARAMETERS lcDNI


		*** Set Environment
		SetSets()

	
		SET EXCLUSIVE OFF
		SET MULTILOCKS ON
		
		IF !USED("USUARIOS")
			USE .\DATOS\USUARIOS IN 0 ALIAS USUARIOS SHARED
		ENDIF
		
		SELECT USUARIOS
		SET ORDER TO TAG DNI
		
		IF SEEK(ALLTRIM(lcDNI))
			RETURN ALLTRIM(Usuarios.Alias)
		ELSE
			RETURN ""
		ENDIF

	ENDFUNC
	





ENDDEFINE

************************************************************************************
*****  end of class definition
************************************************************************************


*****************************
*** additional functions ***
*****************************


*** compose mail alias. custom function.
FUNCTION MakeAlias
	LPARAMETERS lcNombre, lcApellido


	*** Set Environment
	SetSets()


	LOCAL i, lcTmpData, lcNombre1, lcNombre2, lcapellido1, lcApellido2, lcAlias, lcCaracter

	lcNombre 	= LOWER(lcNombre)
	lcApellido 	= LOWER(lcApellido)
	

	IF !USED("Cuentas")
		USE .\datos\CUENTAS IN 0 ALIAS CUENTAS SHARED
	ENDIF
	
	lcApellido1 = ALLTRIM(Token1(lcApellido))
	lcApellido2 = ALLTRIM(Token2(lcApellido))

	lcNombre1 = ALLTRIM(Token1(lcNombre))
	lcNombre2 = ALLTRIM(Token2(lcNombre))


	lcAlias = ;
		ALLTRIM(LEFT(lcNombre1,1))+;
		ALLTRIM(LEFT(lcNombre2,1))+;
		ALLTRIM(lcApellido1)
		
	lcAlias = LOWER(lcAlias)	

	*** Clean some invalidad chars
	lcAlias = STRTRAN(lcAlias,"ñ","n")
	lcAlias = STRTRAN(lcAlias,"ç","c")
	
	*** Removes chars
	lcTmpData = ""
	FOR i=1 TO LEN(lcAlias)
		lcCaracter = SUBSTR(lcAlias,i,1)
		IF ISDIGIT(lcCaracter) OR ISALPHA(lcCaracter)
			lcTmpData = lcTmpData + lcCaracter
		ENDIF
	ENDFOR
	
	lcAlias = lcTmpData
	
	lnContadorcito 	= 0
	lnPosicion		= 0
	DO WHILE .T.
		lnContadorcito 	= lnContadorcito + 1
		lnPosicion		= lnPosicion + 1
		IF lnContadorcito > 10
			lcAlias = "ERROR-"+SYS(2015)
			EXIT
		ENDIF
	
		SELECT Cuentas
		SET ORDER TO tag cuenta
		IF !SEEK(lcAlias)
			EXIT
		ENDIF
		
		IF LEN(lcApellido2) < lnPosicion
			lcApellido2 = lcApellido2 + LEFT("1234567890", lnPosicion - LEN(lcApellido2))
		ENDIF
		
		lcAlias = lcAlias + SUBSTR( lcApellido2, lnPosicion, 1)

	ENDDO


	RETURN lcAlias



ENDFUNC



*****************************************************
*** Transforms a domain to LDAP format
*****************************************************

FUNCTION SplitDomain
	LPARAMETERS lcDomain

	IF EMPTY(lcDomain)
		RETURN ""
	ENDIF

	LOCAL lnPosition, lcString

	lcString 	= ""

	DO WHILE .T.

		lnPosition = ATC( ".", lcDomain, 1 )
		
		IF !EMPTY(lcString)
			lcString = lcString + ","
		ENDIF

		IF lnPosition > 0	
			lcString = lcString + "DC=" + LEFT(lcDomain,lnPosition - 1)
		ELSE
			lcString = lcString + "DC=" + lcDomain
		ENDIF	

		IF lnPosition = 0
			EXIT
		ENDIF

		IF LEN(lcDomain) > (lnPosition + 1)
			lcdomain = SUBSTR(lcDomain,lnPosition+1)
		ELSE
			EXIT
		ENDIF

	ENDDO

	RETURN lcString

ENDFUNC
	
	
FUNCTION SetSets

	CLEAR MACROS
	SET SYSFORMATS OFF	&& No recoge el formato de moneda y hora del systema
	SET CENTURY TO 19 ROLLOVER 30
	SET DATE BRITISH
	SET HELP OFF
	SET SAFETY OFF
	SET MEMOWIDTH TO 120
	SET MULTILOCKS ON
	SET DELETED ON
	SET EXCLUSIVE OFF
	SET NOTIFY OFF
	SET BELL OFF
	SET NEAR OFF
	SET EXACT OFF
	SET INTENSITY OFF
	SET CONFIRM ON
	SET ESCAPE OFF
	SET BELL OFF
	SET TALK OFF
	SET REPROCESS TO 2 SECONDS
	SET HELP OFF
	SET REFRESH TO 1,1
	SET AUTOSAVE ON

	*** Unattended mode
	SYS(2335, 0 )


	
	CD C:\UpdateExchange

	IF FILE("ACTUALIZANDO.FLAG")
		ON SHUTDOWN QUIT
		CLEAR ALL
		CLOSE ALL
		QUIT
	ENDIF
	
	ON ERROR DO ErrHand WITH ERROR(),MESSAGE(),MESSAGE(1),SYS(16),LINENO(), ALIAS(),ORDER(),SYS(18),WONTOP(),GETENV("MACHINE")

ENDFUNC


FUNCTION errhand
LPARAMETERS loform

glYaExiste = .T.

RETURN .t.



*** That' more complicated. In spain we have TWO lastnames, the first 
*** is the lastname of father and the second is the lastname of the mather.
*** Perhaps that functions are not useful to people with only one lastname.


*** first lastname
FUNCTION Token1
LPARAMETERS lcTexto

lcTexto = ALLTRIM(lcTexto)+" "

lnPos = 0
lnPos = AT(" ",lcTexto, 1)

IF lnPos <= 0
	RETURN ""
ENDIF

lcToken1 = LEFT(lcTexto,lnPos-1)

RETURN lcToken1



ENDFUNC


*** Second lastname
FUNCTION Token2

LPARAMETERS lcTexto

lcTexto = ALLTRIM(lcTexto)+" "

lnPos = 0
lnPos = AT(" ",lcTexto, 1)

IF lnPos <= 0
	RETURN ""
ENDIF

lcToken2 = SUBSTR(lcTexto,lnPos+1)


RETURN lcToken2


ENDFUNC



**************************************************************************
**************************************************************************
************************************************************************************
*** Compose email alias
FUNCTION ComponeAlias
	LPARAMETERS lcObjectName

	SET EXCLUSIVE OFF
	SET MULTILOCKS ON
	IF NOT USED("USUARIOS")
		USE .\DATOS\USUARIOS IN 0 ALIAS USUARIOS SHARED
	ENDIF
	
	
	SELECT Usuarios
	SET ORDER TO TAG DNI
	IF !SEEK(lcObjectName)
		RETURN ""
	ENDIF
	

	LOCAL lcAlias, lnCounter, lcNombre, lcApellido, lcApellido1, lcApellido2
	LOCAL lcNombre1, lcNombre2, lcDummy

	lcNombre 	= ALLTRIM(Usuarios.Nombre)
	lcApellido 	= ALLTRIM(Usuarios.Apellido)

	lcApellido1 = ALLTRIM(Token1(lcApellido))
	lcApellido2 = ALLTRIM(Token2(lcApellido))

	lcNombre1 = ALLTRIM(Token1(lcNombre))
	lcNombre2 = ALLTRIM(Token2(lcNombre))


	lcAlias = ;
		ALLTRIM(LEFT(lcNombre1,1))+;
		ALLTRIM(LEFT(lcNombre2,1))+;
		ALLTRIM(lcApellido1)

	lcalias = STRTRAN(lcAlias,"ñ","n")
	lcalias = STRTRAN(lcAlias,"Ñ","N")
	lcalias = STRTRAN(lcAlias,"-","")



	lnCounter = 0

	lcDummy = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	lcTestString = lcAlias

	DO WHILE .T.
		* SELECT Usuarios
		* SET ORDER TO TAG Alias
		
		IF INDEXSEEK(LOWER(lcTestString),.F.,"Usuarios","Alias")
			* MESSAGEBOX(lcTestString+CHR(13)+lcAlias)
			lnCounter = lnCounter + 1
			IF !EMPTY(lcApellido2)
				lcTestString = lcAlias + LEFT(lcApellido2,lnCounter)
				lcTestString = STRTRAN(lcTestString,"ñ","n")
				lcTestString = STRTRAN(lcTestString,"Ñ","N")
				lcalias = STRTRAN(lcAlias,"-","")
			ELSE
				lcTestString = lcAlias + LEFT(lcDummy,lnCounter)
				lcTestString = STRTRAN(lcTestString,"ñ","n")
				lcTestString = STRTRAN(lcTestString,"Ñ","N")
				lcalias = STRTRAN(lcAlias,"-","")
			ENDIF
		ELSE
			lcAlias = lcTestString
			EXIT
		ENDIF
		
		IF lnCounter > 10
			lcAlias = "ERROR"
			EXIT
		ENDIF
		
	ENDDO


	lcAlias = LOWER(lcAlias)
	lcAlias = STRTRAN(lcAlias,"'")
	lcAlias = STRTRAN(lcAlias,".")


RETURN lcAlias

ENDFUNC







**********************************************************************
**********************************************************************

*!*	Structure for table:    C:\TRABAJO\EXCHANGEBULK\DATOS\USUARIOS.DBF
*!*	Number of data records: 7316    
*!*	Date of last update:    09/21/04
*!*	Code Page:              1252    
*!*	Field  Field Name      Type                Width    Dec   Index   Collate Nulls    Next    Step
*!*	    1  DNI             Character              10            Asc   Machine    No
*!*	    2  APELLIDO        Character              35            Asc   Machine    No
*!*	    3  APELLIDO1       Character              31            Asc   Machine    No
*!*	    4  APELLIDO2       Character              31            Asc   Machine    No
*!*	    5  NOMBRE          Character              15            Asc   Machine    No
*!*	    6  OFICINA         Character               4            Asc   Machine    No
*!*	    7  UBICACION       Character               4            Asc   Machine    No
*!*	    8  G03DIR          Character               2                             No
*!*	    9  G03NEG          Integer                 4                             No
*!*	   10  G03TIPO         Character               1                             No
*!*	   11  NOMOFI          Character              35            Asc   Machine    No
*!*	   12  TIPODEP         Character              15                             No
*!*	   13  TIPODEP2        Integer                 4                             No
*!*	   14  ESTADO          Character              12                             No
*!*	   15  CARGO           Character              31                             No
*!*	   16  FUNCION         Character              31                             No
*!*	   17  ALIAS           Character              25            Asc   Machine    No
*!*	   18  LOGIN           Character              25            Asc   Machine    No
*!*	   19  TELEFONO        Character              15                             No
*!*	   20  CREARALIAS      Logical                 1                             No
*!*	   21  CREARCUENTA     Logical                 1                             No
*!*	   22  DISPLAY         Character             125                             No
*!*	   23  CAMNOCAM        Logical                 1            Asc   Machine    No
*!*	   24  TELEFONOIBER    Character              15                             No
*!*	   25  MOVIL           Character              15                             No
*!*	   26  MOVILIBER       Character              15                             No
*!*	   27  SEXO            Character               1                             No
*!*	** Total **                                  505


*!*	NOTE:
*!*	In my country all people has an identification card called "DNI" and the number of
*!*	that card is the key field of the users table.


