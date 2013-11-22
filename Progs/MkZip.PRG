******************************************************************************
***
*** FUNCTION: MkZip.prg
***
******************************************************************************
***
*** AUTHOR : 	Arnaud Poizat / Paris / Salustro-Reydel / RSMi
***			 	  apoizat@salustro-reydel.fr
*** DATE :     	March 28 2002 17:38
*** PURPOSE :   Launch Winzip via it's command line
*** 		      to make a .zip file with specified list files
***
*** USING : 	ShellExecute  of  SHELL32.dll
***
*** for 		Windows 2000, VisualFoxPro 7.0 SP1
*** INSTALLED :	Winzip 8.0 and Command Line Support Add-On Version 1.0
***
******************************************************************************

LPARAMETER pZipName, pFilesToZip, pFilesNoZip
*
* Parameter list description
* --------------------------
*
*  pZipName 	-	The name of the .zip file to be generated, with full path
*
*  pFilesToZip	-	The names of the files to be zipped
*					- allow wild card
*////	idea for next version :	- if 1st char is "@" : indirect list,
*////				  			(the list itself resides in the file specified after "@".)
*
*  pFilesNoZip	(optional) -	The names of the files to exclude from pFilesToZip
*////	idea for next version :	- if 1st char is "@" : indirect list
*
IF PARAMETERS() < 2			&&	Two parameters needed, at least
	RETURN -1
ENDIF
*!*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*!*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*!* API Declarations
*!* ----------------
*!*   Found on  News2News   http://www.news2news.com/vfp/ 
*!*
    
DECLARE INTEGER ShellExecute IN shell32 ;  
    Integer nhwnd, String  cOperation, String  cFile,;  
    String  cParameters, String  cDirectory, Integer nShowCmd 
*!*
*!* Parameters: 
*!* ===========
*!* nhwnd			Handle to a parent window. 
*!*						This window receives any message boxes that an application produces, 
*!*						such as error reporting. 
*!* cOperation		A string, referred to as a verb, that specifies the action to be performed: 
*!*						edit, explore, find, open, print 
*!* cFile			Address of a null-terminated string 
*!*						that specifies the file or object on which to execute the specified verb. 
*!* cParameters 	If the cFile parameter specifies an executable file, 
*!*						cParameters is an address to a null-terminated string that specifies
*!*						the parameters to be passed to the application. 
*!* cDirectory 	Address of a null-terminated string that specifies the default directory.
*!*
*!* nShowCmd		Flags that specify how an application is to be displayed when it is opened. 
*!* ============
*!*
*!* 
*!* Return value : 
*!* ============	Returns a value greater than 32 if successful, or an error value that is less 
*!*						than or equal to 32 otherwise (user defined).   
*!*
*!* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*@* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@*  COMMENTS
*@* 
*@*		*@* are comments ready to disappear and provide infos for tests
*@*
*@* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

*@*
*@*lnbegin = SECONDS()			&&	just to display elapsed time while testing 
*@*

*** *********************************************************************************************
***
***		Is Line Support Add-On installed ?						NO : Return  -1
***		If yes, prepare the cFile parameter of ShellExecute
***
*************************************************************************************************
lcFile 		 =   "C:\Program Files\WinZip\WZZIP.EXE"		&&	 Wzzip.exe is line support add-on	
***															&&	( Winzip32.exe is normal version )
IF !FILE(lcFile)
	WAIT "Command Line Support Add-On NOT INSTALLED" WINDOW
	WAIT "GO TO Winzip.com and download wzcline.exe" WINDOW
	RETURN -1
ENDIF
lcFile 		 =   ["] + (lcFile) + ["] + CHR(0)

*** *********************************************************************************************
*** 
***		Build the parameters sent to the file "opened" by ShellExecute
***
*** *********************************************************************************************
***
IF LEFT(UPPER(ALLTRIM(pZipName)), 2) <> "A:"
	lcParameters =   '-yb -P '					&&	Winzip will work in batch mode  ( -yb )
***												&&	and will save full path for each file added ( -P )
ELSE
	lcParameters =   '-ybc -P -& '				&&	-&  for multi-disk, and c for Ok on prompt
ENDIF
***
lcParameters =   lcParameters + '-en '			&&	Set the compression level. 
***													-ex = maximum (smallest file); 
***											==>		-en = normal (default); 
***													-ef = fast; 
***													-es = super speed; -e0 = no
***
***		Add the file names to exclude, to the parameters
***
IF PARAMETERS() = 3
	IF !EMPTY(pFilesNoZip)
		lcParameters =   lcParameters + '-x"'
		lcParameters =   lcParameters + (ALLTRIM(pFilesNoZip)) 
		lcParameters =   lcParameters + '" '
	ENDIF
ENDIF
*** *************************************************************
***		Add the name of the .zip file, to the parameters
***
***	( Next versions : .zip will replace any other/empty suffix )
*** *************************************************************
lcParameters =   lcParameters + '"'
lcParameters =   lcParameters + (ALLTRIM(pZipName))
lcParameters =   lcParameters + '" '
***
***		If pZipName already exists, delete it first 
***		( to prevent adding pFilesToZip inside it ) 
***	
IF FILE((ALLTRIM(pZipName)))
	DELETE FILE (ALLTRIM(pZipName))
ENDIF
	
	
*** *****************************************************
***		Is File list empty ?									YES : Return  -2
*** *****************************************************

lcNbz = ADIR(aListZ, (pFilesToZip))		&&	put the names to add in an array 
IF lcNbz > 0							&&  some files found
*@*
*@*	Sum the filesizes before zipping
*@*
*@*	iTotSize = 0
*@*	FOR iZip = 1 TO lcNbz
*@*		iTotSize = iTotSize + aListZ(iZip, 2)
*@*	ENDFOR
*
	IF PARAMETERS() > 2					&&  a list of files to exclude from zipping was given
		lcNbNotZ = ADIR(aListNotZ, (pFilesNoZip))   &&	put the names to exclude in another array
		IF lcNbNotZ > 0								&&  some files to exclude ?
		
			FOR iZip = 1 TO lcNbNotZ				&&  test if each file to exclude exists in the ones to add
				lcXclude = aListNotZ(iZip, 1)
				IF ASCAN(aListZ, lcXclude, 1, 1, 1, 7 ) > 0		&& found (case insensitive, exact On)
					lcNbZ = lcNbZ - 1							&& one less to add
*@*					iTotSize = iTotSize - aListNotZ(iZip, 2)	&& and less bytes too to zip
				ENDIF
			ENDFOR
			
		ENDIF	&&  lcNbNotZ > 0   some files to exclude ?
	ENDIF	&&	PARAMETERS() > 2   3rd parameter if files to exclude from zipping
ENDIF	&&	lcNbz > 0	
*
IF lcNbz = 0							&&   obviously, nothing to add into that .zip
		RETURN -2
ENDIF
*** ************************************************************
*** 		Ok, let's zip again   (like we did last summer...)
*** ************************************************************
lcParameters =   lcParameters + '"'
lcParameters =   lcParameters + (ALLTRIM(pFilesToZip))
lcParameters =   lcParameters + '"' + CHR(0) 
lcDirectory	 =	 "" + CHR(0) 

*** *********************************************************
***
***	 	R U N
***
*** *********************************************************
IF LEFT(UPPER(ALLTRIM(pZipName)), 2) = "A:"
	iShEx = ShellExecute(0,"Open",lcFile, lcParameters,"",1)		&& with a beautiful DOS-type black window
ELSE
	iShEx = ShellExecute(0,"Open",lcFile, lcParameters,"",0)		&& without any progress window
ENDIF
*@* *********************************************************
*@* 		S T A T I S T I C S
*@* *********************************************************
*@*iTotSize = ROUND(iTotSize/1024, 1)
*@*lnend = SECONDS()
*@*WAIT TRANSFORM(lcNbz, '999,999') + " Files in " + ALLTRIM(TRANSFORM(iTotSize, '999,999.9'));
*@*				 + " Ko in :" + ALLTRIM(TRANSFORM(lnend - lnbegin,'999.999'))+ " s. " WINDOW TIMEOUT 5
*@*
*@*
*@*lcZip = ADIR(aListZ, ALLTRIM(pZipName))											&&	to find the .zip size
*@*IF lcZip = 1																	&&	if 0 : process is not yet finished
*@*	iRateZip = (iTotSize - ROUND(aListZ(1, 2)/1024, 1))/ iTotSize * 100	 		&&  compute compress rate
*@*	WAIT TRANSFORM(iRateZip, '999.99') + " % global compression. " WINDOW
*@*ENDIF
*@*
*** *********************************************************
***
RELEASE lcFile, lcParameters, lcDirectory
RETURN iShEx