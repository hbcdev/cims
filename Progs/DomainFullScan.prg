*****************************************************************
*** Written by:
*** Jose Enrique Llopis - futura@lobocom.es +34-629564331
*** www.futuracenter.com
*****************************************************************


*** Perfoms a full, recursive scan of the active directory to retrieve information about users.
*** Very useful funtion to load data to a foxpro table

CLEAR

CLOSE ALL

IF NOT USED("Usuarios")
	USE .\datos\Usuarios IN 0 ALIAS Usuarios
ENDIF


*** Sets the domain to scan
lcDominio 	= "REDCAM"


*** Gets Root Object. the domain example is  redcam.es  
oDomainObj = GetObject("LDAP://DC=REDCAM,DC=ES")

*** and now go to scan...
=ExploraRama( oDomainObj, "" )


RETURN

*** recursive function to scan the full tree
FUNCTION ExploraRama
	LPARAMETERS loRama, lcBaseRoot

	

	LOCAL lcClass, lcName, loSubDomainObj, lcOldBaseRoot, lcStringConn
	
	FOR EACH ObjUser IN loRama
	*!*		IF ObjUser.Class = "User"
			*** BuscayCambia()
			
			lcClass = UPPER(ObjUser.Class)
			lcName	= ObjUser.Name


			*** MESSAGEBOX(lcName + CHR(13) + lcBaseRoot)


			lcOldBaseRoot = lcBaseRoot

			IF UPPER(lcName) = "CN=SYSTEM"
				LOOP
			ENDIF
			
			DO CASE
				CASE lcClass = "CONTAINER"
					loSubDomainObj = .NULL.
					TRY
						lcStringConn = IIF(EMPTY(lcBaseRoot),lcName,lcName+Ponecoma(lcBaseRoot))
						loSubDomainObj = GetObject("LDAP://"+lcStringConn+",DC=REDCAM,DC=ES")
					CATCH TO oErr
					ENDTRY
					
					IF VARTYPE( loSubDomainObj ) = "O"
						lcTexto = "EXPLORANDO RAMA:"+lcName+CHR(13)
						? lcTexto
						IF LEFT(lcName,2) = "CN"
							IF !EMPTY( lcBaseRoot )
								lcBaseRoot = "," + lcName + "," + lcBaseRoot
							ELSE
								lcBaseRoot = lcName
							ENDIF
						ENDIF
						ExploraRama( loSubDomainObj, lcBaseRoot )
						lcBaseRoot = lcOldBaseRoot
					ENDIF
				CASE lcClass = "ORGANIZATIONALUNIT"
					loSubDomainObj = .NULL.
					TRY
						&& loSubDomainObj = GetObject("LDAP://"+lcName+lcBaseRoot+",DC=REDCAM,DC=ES")
						lcStringConn = IIF(EMPTY(lcBaseRoot),lcName,lcName+Ponecoma(lcBaseRoot))
						loSubDomainObj = GetObject("LDAP://"+lcStringConn+",DC=REDCAM,DC=ES")
					CATCH TO oErr
					ENDTRY
					IF VARTYPE( loSubDomainObj ) = "O"
						lcTexto = "EXPLORANDO RAMA:"+lcName+CHR(13)
						? lcTexto
						* ? lcTexto
						IF LEFT(lcName,2) = "CN"
							IF !EMPTY( lcBaseRoot )
								lcBaseRoot = "," + lcName + "," + lcBaseRoot
							ELSE
								lcBaseRoot = lcName
							ENDIF
						ENDIF
						
						ExploraRama( loSubDomainObj , lcBaseRoot )
						lcBaseRoot = lcOldBaseRoot
					ENDIF
			ENDCASE

			IF VARTYPE(	ObjUser ) = "O"	
				lcClaseObjeto = UPPER(ObjUser.Class)
				IF lcClaseObjeto = "USER"
					*** Actualiza los datos del usuario
					ActualizaUsuario( ObjUser )
				ENDIF
				
*!*					lcName = ObjUser.Name
*!*					INSERT INTO Listadir (Nombre) VALUES ( lcName )
				*** ? lcName
			ENDIF
	ENDFOR

ENDFUNC

*** Puts a comma char on the left of the string, if not exists
FUNCTION PoneComa
LPARAMETERS lcDatastring

	lcDatastring = LTRIM(lcDatastring)
	IF LEFT(lcDatastring,1) <> ","
		lcDatastring = ","+lcDatastring
	ENDIF

	RETURN lcDatastring

ENDFUNC


*************************************************************
*** Save email data of user objects (address=direcciones in spanish) ***
*************************************************************
FUNCTION Verdirecciones
		LPARAMETERS objPerson
		

		IF VARTYPE(objPerson) <> "O"
			RETURN .F.
		ENDIF



		IF !USED("Cuentas")
			USE .\Datos\Cuentas IN 0 ALIAS Cuentas
		ENDIF

	
		lcName = ALLTRIM(objPerson.cn)
		
		*** ? objPerson.GET("mail")
		
		RELEASE varAddrs
		
		TRY
			varAddrs = objPerson.GetEx("proxyAddresses")
		CATCH TO oErr
		ENDTRY
		
		IF VARTYPE(varAddrs) = "U"
			RETURN
		ENDIF
		
		
		lnNumAddress = ALEN( varAddrs, 1 )
	
		FOR j=1 TO 	lnNumAddress
		
			INSERT INTO cuentas ( DNI, CUENTA ) VALUES ( lcName, varAddrs(j) )
		ENDFOR

ENDFUNC




*************************************************************
*** saves full data of the object				          ***
*************************************************************
FUNCTION VerDatosPer
		LPARAMETERS objPerson
		

		IF VARTYPE(objPerson) <> "O"
			RETURN .F.
		ENDIF
		
			
		lcVar01 = IIF( VARTYPE(objPerson.SamAccountName) = "C", NVL(objPerson.SamAccountName,""), "")			
		lcVar02 = IIF( VARTYPE(objPerson.UserPrincipalName) = "C", NVL(objPerson.UserPrincipalName,""), "")
		lcVar03 = IIF( VARTYPE(objPerson.MailNickName) = "C", NVL(objPerson.MailNickName,""), "")			
		lcVar04 = IIF( VARTYPE(objPerson.DisplayName) = "C", NVL(objPerson.DisplayName,""), "")			
		lcVar05 = IIF( VARTYPE(objPerson.TelephoneNumber) = "C", NVL(objPerson.TelephoneNumber,""), "")			
		lcVar06 = IIF( VARTYPE(objPerson.Title) = "C", NVL(objPerson.Title,""), "")
		lcVar07 = IIF( VARTYPE(objPerson.Initials) = "C", NVL(objPerson.Initials,""), "")
		lcVar08 = IIF( VARTYPE(objPerson.GivenName) = "C", NVL(objPerson.GivenName,""), "")
		lcVar09 = IIF( VARTYPE(objPerson.sn) = "C", NVL(objPerson.sn,""), "")
		lcVar10 = IIF( VARTYPE(objPerson.PhysicalDeliveryOfficeName) = "C", NVL(objPerson.PhysicalDeliveryOfficeName,""), "")
		lcVar11 = IIF( VARTYPE(objPerson.Company) = "C", NVL(objPerson.Company,""), "")
		lcVar12 = IIF( VARTYPE(objPerson.Department) = "C", NVL(objPerson.Department,""), "")
		lcVar13 = IIF( VARTYPE(objPerson.Description) = "C", NVL(objPerson.Description,""), "")

				
		IF !USED("DatosPer")
			USE .\Datos\DatosPer IN 0 ALIAS DatosPer
		ENDIF

		INSERT INTO DatosPer ( ;
			c01, ;
			c02, ;
			c03, ;
			c04, ;
			c05, ;
			c06, ;
			c07, ;
			c08, ;
			c09, ;
			c10, ;
			c11, ;
			c12, ;
			c13 ) ;
		VALUES  ( ;
			lcVar01, ;
			lcVar02, ;
			lcVar03, ;
			lcVar04, ;
			lcVar05, ;
			lcVar06, ;
			lcVar07, ;
			lcVar08, ;
			lcVar09, ;
			lcVar10, ;
			lcVar11, ;
			lcVar12, ;
			lcVar13  ;
		)

ENDFUNC



*** Updates user data
FUNCTION ActualizaUsuario


		LPARAMETERS objPerson
		

		IF VARTYPE(objPerson) <> "O"
			RETURN .F.
		ENDIF


		lcDNI = IIF( VARTYPE(objPerson.SamAccountName) = "C", NVL(objPerson.SamAccountName,""), "")


		*** Formatea el DNI
		lcDNI = STRTRAN(lcDNI," ","0")
	
		IF LEFT(lcDNI,1) = "X"
			lcDNI = SUBSTR(lcDNI,2)
		ENDIF
	
		DO WHILE .T.

			IF LEN(lcDNI) <= 8
				EXIT
			ENDIF
			
			IF LEFT(lcDNI,1) = "0"
				lcDNI = SUBSTR(lcDNI,2)
			ELSE
				EXIT
			ENDIF

		ENDDO


		SELECT Usuarios
		SET ORDER TO TAG DNI
		
		IF SEEK(lcDNI)
			lcDisplay = Usuarios.Display
		ELSE
			RETURN
		ENDIF
		

		IF Usuarios.CrearCuenta != .T.
			RETURN
		ENDIF


		*** Display
		lcTempData	= BuscaExcepcion(lcDNI, "DISPLAY")
		lcDisplay 	= IIF(EMPTY(lcTempData),lcDisplay,lcTempData)

		
		IF EMPTY(lcDisplay)
			RETURN
		ENDIF


		lcDescription = IIF( VARTYPE(objPerson.DisplayName) = "C", NVL(objPerson.DisplayName,""), "")			


*!*			cMessageTitle = ' * * * PRUEBA * * * '
*!*			cMessageText = ALLTRIM(Usuarios.DNI) + CHR(13) + lcDisplay + CHR(13) + 	lcDescription + '¿Continuo?'
*!*			nDialogType = 4 + 32 + 256
*!*			*  4 = Yes and No buttons
*!*			*  32 = Question mark icon
*!*			*  256 = Second button is default

*!*			nAnswer = MESSAGEBOX(cMessageText, nDialogType, cMessageTitle)

*!*			DO CASE
*!*			   CASE nAnswer = 6
*!*			  	***
*!*			   CASE nAnswer = 7
*!*			    CANCEL
*!*			ENDCASE


		lcDisplay 		= ALLTRIM(lcDisplay)
		lcDescription 	= ALLTRIM(lcDescription)


		objPerson.Put("Description",lcDescription)
		objPerson.Put("DisplayName",lcDisplay)
		*** Guarda la información
		objPerson.SetInfo



ENDFUNC




******************************************************
*** Exception table. to skip some users
FUNCTION BuscaExcepcion
LPARAMETERS lcDNI, lcCampo


	IF NOT USED("Excepcion2")
		USE .\Datos\Excepcion2 IN 0 ALIAS Excepcion2
	ENDIF
	
	
	SELECT Excepcion2
	SET ORDER TO TAG DNICAMPO
	
	IF SEEK( lcDNI + lcCampo )
		RETURN ALLTRIM(Excepcion2.Valor)
	ELSE
		RETURN ""
	ENDIF


ENDFUNC





*!*	Structure for table:    C:\TRABAJO\EXCHANGEBULK\DATOS\EXCEPCION2.DBF
*!*	Number of data records: 79      
*!*	Date of last update:    08/24/04
*!*	Code Page:              1252    
*!*	Field  Field Name      Type                Width    Dec   Index   Collate Nulls    Next    Step
*!*	    1  DNI             Character              10            Asc   Machine    No
*!*	    2  CAMPO           Character             100                             No
*!*	    3  VALOR           Character             100                             No
*!*	** Total **                                  211
