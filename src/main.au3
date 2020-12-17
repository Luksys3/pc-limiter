;#RequireAdmin
#include "libraries/WinHttp.au3"

#include <AutoItConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <StaticConstants.au3>
#include <WinAPIFiles.au3>

Global Const $startupName = "pc-limiter.exe"
Global Const $productionName = "pc-limiter-PRODUCTION.exe"
Global $countdownMinutes = 0.1

; For monitor on/off
Global Const $lciWM_SYSCommand = 274
Global Const $lciSC_MonitorPower = 61808
Global Const $lciPower_Off = 2
Global Const $lciPower_On = -1

Global $blockIn = $countdownMinutes * 60
Global $blockInTextShape = Null

; UNBLOCKED, COUNTDOWN, BLOCKED
Global $status = "UNBLOCKED"

; Handles all autoit errors
Global $oErrorHandler = ObjEvent("AutoIt.Error", "_ErrFunc")

$programProcesses = ProcessList($startupName)
If $programProcesses[0][0] > 1 OR (@ScriptName == $productionName AND $programProcesses[0][0] > 0) Then
   MsgBox($MB_SYSTEMMODAL, "Stopped!", "PC Limiter is already running.")
   Exit
Else
   copySelfToStartup()
EndIf

While (true):
   Local $webStatus = StringLeft(getStatus(), 1)
   ConsoleWrite("'" & $webStatus & "' ")

   If $webStatus == "1" AND $status == "UNBLOCKED" Then
	  ConsoleWrite('begin')
	  beginCountdown()
   EndIf

   If $webStatus <> "1" AND $status <> "UNBLOCKED" Then
	  unblock()
   EndIf

   If $status == "UNBLOCKED" Then
	  Sleep(10000)
   ElseIf $status == "COUNTDOWN" Then
	  If Mod($blockIn, 30) == 0 OR ($blockIn <= 30 AND Mod($blockIn, 10) == 0) OR $blockIn <= 10 Then
		 writeText(getBlockInText())
	  EndIf

	  Sleep(1000)
	  $blockIn -= 1

	  If $blockIn < 0 Then
		 writeText("--:--")
		 Sleep(5000)
		 block()
	  EndIf
   ElseIf $status == "BLOCKED" Then
	  Sleep(5000)
   EndIf
WEnd

Func getStatus()
   Return HttpGet("https://------.eu/api/limiter/")
EndFunc

Func block()
   $status = "BLOCKED"

   writeText("BLOCKED")
   Send("{VOLUME_MUTE}")
   BlockInput($BI_DISABLE)
EndFunc

Func unblock()
   $status = "UNBLOCKED"

   clearText()
   Send("{VOLUME_MUTE}")
   BlockInput($BI_ENABLE)
EndFunc

Func beginCountdown()
   $status = "COUNTDOWN"

   $blockIn = $countdownMinutes * 60
EndFunc

Func writeText($text)
   clearText()
   $blockInTextShape = _FreeText_Create($text, 20, 20, 40, "red", 100)
EndFunc

Func clearText()
   If $blockInTextShape <> Null Then
	  _FreeText_Delete($blockInTextShape)
	  $blockInTextShape = Null
   EndIf
EndFunc

Func showMonitor($show)
   Local $Progman_hwnd = WinGetHandle('[CLASS:Progman]')
   DllCall('user32.dll', 'int', 'SendMessage', _
				'hwnd', $Progman_hwnd, _
				'int', $lciWM_SYSCommand, _
				'int', $lciSC_MonitorPower, _
				'int', $show == True ? $lciPower_On : $lciPower_Off)
EndFunc

Func getBlockInText()
   Local $seconds = Mod($blockIn, 60)
   Return Int($blockIn / 60) & ":" & ($seconds <= 9 ? "0" : "") & $seconds
EndFunc

Func copySelfToStartup()
   If @ScriptName <> $productionName Then
	  Return
   EndIf

   Local Const $fullStartupPath = @StartupDir & "/" & $startupName

   FileDelete($fullStartupPath)
   FileCopy(@ScriptFullPath, $fullStartupPath)
   ShellExecute($fullStartupPath)

   MsgBox($MB_SYSTEMMODAL, "Success!", "PC Limiter started for production.")

   Sleep(2000)
   Exit
EndFunc

Func _ErrFunc()
   Local $info = 'Error occured#br#' & _
				 "ERR.DESCRIPTION:    " & $oErrorHandler.description    & "#br#" & _
				 "ERR.WINDESCRIPTION: " & $oErrorHandler.windescription & "#br#" & _
				 "ERR.NUMBER:         " & hex($oErrorHandler.number,8)  & "#br#" & _
				 "ERR.LASTDLLERROR:   " & $oErrorHandler.lastdllerror   & "#br#" & _
				 "ERR.SCRIPTLINE:     " & $oErrorHandler.scriptline     & "#br#" & _
				 "ERR.SOURCE:         " & $oErrorHandler.source         & "#br#" & _
				 "ERR.HELPFILE:       " & $oErrorHandler.helpfile       & "#br#" & _
				 "ERR.HELPCONTEXT:    " & $oErrorHandler.helpcontext

   ConsoleWrite($info)
EndFunc

Func _FreeText_Create($String, $Left = -1, $Top = -1, $Size = 50, $Color = "Black", $Font = "Arial", $Weight = 1000)
	Local $TL_S = StringSplit($String, ""), $T_GUI[UBound($TL_S)][2], $rgn, $Space = 2 ; Adjust as needed
	If $Left = -1 Then $Left = (@DesktopWidth * .5) - (($TL_S[0] * $Size) * .6) ; Adjust as needed
	If StringIsXDigit($Color) = 0 Then $Color = _GetColorByName($Color)
	For $x = 1 To $TL_S[0]
		$T_GUI[$x][0] = GUICreate("", $Size + $Space, $Size + $Space, $Left + ($x * ($Size + $Space) * 0.5), $Top, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
		GUISetBkColor($Color)
		$rgn = CreateTextRgn($T_GUI[$x][0], $TL_S[$x], $Size, $Font, $Weight)
		SetWindowRgn($T_GUI[$x][0], $rgn)
		$T_GUI[$x][1] = $TL_S[$x]
		GUISetState()
	Next
	Return $T_GUI
 EndFunc   ;==>_FreeText_Create

 Func _GetColorByName($name)
	Select
		Case $name = "black"
			Return "0x000000"
		Case $name = "white"
			Return "0xffffff"
		Case $name = "red"
			Return "0xff0000"
		Case $name = "blue"
			Return "0x0000ff"
		Case $name = "green"
			Return "0x00ff00"
		Case $name = "yellow"
			Return "0xffff00"
		Case $name = "violet"
			Return "0xAE7BE1"
		Case $name = "win_xp_bg"
			Return "0xECE9D8"
		Case $name = "Random"
			Return "Random"
		Case Else
			Return "0x000000" ; just return black
	EndSelect
EndFunc   ;==>_GetColorByName

Func CreateTextRgn(ByRef $CTR_hwnd, $CTR_Text, $CTR_height, $CTR_font = "Microsoft Sans Serif", $CTR_weight = 1000)
	Local Const $ANSI_CHARSET = 0
	Local Const $OUT_CHARACTER_PRECIS = 2
	Local Const $CLIP_DEFAULT_PRECIS = 0
	Local Const $PROOF_QUALITY = 2
	Local Const $FIXED_PITCH = 1
	Local Const $RGN_XOR = 3
	If $CTR_font = "" Then $CTR_font = "Microsoft Sans Serif"
	If $CTR_weight = -1 Then $CTR_weight = 1000
	Local $gdi_dll = DllOpen("gdi32.dll")
	Local $CTR_hDC = DllCall("user32.dll", "int", "GetDC", "hwnd", $CTR_hwnd)
	Local $CTR_hMyFont = DllCall($gdi_dll, "hwnd", "CreateFont", "int", $CTR_height, "int", 0, "int", 0, "int", 0, _
			"int", $CTR_weight, "int", 0, "int", 0, "int", 0, "int", $ANSI_CHARSET, "int", $OUT_CHARACTER_PRECIS, _
			"int", $CLIP_DEFAULT_PRECIS, "int", $PROOF_QUALITY, "int", $FIXED_PITCH, "str", $CTR_font)
	Local $CTR_hOldFont = DllCall($gdi_dll, "hwnd", "SelectObject", "int", $CTR_hDC[0], "hwnd", $CTR_hMyFont[0])
	DllCall($gdi_dll, "int", "BeginPath", "int", $CTR_hDC[0])
	DllCall($gdi_dll, "int", "TextOut", "int", $CTR_hDC[0], "int", 0, "int", 0, "str", $CTR_Text, "int", StringLen($CTR_Text))
	DllCall($gdi_dll, "int", "EndPath", "int", $CTR_hDC[0])
	Local $CTR_hRgn1 = DllCall($gdi_dll, "hwnd", "PathToRegion", "int", $CTR_hDC[0])
	Local $CTR_rc = DllStructCreate("int;int;int;int")
	DllCall($gdi_dll, "int", "GetRgnBox", "hwnd", $CTR_hRgn1[0], "ptr", DllStructGetPtr($CTR_rc))
	Local $CTR_hRgn2 = DllCall($gdi_dll, "hwnd", "CreateRectRgnIndirect", "ptr", DllStructGetPtr($CTR_rc))
	DllCall($gdi_dll, "int", "CombineRgn", "hwnd", $CTR_hRgn2[0], "hwnd", $CTR_hRgn2[0], "hwnd", $CTR_hRgn1[0], "int", $RGN_XOR)
	DllCall($gdi_dll, "int", "DeleteObject", "hwnd", $CTR_hRgn1[0])
	DllCall("user32.dll", "int", "ReleaseDC", "hwnd", $CTR_hwnd, "int", $CTR_hDC[0])
	DllCall($gdi_dll, "int", "SelectObject", "int", $CTR_hDC[0], "hwnd", $CTR_hOldFont[0])
	DllClose($gdi_dll)
	Return $CTR_hRgn2[0]
EndFunc   ;==>CreateTextRgn

Func SetWindowRgn($h_win, $rgn)
	DllCall("user32.dll", "long", "SetWindowRgn", "hwnd", $h_win, "long", $rgn, "int", 1)
EndFunc   ;==>SetWindowRgn

Func _FreeText_Delete($T_GUI)
	If Not IsArray($T_GUI) Then Return 0
	For $x = 1 To UBound($T_GUI) - 1
		Sleep(1)
		GUIDelete($T_GUI[$x][0])
	Next
	Return 1
EndFunc   ;==>_FreeText_Delete