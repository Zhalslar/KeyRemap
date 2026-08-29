#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ============================================================
; KeyRemap - 极简按键映射工具 (AutoHotkey v2)
; 功能: 键位映射 / 托盘驻留 / 开机自启 / INI 配置持久化
; ============================================================

global configFile := A_ScriptDir "\KeyRemap.ini"
global mappings := []          ; 元素: {src: "CapsLock", dst: "Enter"}
global activeKeys := []        ; 当前已注册的热键，便于卸载
global enabled := true
global mainGui := ""

; 下拉框常用键（ Combo 可编辑，允许手工输入任意键名 ）
global keyList := ["CapsLock", "Enter", "Space", "Tab", "Escape", "Backspace", "Delete", "Insert"
    , "Home", "End", "PgUp", "PgDn", "Up", "Down", "Left", "Right"
    , "LWin", "RWin", "LAlt", "RAlt", "LCtrl", "RCtrl", "LShift", "RShift", "AppsKey"
    , "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"
    , "NumLock", "ScrollLock", "PrintScreen", "Pause"
    , "Volume_Up", "Volume_Down", "Volume_Mute", "Media_Next", "Media_Prev", "Media_Play_Pause"]

; ================= 启动流程 =================
firstRun := !FileExist(configFile)
LoadConfig()
ApplyHotkeys()
SetupTray()

; 首次运行弹出设置窗口；之后静默驻留托盘（开机自启时不打扰）
if firstRun
    ShowSettings()

; ================= 热键核心 =================
SendMapped(dst, *) {
    Send("{Blind}{" dst "}")
}

ApplyHotkeys() {
    global activeKeys, mappings, enabled
    for k in activeKeys {
        try Hotkey(k, "Off")
    }
    activeKeys := []
    if !enabled
        return
    for m in mappings {
        if (m.src = "" || m.dst = "")
            continue
        ; "$" 前缀防止映射目标再次触发热键造成递归
        Hotkey("$" m.src, SendMapped.Bind(m.dst), "On")
        activeKeys.Push("$" m.src)
    }
}

; ================= 配置读写 =================
LoadConfig() {
    global mappings, enabled, configFile
    mappings := []
    if !FileExist(configFile) {
        mappings.Push({src: "CapsLock", dst: "Enter"})   ; 默认映射
        return
    }
    enabled := (IniRead(configFile, "Settings", "Enabled", "1") = "1")
    loop 100 {
        line := IniRead(configFile, "Mappings", A_Index, "")
        if (line = "")
            break
        parts := StrSplit(line, "|")
        if (parts.Length = 2)
            mappings.Push({src: parts[1], dst: parts[2]})
    }
}

SaveConfig() {
    global mappings, enabled, configFile
    if FileExist(configFile)
        FileDelete(configFile)
    IniWrite(enabled ? "1" : "0", configFile, "Settings", "Enabled")
    for i, m in mappings
        IniWrite(m.src "|" m.dst, configFile, "Mappings", i)
}

; ================= 开机自启（注册表 Run 项，免计划任务） =================
SetAutostart(on) {
    runKey := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
    if on {
        cmd := A_IsCompiled ? '"' A_ScriptFullPath '"' : '"' A_AhkPath '" "' A_ScriptFullPath '"'
        RegWrite(cmd, "REG_SZ", runKey, "KeyRemap")
    } else {
        try RegDelete(runKey, "KeyRemap")
    }
}

IsAutostart() {
    try return RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", "KeyRemap") != ""
    catch
        return false
}

; ================= 托盘菜单 =================
SetupTray() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("打开设置", (*) => ShowSettings())
    A_TrayMenu.Add("启用映射", ToggleEnable)
    A_TrayMenu.Add()
    A_TrayMenu.Add("退出", (*) => ExitApp())
    A_TrayMenu.Default := "打开设置"
    UpdateTray()
}

ToggleEnable(*) {
    global enabled
    enabled := !enabled
    ApplyHotkeys()
    SaveConfig()
    UpdateTray()
}

UpdateTray() {
    global enabled
    if enabled
        A_TrayMenu.Check("启用映射")
    else
        A_TrayMenu.Uncheck("启用映射")
    A_IconTip := "KeyRemap - " (enabled ? "已启用" : "已停用")
}

; ================= 设置窗口 =================
ShowSettings(*) {
    global mainGui, mappings, enabled, keyList

    if (mainGui != "") {
        mainGui.Show()
        return
    }

    g := Gui("+MinSize460x", "KeyRemap 按键映射")
    g.SetFont("s10", "Microsoft YaHei UI")
    g.MarginX := 14
    g.MarginY := 12

    ; 映射列表
    lv := g.AddListView("w432 h180 Grid -Multi", ["原键", "映射为"])
    lv.ModifyCol(1, 200)
    lv.ModifyCol(2, 200)
    for m in mappings
        lv.Add(, m.src, m.dst)

    ; 添加行
    g.AddText("xm y+14 w52 h24 +0x200", "原键")
    cbSrc := g.AddComboBox("x+8 yp-3 w120", keyList)
    g.AddText("x+14 yp+3 w52 h24 +0x200", "映射为")
    cbDst := g.AddComboBox("x+8 yp-3 w120", keyList)
    btnAdd := g.AddButton("x+14 yp-1 w70", "添加")

    ; 操作行
    btnDel := g.AddButton("xm y+12 w70", "删除")
    chkEnable := g.AddCheckbox("x+30 yp+4", "启用映射")
    chkEnable.Value := enabled
    chkAuto := g.AddCheckbox("x+24", "开机自启")
    chkAuto.Value := IsAutostart()

    ; 保存
    btnSave := g.AddButton("xm y+16 w432 h34 Default", "保存并应用")

    AddMapping(*) {
        src := Trim(cbSrc.Text)
        dst := Trim(cbDst.Text)
        if (src = "" || dst = "") {
            MsgBox("请填写原键和映射目标键。", "KeyRemap", "Icon!")
            return
        }
        lv.Add(, src, dst)
        cbSrc.Text := ""
        cbDst.Text := ""
    }

    DelMapping(*) {
        while (row := lv.GetNext())
            lv.Delete(row)
    }

    ToggleFromGui(*) {
        global enabled
        enabled := chkEnable.Value
        ApplyHotkeys()
        UpdateTray()
    }

    SaveApply(*) {
        global mappings, enabled
        mappings := []
        loop lv.GetCount()
            mappings.Push({src: lv.GetText(A_Index, 1), dst: lv.GetText(A_Index, 2)})
        enabled := chkEnable.Value
        SaveConfig()
        SetAutostart(chkAuto.Value)
        ApplyHotkeys()
        UpdateTray()
        TrayTip("KeyRemap", "设置已保存并生效", 1)
        g.Hide()
    }

    btnAdd.OnEvent("Click", AddMapping)
    btnDel.OnEvent("Click", DelMapping)
    chkEnable.OnEvent("Click", ToggleFromGui)
    btnSave.OnEvent("Click", SaveApply)
    g.OnEvent("Close", (*) => g.Hide())   ; 关闭按钮仅隐藏，程序驻留托盘

    mainGui := g
    g.Show()
}
