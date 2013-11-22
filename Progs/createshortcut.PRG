WshShell = CreateObject("WScript.Shell")
strDesktop = WshShell.SpecialFolders("Desktop")
oMyShortCut= WshShell.CreateShortcut(strDesktop+"\Foxtest.lnk")
oMyShortCut.WindowStyle = 7  &&Minimized 0=Maximized  4=Normal 
oMyShortcut.IconLocation = home()+"wizards\graphics\builder.ico"
oMyShortCut.TargetPath = "c:\Program Files\Microsoft Visual Studio\VFP98\vfp6.exe" 
oMyShortCut.Arguments = '-c'+'"'+Home()+'config.fpw'+'"'
oMyShortCut.WorkingDirectory = "c:\"
oMyShortCut.Save