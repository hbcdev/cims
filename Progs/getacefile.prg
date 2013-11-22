lcTextFile = GETFILE("TXT", "Text File", "Open")
IF EMPTY(lctextFile)
	RETURN 
ENDIF 
*
Local gnFileHandle,nSize,cString
gnFileHandle = FOPEN(lcTextFile)
* Seek to end of file to determine the number of bytes in the file
nSize =  FSEEK(gnFileHandle, 0, 2)     && Move pointer to EOF
IF nSize <= 0
	 * If the file is empty, display an error message
	 WAIT WINDOW "This file is empty!" NOWAIT
ELSE
	 * If file is not empty, the program stores its contents
	 * in memory, then displays the text on the main Visual FoxPro window
	 = FSEEK(gnFileHandle, 0, 0)      && Move pointer to BOF
	 *DO WHILE !FEOF(gnFileHandle)
 		cString = FREAD(gnFileHandle, 731)
 		lcFld = STRTRAN(STRTRAN(STRTRAN(cString," ",""), ".", ""),";", ",")
	 	i = 0
 		DO WHILE !EMPTY(cString)
 			i = i +1	
	 		lcField = "Field"+ALLTRIM(STR(i))
 			&lcField = STRTRAN(STRTRAN(ALLTRIM(LEFT(cString, AT(";", cString)-1))," ","_"), ".", "")
 			cString = SUBSTR(cString, AT(";", cString)+1)
	 	ENDDO 	
	 *ENDDO 
 ENDIF
 SUSPEND 
*= FCLOSE(gnFileHandle)      	