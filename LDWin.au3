#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=network.ico
#AutoIt3Wrapper_Outfile=LDWin.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Description=Link Discovery for Windows
#AutoIt3Wrapper_Res_Fileversion=0.0.0.2
#AutoIt3Wrapper_Res_LegalCopyright=Chris Hall 2010-2013
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_Res_Field=ProductName|LDWin
#AutoIt3Wrapper_Res_Field=ProductVersion|0.2
#AutoIt3Wrapper_Res_Field=OriginalFileName|LDWin.exe
#AutoIt3Wrapper_Run_AU3Check=n
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;===================================================================================================================================================================
; LDWin - Link Discovery for Windows - Chris Hall 2010-2013
;===================================================================================================================================================================
$VER = "0.2"

#include <GuiConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <File.au3>
#Include <String.au3>
#include <GuiButton.au3>
#include <ComboConstants.au3>
$WinLDPVer = "LDWin - v"& $VER &" - Chris Hall - 2010-" & @YEAR

if IsAdmin() = 0 then
	MsgBox(16,"Exiting","This program requires Local Admistrator rights")
	Exit
	EndIf
FileInstall("tcpdump.exe", @TempDir & '\', 1)
GUISetIcon("network.ico")

$log = FileOpen(@TempDir & "\LinkData.txt", 2)
$wbemFlagReturnImmediately = 0x10
$wbemFlagForwardOnly = 0x20
$colItems = ""
$strComputer = "localhost"
$Output=""
$Nic_Friend =""
$Hardware=""
$IData=""
SplashTextOn("Please Wait","Enumerating Network Cards via WMI...", 300, 50)
$objWMIService = ObjGet("winmgmts:\\" & $strComputer & "\root\CIMV2")
$colItems = $objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapter", "WQL", $wbemFlagReturnImmediately + $wbemFlagForwardOnly)
If IsObj($colItems) then
   For $objItem In $colItems
			FileWriteLine($log, "[" & $objItem.NetConnectionID & "]")
			FileWriteLine($log, "ProductName=" & $objItem.ProductName)
			$value = $objItem.NetConnectionID
			If StringLen($value) > 1 Then $Output = $Output & $value & "|"
			$colItems2 = $objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration", "WQL", $wbemFlagReturnImmediately + $wbemFlagForwardOnly)
			For $objItem2 In $colItems2
				If $objItem.Index = $objItem2.Index Then
					FileWriteLine($log, "SettingID=" & $objItem2.SettingID)
				EndIf
			Next
	Next
Else
   Msgbox(0,"WMI Output","No WMI Objects Found for class: " & "Win32_NetworkAdapterConfiguration" )
Endif
SplashOff()
$gui = GUICreate("Link Discovery for Windows", 550, 400, (@DesktopWidth - 550) / 2, (@DesktopHeight - 400) / 2, $WS_OVERLAPPEDWINDOW + $WS_VISIBLE + $WS_CLIPSIBLINGS)
GUICtrlCreateGroup("Selection ", 15, 10, 520, 110)
GUICtrlCreateLabel("Network Connection:", 30, 35, 100, 20)
$Nic_Friendly = GUICtrlCreateCombo("",145,33,350,20, $CBS_DROPDOWNLIST)
GUICtrlSetData(-1, $Output)
GUICtrlCreateLabel("Network Card:", 30, 62, 100, 20)
$Get = GUICtrlCreateButton("Get Link Data", 120, 85, 100)
$Save = GUICtrlCreateButton("Save Link Data", 260, 85, 100)
$Cancel = GUICtrlCreateButton("Cancel", 400, 85, 100)
If RegRead("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System", "EnableLUA") > 0 Then
    GUICtrlSetImage($Get, "imageres.dll", -2, 0)
	 _GUICtrlButton_SetShield($Get)
EndIf
GUICtrlCreateGroup("Results ", 15, 130, 520, 160)
GUICtrlCreateLabel("Switch Name:", 30, 160, 70, 20)
GUICtrlCreateLabel("Port Identifier:", 30, 190, 70, 20)
GUICtrlCreateLabel("VLAN Identifier:", 30, 220, 75, 20)
GUICtrlCreateLabel("Switch IP Address:", 30, 250, 90, 20)
GUICtrlCreateLabel("Switch Model:", 280, 190, 70, 20)
GUICtrlCreateLabel("Port Duplex:", 280, 220, 70, 20)
GUICtrlCreateLabel("VTP Mgmt Domain:", 280, 250, 95, 20)
GUICtrlCreateGroup("Status ", 15, 300, 520, 65)
GUICtrlCreateLabel($WinLDPVer, 350, 375, 275, 20)

	While 1
		Switch GUIGetMsg()

		Case $Nic_Friendly
			$Nic_Friend = GUICtrlRead ($Nic_Friendly)
			$IData = IniReadSection(@TempDir & "\LinkData.txt", $Nic_Friend)
			$Hardware = $IData[1][1]
			GUICtrlCreateLabel($Hardware, 145, 62, 350, 20)
			ClearResults()
		 Case $Get
			If GUICtrlRead($Nic_Friendly) = "" Then
			   MsgBox(64,"Invalid Selection", "Please select a network card using the dropdown")
			   ContinueLoop
			EndIf
			GetCDP($Nic_Friendly)
		Case $GUI_EVENT_CLOSE
			OnExit()
			ExitLoop
		Case $Cancel
			OnExit()
			ExitLoop
		Case $Save
			SaveData()
		Case Else
				;;;
		EndSwitch
	WEnd
Exit
	Func GetCDP($Nic_Friendly)
		$SaveFile = FileOpen(@TempDir & "\SaveData.txt", 2)
		GUICtrlSetState($Get, $GUI_DISABLE)
		GUICtrlSetState($Save, $GUI_DISABLE)
		ClearResults()
		FileWriteLine($SaveFile, $Nic_Friend & " (" & $Hardware & ") is connected to:")
		FileWriteLine($SaveFile, "------------------------------------------------------")
		$ID = $IData[2][1]

;******** DIAG MODE ********
		$TCPDmpPID = Run(@ComSpec & " /c " & @TempDir & '\tcpdump.exe -i \Device\' & $ID & ' -nn -v -s 1500 -c 1 ether[20:2] == 0x2000 >%temp%\Data_Out.txt', "", @SW_HIDE)
		;$TCPDmpPID = "0"
;******** DIAG MODE ********
		$Secs = 1
		$Status1 = GUICtrlCreateLabel("Running ... May take up to 60 seconds between link announcements ...", 120, 320, 350, 20 )
		$iBegin = TimerInit()
		Do
			$msg = GUIGetMsg()
			If $msg = $Cancel Then
				ProcessClose("tcpdump.exe")
				ExitLoop
			EndIf
			If Ceiling(TimerDiff($iBegin)) = ($Secs * 1000) or Ceiling(TimerDiff($iBegin)) > ($Secs * 1000) Then
				GUICtrlCreateLabel(Round($Secs,0) & " Seconds elapsed", 240, 340, 100, 20 )
				$Secs = $Secs + 1
			EndIf
			$TCPDmpPID = ProcessExists($TCPDmpPID)
		Until $TCPDmpPID = "0" Or TimerDiff($iBegin) > 60000
		GUICtrlDelete($Status1)
		GUICtrlCreateLabel("", 240, 337, 100, 20 )
		GUICtrlCreateLabel("", 210, 317, 200, 20)
$file = FileOpen(@TempDir & "\Data_Out.txt")
$end = _FileCountLines(@TempDir & "\Data_Out.txt")
If $end > 0 Then
$line = 0
Do
;===== CDP ==========================================================================
	If StringInStr(FileReadLine($file, $line), "Device-ID (0x01)") Then
		$SwitchName = StringSplit(FileReadLine($file, $line), "'")
		$SwitchName = StringUpper($SwitchName[2])
		GUICtrlCreateLabel($SwitchName, 140, 160, 180, 20)
		FileWriteLine($SaveFile, "Switch Name:	" & $SwitchName)
	EndIf
	If StringInStr(FileReadLine($file, $line), "Port-ID (0x03)") Then
		$SwitchPort = StringSplit(FileReadLine($file, $line), "'")
		GUICtrlCreateLabel($SwitchPort[2], 140, 190, 120, 20)
		FileWriteLine($SaveFile, "Switch Port:	" & $SwitchPort[2])
	EndIf
	If StringInStr(FileReadLine($file, $line), "VLAN ID (0x0a)") Then
		$VLAN = StringSplit(FileReadLine($file, $line), ":")
		$VLAN = StringStripWS($VLAN[3],8)
		GUICtrlCreateLabel($VLAN, 140, 220, 120, 20)
		FileWriteLine($SaveFile, "VLAN ID:	" & $VLAN)
	EndIf
	If StringInStr(FileReadLine($file, $line), "Address (0x02)") Then
		$SwitchIP = StringSplit(FileReadLine($file, $line), ")")
		$SwitchIP = StringStripWS($SwitchIP[3],8)
		GUICtrlCreateLabel($SwitchIP, 140, 250, 120, 20)
		FileWriteLine($SaveFile, "Switch IP:	" & $SwitchIP)
	EndIf
	If StringInStr(FileReadLine($file, $line), "Platform (0x06)") Then
		$SwitchModel = StringSplit(FileReadLine($file, $line), "'")
		$SwitchModel = StringUpper($SwitchModel[2])
		If StringInStr($SwitchModel, "CISCO") Then
			$SwitchModel = StringTrimLeft(StringUpper($SwitchModel), 6)
		EndIf
			GUICtrlCreateLabel($SwitchModel, 390, 190, 120, 20)
			FileWriteLine($SaveFile, "Switch Model:	" & $SwitchModel)
	EndIf
	If StringInStr(FileReadLine($file, $line), "Duplex (0x0b)") Then
		$Duplex = StringSplit(FileReadLine($file, $line), ":")
		$Duplex = StringLower(StringStripWS($Duplex[3],8))
		$Duplex = _StringProper($Duplex)
		GUICtrlCreateLabel($Duplex, 390, 220, 120, 20)
		FileWriteLine($SaveFile, "Switch Duplex:	" & $Duplex)
	EndIf
	If StringInStr(FileReadLine($file, $line), "VTP Management Domain (0x09)") Then
		$VTP = StringSplit(FileReadLine($file, $line), "'")
		GUICtrlCreateLabel($VTP[2], 390, 250, 120, 20)
		FileWriteLine($SaveFile, "VTP Mgmt:	" & $VTP[2])
	EndIf
;===== LLDP =========================================================================
	If StringInStr(FileReadLine($file, $line), "System Name TLV (5)") Then
		$SwitchName = StringSplit(FileReadLine($file, $line), ":")
		$SwitchName = StringStripWS(StringUpper($SwitchName[2]), 3)
		GUICtrlCreateLabel($SwitchName, 140, 160, 180, 20)
		FileWriteLine($SaveFile, "Switch Name:	" & $SwitchName)
	EndIf
	If StringInStr(FileReadLine($file, $line), "Port Description TLV (4)") Then
		$SwitchPort = StringSplit(FileReadLine($file, $line), ":")
		$SwitchPort = StringStripWS($SwitchPort[2], 3)
		GUICtrlCreateLabel($SwitchPort, 140, 190, 120, 40)
		FileWriteLine($SaveFile, "Switch Port:	" & $SwitchPort)
	EndIf
	If StringInStr(FileReadLine($file, $line), "port vlan id (PVID)") Then
		$VLAN = StringSplit(FileReadLine($file, $line), ":")
		$VLAN = StringStripWS($VLAN[2],3)
		GUICtrlCreateLabel($VLAN, 140, 220, 120, 20)
		FileWriteLine($SaveFile, "VLAN ID:	" & $VLAN)
	EndIf
	If StringInStr(FileReadLine($file, $line), "Management Address TLV (8)") Then
		$SwitchIP = StringSplit(FileReadLine($file, $line), ":")
		If @error Then
			$nextline = $line + 1
			$SwitchIP = StringSplit(FileReadLine($file, $nextline), ":")
		Else
			$SwitchIP = $SwitchIP[2]
		EndIf
		$SwitchIP = StringStripWS(StringUpper($SwitchIP[2]), 3)
		GUICtrlCreateLabel($SwitchIP, 140, 250, 120, 20)
		FileWriteLine($SaveFile, "Switch IP:	" & $SwitchIP)
	EndIf
	If StringInStr(FileReadLine($file, $line), "System Description TLV (6)") Then
		$SwitchModel = StringSplit(FileReadLine($file, $line), ":")
		If @error Then
			$nextline = $line + 1
			$SwitchModel = FileReadLine($file, $nextline)
		Else
			$SwitchModel = $SwitchModel[2]
		EndIf
		$SwitchModel = StringStripWS($SwitchModel, 3)
		GUICtrlCreateLabel($SwitchModel, 390, 190, 120, 40)
		FileWriteLine($SaveFile, "Switch Model:	" & $SwitchModel)
	EndIf
;	If StringInStr(FileReadLine($file, $line), "Duplex (0x0b)") Then
;		$Duplex = StringSplit(FileReadLine($file, $line), ":")
;		$Duplex = StringLower(StringStripWS($Duplex[3],8))
;		$Duplex = _StringProper($Duplex)
;		GUICtrlCreateLabel($Duplex, 390, 220, 120, 20)
;		FileWriteLine($SaveFile, "Switch Duplex:	" & $Duplex)
;	EndIf
;	If StringInStr(FileReadLine($file, $line), "VTP Management Domain (0x09)") Then
;		$VTP = StringSplit(FileReadLine($file, $line), "'")
;		GUICtrlCreateLabel($VTP[2], 390, 250, 120, 20)
;		FileWriteLine($SaveFile, "VTP Mgmt:	" & $VTP[2])
;	EndIf
	$line = $line + 1
Until $line = $end
Else
	If ProcessExists("tcpdump.exe") Then ProcessClose("tcpdump.exe")
	GUICtrlCreateLabel("NO LINK DATA FOUND ... !", 210, 325, 150, 20)
	FileClose($SaveFile)
	FileDelete(@TempDir & "\SaveData.txt")
EndIf
	FileClose($SaveFile)
	FileClose($file)
;******** DIAG MODE ********
	FileDelete(@TempDir & "\Data_Out.txt")
;******** DIAG MODE ********
	GUICtrlSetState($Get, $GUI_ENABLE)
	GUICtrlSetState($Save, $GUI_ENABLE)
	EndFunc

	Func ClearResults()
		GUICtrlCreateLabel("", 140, 160, 180, 20)
		GUICtrlCreateLabel("", 140, 190, 120, 20)
		GUICtrlCreateLabel("", 140, 220, 120, 20)
		GUICtrlCreateLabel("", 140, 250, 120, 20)
		GUICtrlCreateLabel("", 390, 190, 120, 20)
		GUICtrlCreateLabel("", 390, 220, 120, 20)
		GUICtrlCreateLabel("", 390, 250, 120, 20)
	EndFunc

	Func SaveData()
		If FileExists(@TempDir & "\SaveData.txt") = 0 Then Return
		$UserSave = FileSaveDialog("Save Link Data to","::{20D04FE0-3AEA-1069-A2D8-08002B30309D}","Text Documents (*.txt)", 2)
		If $UserSave = "" Then Return
		If StringInStr($UserSave, ".txt") = 0 Then $UserSave = $UserSave & ".txt"
		FileOpen($UserSave, 1)
		FileWrite($UserSave, FileRead(@TempDir & "\SaveData.txt") & @CRLF)
		FileClose($UserSave)
	EndFunc

	Func OnExit()
		If ProcessExists("tcpdump.exe") Then ProcessClose("tcpdump.exe")
		FileClose($log)
		FileDelete(@TempDir & "\LinkData.txt")

		FileDelete(@TempDir & "\tcpdump.exe")
		FileDelete(@TempDir & "\SaveData.txt")
	EndFunc