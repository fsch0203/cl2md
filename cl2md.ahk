_DateFormat := "yyyy-MM-dd HH:mm"
_CopyPlusMenu = 0 ; If true: show menu when url is copied
_UrlsFileShort := "urls.md"
_arrUrlsFiles := [] ; recently used UrlFiles
_HotkeyCopyPlus := "^+c"
_RootFolder := A_MyDocuments . "\"

EnvGet, LocalAppData, LocalAppData
FileCreateDir, %LocalAppData%\cl2md
FileAppend, , %LocalAppData%\cl2md\cl2md.ini
_IniFile = %LocalAppData%\cl2md\cl2md.ini

getSettings()
showQuickStartGuide()

#Persistent
#SingleInstance Force
#NoEnv

SetBatchLines, -1
SetWorkingDir %A_ScriptDir%
OnClipboardChange("getUrlFromCB")

Menu, tray, icon, icon-teal.png, 1
Menu, Tray, NoStandard ; remove default tray menu entries
Menu, Tray, Add, Show settings, startSettingsMenu ; add a new tray menu entry
Menu, Tray, Add, Show help, QuickStartGuide ; add a new tray menu entry
; Menu, Tray, Add, Edit settings, editSettings ; add another tray menu entry
Menu, Tray, Add, Exit, Exit ; add another tray menu entry
Menu, Tray, Default, Show settings ;When doubleclicking the tray icon, run the tray menu entry called "MyDefaultAction".
Menu, Tray, Icon, Show help, shell32, 24
Menu, Tray, Icon, Show settings, shell32, 138
Menu, Tray, Icon, Exit, shell32.dll, 28
Menu, Tray, Tip, %AppWindow% Open %_AppName% with %_HotkeyMain%

; Hotkeys ------------------------------------------------------------------

#IfWinActive CopyLink2MD Settings ahk_class AutoHotkeyGUI
    Esc::!F4
    Enter::SaveSettings()

#IfWinActive Edit bookmark ahk_class AutoHotkeyGUI
    Esc::!F4
    Enter::saveBookmark()
    ; Enter::Tab

#IfWinActive ; Other hotkeys
    ^+r::goReloadCB()

; End Hotkeys ------------------------------------------------------------------

return

; ============ Functions ======================================

getUrlFromCB(Type) { ; Runs when clipboard has changed (by Ctrl-c)
    global _arrCbRows, _CopyPlusMenu, _GrabEveryUrl, _RowsSelected
    If (_CopyPlusMenu = 1) {
        clip := Clipboard
        tags := ""
        arrAutoTags := getAutotags()
        RegExMatch(clip, "https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)", url)
        if StrLen(url) > 0 {
            If (SubStr(url, 0) = "/") ; kill closing /
                url:= SubStr(url, 1, StrLen(url) - 1)
            for index, row in arrAutotags 
            {
                arrAutotag := StrSplit(row, "=")
                If (InStr(url, arrAutotag[1]))
                    tags := arrAutotag[2]
            }
            WinGetTitle, title, A
            GrabbedRow := AddQuotes(A_now) . "," . AddQuotes(title) . "," . AddQuotes(url) . "," . AddQuotes(tags) . "," . AddQuotes(0)
            _RowsSelected := 0 ; so we know it's a new record
            showEditBookmark(GrabbedRow)
            _CopyPlusMenu = 0
        }
    }
}

getSettings(){
    global _HotkeyCopyPlus, _UrlsFileShort, _IniFile, _RootFolder, _arrUrlsFiles
    IniRead, _HotkeyCopyPlus, %_IniFile%, Settings, HotkeyCopyPlus, %_HotkeyCopyPlus%
    IniRead, _UrlsFileShort, %_IniFile%, Settings, UrlsFileShort, %_UrlsFileShort%
    IniRead, strUrlsFiles, %_IniFile%, Settings, UrlsFiles, %_UrlsFileShort%
    _arrUrlsFiles := StrSplit(strUrlsFiles , ",")
    IniRead, _RootFolder, %_IniFile%, Settings, RootFolder, %_RootFolder%
    Hotkey, %_HotkeyCopyPlus%, doCopyPlus ; Calls function() when a is pressed
}

doCopyPlus(){
    global _CopyPlusMenu
    _CopyPlusMenu = 1
    Send, ^c
}

showEditBookmark(GrabbedRow){
    global _UrlsFileShort, _RootFolder, _arrUrlsFiles
    global editTitle, editUrl, editTags, editFav, comboUrlsFileShort, picFav
    grabbeddate := getCsvField(GrabbedRow, 1)
    grabbedtitle := getCsvField(GrabbedRow, 2)
    grabbedurl := getCsvField(GrabbedRow, 3)
    grabbedtags := getCsvField(GrabbedRow, 4)
    grabbedfav := getCsvField(GrabbedRow, 5)
    Gui, EditBookmark:New, +Resize, Edit Bookmark
    Gui, Font, s9, Verdana  ; Set 9-point Verdana.
    Gui, Add, Text, x20 y10 w280 h20 , Title
    Gui, Add, Edit, x20 yp+20 w420 h20 veditTitle, Edit
    Gui, Add, Text, x22 yp+30 w280 h20 , Url
    Gui, Add, Edit, x22 yp+20 w420 h20 veditUrl, Edit
    Gui, Add, Text, x22 yp+30 w280 h20 , Tags
    Gui, Add, Edit, x22 yp+20 w420 h20 veditTags, Edit
    Gui, Add, Text, x22 yp+30 w280 h20 , Urls-file
    strUrlsFiles := ""
    For index, value in _arrUrlsFiles {
        strUrlsFiles .= value . "|"
    }
    Gui, Add, ComboBox, x22 yp+20 w420 h20 r8 vcomboUrlsFileShort Choose1, %strUrlsFiles%
    Gui, Add, Button, x445 yp w20 h20 gsetUrlsFile, >
    Gui, Add, Text, x22 yp+30 w280 h20 , Root-folder
    Gui, Add, Text, x22 yp+20 w420 h20, %_RootFolder%
    Gui, Add, Button, x312 yp+35 w60 h20 Default gsaveBookmark, &Save
    Gui, Add, Button, x22 yp w60 h20 gstartSettingsMenu, Se&ttings
    Gui, Add, Button, x382 yp w60 h20 gcancelBookmark, &Cancel

    GuiControl, EditBookmark:, editTitle, %grabbedtitle%
    GuiControl, EditBookmark:, editUrl, %grabbedurl%
    GuiControl, EditBookmark:, editTags, %grabbedtags%
    GuiControl, EditBookmark:, editFav, %grabbedfav%
    width := 480
    height := 300
    xleft := (A_ScreenWidth / 2) - (width /2)
    ytop := (A_ScreenHeight /2) - (height / 2)
    Gui, EditBookmark:Show, center x%xleft% y%ytop% h%height% w%width%, Edit bookmark
}

setUrlsFile(){ ; activated by button next to comboUrlsFileShort
    global _UrlsFileShort, _RootFolder, _arrUrlsFiles
    FileSelectFile, SelectedFile, 0, %_RootFolder% , Open a file, Markdown documents (*.md)
    if (SelectedFile = ""){
        ; MsgBox, The user didn't select anything.
    } else {
        RootLength := StrLen(_RootFolder) + 1
        _UrlsFileShort := SubStr(SelectedFile, RootLength)
        ; MsgBox, %_UrlsFileShort%
        For index, value in _arrUrlsFiles {
            If (value = _UrlsFileShort) {
                RemovedValue := _arrUrlsFiles.RemoveAt(index)
            }
        }
        _arrUrlsFiles.InsertAt(1, _UrlsFileShort)
        ; MsgBox, %_arrUrlsFiles%
        GuiControl, EditBookmark:, comboUrlsFileShort, %_UrlsFileShort%||
    }
}

setRootFolder(){
    global _RootFolder
    FileSelectFolder, Folder, , 1, Select root directory (vault or subfolder)
    Folder := RegExReplace(Folder, "\\$")  ; Removes the trailing backslash, if present.
    Folder .= "\"
    MsgBox, %Folder%

    if (Folder = ""){
        ; MsgBox, The user didn't select anything.
    } else {
        GuiControl, Settings:, RootFolder, %Folder%
    }
}

saveBookmark(){
    global _UrlsFileShort, _RootFolder, _IniFile, _DateFormat, _HotkeyCopyPlus, _arrUrlsFiles
    GuiControlGet, editTitle, EditBookmark:
    GuiControlGet, editUrl, EditBookmark:
    GuiControlGet, editTags, EditBookmark:
    GuiControlGet, comboUrlsFileShort, EditBookmark:
    ; tooltip, % editTitle a_space editUrl  , 100, 100, 3
    editTitle := SubStr(editTitle, 1, 60)
    tags := ""
    If (InStr(editTags, ",")){
        Loop, Parse, editTags, % ","
            tags .= "#" . Trim(A_LoopField) . " "
    } Else {
        Loop, Parse, editTags, % " "
            tags .= (StrLen(Trim(A_LoopField)) > 0) ? "#" . Trim(A_LoopField) . " " : ""
    }
    editTags := Trim(tags)
    ; FormatTime, now, , yyyy-MM-dd
    FormatTime, now, , %_DateFormat%
    row := Chr(13) . Chr(10) . now . " " . editTags 
    row .= Chr(13) . Chr(10) . "[" . editTitle . "]"
    row .= "(" . editUrl . ")" . Chr(13) . Chr(10)
    _UrlsFileShort := comboUrlsFileShort
    IniWrite, %_UrlsFileShort%, %_IniFile%, Settings, UrlsFileShort

    For index, value in _arrUrlsFiles { ; sort _arrUrlsFiles LIFO
        If (value = _UrlsFileShort) {
            RemovedValue := _arrUrlsFiles.RemoveAt(index)
        }
    }
    _arrUrlsFiles.InsertAt(1, _UrlsFileShort)
    strUrlsFiles := "" ; make a string from _arrUrlsFiles
    For index, value in _arrUrlsFiles {
        strUrlsFiles .= value . ","
    }
    If (SubStr(strUrlsFiles, 0) = ","){
        strUrlsFiles := SubStr(strUrlsFiles, 1, StrLen(strUrlsFiles) - 1)
    }
    IniWrite, %strUrlsFiles%, %_IniFile%, Settings, UrlsFiles
    IniWrite, %_HotkeyCopyPlus%, %_IniFile%, Settings, HotkeyCopyPlus

    UrlsFile := _RootFolder . _UrlsFileShort
    FileAppend, %row%, %UrlsFile%
    WinClose, Edit bookmark
}

cancelBookmark(){
    Gui, EditBookmark:Destroy
}

Exit() {
    ExitApp
}

editSettings() { ;edit settings file from menu bar
    global _IniFile
    Run, Edit %_IniFile%
}

Log(msg){
    LogFile = %A_ScriptDir%\MyLog.txt
    FormatTime, TimeString, , yyyy-MM-dd HH:mm:ss
    FileAppend, `n%TimeString%: %msg%, %LogFile%
}

getAutotags(){ ; return arrAutoTags from _Inifile
    global _IniFile
    arrAutoTags := []
    IniRead, autotags, %_IniFile%, Autotag
    for index, autotag in StrSplit(autotags, "`n")
    {
        arrAutotags[index] := autotag
    }
    return arrAutoTags
}

getCsvField(row, fieldnr){
    Loop, parse, row, CSV 
    {
        if (A_Index = fieldnr)
        return A_LoopField
    }
}

doEscape(){
    global _arrCbRows, _TagSelected, _Found
    tot := _arrCbRows.length()
    If (_Found < tot) {
        _TagSelected := ""
        GuiControl,Main:,_CurrText,
        GuiControl,Main:,_CurrTag,
    } Else {
        Send, !{F4}
    }
}

AddQuotes(MyString) { ; add double quotes on string
	StringReplace,  MyString,  MyString, `", `"`", All
	return """" MyString """"
}

goReloadCB(){
    global _ShowMainOnLoad, _IniFile
    MsgBox, 48, CopyLink2MD, Reloaded!
    Reload
    Sleep 1000 ; If successful, the reload will close this instance during the Sleep, so the line below will never be reached.
    MsgBox, 4,, The script could not be reloaded. Would you like to open it for editing?
    IfMsgBox, Yes, Edit
}

; QuickStartGuide ============================================================================================

showQuickStartGuide(){
    global _IniFile
    IniRead, hideQuickStartGuideAtStartup, %_IniFile%, Settings, hideQuickStartGuideAtStartup
	If !(hideQuickStartGuideAtStartup = 1)
		QuickStartGuide()
}

QuickStartGuide(){
    global _IniFile, _HotkeyMain, _HotkeyCopyPlus, hideQuickStartGuideAtStartup
    static doc
    IniRead, hideQuickStartGuideAtStartup, %_IniFile%, Settings, hideQuickStartGuideAtStartup
    FileRead, quickstarthtml, %A_ScriptDir%\quickstart.html
    ; MsgBox, %quickstarthtml%
    StringReplace, quickstarthtml, quickstarthtml, [hotkeymain], %_HotkeyMain%, All
    StringReplace, quickstarthtml, quickstarthtml, [hotkeycopyplus], %_HotkeyCopyPlus%, All
    StringReplace, quickstarthtml, quickstarthtml, +, Shift+, All
    StringReplace, quickstarthtml, quickstarthtml, #, WinKey+, All
    StringReplace, quickstarthtml, quickstarthtml, ^, Ctrl+, All
    StringReplace, quickstarthtml, quickstarthtml, !, Alt+, All

    Gui, 55:Destroy
    Gui, 55:Add, ActiveX, w550 h430 x10 y10 vdoc, HTMLFile
    doc.write(quickstarthtml)
    Gui, 55:font, s10 arial
    Gui, 55:Add, Checkbox, xp yp+440 w420 h25 g55GuiStartupCheckbox vhideQuickStartGuideAtStartup Checked%hideQuickStartGuideAtStartup%, Hide Quick start guide at start up.
    Gui, 55:Show,,CopyLink2MD Quick Start Guide
}

55GuiStartupCheckbox(){
    global hideQuickStartGuideAtStartup, _IniFile
    Gui, 55:Submit, NoHide
    ; MsgBox, %hideQuickStartGuideAtStartup% 
    IniWrite, %hideQuickStartGuideAtStartup%, %_IniFile%, Settings, hideQuickStartGuideAtStartup
}

55GuiClose(){
    Gui, 55:Destroy
}

; Settings =============================================================================

startSettingsMenu(){
    showSettingsMenu()
    FillSettingsMenu()
}

FillSettingsMenu(){
    global _HotkeyCopyPlus
    arrAutoTags := getAutotags()
    for index, row in arrAutotags 
    {
        arrAutotag := StrSplit(row, "=")
        urlpart := arrAutotag[1]
        autotag := arrAutotag[2]
        GuiControl,Settings:,urlpart%index%, %urlpart%
        GuiControl,Settings:,autotag%index%, %autotag%
    }
    GuiControl, Settings:, CtrlC, 0
    GuiControl, Settings:, AltC, 0
    GuiControl, Settings:, ShftC, 0
    GuiControl, Settings:, WinC, 0
    If InStr(_HotkeyCopyPlus, "^")
        GuiControl, Settings:, CtrlC, 1
    If InStr(_HotkeyCopyPlus, "!")
        GuiControl, Settings:, AltC, 1
    If InStr(_HotkeyCopyPlus, "+")
        GuiControl, Settings:, ShftC, 1
    If InStr(_HotkeyCopyPlus, "#")
        GuiControl, Settings:, WinC, 1
    hkcp := RegExReplace(_HotkeyCopyPlus, "[\^!+#]" , "")
    GuiControl, Settings:,HotkeyCopyPlus, %hkcp%
}

SaveSettings(){
    global _IniFile
    GuiControlGet, HotkeyCopyPlus, Settings:
    GuiControlGet, RootFolder, Settings:
    GuiControlGet, CtrlC, Settings:
    GuiControlGet, AltC, Settings:
    GuiControlGet, ShftC, Settings:
    GuiControlGet, WinC, Settings:
    hkcp := ""
    If (CtrlC = 1)
        hkcp .= "^"
    If (AltC = 1)
        hkcp .= "!"
    If (ShftC = 1)
        hkcp .= "+"
    If (WinC = 1)
        hkcp .= "#"
    hkcp .= HotkeyCopyPlus
    IniWrite, %hkcp%, %_IniFile%, Settings, HotkeyCopyPlus
    IniWrite, %RootFolder%, %_IniFile%, Settings, RootFolder
    GuiControlGet, urlpart1, Settings:
    GuiControlGet, urlpart2, Settings:
    GuiControlGet, urlpart3, Settings:
    GuiControlGet, urlpart4, Settings:
    GuiControlGet, urlpart5, Settings:
    GuiControlGet, urlpart6, Settings:
    GuiControlGet, urlpart7, Settings:
    GuiControlGet, urlpart8, Settings:
    GuiControlGet, autotag1, Settings:
    GuiControlGet, autotag2, Settings:
    GuiControlGet, autotag3, Settings:
    GuiControlGet, autotag4, Settings:
    GuiControlGet, autotag5, Settings:
    GuiControlGet, autotag6, Settings:
    GuiControlGet, autotag7, Settings:
    GuiControlGet, autotag8, Settings:
    IniDelete, %_IniFile%, Autotag
    If (urlpart1 <> "" And autotag1 <> "")
        IniWrite, %autotag1%, %_IniFile%, Autotag, %urlpart1%
    If (urlpart2 <> "" And autotag2 <> "")
        IniWrite, %autotag2%, %_IniFile%, Autotag, %urlpart2%
    If (urlpart3 <> "" And autotag3 <> "")
        IniWrite, %autotag3%, %_IniFile%, Autotag, %urlpart3%
    If (urlpart4 <> "" And autotag4 <> "")
        IniWrite, %autotag4%, %_IniFile%, Autotag, %urlpart4%
    If (urlpart5 <> "" And autotag5 <> "")
        IniWrite, %autotag5%, %_IniFile%, Autotag, %urlpart5%
    If (urlpart6 <> "" And autotag6 <> "")
        IniWrite, %autotag6%, %_IniFile%, Autotag, %urlpart6%
    If (urlpart7 <> "" And autotag7 <> "")
        IniWrite, %autotag7%, %_IniFile%, Autotag, %urlpart7%
    If (urlpart8 <> "" And autotag8 <> "")
        IniWrite, %autotag8%, %_IniFile%, Autotag, %urlpart8%
    Gui, Settings:Destroy
    MsgBox, 36, Save settings, If settings have been changed you need to reload.`nReload now? (press Yes or No)
    IfMsgBox Yes
        goReloadCB()
}

showSettingsMenu(){
    global _Width, _Height
    global urlpart1, urlpart2, urlpart3, urlpart4, urlpart5, urlpart6, urlpart7, urlpart8
    global autotag1, autotag2, autotag3, autotag4, autotag5, autotag6, autotag7, autotag8
    global HotkeyCopyPlus, CtrlC, AltC, ShftC, WinC, RootFolder, _RootFolder
    Gui, Settings:New,, Settings
    Gui, Font, s9, Verdana  ; Set 9-point Verdana.
    Gui, Font, w700, Verdana 
    Gui, Add, Text, x20 yp+30 w180 h20 , Hotkey
    Gui, Font, w400, Verdana 
    Gui, Add, Text, x20 yp+28 w120 h20 , Copy url to save
    Gui, Add, CheckBox, x150 yp w50 h20 vCtrlC, Ctrl
    Gui, Add, CheckBox, x200 yp w50 h20 vAltC, Alt
    Gui, Add, CheckBox, x250 yp w50 h20 vShftC, Shft
    Gui, Add, CheckBox, x300 yp w50 h20 vWinC, Win
    Gui, Add, Edit, x350 yp w90 h20 vHotkeyCopyPlus, 
    Gui, Font, w700, Verdana 
    Gui, Add, Text, x22 yp+40 w280 h20 , Root-folder
    Gui, Font, w400, Verdana 
    Gui, Add, Button, x430 yp w60 h20 gsetRootFolder, Se&lect
    Gui, Add, Edit, x22 yp+26 w470 h20 vRootFolder, %_RootFolder%
    Gui, Font, w700, Verdana 
    Gui, Add, Text, x20 yp+40 w180 h20 , Autotags
    Gui, Font, w400, Verdana 
    Gui, Add, Text, x20 yp+30 w150 h20 , URL-part
    Gui, Add, Text, x200 yp w150 h20 , Tag
    Gui, Add, Text, x187 yp+20 w10 h20 , :
    Gui, Add, Edit, x20 yp w160 h20 vurlpart1, 
    Gui, Add, Edit, x200 yp w160 h20 vautotag1, 
    Gui, Add, Text, x187 yp+25 w10 h20 , :
    Gui, Add, Edit, x20 yp w160 h20 vurlpart2, 
    Gui, Add, Edit, x200 yp w160 h20 vautotag2, 
    Gui, Add, Text, x187 yp+25 w10 h20 , :
    Gui, Add, Edit, x20 yp w160 h20 vurlpart3, 
    Gui, Add, Edit, x200 yp w160 h20 vautotag3, 
    Gui, Add, Text, x187 yp+25 w10 h20 , :
    Gui, Add, Edit, x20 yp w160 h20 vurlpart4, 
    Gui, Add, Edit, x200 yp w160 h20 vautotag4, 
    Gui, Add, Text, x187 yp+25 w10 h20 , :
    Gui, Add, Edit, x20 yp w160 h20 vurlpart5, 
    Gui, Add, Edit, x200 yp w160 h20 vautotag5, 
    Gui, Add, Text, x187 yp+25 w10 h20 , :
    Gui, Add, Edit, x20 yp w160 h20 vurlpart6, 
    Gui, Add, Edit, x200 yp w160 h20 vautotag6, 
    Gui, Add, Text, x187 yp+25 w10 h20 , :
    Gui, Add, Edit, x20 yp w160 h20 vurlpart7, 
    Gui, Add, Edit, x200 yp w160 h20 vautotag7, 
    Gui, Add, Text, x187 yp+25 w10 h20 , :
    Gui, Add, Edit, x20 yp w160 h20 vurlpart8, 
    Gui, Add, Edit, x200 yp w160 h20 vautotag8, 
    Gui, Add, Button, Default x310 yp+40 w60 h20 gSaveSettings, &Save
    Gui, Add, Button, x380 yp w60 h20 gCancelSettings, &Cancel
    _Width := 500
    xpos := (A_ScreenWidth / 2) - (_Width / 2)
    ypos := 100
    Gui, Settings:Show, center x%xpos% y%ypos% h470 w%_Width%, CopyLink2MD Settings
}    

CancelSettings:
    Gui, Settings:Destroy
Return

; =================================================================================
; Function: AutoXYWH
;   Move and resize control automatically when GUI resizes.
; Parameters:
;   DimSize - Can be one or more of x/y/w/h  optional followed by a fraction
;             add a '*' to DimSize to 'MoveDraw' the controls rather then just 'Move', this is recommended for Groupboxes
;   cList   - variadic list of ControlIDs
;             ControlID can be a control HWND, associated variable name, ClassNN or displayed text.
;             The later (displayed text) is possible but not recommend since not very reliable 
; Examples:
;   AutoXYWH("xy", "Btn1", "Btn2")
;   AutoXYWH("w0.5 h 0.75", hEdit, "displayed text", "vLabel", "Button1")
;   AutoXYWH("*w0.5 h 0.75", hGroupbox1, "GrbChoices")
; ---------------------------------------------------------------------------------
; Version: 2015-5-29 / Added 'reset' option (by tmplinshi)
;          2014-7-03 / toralf
;          2014-1-2  / tmplinshi
; requires AHK version : 1.1.13.01+
; =================================================================================
AutoXYWH(DimSize, cList*){       ; http://ahkscript.org/boards/viewtopic.php?t=1079
    static cInfo := {}

    If (DimSize = "reset")
    Return cInfo := {}

    For i, ctrl in cList {
        ctrlID := A_Gui ":" ctrl
        If ( cInfo[ctrlID].x = "" ){
            GuiControlGet, i, %A_Gui%:Pos, %ctrl%
            MMD := InStr(DimSize, "*") ? "MoveDraw" : "Move"
            fx := fy := fw := fh := 0
            For i, dim in (a := StrSplit(RegExReplace(DimSize, "i)[^xywh]")))
                If !RegExMatch(DimSize, "i)" dim "\s*\K[\d.-]+", f%dim%)
                    f%dim% := 1
            cInfo[ctrlID] := { x:ix, fx:fx, y:iy, fy:fy, w:iw, fw:fw, h:ih, fh:fh, gw:A_GuiWidth, gh:A_GuiHeight, a:a , m:MMD}
        } Else If ( cInfo[ctrlID].a.1) {
            dgx := dgw := A_GuiWidth  - cInfo[ctrlID].gw  , dgy := dgh := A_GuiHeight - cInfo[ctrlID].gh
            For i, dim in cInfo[ctrlID]["a"]
                Options .= dim (dg%dim% * cInfo[ctrlID]["f" dim] + cInfo[ctrlID][dim]) A_Space
            GuiControl, % A_Gui ":" cInfo[ctrlID].m , % ctrl, % Options
        } 
    } 
}


