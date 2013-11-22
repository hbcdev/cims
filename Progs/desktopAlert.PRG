local oApi
oApi = createobject('Shell.Application')
if os(3) >= '6'
	oApi.ShellExecute('vfpalert.exe','/RegServer','E:\VFPAlert\','runas')
else
	oApi.ShellExecute('vfpalert.exe','/RegServer','E:\VFPAlert\','open')
endif
release oApi
