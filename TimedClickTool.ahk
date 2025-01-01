#Requires AutoHotkey v2.0  ; 确保脚本在 AutoHotkey v2 下运行
#NoTrayIcon                ; 不显示托盘图标
; AI工具辅助
; 默认点击间隔时间（秒）、点击次数、点击间隔（毫秒）、循环次数和按键类型
ClickInterval := 5
ClickCount := 1
ClickDelay := 100  ; 默认点击间隔为 100 毫秒
LoopCount := 1     ; 默认循环次数为 1
ClickButton := "左键"  ; 默认点击左键
IsRunning := false  ; 标记定时器是否正在运行
IsPaused := false   ; 标记是否处于暂停状态
RemainingTime := 0  ; 剩余时间（毫秒）

; 启动时弹出信息窗口
MsgBox("欢迎使用定时点击工具`n使用AutoHotkey v2.0编写`n`n`nHAF半个水果`nhttps://github.com/little-Data/TimedClickTool`n`n点击确定后即可使用`n", "欢迎", "OK")

; 创建 GUI 窗口
MyGui := Gui()
MyGui.Title := "定时点击工具"
MyGui.Add("Text",, "点击间隔时间（秒）:")
MyGui.Add("Edit", "vClickInterval").Text := ClickInterval
MyGui.Add("Text", "yp+30", "点击次数:")
MyGui.Add("Edit", "vClickCount").Text := ClickCount
MyGui.Add("Text", "yp+30", "点击间隔（毫秒）:")
MyGui.Add("Edit", "vClickDelay").Text := ClickDelay
MyGui.Add("Text", "yp+30", "循环次数:`n(-1 为无限循环， 按“重设”停止)")
MyGui.Add("Edit", "vLoopCount").Text := LoopCount
MyGui.Add("Text", "yp+30", "点击按键:")
ClickButtonDropdown := MyGui.Add("DropDownList", "vClickButton", ["左键", "中键", "右键"])
ClickButtonDropdown.Text := ClickButton  ; 设置默认选项
MyGui.Add("Text", "yp+30", "剩余时间:")
RemainingTimeText := MyGui.Add("Text", "yp+0 w100", "00:00:00.000")  ; 显示剩余时间

; 添加按钮（默认垂直排列）
StartButton := MyGui.Add("Button", "Default", "开始")
StartButton.OnEvent("Click", StartClick)
PauseButton := MyGui.Add("Button",, "暂停")
PauseButton.OnEvent("Click", PauseClick)
ResetButton := MyGui.Add("Button",, "重设")
ResetButton.OnEvent("Click", ResetClick)
AboutButton := MyGui.Add("Button",, "关于")
AboutButton.OnEvent("Click", AboutClick)
MyGui.Show()
PauseButton.Enabled := false

; 格式化时间为 HH:MM:SS.MS
FormatTime(ms) {
    ; 计算小时、分钟、秒和毫秒
    hours := Format("{:02}", ms // 3600000)
    ms := Mod(ms, 3600000)
    minutes := Format("{:02}", ms // 60000)
    ms := Mod(ms, 60000)
    seconds := Format("{:02}", ms // 1000)
    ms := Format("{:03}", Mod(ms, 1000))
    return hours ":" minutes ":" seconds "." ms
}

; 执行点击的函数
PerformClicks() {
    global ClickCount, ClickButton, ClickDelay, ClickInterval, RemainingTime, IsRunning, LoopCount
    Loop ClickCount {
        ; 根据选择的按键执行点击
        if (ClickButton = "左键") {
            Click("Left")
        } else if (ClickButton = "中键") {
            Click("Middle")
        } else if (ClickButton = "右键") {
            Click("Right")
        }
        Sleep(ClickDelay)  ; 每次点击间隔自定义时间
    }
    ; 主要功能执行结束后，恢复按钮状态
    StartButton.Enabled := true
    PauseButton.Enabled := false

    ; 如果未点击“重设”按钮且循环次数未用完，则重新开始倒计时
    if (IsRunning && (LoopCount = -1 || LoopCount > 1)) {
        if (LoopCount != -1) {
            LoopCount--  ; 减少循环次数
            PauseButton.Enabled := true
            StartButton.Enabled := false
        }
        RemainingTime := ClickInterval * 1000
        RemainingTimeText.Text := FormatTime(RemainingTime)
        SetTimer(UpdateRemainingTime, 100)  ; 每 100 毫秒更新一次
    } else {
        IsRunning := false
    }
}

; 更新剩余时间的函数
UpdateRemainingTime() {
    global RemainingTime, RemainingTimeText
    if (RemainingTime > 0) {
        RemainingTime -= 100  ; 每次减少 100 毫秒
        RemainingTimeText.Text := FormatTime(RemainingTime)
    } else {
        SetTimer(UpdateRemainingTime, 0)  ; 停止定时器
        IsRunning := false
        PerformClicks()  ; 在指定时间后执行点击
    }
}

; 开始按钮的事件
StartClick(*) {
    global IsRunning, IsPaused, ClickInterval, ClickCount, ClickDelay, ClickButton, RemainingTime, LoopCount
    ; 获取用户输入的点击间隔时间、点击次数、点击间隔、循环次数和按键类型
    ClickInterval := MyGui.Submit(false).ClickInterval
    ClickCount := MyGui.Submit(false).ClickCount
    ClickDelay := MyGui.Submit(false).ClickDelay
    LoopCount := MyGui.Submit(false).LoopCount
    ClickButton := MyGui.Submit(false).ClickButton

    ; 检查输入是否为整数（循环次数可以是 -1）
    if !(IsInteger(ClickInterval) && IsInteger(ClickCount) && IsInteger(ClickDelay) && (IsInteger(LoopCount) || LoopCount = -1)) {
        MsgBox("错误：输入必须为整数！", "错误", "OK")
        return  ; 停止运行
    }

    ; 检查点击间隔时间是否小于 2 秒
    if (ClickInterval < 2) {
        MsgBox("错误：点击间隔时间不能小于 2 秒！", "错误", "OK")
        return  ; 停止运行
    }

    if (IsPaused) {
        ; 如果处于暂停状态，则恢复计时器
        SetTimer(UpdateRemainingTime, 100)
        IsPaused := false
        PauseButton.Enabled := true  ; 暂停按钮恢复正常
    } else {
        ; 将秒转换为毫秒
        RemainingTime := ClickInterval * 1000
        RemainingTimeText.Text := FormatTime(RemainingTime)
        ; 启动定时器
        SetTimer(UpdateRemainingTime, 100)  ; 每 100 毫秒更新一次
        IsRunning := true
    }
    StartButton.Enabled := false  ; 开始按钮变为不可用
    PauseButton.Enabled := true   ; 暂停按钮恢复正常
    ResetButton.Enabled := true   ; 重设按钮恢复正常
}

; 暂停按钮的事件
PauseClick(*) {
    global IsPaused
    ; 暂停计时器
    SetTimer(UpdateRemainingTime, 0)
    IsPaused := true
    StartButton.Enabled := true  ; 开始按钮恢复正常
    PauseButton.Enabled := false  ; 暂停按钮变为不可用
}

; 重设按钮的事件
ResetClick(*) {
    global RemainingTime, ClickInterval, ClickCount, ClickDelay, ClickButton, IsRunning, IsPaused, LoopCount
    ; 停止定时器
    SetTimer(UpdateRemainingTime, 0)
    IsRunning := false
    IsPaused := false
    ; 重置剩余时间
    RemainingTime := ClickInterval * 1000
    RemainingTimeText.Text := FormatTime(RemainingTime)
    StartButton.Enabled := true  ; 开始按钮恢复正常
    PauseButton.Enabled := false  ; 暂停按钮变为不可用
}

; 关于按钮的事件
AboutClick(*) {
    MsgBox("定时点击工具`n版本: 1.0`n作者: HAF半个水果`n描述: 这是一个用于定时点击鼠标按键的工具，使用AutoHotkey v2.0编写`n`nhttps://github.com/little-Data/TimedClickTool", "关于", "OK")
}

; 关闭窗口时的事件
GuiClose(*) {
    ExitApp()  ; 直接退出软件
}

; 判断是否为整数的函数
IsInteger(value) {
    return value ~= "^-?\d+$"
}