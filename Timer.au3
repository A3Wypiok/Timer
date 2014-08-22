#include <GuiConstants.au3>
#include <WindowsConstants.au3>
#include <SendMessage.au3>
#include <GuiconstantsEx.au3>
#include <StaticConstants.au3>
#include <EditConstants.au3>
#Include <WinAPI.au3>
#include <TrayConstants.au3>
#include <Timers.au3>

Opt("TrayMenuMode", 3)

;Global var for GUI
Global $hGUI, $input
Global Const $SC_DRAGMOVE = 0xF012
Global $filename = "GuiSettings.ini", $pathFileSettings = @WorkingDir & "\" & $filename

;Global var for Key
Global $key = LinkKey(IniRead($pathFileSettings, "HotKey", "Key", "ç"))

;Global var for Time
Global $defaultTime = Int(IniRead($pathFileSettings, "Timer", "Time", 60000))
Global $ms ;This is the time in milliseconds

;Global var for Timers
Global $iTimer, $iTimerSec

; Global var for TrayItems
Global $isPause = 0, $pass = 1, $flag = 0

OnAutoItExitRegister("OnAutoItExit")

Global $idHotKey = TrayCreateItem("Change HotKey")

Global $idTimer = TrayCreateItem("Change Timer")
TrayCreateItem("") ; Create a separator line.

Global $idPassThrough = TrayCreateItem("Pass Through")
TrayItemSetState($idPassThrough, $TRAY_CHECKED)
TrayCreateItem("") ; Create a separator line.

Global $idScriptState = TrayCreateItem("Disable")
TrayCreateItem("") ; Create a separator line.

Global $idExit = TrayCreateItem("Exit")

TraySetState(3) ; Show the tray menu.
TraySetToolTip("Timer")
TraySetIcon(@WorkingDir & "\" & "timer.ico") ; set icon

While 1
   ; A loop
   $msg = GUIGetMsg()
   Switch $msg
	  Case $GUI_EVENT_PRIMARYDOWN
		 _SendMessage($hGUI, $WM_SYSCOMMAND, $SC_DRAGMOVE, 0)
	  Case $GUI_EVENT_CLOSE
		 ExitLoop
   EndSwitch

   $msg = TrayGetMsg()
   Switch $msg
	  Case $idHotKey
		 ChangeHotKey()
	  Case $idTimer
		 ChangeTimer()
	  Case $idPassThrough
		 PassThrough()
	  Case $idScriptState
		 ScriptState()
	  Case $idExit ; Exit the loop.
		 ExitLoop
   EndSwitch
WEnd
Exit

;----------------------------------
Func timer()
   if $flag == 0 Then
	  startTimer()
   Else
	  stopTimer(-1, -1, -1, -1)
   EndIf

	HotKeySet($key)
	If $pass = 1 Then
		Send($key)
	EndIf
	HotKeySet($key, "timer")
EndFunc

Func startTimer()
   $ms = Int(IniRead($pathFileSettings, "Timer", "Time", $defaultTime))
   $defaultTime = $ms

	$flag = 1

	$hGUI= GuiCreate("PortalTimer",200, 50, IniRead($pathFileSettings, "Position", "X-Pos", 0),IniRead($pathFileSettings, "Position", "Y-Pos", 0), $WS_POPUP, BitOr($WS_EX_TOOLWINDOW, $WS_EX_TOPMOST, $WS_EX_LAYERED))
	GUISetIcon("portal.ico")

	$iTimer = _Timer_SetTimer($hGUI, $ms, "stopTimer")

	Local $color = 0xe07300
	GUISetBkColor($color)
	_WinAPI_SetLayeredWindowAttributes($hGUI, $color, 255)

	$input = GUICtrlCreateLabel("", 5, -2, 190, 50, BitOr($SS_CENTER, $ES_READONLY))
	GUICtrlSetFont($input, 36, 800, Default, "Agency FB", 3)
	GUICtrlSetColor ($input, 0xea730d) ;orange

	$iTimerSec = _Timer_SetTimer($hGUI, 1000, "_MinusOne")

	UpdateTime()

	GuiSetState(@SW_SHOWNOACTIVATE, $hGUI)
EndFunc

Func stopTimer($hWnd, $iMsg, $iIDTimer, $iTime)
   _Timer_KillTimer($hGUI, $iTimerSec)
   _Timer_KillTimer($hGUI, $iTimer)

   $flag = 0
   SavePosition()
   GUIDelete($hGUI)
EndFunc

func SavePosition()
	Local $a = WinGetPos($hGUI)

	If WinExists($hGUI) Then
		IniWrite($pathFileSettings, "Position", "X-Pos", $a[0])
		IniWrite($pathFileSettings, "Position", "Y-Pos", $a[1])
	EndIf
EndFunc

func OnAutoItExit()
    SavePosition()
EndFunc

func _MinusOne($hWnd, $iMsg, $iIDTimer, $iTime)
	$ms = $ms - 1000
	UpdateTime()
EndFunc

Func UpdateTime()
	Local $minutes = Int($ms / 60000)
	Local $secondes = Int(Mod($ms, 60000)/1000)
	Local $time = StringFormat("%02d", $minutes) & ":" & StringFormat("%02d", $secondes)
	GUICtrlSetData($input, $time)
EndFunc

Func LinkKey($k)
   $newKey = '{' & $k & '}'
   HotKeySet($newKey, "timer")
   return $newKey
EndFunc

Func ChangeHotKey()
   Local $cHotkey = InputBox("Change HotKey", "Change HotKey (only one key)", IniRead($pathFileSettings, "HotKey", "Key", "ç"), " M1")
   If $cHotkey <> "" and @error <> 1 Then
	  HotKeySet($key) ;remove hotkey
	  $key = LinkKey($cHotkey)
	  IniWrite($pathFileSettings, "HotKey", "Key", $cHotkey)
   EndIf
EndFunc

Func ChangeTimer()
   _Timer_KillTimer($hGUI, $iTimer)

   Local $minutes = Int($defaultTime / 60000)
   Local $secondes = Int(Mod($defaultTime, 60000)/1000)
   Local $str = StringFormat("%02d", $minutes) & ":" & StringFormat("%02d", $secondes)

   Local $cTimer = InputBox("Change Timer", "Change the countdown (mm:ss)", $str, " M5")
   If $cTimer <> "" and @error <> 1 Then ; si ce n'est pas cancel
	  Local $aArray = StringRegExp($cTimer, '([0-9]{2}):([0-9]{2})', 1)
	  If @error = 0 Then ; si c'est une bonne expression (mm:ss)
		 $minutes = $aArray[0]
		 $secondes = $aArray[1]
		 Local $toIniFile = ($minutes*60 + $secondes)*1000 ; convertion en ms
		 IniWrite($pathFileSettings, "Timer", "Time", $toIniFile)
		 $iTimer = _Timer_SetTimer($hGUI, $toIniFile, "stopTimer")
		 $defaultTime = $toIniFile
	  EndIf
   EndIf
EndFunc

Func PassThrough()
	If $pass = 1 Then
		$pass = 0
		TrayItemSetState($idPassThrough, $TRAY_UNCHECKED)
	Else
		$pass = 1
		TrayItemSetState($idPassThrough, $TRAY_CHECKED)
	EndIf
EndFunc

Func ScriptState()
	If $isPause = 1 Then
		HotKeySet($key, "timer")
		$isPause = 0
		TrayItemSetText($idScriptState, "Disable")
	Else
		HotKeySet($key)

		TrayItemSetText($idScriptState, "Activate")
		$isPause = 1
	EndIf
EndFunc
