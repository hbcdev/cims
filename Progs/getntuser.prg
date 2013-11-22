*** User 
DECLARE INTEGER GetUserName in WIN32API String @,Integer @ 
LOCAL lcUser 
lcUser=SPACE(20) 
GetUserName(@lcUser,20) 
lcUser=UPPER(STRTRAN(lcUser,CHR(0),'')) 

*** Group 
*This code shows how to use the Pointers Class to get the local group memberships for a user on Windows NT. In order to do this, you must use NetUserGetLocalGroups() NET32 API function with the structure LOCALGROUP_USERS_INFO_0 as the 5th parameter. 
*-- This function returns the local group memberships 
* for a specified user. 
* 
*-- It uses: 
* - the NetUserGetLocalGroups Win32 API function 
* to retrieve the wanted information from the OS. 
* - the Pointers Control to convert the result 
* from NetUserGetLocalGroups to VFP string format. 
* 
*-- Parameters: 
* 1. The server name. It can also be a domain name. 
* Use the empty string for the current computer. 
* Ex: \\MyServer 

* 2. The user name. It can also be in the 
* DomainName\UserName format. 
* Ex: JoeDoe 
* MyServer\JoeDoe 

*-- Note: The documentation I found for the 
* NetUserGetLocalGroups functionis very unclear. 
* You may find that this code doesn't respect 
* some docs. I would say that those docs are 
* interpretable :), but this code works. :) 

FUNCTION GetUserLocalGroups 
PARAMETERS tcServerName, tcUserName 


LOCAL lcServerName, lcUserName, lnFlags, lnBufferPointer 
LOCAL lnPreferedMaxLength, lnEntriesRead, lnTotalEntries 
LOCAL loPointersObject, lcPointer, lnPointer 
LOCAL lcGroupName, lnI 

DECLARE INTEGER NetUserGetLocalGroups IN NETAPI32 ; 

STRING @ServerName, ; 
STRING @UserName, ; 
INTEGER nLevel, ; 
INTEGER Flags, ; 
INTEGER @BufferPointer, ; 
INTEGER PreferedMaxLength, ; 
INTEGER @EntriesRead, ; 
INTEGER @TotalEntries 

DECLARE INTEGER NetApiBufferFree IN NETAPI32 ; 
INTEGER Pointer 

*-- This is the structure used by NetUserGetLocalGroups 
* to retrieve the local group name. 
*typedef struct _LOCALGROUP_USERS_INFO_0 { 
* LPWSTR lgrui0_name; 
*} LOCALGROUP_USERS_INFO_0 

*-- The server name and the user name 

* must be in Unicode format. 
lcServerName = STRCONV(STRCONV(tcServerName + CHR(0), 1), 5) 
lcUserName = STRCONV(STRCONV(tcUserName + CHR(0), 1), 5) 

*-- This is the maximum length of the returned buffer. 
* TIP: If it's too small, the NetUserGetLocalGroups function 
* will return error code 234 or 2123, 
* we double the buffer length, etc, until the length 
* is ok. Bingo! 
* Start with 10K. This should be enough almost all the times. 
lnPreferedMaxLength = 10000 


*-- Make lnFlags = 1 if you want this function to return 
* the local groups of which the user is indirectly a member 
* (that is, by the virtue of being in a global group that 
* itself is a member of one or more local groups). 
lnFlags = 0 

*-- The loop is only to find the good buffer length 
llContinue = .T. 
DO WHILE llContinue 
llContinue = .F. 

*-- Initialize the output params 
lnBufferPointer = 0 
lnEntriesRead = 0 
lnTotalEntries = 0 
lnError = NetUserGetLocalGroups(; 

@lcServerName, ; 
@lcUsername, ; 
0, ; 
lnFlags, ; 
@lnBufferPointer, ; 
lnPreferedMaxLength, ; 
@lnEntriesRead, ; 
@lnTotalEntries) 
DO CASE 
CASE lnError = 234 or lnError = 2123 
*-- The prefered buffer length is too small. 
* Double it and retry. 
lnPreferedMaxLength = lnPreferedMaxLength * 2 
llContinue = .T. 

CASE lnError = 0 
*-- The NetUserGetLocalGroups was successful 

IF lnTotalEntries > 0 
? "The user is member in " + ; 
LTRIM(STR(lnTotalEntries)) + ; 
" local groups:" 

*-- Instantiate the Pointers control. 
* We need it to retrieve the group names. 
SET CLASSLIB TO POINTERS ADDITIVE 
loPointersObject = CREATEOBJECT("Pointers") 
RELEASE CLASSLIB POINTERS 

*-- lnBufferPointer is a pointer to pointer to 
* the first group name (Unicode) 

*-- lnBufferPointer+4 is a pointer to pointer to 
* the second group name (Unicode) 
*-- Etc 
FOR lnI = 1 TO lnTotalEntries 
*-- Get the first pointer value 
lcPointer = loPointersObject.GetMemory(; 
lnBufferPointer + (lnI - 1) * 4, 4) 
lnPointer = loPointersObject.Converter.; 
DWordStringToNumber(lcPointer) 
*-- Get the string pointed by the previous pointer 
*-- 256 is the max length of a local group name 

lcGroupName = loPointersObject.GetMemory(; 

lnPointer, 256) 

*-- Convert the group name to ANSI. 
* The UnicodeToAnsiString function is defined after 
* the current function. 
lcGroupName = UnicodeToAnsiString(lcGroupName) 
? lcGroupName 
ENDFOR 
ELSE 
? "The user is not a member of any local group." 
ENDIF 

OTHERWISE 
*-- Error 
*-- Your error handler must handle this. 
? "Error:", lnError 
ENDCASE 
IF lnBufferPointer <> 0 

*-- Clean up the memory allocated by NetUserGetLocalGroups 
NetApiBufferFree(lnBufferPointer) 
ENDIF 
ENDDO 
RETURN 


*-- Converts a Unicode string to Ansi string. 
FUNCTION UnicodeToAnsiString 
PARAMETERS tcUnicodeString 

LOCAL lnAt00, lcAnsiString 

lnAt00 = AT( CHR(0) + CHR(0) + CHR(0), tcUnicodeString) 
IF lnAt00 > 0 
lcAnsiString = LEFT(tcUnicodeString, lnAt00 + 1) 
ELSE 
lcAnsiString = tcUnicodeString 
ENDIF 
lcAnsiString = STRCONV(STRCONV(lcAnsiString, 2), 6) 

RETURN lcAnsiString 


