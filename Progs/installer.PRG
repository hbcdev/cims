
#define REINSTALLMODE_FILEMISSING          2  && Reinstall only if file is missing
#define REINSTALLMODE_FILEOLDERVERSION     4  && Reinstall if file is missing, or older version
#define REINSTALLMODE_FILEEQUALVERSION     8  && Reinstall if file is missing, or equal or older version
#define REINSTALLMODE_FILEEXACT           16  && Reinstall if file is missing, or not exact version
#define REINSTALLMODE_FILEVERIFY          32  && checksum executables, reinstall if missing or corrupt
#define REINSTALLMODE_FILEREPLACE         64  && Reinstall all files, regardless of version
#define REINSTALLMODE_MACHINEDATA        128  && insure required machine reg entries
#define REINSTALLMODE_USERDATA           256  && insure required user reg entries
#define REINSTALLMODE_SHORTCUT           512  && validate shortcuts items
#define REINSTALLMODE_PACKAGE           1024  && use re-cache source install package


#define ERROR_SUCCESS                      0  && Success
#define ERROR_INSTALL_USEREXIT          1602  && User cancel installation.
#define ERROR_INSTALL_FAILURE           1603  && Fatal error during installation.
#define ERROR_INSTALL_SUSPEND           1604  && Installation suspended, incomplete.
#define ERROR_UNKNOWN_PRODUCT           1605  && This action is only valid for products that are currently installed.
#define ERROR_UNKNOWN_FEATURE           1606  && Feature ID not registered.
#define ERROR_UNKNOWN_COMPONENT         1607  && Component ID not registered.
#define ERROR_UNKNOWN_PROPERTY          1608  && Unknown property.
#define ERROR_INVALID_HANDLE_STATE      1609  && Handle is in an invalid state.
#define ERROR_BAD_CONFIGURATION         1610  && The configuration data for this product is corrupt.  Contact your support personnel.
#define ERROR_INDEX_ABSENT              1611  && Component qualifier not present.
#define ERROR_INSTALL_SOURCE_ABSENT     1612  && The installation source for this product is not available.  Verify that the source exists and that you can access it.
#define ERROR_PRODUCT_UNINSTALLED       1614  && Product is uninstalled.
#define ERROR_BAD_QUERY_SYNTAX          1615  && SQL query syntax invalid or unsupported.
#define ERROR_INVALID_FIELD             1616  && Record field does not exist.


If !File("REQUIREDFILE.TXT")

   Declare Long MsiReinstallProduct In MSI.DLL String cProduct, Long nLevel

   If MsiReinstallProduct("{D4A7800F-92E5-11D4-B09E-0080AD42C637}", REINSTALLMODE_FILEOLDERVERSION) <> ERROR_SUCCESS
      MessageBox("Unable to repair product installation")
   Endif

Endif
