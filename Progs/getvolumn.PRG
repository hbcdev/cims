&&volumn ของ disk 

&&1. WinAPI

Declare Integer GetVolumeInformation in kernel32 ;
String lpRootPathName, ;
String lpVolumeNameBuffer, ;
Integer nVolumeNameSize, ;
Integer @lpVolumeSerialNumber, ;
Integer @lpMaximumComponentLength, ;
Integer @lpFileSystemFlags, ;
String lpFileSystemNameBuffer, ;
Integer nFileSystemNameSize

2. Windows Script Host (WSH)

oFile = CreateObject("Scripting.FileSystemObject")
oDrive = oFile.GetDrive("C:")
WITH oDrive
? .VolumeName
? .SerialNumber
ENDWITH
