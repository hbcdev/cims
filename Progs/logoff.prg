** Program: WinExit.prg ** 
** Purpose: Demonstrates how to declare and use the Win32 ** 
** ExitWindowsEx API. ** 
**---------------------------------------------------------------** 
uFlags = 0 
* uFlags ข้อมูลชนิด INTEGER ที่ใช้สำหรับกำหนดหน้าที่ให้ฟังก์ชัน ExitWindowsEx ( ) สามารถมีค่าได้ดังนี้ 
*     0    เมื่อต้องการ สั่งให้ Log Off ออกจากระบบเครือข่าย 
*    1    เมื่อต้องการ สั่งให้ Shutdown เครื่อง 
*    2     เมื่อต้องการสั่งให้ Restart เครื่องใหม่ 
*    4     เมื่อต้องการออกจาก Windows 
dwReserved = 0 
DECLARE INTEGER ExitWindowsEx IN Win32API AS ExitWindows INTEGER @uFlags , INTEGER dwReserved 
RetVal = ExitWindows(@uFlags, dwReserved) 
CLEAR DLLS 
** End Program 
