; <COMPILER: v1.1.31.01>

; #############################
; #     Script Initialization
; #############################

#NoEnv                          ; Recommended for performance and compatibility with future AutoHotkey releases.
SetBatchLines -1                ; Run script at maximum speed.
SetTitleMatchMode, 2            ; Allow partial title matches.
#SingleInstance Force           ; Only allow one instance of this script.
SetWorkingDir %A_ScriptDir%     ; Ensures a consistent starting directory.

; #############################
; #       Global Variables
; #############################

current_version := "1.0.0"          ; CHANGE ME EVERY VERSION (semantic version)
Version_Upgrade := "Official Release v1"
wintitle := "PJs Auto Clicker v1.0.0"  ; CHANGE ME EVERY VERSION
targettitle := "none"
targetwinclass := "GLFW30"
id := 0
ProgState := 0
BreakLoop := 0
MobClickDelay := 550            ; Default delay between clicks for mob grinding (550ms = ~1.8 clicks/sec)
FoodClickDelay := 550           ; Default delay between clicks for mob grinding + eating (550ms = ~1.8 clicks/sec)
ElytraRocketInterval := 5500    ; Interval between rocket fires for Elytra (5500ms = Duration III default)
SweepDistance := 125            ; Default sweep distance for mob grinding (125 pixels = 1 Minecraft block)
SweepClickDelay := 750          ; Default delay between clicks for mob sweep (750ms = perfect Minecraft sword swing with sync buffer)
GuiX := ""                      ; GUI X position (empty = center on first show)
GuiY := ""                      ; GUI Y position (empty = center on first show)

; #############################
; #      Hotkey Definitions
; #############################

; Universal Control Hotkeys
Hotkey, !^Space, StartCurrent  ; Ctrl + Alt + SPACE - Start Current Mode
Hotkey, !^s, Stop              ; Ctrl + Alt + S - Stop Automation
Hotkey, !^w, SelectWindow      ; Ctrl + Alt + W - Select Target Window

; #############################
; #        Menu Definitions
; #############################

; Clicking Menu
Menu, ClickingMenu, Add, 1 Left Click per second - w/ Food, MenuFOOD
Menu, ClickingMenu, Add, 1 Left Click per second - no food, MenuMOB
Menu, ClickingMenu, Add, Mob Grinding w/ Mouse Sweep, MenuMOBSWEEP
Menu, ClickingMenu, Add, Hold Left Click, MenuHOLDCLICK
Menu, ClickingMenu, Add, Hold Right Click, MenuHOLDRCLICK

; Movement Menu
Menu, MovementMenu, Add, Hold Forwards (w) + Eat, MenuFOODwards
Menu, MovementMenu, Add, Hold Forwards (w), MenuFORWARD
Menu, MovementMenu, Add, Hold Left (a), MenuLEFT
Menu, MovementMenu, Add, Hold Right (d), MenuRIGHT
Menu, MovementMenu, Add, Hold Backwards (s), MenuBACK
Menu, MovementMenu, Add
Menu, MovementMenu, Add, Elytra Flight - No Mouse (Can Alt-Tab), MenuENDFLIGHT
Menu, MovementMenu, Add, Elytra Flight - With Mouse (No Alt-Tab), MenuENDFLIGHTMOUSE

; Options Menu
Menu, OptionsMenu, Add, Click Here to Stop Action, Stop
Menu, OptionsMenu, Add, Check For Updates, MenuUpdate

; Main Menu
Menu, ClickerMenu, Add, Home, GoHome
Menu, ClickerMenu, Add, Clickers, :ClickingMenu
Menu, ClickerMenu, Add, Movement, :MovementMenu
Menu, ClickerMenu, Add, Options, :OptionsMenu

; #############################
; #          Main GUI
; #############################

if (ProgState != 0)
    Return

; Image asset info
CtrlW_ImgUrl  := "https://raw.githubusercontent.com/im-PJs/PJs-AutoClicker/refs/heads/main/PJs_AutoClicker_Asset.png"
CtrlW_ImgDir  := A_ScriptDir . "\\PJs_AutoClicker_assets"
CtrlW_ImgPath := CtrlW_ImgDir . "\\PJs_AutoClicker_Asset.png"

; Ensure image asset exists locally
EnsureCtrlWImage(CtrlW_ImgUrl, CtrlW_ImgDir, CtrlW_ImgPath)

; --- Intro window ---
Gui, Intro: New, +OwnDialogs +AlwaysOnTop -Resize, %wintitle%
Gui, Intro: Margin, 0, 0   ; bezel-less look

if FileExist(CtrlW_ImgPath) {
    Gui, Intro: Add, Pic, vpic_get Center w650 h650, %CtrlW_ImgPath%
} else {
    Gui, Intro: Color, 232323, 232323
    Gui, Intro: Font, s18 Bold, Segoe UI
    Gui, Intro: Add, Text, cFFFFFF Center w460, Use Ctrl+Alt+W to select your screen
    Gui, Intro: Font, s10, Segoe UI
    Gui, Intro: Add, Link, cA9A9A9 Center w460, Cannot connect to image (<a href=\"%CtrlW_ImgUrl%\">link</a>)
    Gui, Intro: Font
}

Gui, Intro: Show, AutoSize Center
Return


; #############################
; # Function Definitions
; #############################


; --- Save Current GUI Position ---
SaveGuiPos() {
    global GuiX, GuiY, wintitle
    WinGetPos, GuiX, GuiY,,, %wintitle%
}


; --- Go Home (Return to Main Menu Without Changing Window) ---
GoHome:
{
    global GuiX, GuiY
    BreakLoop := 1
    SaveGuiPos()
    Gui, Destroy

    ; Build Main Menu GUI (without changing target window)
    if (GuiX = "" || GuiY = "")
        Gui, Show, w650 h540 Center, %wintitle%
    else
        Gui, Show, x%GuiX% y%GuiY% w650 h540, %wintitle%
    Gui, +OwnDialogs
    Gui, Menu, ClickerMenu

    ; Display target window information
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y15 w610, Target Window Title: %targettitle%
    Gui, Add, Text, x20 y35 w610, Window HWIND is: %id%
    Gui, Add, Text, x20 y55 w610, To change mode of operation, select from the buttons below.
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y80 w610, MODE:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y105 vMode w30, None

    ; Attack Options
    Gui, Font, Bold s10
    Gui, Add, Text, x20 y140 w200, ATTACK OPTIONS
    Gui, Font, s7 cGreen Bold
    Gui, Add, Text, x225 y143 w95, [+] Alt-Tab Safe
    Gui, Font, s8 norm cBlack

    Gui, Add, Button, x20 y165 w145 h40 gMenuMOB, Mob Grinding
    Gui, Add, Button, x175 y165 w145 h40 gMenuFOOD, Mob Grinding + Eating
    Gui, Add, Button, x20 y215 w145 h40 gMenuHOLDCLICK, Hold Left Click
    Gui, Add, Button, x175 y215 w145 h40 gMenuHOLDRCLICK, Hold Right Click

    ; Movement Options (D-Pad layout)
    Gui, Font, Bold s10
    Gui, Add, Text, x360 y140 w150, MOVEMENT
    Gui, Font, s7 cGreen Bold
    Gui, Add, Text, x515 y143 w95, [+] Alt-Tab Safe
    Gui, Font, s8 norm cBlack

    Gui, Add, Button, x445 y165 w80 h40 gMenuFORWARD, Walk`nForwards
    Gui, Add, Button, x360 y215 w80 h40 gMenuLEFT, Walk`nLeft
    Gui, Add, Button, x530 y215 w80 h40 gMenuRIGHT, Walk`nRight
    Gui, Add, Button, x445 y265 w80 h40 gMenuBACK, Walk`nBack

    ; Experimental Features Section
    Gui, Font, Bold s11
    Gui, Add, Text, x210 y320 w250, EXPERIMENTAL FEATURES
    Gui, Font, s8 norm cBlack

    ; Row 1 - Three buttons with status below
    Gui, Add, Button, x20 y350 w200 h50 gMenuFOODwards, Walk Forward + Auto Eat
    Gui, Font, s7 cGreen Bold
    Gui, Add, Text, x20 y402 w200 Center, [+] ALT-TAB SAFE
    Gui, Font, s8 norm cBlack

    Gui, Add, Button, x225 y350 w200 h50 gMenuMOBSWEEP, Mob Grind + Mouse Sweep
    Gui, Font, s7 cRed Bold
    Gui, Add, Text, x225 y402 w200 Center, [X] NO ALT-TAB
    Gui, Font, s8 norm cBlack

    Gui, Add, Button, x430 y350 w200 h50 gMenuENDFLIGHT, Elytra Flight (No Mouse)`n7000 Blocks
    Gui, Font, s7 cGreen Bold
    Gui, Add, Text, x430 y402 w200 Center, [+] ALT-TAB SAFE
    Gui, Font, s8 norm cBlack

    ; Row 2 - Full width elytra flight with mouse
    Gui, Add, Button, x20 y430 w610 h50 gMenuENDFLIGHTMOUSE, Elytra Flight (With Mouse Control) - Better Efficiency - 7000 Blocks
    Gui, Font, s7 cRed Bold
    Gui, Add, Text, x20 y482 w610 Center, [X] NO ALT-TAB - Window Must Stay Active - Best Flight Performance
    Gui, Font, s8 norm cBlack

    ; Tooltips for buttons
    GuiControl,, MenuMOB, Tooltip, This mode will automate mob grinding.
    GuiControl,, MenuFOOD, Tooltip, This mode will automate mob grinding and eating.
    GuiControl,, MenuHOLDCLICK, Tooltip, This mode will hold the left mouse button.
    GuiControl,, MenuHOLDRCLICK, Tooltip, This mode will hold the right mouse button.
    GuiControl,, MenuFORWARD, Tooltip, This mode will automate walking forwards.
    GuiControl,, MenuLEFT, Tooltip, This mode will automate walking to the left.
    GuiControl,, MenuRIGHT, Tooltip, This mode will automate walking to the right.
    GuiControl,, MenuBACK, Tooltip, This mode will automate walking backwards.
    GuiControl,, MenuFOODwards, Tooltip, This mode will automate walking forwards and eating.

    Gui, Show,, %wintitle%

    ; Ensure mouse buttons are released
    ControlClick, , ahk_id %id%, , Right, , NAU
    ControlClick, , ahk_id %id%, , Left, , NAU
    ProgState := 1
    Sleep 500
    Return
}

; --- Select Target Window ---
SelectWindow:
{
; Close intro window so you won't have 2 windows
    Gui, Intro: Destroy

    MouseGetPos, , , id, control
    WinGetTitle, targettitle, ahk_id %id%
    WinGetClass, targetclass, ahk_id %id%
    Gosub, GoHome
    Return
}

; --- Update Checker Function ---
MenuUpdate:
{
    global GuiX, GuiY
    repo_script_url := "https://raw.githubusercontent.com/im-PJs/PJs-AutoClicker/main/PJs_AutoClicker.ahk"
    tooltip, Checking for update...
    latest_script := fetch(repo_script_url)
    tooltip
    ; Parse the version number from the latest script (supports semantic versions like 3.0.1)
    if RegExMatch(latest_script, "i)current_version\s*:=\s*""([0-9]+(?:\.[0-9]+)*)""", m)
        latest_version := m1
    else {
        MsgBox, 262144, Update, Failed to check for update
        Return
    }

    comp := CompareSemver(latest_version, current_version)
    if (comp = 1){
        SaveGuiPos()
        Gui, Destroy
        if (GuiX = "" || GuiY = "")
            Gui, Show, w275 h135 Center, Update Available
        else
            Gui, Show, x%GuiX% y%GuiY% w275 h135, Update Available
        Gui, +OwnDialogs
        Gui, Menu, ClickerMenu
        Gui, Font, Bold
        Gui, Add, Text,, You are using an old version: %current_version%
        Gui, Add, Text,, The latest version is: %latest_version%
        Gui, Font
        Gui, Add, Button, x87 y57 w100 h20 gButton1, Direct Download
        Gui, Add, Button, x87 y82 w100 h20 gButton2, Github
        Gui, Show,, %wintitle%
    }
    else if (comp = -1){
        SaveGuiPos()
        Gui, Destroy
        if (GuiX = "" || GuiY = "")
            Gui, Show, w310 h150 Center, Ahead of Release
        else
            Gui, Show, x%GuiX% y%GuiY% w310 h150, Ahead of Release
        Gui, +OwnDialogs
        Gui, Menu, ClickerMenu
        Gui, Font, Bold
        Gui, Add, Text,, Wow! You are using a newer version than released!
        Gui, Add, Text,, Your current version is: %current_version%
        Gui, Add, Text,, The latest released version is: %latest_version%
        Gui, Font
        Gui, Add, Button, x105 y80 w100 h20 gButton1, Direct Download
        Gui, Add, Button, x105 y102 w100 h20 gButton2, Github
        Gui, Show,, %wintitle%
    }
    else if (comp = 0){
        SaveGuiPos()
        Gui, Destroy
        if (GuiX = "" || GuiY = "")
            Gui, Show, w275 h86 Center, Up-to-Date
        else
            Gui, Show, x%GuiX% y%GuiY% w275 h86, Up-to-Date
        Gui, +OwnDialogs
        Gui, Menu, ClickerMenu
        Gui, Font, Bold, s10
        Gui, Add, Text,, You are using the newest version! :)
        Gui, Add, Text,, Current version: %current_version%
        Gui, Add, Button, x87 y82 w100 h20 gButton2, Github
        Gui, Font
        Gui, Show,, %wintitle%
    }
    else{
        SaveGuiPos()
        Gui, Destroy
        if (GuiX = "" || GuiY = "")
            Gui, Show, w275 h80 Center, Unknown Version Status
        else
            Gui, Show, x%GuiX% y%GuiY% w275 h80, Unknown Version Status
        Gui, +OwnDialogs
        Gui, Menu, ClickerMenu
        Gui, Font, Bold, s10
        Gui, Add, Text,, You are using the newest version! :)
        Gui, Add, Text,, Version: %current_version%
        Gui, Font
        Gui, Show,, %wintitle%
    }
    Return
}

; --- Update Buttons ---
Button1: ; Direct Download
    Run, https://github.com/im-PJs/PJs-AutoClicker/releases/latest/download/PJs_AutoClicker.ahk
Return

Button2: ; Github
    Run, https://github.com/im-PJs/PJs-AutoClicker
Return

; #############################
; #     Automation Functions
; #############################

; --- Mob Grinding Menu ---
MenuMOB:
{
    global GuiX, GuiY
    BreakLoop := 1
    SaveGuiPos()
    Gui, Destroy
    if (GuiX = "" || GuiY = "")
        Gui, Show, w460 h475 Center, Mob Grinding
    else
        Gui, Show, x%GuiX% y%GuiY% w460 h475, Mob Grinding
    Gui, +OwnDialogs
    Gui, Menu, ClickerMenu

    ; Target Window Info
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y10 w420, Target Window: %targettitle%
    Gui, Add, Text, x20 y25 w420, Window HWIND: %id%

    ; Header
    Gui, Font, Bold s11
    Gui, Add, Text, x20 y50 w420, MOB GRINDING
    Gui, Font, s8 norm cGreen Bold
    Gui, Add, Text, x20 y75 w420, [+] Alt-Tab Safe - Run in Background
    Gui, Font, s8 norm cBlack

    ; What it does
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y105, What it does:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y125 w420, Automatically left-clicks at your chosen speed without eating food.

    ; Best for
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y155, Best for:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y175 w420, - Mob grinding with regeneration beacons`n- Raid farms where you don't need food`n- Any AFK grinding setup with healing

    ; Click Speed Slider
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y230, Click Speed:
    Gui, Font, s8 norm
    Gui, Add, Slider, x20 y250 w300 h30 vMobClickDelay gMobSliderUpdate Range100-2000 TickInterval100, %MobClickDelay%
    Gui, Font, s8 norm
    Gui, Add, Text, x330 y255 w110 vMobClickLabel, %MobClickDelay%ms (~1.8/sec)

    ; Preset Speed Buttons
    Gui, Font, s7 norm
    Gui, Add, Button, x20 y285 w70 h25 gMobPresetSlow, Slow (1/s)
    Gui, Add, Button, x95 y285 w75 h25 gMobPresetNormal, Normal (2/s)
    Gui, Add, Button, x175 y285 w70 h25 gMobPresetFast, Fast (4/s)
    Gui, Add, Button, x250 y285 w70 h25 gMobPresetMax, Max (10/s)

    ; How to use
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y320, How to use:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y340 w420, 1. Use presets or adjust slider for click speed`n2. Position yourself at your mob farm`n3. Press Ctrl+Alt+SPACE to start`n4. Press Ctrl+Alt+S to stop anytime

    ; Buttons
    Gui, Font, s8 norm
    Gui, Add, Button, x90 y410 w120 h35 gMOB, START
    Gui, Add, Button, x250 y410 w120 h35 gStop, STOP
    Gui, Add, Button, x330 y50 w110 h30 gGoHome, << Home

    Gui, Show,, %wintitle%
    ProgState := 2
    Return
}

; --- Mob Grinding Slider Update ---
MobSliderUpdate:
{
    Gui, Submit, NoHide
    ClicksPerSec := Round(1000 / MobClickDelay, 1)
    GuiControl,, MobClickLabel, %MobClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

; --- Mob Grinding Preset Speed Functions ---
MobPresetSlow:
{
    MobClickDelay := 1000
    GuiControl,, MobClickDelay, %MobClickDelay%
    ClicksPerSec := Round(1000 / MobClickDelay, 1)
    GuiControl,, MobClickLabel, %MobClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

MobPresetNormal:
{
    MobClickDelay := 500
    GuiControl,, MobClickDelay, %MobClickDelay%
    ClicksPerSec := Round(1000 / MobClickDelay, 1)
    GuiControl,, MobClickLabel, %MobClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

MobPresetFast:
{
    MobClickDelay := 250
    GuiControl,, MobClickDelay, %MobClickDelay%
    ClicksPerSec := Round(1000 / MobClickDelay, 1)
    GuiControl,, MobClickLabel, %MobClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

MobPresetMax:
{
    MobClickDelay := 100
    GuiControl,, MobClickDelay, %MobClickDelay%
    ClicksPerSec := Round(1000 / MobClickDelay, 1)
    GuiControl,, MobClickLabel, %MobClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

; --- Mob Grinding Function ---
MOB:
{
    if (ProgState != 2)
        Return
    BreakLoop := 0
    Loop
    {
        if (BreakLoop = 1)
        {
            BreakLoop := 0
            Break
        }
        Sleep %MobClickDelay%
        ControlClick, , ahk_id %id%, , , , NA
    }
    Return
}

; --- Sweep Distance Slider Update ---
SweepSliderUpdate:
{
    Gui, Submit, NoHide
    Blocks := Round(SweepDistance / 125, 1)
    GuiControl,, SweepLabel, %SweepDistance% pixels (~%Blocks% blocks)
    Return
}

; --- Sweep Distance Presets ---
SweepPresetSmall:
{
    SweepDistance := 125  ; 1 Minecraft block
    GuiControl,, SweepDistance, %SweepDistance%
    GuiControl,, SweepLabel, %SweepDistance% pixels (1 block)
    Return
}

SweepPresetMedium:
{
    SweepDistance := 250  ; 2 Minecraft blocks
    GuiControl,, SweepDistance, %SweepDistance%
    GuiControl,, SweepLabel, %SweepDistance% pixels (2 blocks)
    Return
}

SweepPresetLarge:
{
    SweepDistance := 375  ; 3 Minecraft blocks
    GuiControl,, SweepDistance, %SweepDistance%
    GuiControl,, SweepLabel, %SweepDistance% pixels (3 blocks)
    Return
}

SweepPresetXLarge:
{
    SweepDistance := 550  ; 4 Minecraft blocks
    GuiControl,, SweepDistance, %SweepDistance%
    GuiControl,, SweepLabel, %SweepDistance% pixels (4 blocks)
    Return
}

; --- Sweep Click Speed Slider Update ---
SweepClickSliderUpdate:
{
    Gui, Submit, NoHide
    ClicksPerSec := Round(1000 / SweepClickDelay, 1)
    GuiControl,, SweepClickLabel, %SweepClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

; --- Sweep Click Speed Presets ---
SweepClickPerfect:
{
    SweepClickDelay := 750  ; Perfect for Minecraft sword cooldown (0.625s = 625ms, adding 125ms buffer for reliable sync)
    GuiControl,, SweepClickDelay, %SweepClickDelay%
    ClicksPerSec := Round(1000 / SweepClickDelay, 1)
    GuiControl,, SweepClickLabel, %SweepClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

SweepClickNormal:
{
    SweepClickDelay := 500  ; 2 clicks per second
    GuiControl,, SweepClickDelay, %SweepClickDelay%
    ClicksPerSec := Round(1000 / SweepClickDelay, 1)
    GuiControl,, SweepClickLabel, %SweepClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

SweepClickFast:
{
    SweepClickDelay := 250  ; 4 clicks per second
    GuiControl,, SweepClickDelay, %SweepClickDelay%
    ClicksPerSec := Round(1000 / SweepClickDelay, 1)
    GuiControl,, SweepClickLabel, %SweepClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

SweepClickMax:
{
    SweepClickDelay := 100  ; 10 clicks per second
    GuiControl,, SweepClickDelay, %SweepClickDelay%
    ClicksPerSec := Round(1000 / SweepClickDelay, 1)
    GuiControl,, SweepClickLabel, %SweepClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

; --- Mob Grinding with Mouse Sweep Menu ---
MenuMOBSWEEP:
{
    global GuiX, GuiY
    BreakLoop := 1
    SaveGuiPos()
    Gui, Destroy
    if (GuiX = "" || GuiY = "")
        Gui, Show, w460 h600 Center, Mob Grind + Mouse Sweep
    else
        Gui, Show, x%GuiX% y%GuiY% w460 h600, Mob Grind + Mouse Sweep
    Gui, +OwnDialogs
    Gui, Menu, ClickerMenu

    ; Target Window Info
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y10 w420, Target Window: %targettitle%
    Gui, Add, Text, x20 y25 w420, Window HWIND: %id%

    ; Header
    Gui, Font, Bold s11
    Gui, Add, Text, x20 y50 w420, MOB GRIND + MOUSE SWEEP
    Gui, Font, s8 norm cRed Bold
    Gui, Add, Text, x20 y75 w420, [X] NO ALT-TAB - Window Must Stay Active
    Gui, Font, s8 norm cBlack

    ; What it does
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y105, What it does:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y125 w420, Clicks at your chosen speed while sweeping mouse left and right in a smooth pattern.

    ; Best for
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y170, Best for:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y190 w420, - Dual mob spawners (look between both)`n- Grinders with multiple kill points`n- Any setup requiring side-to-side coverage

    ; Sweep Distance Slider
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y245, Sweep Distance:
    Gui, Font, s8 norm
    Gui, Add, Slider, x20 y265 w300 h30 vSweepDistance gSweepSliderUpdate Range20-600 TickInterval20, %SweepDistance%
    Gui, Font, s8 norm
    Gui, Add, Text, x330 y270 w110 vSweepLabel, %SweepDistance% pixels (1 block)

    ; Preset Distance Buttons
    Gui, Font, s7 norm
    Gui, Add, Button, x20 y300 w70 h25 gSweepPresetSmall, 1 Block
    Gui, Add, Button, x95 y300 w70 h25 gSweepPresetMedium, 2 Blocks
    Gui, Add, Button, x170 y300 w70 h25 gSweepPresetLarge, 3 Blocks
    Gui, Add, Button, x245 y300 w70 h25 gSweepPresetXLarge, 4 Blocks

    ; Click Speed Slider
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y340, Click Speed:
    Gui, Font, s8 norm
    Gui, Add, Slider, x20 y360 w300 h30 vSweepClickDelay gSweepClickSliderUpdate Range100-2000 TickInterval100, %SweepClickDelay%
    Gui, Font, s8 norm
    ClicksPerSec := Round(1000 / SweepClickDelay, 1)
    Gui, Add, Text, x330 y365 w110 vSweepClickLabel, %SweepClickDelay%ms (~%ClicksPerSec%/sec)

    ; Preset Click Speed Buttons
    Gui, Font, s7 norm
    Gui, Add, Button, x20 y395 w90 h25 gSweepClickPerfect, Perfect Swing
    Gui, Add, Button, x115 y395 w70 h25 gSweepClickNormal, Normal
    Gui, Add, Button, x190 y395 w55 h25 gSweepClickFast, Fast
    Gui, Add, Button, x250 y395 w55 h25 gSweepClickMax, Max

    ; How to use
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y435, How to use:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y455 w420, 1. Aim at the center of your grinder`n2. Adjust sweep distance (blocks) and click speed above`n3. Press START or Ctrl+Alt+SPACE to begin

    ; Important warning
    Gui, Font, Bold s9 cRed
    Gui, Add, Text, x20 y505, IMPORTANT:
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y525 w420, Window MUST stay active! You CANNOT alt-tab during this mode.

    ; Buttons
    Gui, Font, s8 norm
    Gui, Add, Button, x130 y545 w95 h30 gMOBSWEEP, START
    Gui, Add, Button, x240 y545 w95 h30 gStop, STOP
    Gui, Add, Button, x330 y50 w110 h30 gGoHome, << Home

    Gui, Show,, %wintitle%
    ProgState := 12
    Return
}

; --- Mob Grinding with Mouse Sweep Function ---
MOBSWEEP:
{
    if (ProgState != 12)
        Return
    BreakLoop := 0

    Gui, Submit, NoHide  ; Get current sweep distance and click delay values

    ; Simple countdown
    ToolTip, Starting Mob Sweep...`nSweep Distance: %SweepDistance% pixels`nClick Delay: %SweepClickDelay%ms`nStarting in 3..., 10, 10
    Sleep 1000
    ToolTip, Starting Mob Sweep...`nSweep Distance: %SweepDistance% pixels`nClick Delay: %SweepClickDelay%ms`nStarting in 2..., 10, 10
    Sleep 1000
    ToolTip, Starting Mob Sweep...`nSweep Distance: %SweepDistance% pixels`nClick Delay: %SweepClickDelay%ms`nStarting in 1..., 10, 10
    Sleep 1000
    ToolTip, GO! Mob Sweep Active!`nPress Ctrl+Alt+S to STOP, 10, 10
    Sleep 1500
    ToolTip

    ; === SWEEP PHASE ===
    SweepStep := 3 + Floor(SweepDistance / 40)  ; Moderate speed scaling (1 block=6px/step, 2 blocks=9px/step, 4 blocks=15px/step)
    SweepDelay := 30          ; Delay between movements (smooth but not too slow)
    ClickInterval := SweepClickDelay  ; Use the slider/preset value

    CurrentPosition := 0      ; 0 = center, negative = left, positive = right
    SweepPhase := "LEFT"      ; LEFT, CENTER_FROM_LEFT, RIGHT, CENTER_FROM_RIGHT

    LastClickTime := A_TickCount
    LastMouseMove := A_TickCount

    Loop
    {
        if (BreakLoop = 1)
        {
            ToolTip
            BreakLoop := 0
            Break
        }

        CurrentTime := A_TickCount

        ; Handle clicking at regular intervals
        if (CurrentTime - LastClickTime >= ClickInterval)
        {
            ControlClick, , ahk_id %id%, , , , NA
            LastClickTime := CurrentTime
        }

        ; Handle mouse sweeping
        if (CurrentTime - LastMouseMove >= SweepDelay)
        {
            ; PHASE 1: Sweep LEFT from center
            if (SweepPhase = "LEFT")
            {
                if (CurrentPosition > -SweepDistance)
                {
                    DllCall("mouse_event", "UInt", 0x0001, "Int", -SweepStep, "Int", 0, "UInt", 0, "UInt", 0)
                    CurrentPosition -= SweepStep
                }
                else
                {
                    SweepPhase := "CENTER_FROM_LEFT"
                }
            }
            ; PHASE 2: Return to CENTER from left
            else if (SweepPhase = "CENTER_FROM_LEFT")
            {
                if (CurrentPosition < 0)
                {
                    DllCall("mouse_event", "UInt", 0x0001, "Int", SweepStep, "Int", 0, "UInt", 0, "UInt", 0)
                    CurrentPosition += SweepStep
                }
                else
                {
                    CurrentPosition := 0
                    SweepPhase := "RIGHT"
                }
            }
            ; PHASE 3: Sweep RIGHT from center
            else if (SweepPhase = "RIGHT")
            {
                if (CurrentPosition < SweepDistance)
                {
                    DllCall("mouse_event", "UInt", 0x0001, "Int", SweepStep, "Int", 0, "UInt", 0, "UInt", 0)
                    CurrentPosition += SweepStep
                }
                else
                {
                    SweepPhase := "CENTER_FROM_RIGHT"
                }
            }
            ; PHASE 4: Return to CENTER from right
            else if (SweepPhase = "CENTER_FROM_RIGHT")
            {
                if (CurrentPosition > 0)
                {
                    DllCall("mouse_event", "UInt", 0x0001, "Int", -SweepStep, "Int", 0, "UInt", 0, "UInt", 0)
                    CurrentPosition -= SweepStep
                }
                else
                {
                    CurrentPosition := 0
                    SweepPhase := "LEFT"
                }
            }

            LastMouseMove := CurrentTime
        }

        Sleep 10
    }

    ToolTip
    Return
}

; --- Mob Grinding + Eating Menu ---
MenuFOOD:
{
    global GuiX, GuiY
    BreakLoop := 1
    SaveGuiPos()
    Gui, Destroy
    if (GuiX = "" || GuiY = "")
        Gui, Show, w460 h510 Center, Mob Grinding + Eating
    else
        Gui, Show, x%GuiX% y%GuiY% w460 h510, Mob Grinding + Eating
    Gui, +OwnDialogs
    Gui, Menu, ClickerMenu

    ; Target Window Info
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y10 w420, Target Window: %targettitle%
    Gui, Add, Text, x20 y25 w420, Window HWIND: %id%

    ; Header
    Gui, Font, Bold s11
    Gui, Add, Text, x20 y50 w420, MOB GRINDING + AUTO EAT
    Gui, Font, s8 norm cGreen Bold
    Gui, Add, Text, x20 y75 w420, [+] Alt-Tab Safe - Run in Background
    Gui, Font, s8 norm cBlack

    ; What it does
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y105, What it does:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y125 w420, Left-clicks at your chosen speed AND automatically right-clicks to eat food when you get hungry.

    ; Best for
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y160, Best for:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y180 w420, - Unattended mob grinding without beacons`n- Long AFK sessions where you need healing`n- Any farm where food is required

    ; Click Speed Slider
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y235, Click Speed:
    Gui, Font, s8 norm
    Gui, Add, Slider, x20 y255 w300 h30 vFoodClickDelay gFoodSliderUpdate Range100-2000 TickInterval100, %FoodClickDelay%
    Gui, Font, s8 norm
    Gui, Add, Text, x330 y260 w110 vFoodClickLabel, %FoodClickDelay%ms (~1.8/sec)

    ; Preset Speed Buttons
    Gui, Font, s7 norm
    Gui, Add, Button, x20 y290 w70 h25 gFoodPresetSlow, Slow (1/s)
    Gui, Add, Button, x95 y290 w75 h25 gFoodPresetNormal, Normal (2/s)
    Gui, Add, Button, x175 y290 w70 h25 gFoodPresetFast, Fast (4/s)
    Gui, Add, Button, x250 y290 w70 h25 gFoodPresetMax, Max (10/s)

    ; How to use
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y325, How to use:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y345 w420, 1. Put food in your hand (steak, golden carrots, etc.)`n2. Use presets or adjust slider for click speed`n3. Press Ctrl+Alt+SPACE to start`n4. Press Ctrl+Alt+S to stop anytime

    ; Buttons
    Gui, Font, s8 norm
    Gui, Add, Button, x90 y445 w120 h35 gFOOD, START
    Gui, Add, Button, x250 y445 w120 h35 gStop, STOP
    Gui, Add, Button, x330 y50 w110 h30 gGoHome, << Home

    Gui, Show,, %wintitle%
    ProgState := 4
    Return
}

; --- Food Slider Update ---
FoodSliderUpdate:
{
    Gui, Submit, NoHide
    ClicksPerSec := Round(1000 / FoodClickDelay, 1)
    GuiControl,, FoodClickLabel, %FoodClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

; --- Food Preset Speed Functions ---
FoodPresetSlow:
{
    FoodClickDelay := 1000
    GuiControl,, FoodClickDelay, %FoodClickDelay%
    ClicksPerSec := Round(1000 / FoodClickDelay, 1)
    GuiControl,, FoodClickLabel, %FoodClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

FoodPresetNormal:
{
    FoodClickDelay := 500
    GuiControl,, FoodClickDelay, %FoodClickDelay%
    ClicksPerSec := Round(1000 / FoodClickDelay, 1)
    GuiControl,, FoodClickLabel, %FoodClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

FoodPresetFast:
{
    FoodClickDelay := 250
    GuiControl,, FoodClickDelay, %FoodClickDelay%
    ClicksPerSec := Round(1000 / FoodClickDelay, 1)
    GuiControl,, FoodClickLabel, %FoodClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

FoodPresetMax:
{
    FoodClickDelay := 100
    GuiControl,, FoodClickDelay, %FoodClickDelay%
    ClicksPerSec := Round(1000 / FoodClickDelay, 1)
    GuiControl,, FoodClickLabel, %FoodClickDelay%ms (~%ClicksPerSec%/sec)
    Return
}

; --- Mob Grinding + Eating Function ---
FOOD:
{
    if (ProgState != 4)
        Return
    BreakLoop := 0

    ; Hold right-click down for continuous eating
    ControlClick, , ahk_id %id%, , Right, , D

    Loop
    {
        if (BreakLoop = 1)
        {
            ; Release right-click when stopping
            ControlClick, , ahk_id %id%, , Right, , U
            BreakLoop := 0
            Break
        }

        ; Left-click attack at configured speed
        ControlClick, , ahk_id %id%, , Left, , NA
        Sleep %FoodClickDelay%
    }

    ; Ensure mouse buttons are released
    ControlClick, , ahk_id %id%, , Right, , U
    ControlClick, , ahk_id %id%, , Left, , U
    Return
}

; --- Hold Left Click Menu ---
MenuHOLDCLICK:
{
    global GuiX, GuiY
    BreakLoop := 1
    SaveGuiPos()
    Gui, Destroy
    if (GuiX = "" || GuiY = "")
        Gui, Show, w460 h340 Center, Hold Left Click
    else
        Gui, Show, x%GuiX% y%GuiY% w460 h340, Hold Left Click
    Gui, +OwnDialogs
    Gui, Menu, ClickerMenu

    ; Target Window Info
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y10 w420, Target Window: %targettitle%
    Gui, Add, Text, x20 y25 w420, Window HWIND: %id%

    ; Header
    Gui, Font, Bold s11
    Gui, Add, Text, x20 y50 w420, HOLD LEFT CLICK
    Gui, Font, s8 norm cGreen Bold
    Gui, Add, Text, x20 y75 w420, [+] Alt-Tab Safe - Run in Background
    Gui, Font, s8 norm cBlack

    ; What it does
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y105, What it does:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y125 w420, Continuously holds down the left mouse button.

    ; Best for
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y155, Best for:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y175 w420, - Mining long tunnels or strip mining`n- Breaking blocks continuously`n- Any task requiring constant left-click

    ; How to use
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y225, How to use:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y245 w420, Press Ctrl+Alt+SPACE to start, Ctrl+Alt+S to stop

    ; Buttons
    Gui, Font, s8 norm
    Gui, Add, Button, x90 y275 w120 h35 gHOLDCLICK, START
    Gui, Add, Button, x250 y275 w120 h35 gStop, STOP
    Gui, Add, Button, x330 y50 w110 h30 gGoHome, << Home

    Gui, Show,, %wintitle%
    ProgState := 3
    Return
}

; --- Hold Left Click Function ---
HOLDCLICK:
{
    if (ProgState != 3)
        Return
    BreakLoop := 0
    ControlClick, , ahk_id %id%, , Left, , D  ; Hold down left click
    Loop
    {
        if (BreakLoop = 1)
        {
            ControlClick, , ahk_id %id%, , Left, , U  ; Release left click
            BreakLoop := 0
            Break
        }
        Sleep 100
    }
    Return
}

; --- Hold Right Click Menu ---
MenuHOLDRCLICK:
{
    global GuiX, GuiY
    BreakLoop := 1
    SaveGuiPos()
    Gui, Destroy
    if (GuiX = "" || GuiY = "")
        Gui, Show, w460 h340 Center, Hold Right Click
    else
        Gui, Show, x%GuiX% y%GuiY% w460 h340, Hold Right Click
    Gui, +OwnDialogs
    Gui, Menu, ClickerMenu

    ; Target Window Info
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y10 w420, Target Window: %targettitle%
    Gui, Add, Text, x20 y25 w420, Window HWIND: %id%

    ; Header
    Gui, Font, Bold s11
    Gui, Add, Text, x20 y50 w420, HOLD RIGHT CLICK
    Gui, Font, s8 norm cGreen Bold
    Gui, Add, Text, x20 y75 w420, [+] Alt-Tab Safe - Run in Background
    Gui, Font, s8 norm cBlack

    ; What it does
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y105, What it does:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y125 w420, Continuously holds down the right mouse button.

    ; Best for
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y155, Best for:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y175 w420, - Placing blocks continuously`n- Eating food constantly`n- Any task requiring constant right-click

    ; How to use
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y225, How to use:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y245 w420, Press Ctrl+Alt+SPACE to start, Ctrl+Alt+S to stop

    ; Buttons
    Gui, Font, s8 norm
    Gui, Add, Button, x90 y275 w120 h35 gHOLDRCLICK, START
    Gui, Add, Button, x250 y275 w120 h35 gStop, STOP
    Gui, Add, Button, x330 y50 w110 h30 gGoHome, << Home

    Gui, Show,, %wintitle%
    ProgState := 10
    Return
}

; --- Hold Right Click Function ---
HOLDRCLICK:
{
    if (ProgState != 10)
        Return
    BreakLoop := 0
    ControlClick, , ahk_id %id%, , Right, , D  ; Hold down right click
    Loop
    {
        if (BreakLoop = 1)
        {
            ControlClick, , ahk_id %id%, , Right, , U  ; Release right click
            BreakLoop := 0
            Break
        }
        Sleep 100
    }
    Return
}

; --- Movement Functions ---
; The following movement functions follow a similar pattern
; They hold down a movement key and release it when stopped

; --- Walk Forwards Menu ---
MenuFORWARD:
{
    global GuiX, GuiY
    BreakLoop := 1
    SaveGuiPos()
    Gui, Destroy
    if (GuiX = "" || GuiY = "")
        Gui, Show, w460 h275 Center, Walk Forwards
    else
        Gui, Show, x%GuiX% y%GuiY% w460 h275, Walk Forwards
    Gui, +OwnDialogs
    Gui, Menu, ClickerMenu

    ; Target Window Info
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y10 w420, Target Window: %targettitle%
    Gui, Add, Text, x20 y25 w420, Window HWIND: %id%

    ; Header
    Gui, Font, Bold s11
    Gui, Add, Text, x20 y50 w420, WALK FORWARDS (W)
    Gui, Font, s8 norm cGreen Bold
    Gui, Add, Text, x20 y75 w420, [+] Alt-Tab Safe - Run in Background
    Gui, Font, s8 norm cBlack

    ; What it does
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y105, What it does:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y125 w420, Holds down the W key to continuously walk forward.

    ; How to use
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y165, How to use:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y185 w420, Press Ctrl+Alt+SPACE to start, Ctrl+Alt+S to stop

    ; Buttons
    Gui, Font, s8 norm
    Gui, Add, Button, x90 y215 w120 h35 gFORWARD, START
    Gui, Add, Button, x250 y215 w120 h35 gStop, STOP
    Gui, Add, Button, x330 y50 w110 h30 gGoHome, << Home

    Gui, Show,, %wintitle%
    ProgState := 5
    Return
}

; --- Walk Forwards Function ---
FORWARD:
{
    if (ProgState != 5)
        Return
    BreakLoop := 0
    ControlSend, , {w down}, ahk_id %id%  ; Hold down 'W' key
    Loop
    {
        if (BreakLoop = 1)
        {
            ControlSend, , {w up}, ahk_id %id%  ; Release 'W' key
            BreakLoop := 0
            Break
        }
        Sleep 100
    }
    Return
}

; --- Walk Left Menu ---
MenuLEFT:
{
    global GuiX, GuiY
    BreakLoop := 1
    SaveGuiPos()
    Gui, Destroy
    if (GuiX = "" || GuiY = "")
        Gui, Show, w460 h275 Center, Walk Left
    else
        Gui, Show, x%GuiX% y%GuiY% w460 h275, Walk Left
    Gui, +OwnDialogs
    Gui, Menu, ClickerMenu

    ; Target Window Info
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y10 w420, Target Window: %targettitle%
    Gui, Add, Text, x20 y25 w420, Window HWIND: %id%

    ; Header
    Gui, Font, Bold s11
    Gui, Add, Text, x20 y50 w420, WALK LEFT (A)
    Gui, Font, s8 norm cGreen Bold
    Gui, Add, Text, x20 y75 w420, [+] Alt-Tab Safe - Run in Background
    Gui, Font, s8 norm cBlack

    ; What it does
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y105, What it does:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y125 w420, Holds down the A key to continuously strafe left.

    ; How to use
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y165, How to use:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y185 w420, Press Ctrl+Alt+SPACE to start, Ctrl+Alt+S to stop

    ; Buttons
    Gui, Font, s8 norm
    Gui, Add, Button, x90 y215 w120 h35 gLEFT, START
    Gui, Add, Button, x250 y215 w120 h35 gStop, STOP
    Gui, Add, Button, x330 y50 w110 h30 gGoHome, << Home

    Gui, Show,, %wintitle%
    ProgState := 6
    Return
}

; --- Walk Left Function ---
LEFT:
{
    if (ProgState != 6)
        Return
    BreakLoop := 0
    ControlSend, , {a down}, ahk_id %id%  ; Hold down 'A' key
    Loop
    {
        if (BreakLoop = 1)
        {
            ControlSend, , {a up}, ahk_id %id%  ; Release 'A' key
            BreakLoop := 0
            Break
        }
        Sleep 100
    }
    Return
}

; --- Walk Right Menu ---
MenuRIGHT:
{
    global GuiX, GuiY
    BreakLoop := 1
    SaveGuiPos()
    Gui, Destroy
    if (GuiX = "" || GuiY = "")
        Gui, Show, w460 h275 Center, Walk Right
    else
        Gui, Show, x%GuiX% y%GuiY% w460 h275, Walk Right
    Gui, +OwnDialogs
    Gui, Menu, ClickerMenu

    ; Target Window Info
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y10 w420, Target Window: %targettitle%
    Gui, Add, Text, x20 y25 w420, Window HWIND: %id%

    ; Header
    Gui, Font, Bold s11
    Gui, Add, Text, x20 y50 w420, WALK RIGHT (D)
    Gui, Font, s8 norm cGreen Bold
    Gui, Add, Text, x20 y75 w420, [+] Alt-Tab Safe - Run in Background
    Gui, Font, s8 norm cBlack

    ; What it does
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y105, What it does:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y125 w420, Holds down the D key to continuously strafe right.

    ; How to use
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y165, How to use:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y185 w420, Press Ctrl+Alt+SPACE to start, Ctrl+Alt+S to stop

    ; Buttons
    Gui, Font, s8 norm
    Gui, Add, Button, x90 y215 w120 h35 gRIGHT, START
    Gui, Add, Button, x250 y215 w120 h35 gStop, STOP
    Gui, Add, Button, x330 y50 w110 h30 gGoHome, << Home

    Gui, Show,, %wintitle%
    ProgState := 7
    Return
}

; --- Walk Right Function ---
RIGHT:
{
    if (ProgState != 7)
        Return
    BreakLoop := 0
    ControlSend, , {d down}, ahk_id %id%  ; Hold down 'D' key
    Loop
    {
        if (BreakLoop = 1)
        {
            ControlSend, , {d up}, ahk_id %id%  ; Release 'D' key
            BreakLoop := 0
            Break
        }
        Sleep 100
    }
    Return
}

; --- Walk Backwards Menu ---
MenuBACK:
{
    global GuiX, GuiY
    BreakLoop := 1
    SaveGuiPos()
    Gui, Destroy
    if (GuiX = "" || GuiY = "")
        Gui, Show, w460 h275 Center, Walk Backwards
    else
        Gui, Show, x%GuiX% y%GuiY% w460 h275, Walk Backwards
    Gui, +OwnDialogs
    Gui, Menu, ClickerMenu

    ; Target Window Info
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y10 w420, Target Window: %targettitle%
    Gui, Add, Text, x20 y25 w420, Window HWIND: %id%

    ; Header
    Gui, Font, Bold s11
    Gui, Add, Text, x20 y50 w420, WALK BACKWARDS (S)
    Gui, Font, s8 norm cGreen Bold
    Gui, Add, Text, x20 y75 w420, [+] Alt-Tab Safe - Run in Background
    Gui, Font, s8 norm cBlack

    ; What it does
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y105, What it does:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y125 w420, Holds down the S key to continuously walk backwards.

    ; How to use
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y165, How to use:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y185 w420, Press Ctrl+Alt+SPACE to start, Ctrl+Alt+S to stop

    ; Buttons
    Gui, Font, s8 norm
    Gui, Add, Button, x90 y215 w120 h35 gBACK, START
    Gui, Add, Button, x250 y215 w120 h35 gStop, STOP
    Gui, Add, Button, x330 y50 w110 h30 gGoHome, << Home

    Gui, Show,, %wintitle%
    ProgState := 8
    Return
}

; --- Walk Backwards Function ---
BACK:
{
    if (ProgState != 8)
        Return
    BreakLoop := 0
    ControlSend, , {s down}, ahk_id %id%  ; Hold down 'S' key
    Loop
    {
        if (BreakLoop = 1)
        {
            ControlSend, , {s up}, ahk_id %id%  ; Release 'S' key
            BreakLoop := 0
            Break
        }
        Sleep 100
    }
    Return
}

; --- Walk Forwards + Eating Menu ---
MenuFOODwards:
{
    global GuiX, GuiY
    BreakLoop := 1
    SaveGuiPos()
    Gui, Destroy
    if (GuiX = "" || GuiY = "")
        Gui, Show, w460 h395 Center, Walk Forward + Auto Eat
    else
        Gui, Show, x%GuiX% y%GuiY% w460 h395, Walk Forward + Auto Eat
    Gui, +OwnDialogs
    Gui, Menu, ClickerMenu

    ; Target Window Info
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y10 w420, Target Window: %targettitle%
    Gui, Add, Text, x20 y25 w420, Window HWIND: %id%

    ; Header
    Gui, Font, Bold s11
    Gui, Add, Text, x20 y50 w420, WALK FORWARD + AUTO EAT
    Gui, Font, s8 norm cGreen Bold
    Gui, Add, Text, x20 y75 w420, [+] Alt-Tab Safe - Run in Background
    Gui, Font, s8 norm cBlack

    ; What it does
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y105, What it does:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y125 w420, Holds W to walk forward AND right-click to eat when hungry.

    ; Best for
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y170, Best for:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y190 w420, - Long distance walking while staying fed`n- Exploring/traveling AFK`n- Walking to destinations while auto-healing

    ; How to use
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y240, How to use:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y260 w420, 1. Put food in your hand`n2. Press Ctrl+Alt+SPACE to start`n3. Press Ctrl+Alt+S to stop

    ; Buttons
    Gui, Font, s8 norm
    Gui, Add, Button, x90 y310 w120 h35 gFOODwards, START
    Gui, Add, Button, x250 y310 w120 h35 gStop, STOP
    Gui, Add, Button, x330 y50 w110 h30 gGoHome, << Home

    Gui, Show,, %wintitle%
    ProgState := 9
    Return
}

; --- Walk Forwards + Eating Function ---
FOODwards:
{
    if (ProgState != 9)
        Return
    BreakLoop := 0
    ControlSend, , {w down}, ahk_id %id%  ; Hold down 'W' key
    ControlClick, , ahk_id %id%, , Right, , D  ; Hold down right click
    Loop
    {
        if (BreakLoop = 1)
        {
            ControlSend, , {w up}, ahk_id %id%  ; Release 'W' key
            ControlClick, , ahk_id %id%, , Right, , U  ; Release right click
            BreakLoop := 0
            Break
        }
        Sleep 100
    }
    Return
}

; --- End Flight Menu ---
MenuENDFLIGHT:
{
    global GuiX, GuiY
    BreakLoop := 1
    SaveGuiPos()
    Gui, Destroy
    if (GuiX = "" || GuiY = "")
        Gui, Show, w520 h650 Center, Elytra Flight (No Mouse)
    else
        Gui, Show, x%GuiX% y%GuiY% w520 h650, Elytra Flight (No Mouse)
    Gui, +OwnDialogs
    Gui, Menu, ClickerMenu

    ; Target Window Info
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y10 w480, Target Window: %targettitle%
    Gui, Add, Text, x20 y25 w480, Window HWIND: %id%

    ; Header
    Gui, Font, Bold s11
    Gui, Add, Text, x20 y50 w480, ELYTRA FLIGHT - NO MOUSE (Infinite)
    Gui, Font, s8 norm cGreen Bold
    Gui, Add, Text, x20 y75 w480, [+] Alt-Tab Safe - Run in Background
    Gui, Font, s8 norm cBlack

    ; What it does
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y105, What it does:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y125 w480, Fires rockets automatically without moving your mouse. Runs indefinitely until you stop it.

    ; Benefits
    Gui, Font, Bold s9 cGreen
    Gui, Add, Text, x20 y175, Benefits:
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y195 w480, + You CAN alt-tab safely`n+ Relaxed hands-off flying`n- Uses more rockets (less efficient flight path)

    ; Firework Duration Selection
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y260, Firework Type:

    ; Firework interval slider (ms)
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y280, Firework Interval:
    Gui, Add, Slider, x20 y300 w300 h30 vElytraRocketInterval gElytraIntervalSliderUpdate Range3000-7000 TickInterval250, %ElytraRocketInterval%
    Seconds := Round(ElytraRocketInterval / 1000, 2)
    Gui, Add, Text, x330 y305 w170 vElytraIntervalLabel, %ElytraRocketInterval%ms (%Seconds%s)

    ; Presets
    Gui, Font, s7 norm
    Gui, Add, Button, x20 y335 w90 h25 gElytraFWDur1, Duration I
    Gui, Add, Button, x115 y335 w90 h25 gElytraFWDur2, Duration II
    Gui, Add, Button, x210 y335 w90 h25 gElytraFWDur3, Duration III
    Gui, Font, s8 norm cGreen Bold
    Gui, Add, Text, x20 y365 w480 vElytraFWDurLabel, Selected: Duration III (5.5s interval)
    Gui, Font, s8 norm cBlack

    ; Setup
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y380, Setup:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y400 w480, 1. Set your firework interval using the slider or presets above`n2. Equip elytra + rockets in slot 1`n3. In the End, jump off and glide straight`n4. Aim in direction you want to fly`n5. Press Ctrl+Alt+SPACE (3 sec countdown)

    ; Important
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y495, Controls:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y515 w480, Start: Ctrl+Alt+SPACE | Stop: Ctrl+Alt+S

    ; Buttons
    Gui, Font, s8 norm
    Gui, Add, Button, x130 y540 w120 h40 gENDFLIGHT, START FLIGHT
    Gui, Add, Button, x270 y540 w120 h40 gStop, EMERGENCY STOP
    Gui, Add, Button, x400 y50 w100 h30 gGoHome, << Home

    Gui, Show,, %wintitle%
    ProgState := 11
    Return
}

; --- Elytra Firework Interval Slider Update ---
ElytraIntervalSliderUpdate:
{
    Gui, Submit, NoHide
    Seconds := Round(ElytraRocketInterval / 1000, 2)
    GuiControl,, ElytraIntervalLabel, %ElytraRocketInterval%ms (%Seconds%s)
    GuiControl,, ElytraFWDurLabel, Selected: Custom (%Seconds%s interval)
    Return
}

; --- Elytra Firework Duration Buttons ---
ElytraFWDur1:
{
    ElytraRocketInterval := 3750    ; Duration I: Fire every 3.75 seconds
    GuiControl,, ElytraRocketInterval, %ElytraRocketInterval%
    Seconds := Round(ElytraRocketInterval / 1000, 2)
    GuiControl,, ElytraIntervalLabel, %ElytraRocketInterval%ms (%Seconds%s)
    GuiControl,, ElytraFWDurLabel, Selected: Duration I (3.75s interval)
    Return
}

ElytraFWDur2:
{
    ElytraRocketInterval := 4500    ; Duration II: Fire every 4.5 seconds
    GuiControl,, ElytraRocketInterval, %ElytraRocketInterval%
    Seconds := Round(ElytraRocketInterval / 1000, 2)
    GuiControl,, ElytraIntervalLabel, %ElytraRocketInterval%ms (%Seconds%s)
    GuiControl,, ElytraFWDurLabel, Selected: Duration II (4.5s interval)
    Return
}

ElytraFWDur3:
{
    ElytraRocketInterval := 5500    ; Duration III: Fire every 5.5 seconds
    GuiControl,, ElytraRocketInterval, %ElytraRocketInterval%
    Seconds := Round(ElytraRocketInterval / 1000, 2)
    GuiControl,, ElytraIntervalLabel, %ElytraRocketInterval%ms (%Seconds%s)
    GuiControl,, ElytraFWDurLabel, Selected: Duration III (5.5s interval)
    Return
}

; --- Elytra Flight with Mouse Control Menu ---
MenuENDFLIGHTMOUSE:
{
    global GuiX, GuiY
    BreakLoop := 1
    SaveGuiPos()
    Gui, Destroy
    if (GuiX = "" || GuiY = "")
        Gui, Show, w520 h600 Center, Elytra Flight (With Mouse)
    else
        Gui, Show, x%GuiX% y%GuiY% w520 h600, Elytra Flight (With Mouse)
    Gui, +OwnDialogs
    Gui, Menu, ClickerMenu

    ; Target Window Info
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y10 w480, Target Window: %targettitle%
    Gui, Add, Text, x20 y25 w480, Window HWIND: %id%

    ; Header
    Gui, Font, Bold s11
    Gui, Add, Text, x20 y50 w480, ELYTRA FLIGHT - WITH MOUSE (7000 Blocks)
    Gui, Font, s8 norm cRed Bold
    Gui, Add, Text, x20 y75 w480, [X] NO ALT-TAB - Window Must Stay Active
    Gui, Font, s8 norm cBlack

    ; What it does
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y105, What it does:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y125 w480, Fires rockets AND controls mouse for wave flight pattern. Pitch up during boost, dive to gain speed, smooth recovery. Auto-stops at 7000 blocks.

    ; Benefits
    Gui, Font, Bold s9 cGreen
    Gui, Add, Text, x20 y190, Benefits:
    Gui, Font, s8 norm cBlack
    Gui, Add, Text, x20 y210 w480, + Better efficiency - uses FEWER rockets`n+ Maintains optimal altitude automatically`n+ Smooth wave pattern for max speed

    ; Warning
    Gui, Font, Bold s9 cRed
    Gui, Add, Text, x20 y275, WARNING:
    Gui, Font, s8 norm cRed
    Gui, Add, Text, x20 y295 w480, You CANNOT alt-tab out! Mouse control requires window to stay active. DO NOT switch windows during flight.
    Gui, Font, s8 norm cBlack

    ; Setup
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y345, Setup:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y365 w480, 1. Equip elytra + Duration III rockets in slot 1`n2. In the End, jump off and glide straight`n3. Aim in direction you want to fly`n4. Press Ctrl+Alt+SPACE (3 sec countdown)`n5. KEEP WINDOW ACTIVE - do not alt-tab!

    ; Controls
    Gui, Font, Bold s9
    Gui, Add, Text, x20 y470, Controls:
    Gui, Font, s8 norm
    Gui, Add, Text, x20 y490 w480, Start: Ctrl+Alt+SPACE | Stop: Ctrl+Alt+S

    ; Buttons
    Gui, Font, s8 norm
    Gui, Add, Button, x130 y520 w120 h40 gENDFLIGHTMOUSE, START FLIGHT
    Gui, Add, Button, x270 y520 w120 h40 gStop, EMERGENCY STOP
    Gui, Add, Button, x400 y50 w100 h30 gGoHome, << Home

    Gui, Show,, %wintitle%
    ProgState := 13
    Return
}

; --- End Flight Function (Alt-Tab Safe - No Mouse Movement) ---
ENDFLIGHT:
{
    if (ProgState != 11)
        Return
    BreakLoop := 0

    ; Switch to hotbar slot 1 (where rockets should be) - ALT-TAB SAFE
    ControlSend, , 1, ahk_id %id%
    Sleep 200

    ; Countdown
    ToolTip, Starting Elytra Flight (NO MOUSE)`nRocket Interval: %ElytraRocketInterval%ms`nStarting in 3..., 10, 10
    Sleep 1000
    ToolTip, Starting Elytra Flight (NO MOUSE)`nRocket Interval: %ElytraRocketInterval%ms`nStarting in 2..., 10, 10
    Sleep 1000
    ToolTip, Starting Elytra Flight (NO MOUSE)`nRocket Interval: %ElytraRocketInterval%ms`nStarting in 1..., 10, 10
    Sleep 1000
    ToolTip, GO! Elytra Flight Active!`nPress Ctrl+Alt+S to STOP, 10, 10
    Sleep 1500
    ToolTip

    LastRocketTime := A_TickCount

    Loop
    {
        if (BreakLoop = 1)
        {
            ToolTip
            BreakLoop := 0
            Break
        }

        CurrentTime := A_TickCount
        TimeSinceRocket := CurrentTime - LastRocketTime

        ; Fire rocket at configured interval - USES CONTROLCLICK FOR ALT-TAB SAFETY
        if (TimeSinceRocket >= ElytraRocketInterval)
        {
            ControlClick, , ahk_id %id%, , Right, , NA
            LastRocketTime := CurrentTime
        }

        Sleep 100
    }

    ToolTip
    Return
}

; --- Elytra Flight with Mouse Control Function ---
ENDFLIGHTMOUSE:
{
    if (ProgState != 13)
        Return
    BreakLoop := 0

    ; Variables for tracking
    DistanceTraveled := 0
    TargetDistance := 7000
    FlightSpeed := 20  ; Approximate blocks per second with elytra + rockets
    UpdateInterval := 50  ; Check status every 50ms

    ; Flight cycle timing with MOUSE CONTROL (slower, longer cycle for wave pattern)
    FirstRocketTime := 0 ; Fire first rocket immediately
    SecondRocketTime := 2500 ; Fire second rocket 2.5 seconds later
    InitialPitchUpTime := 3200 ; Extended to include both rockets and pitch up
    HoldUpDuration := 3000 ; Maintain during boost
    PitchDownTransition := 1000 ; Smooth to steeper glide
    HoldDownDuration := 5500 ; Slightly longer glide to bleed off more height
    PitchUpTransition := 2000 ; Gradual recovery
    HoldWaitDuration := 500 ; Stabilize
    TotalCycleDuration := InitialPitchUpTime + HoldUpDuration + PitchDownTransition + HoldDownDuration + PitchUpTransition + HoldWaitDuration

    ; Mouse movement settings (ENABLED for wave flight pattern)
    InitialUpAmount := 13 ; Slightly reduced up for less aggressive height gain
    PitchDownAmount := 28 ; Steeper down angle (~25-30° based on sims) to compensate and lose more height during glide
    PitchUpAmount := 14 ; Keep for recovery
    MouseMoveDelay := 25 ; Smooth

    ; Switch to hotbar slot 1 (where rockets should be)
    ControlSend, , 1, ahk_id %id%
    Sleep 200

    ; Activate the window
    WinActivate, ahk_id %id%
    Sleep 300

    ToolTip, Starting Elytra Flight WITH MOUSE CONTROL - Target: 7000 blocks`nStarting in 3..., 10, 10
    Sleep 1000
    ToolTip, Starting Elytra Flight WITH MOUSE CONTROL - Target: 7000 blocks`nStarting in 2..., 10, 10
    Sleep 1000
    ToolTip, Starting Elytra Flight WITH MOUSE CONTROL - Target: 7000 blocks`nStarting in 1..., 10, 10
    Sleep 1000

    LoopCounter := 0
    StartTime := A_TickCount
    CycleStartTime := A_TickCount
    LastMouseMove := A_TickCount

    ; Ensure Minecraft window is active for mouse movements
    WinActivate, ahk_id %id%
    Sleep 500

    Loop
    {
        if (BreakLoop = 1)
        {
            ToolTip
            BreakLoop := 0
            Break
        }

        CurrentTime := A_TickCount
        CycleTime := CurrentTime - CycleStartTime
        TimeSinceMouseMove := CurrentTime - LastMouseMove

        ; Calculate phase boundaries
        Phase2Start := InitialPitchUpTime
        Phase3Start := Phase2Start + HoldUpDuration
        Phase4Start := Phase3Start + PitchDownTransition
        Phase5Start := Phase4Start + HoldDownDuration
        Phase6Start := Phase5Start + PitchUpTransition

        ; Determine current phase of the flight cycle
        if (CycleTime < InitialPitchUpTime)
        {
            ; Phase 1: Fire rocket twice and pitch up slightly
            FlightPhase := "ROCKET x2 + UP"

            ; Fire first rocket only once at the very start (within first update interval)
            if (CycleTime >= FirstRocketTime && CycleTime < (FirstRocketTime + UpdateInterval))
            {
                ; Method 1: Try ControlClick with activation
                ControlClick, , ahk_id %id%, , Right, , NAD
                ControlClick, , ahk_id %id%, , Right, , NAU

            }

            ; Fire second rocket only once at 2.5 seconds (within one update interval window)
            if (CycleTime >= SecondRocketTime && CycleTime < (SecondRocketTime + UpdateInterval))
            {
                ; Method 1: Try ControlClick with activation
                ControlClick, , ahk_id %id%, , Right, , NAD
                ControlClick, , ahk_id %id%, , Right, , NAU
            }

            ; Pitch up movements after second rocket fires
            if (CycleTime >= (SecondRocketTime + 100) && TimeSinceMouseMove >= MouseMoveDelay)
            {
                DllCall("mouse_event", "UInt", 0x0001, "Int", 0, "Int", -InitialUpAmount, "UInt", 0, "UInt", 0)
                LastMouseMove := CurrentTime
            }
        }
        else if (CycleTime < Phase3Start)
        {
            ; Phase 2: Hold the upward angle (no mouse movement)
            FlightPhase := "HOLD UP"
        }
        else if (CycleTime < Phase4Start)
        {
            ; Phase 3: Smoothly pitch down
            FlightPhase := "PITCH DOWN"

            if (TimeSinceMouseMove >= MouseMoveDelay)
            {
                DllCall("mouse_event", "UInt", 0x0001, "Int", 0, "Int", PitchDownAmount, "UInt", 0, "UInt", 0)
                LastMouseMove := CurrentTime
            }
        }
        else if (CycleTime < Phase5Start)
        {
            ; Phase 4: Hold down angle (no mouse movement)
            FlightPhase := "HOLD DOWN"
        }
        else if (CycleTime < Phase6Start)
        {
            ; Phase 5: Slowly ramp back up (not too much)
            FlightPhase := "RAMP UP"

            if (TimeSinceMouseMove >= MouseMoveDelay)
            {
                DllCall("mouse_event", "UInt", 0x0001, "Int", 0, "Int", -PitchUpAmount, "UInt", 0, "UInt", 0)
                LastMouseMove := CurrentTime
            }
        }
        else if (CycleTime < TotalCycleDuration)
        {
            ; Phase 6: Wait before next rocket
            FlightPhase := "WAIT"
        }
        else
        {
            ; Cycle complete, reset to fire next rocket
            CycleStartTime := A_TickCount
        }

        ; Update distance calculation every second
        if (Mod(LoopCounter, 1000/UpdateInterval) = 0)
        {
            ElapsedSeconds := (CurrentTime - StartTime) / 1000
            DistanceTraveled := Floor(ElapsedSeconds * FlightSpeed)
            RemainingDistance := TargetDistance - DistanceTraveled

            ; Calculate time remaining
            TimeRemaining := Floor((RemainingDistance / FlightSpeed))
            MinutesRemaining := Floor(TimeRemaining / 60)
            SecondsRemaining := Mod(TimeRemaining, 60)

            ; Update tooltip with progress and current phase
            ToolTip, ELYTRA FLIGHT (MOUSE CONTROL) - %FlightPhase%`nDistance: %DistanceTraveled% / %TargetDistance% blocks`nRemaining: %RemainingDistance% blocks (%MinutesRemaining%m %SecondsRemaining%s)`n`nPress Ctrl+Alt+S to EMERGENCY STOP, 10, 10

            ; Check if target reached
            if (DistanceTraveled >= TargetDistance)
            {
                ToolTip, TARGET REACHED!`n7000 blocks traveled!`nFlight automation stopped., 10, 10
                Sleep 5000
                ToolTip
                BreakLoop := 1
                Break
            }
        }

        LoopCounter++
        Sleep UpdateInterval
    }

    ToolTip
    Return
}

; --- Universal Start Function ---
StartCurrent:
{
    ; Route to the appropriate function based on current ProgState
    if (ProgState = 2)
        Gosub, MOB
    else if (ProgState = 3)
        Gosub, HOLDCLICK
    else if (ProgState = 4)
        Gosub, FOOD
    else if (ProgState = 5)
        Gosub, FORWARD
    else if (ProgState = 6)
        Gosub, LEFT
    else if (ProgState = 7)
        Gosub, RIGHT
    else if (ProgState = 8)
        Gosub, BACK
    else if (ProgState = 9)
        Gosub, FOODwards
    else if (ProgState = 10)
        Gosub, HOLDRCLICK
    else if (ProgState = 11)
        Gosub, ENDFLIGHT
    else if (ProgState = 12)
        Gosub, MOBSWEEP
    else if (ProgState = 13)
        Gosub, ENDFLIGHTMOUSE
    else
    {
        ToolTip, Please select a mode from the menu first!, 10, 10
        Sleep 2000
        ToolTip
    }
    Return
}

; --- Stop Function ---
Stop:
{
    BreakLoop := 1
    ; Release mouse buttons
    ControlClick, , ahk_id %id%, , Right, , NAU
    ControlClick, , ahk_id %id%, , Left, , NAU
    ; Release movement keys
    ControlSend, , {w up}{a up}{s up}{d up}, ahk_id %id%
    Sleep 500
    Return
}

; #############################
; #      Script Exit Handlers
; #############################

#If WinActive(wintitle)
Esc::
    ConfirmExit()
Return
#If  ; end context


GuiClose:
GuiEscape:
    ConfirmExit()
Return

ConfirmExit() {
    global ProgState, BreakLoop, id, wintitle
    WinActivate, %wintitle%

    ; First confirmation
    MsgBox, 262148, Exit Confirmation, Are you sure you want to exit?
    IfMsgBox, No
        Return

    ; Only warn if automation is actively running
    if (ProgState >= 2 && BreakLoop = 0) {
        MsgBox, 262148, Running Confirmation, Automation is currently running. Exit anyway?
        IfMsgBox, No
            Return
    }

    Gosub, Stop
    Sleep, 200
    ExitApp
}


; #############################
; #        Helper Functions
; #############################

EnsureCtrlWImage(url, dir, path) {
    ; Make sure the assets folder exists
    if !FileExist(dir)
        FileCreateDir, %dir%

    ; Check if file exists and is valid
    needsDownload := !FileExist(path)
    if (!needsDownload) {
        FileGetSize, sz, %path%
        if (sz <= 0)
            needsDownload := true
    }

    ; Try to download if missing or invalid
    if (needsDownload) {
        UrlDownloadToFile, %url%, %path%
        if (ErrorLevel) {
            if FileExist(path)
                FileDelete, %path%
            return false
        }
        FileGetSize, sz2, %path%
        if (sz2 <= 0) {
            if FileExist(path)
                FileDelete, %path%
            return false
        }
    }

    return true
}

CompareSemver(v1, v2) {
    StringSplit, a, v1, .
    StringSplit, b, v2, .
    maxParts := (a0 > b0) ? a0 : b0
    Loop, %maxParts%
    {
        ai := (A_Index <= a0) ? a%A_Index% : 0
        bi := (A_Index <= b0) ? b%A_Index% : 0
        if ((ai+0) > (bi+0))
            return 1
        else if ((ai+0) < (bi+0))
            return -1
    }
    return 0
}

fetch(url) {
    req := ComObjCreate("Msxml2.XMLHTTP")
    req.open("GET", url, true)
    req.send()
    while req.readyState != 4
        sleep 100
    return req.responseText
}
