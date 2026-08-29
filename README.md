# KeyRemap

极简 Windows 按键映射工具，基于 AutoHotkey v2。单文件、免安装、托盘驻留，支持自定义任意键位映射并持久化到 INI 配置。

## 功能特性

- **键位映射**：将任意按键映射为另一个按键（如 CapsLock → Enter）
- **图形化设置界面**：列表式管理映射，下拉选择或手工输入键名
- **托盘驻留**：关闭窗口仅隐藏，程序常驻系统托盘，可随时停用/启用
- **开机自启**：通过注册表 Run 项实现，无需计划任务
- **配置持久化**：映射与开关状态保存于 `KeyRemap.ini`，重启不丢失
- **防递归**：热键使用 `$` 前缀注册，映射目标不会再次触发热键
- **屏幕顶边滚轮调音量**：鼠标指针移到屏幕顶边时滚动滚轮，上滑调大、下滑调小（可在设置中关闭）
- **顶边 Ctrl+滚轮调亮度**：顶边按住 `Ctrl` 滚动滚轮调节屏幕亮度（每次 ±10%，仅支持笔记本内置屏等 WMI 可调设备，可在设置中关闭）

## 快速开始

### 方式一：直接运行脚本（需安装 AutoHotkey v2）

1. 安装 [AutoHotkey v2.0+](https://www.autohotkey.com/)
2. 双击 `KeyRemap.ahk` 运行

### 方式二：使用编译好的 exe

直接运行 `KeyRemap.exe`，无需安装任何依赖。

## 使用说明

1. 首次运行会自动弹出设置窗口；之后在系统托盘右键图标选择「打开设置」
2. 在「原键」「映射为」下拉框中选择（或输入）键名，点击「添加」
3. 勾选「开机自启」可让程序随 Windows 启动
4. 点击「保存并应用」立即生效

默认映射为 `CapsLock → Enter`。

## 配置文件

`KeyRemap.ini` 与程序同目录，格式示例：

```ini
[Settings]
Enabled=1
WheelVolume=1
WheelBrightness=1
[Mappings]
1=CapsLock|Enter
```

## 自行编译

使用 AutoHotkey v2 自带的 Ahk2Exe 编译器：

```
Ahk2Exe.exe /in KeyRemap.ahk /out KeyRemap.exe
```

## 许可证

[MIT License](LICENSE)
