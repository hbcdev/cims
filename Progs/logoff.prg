** Program: WinExit.prg ** 
** Purpose: Demonstrates how to declare and use the Win32 ** 
** ExitWindowsEx API. ** 
**---------------------------------------------------------------** 
uFlags = 0 
* uFlags �����Ū�Դ INTEGER ���������Ѻ��˹�˹�ҷ�����ѧ��ѹ ExitWindowsEx ( ) ����ö�դ����ѧ��� 
*     0    ����͵�ͧ��� ������ Log Off �͡�ҡ�к����͢��� 
*    1    ����͵�ͧ��� ������ Shutdown ����ͧ 
*    2     ����͵�ͧ��������� Restart ����ͧ���� 
*    4     ����͵�ͧ����͡�ҡ Windows 
dwReserved = 0 
DECLARE INTEGER ExitWindowsEx IN Win32API AS ExitWindows INTEGER @uFlags , INTEGER dwReserved 
RetVal = ExitWindows(@uFlags, dwReserved) 
CLEAR DLLS 
** End Program 
