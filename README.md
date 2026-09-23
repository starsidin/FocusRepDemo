# 专注俯卧撑：iPhone 演示版

这是一款仅用于演示的原生 iOS App。它在灵动岛显示预设倒计时、运动提示和时间进度；长按灵动岛查看展开内容，轻点进入俯卧撑任务页面。

## 已实现的边界

- App 内手动开始 30 分钟倒计时；另有 1 分钟测试选项。
- 灵动岛收起、展开、最小化和锁屏画面。
- 倒计时与时间进度条使用系统视图显示。
- 点击实时活动跳到俯卧撑任务页。
- 任务页可直接打开后置摄像头，用 Apple Vision 在本机识别人体关节点；画面叠加骨架、显示手肘角度，并根据侧面俯卧撑的下压与推起动作计数。
- 检测是供真机验证的初版规则：需要全身进入画面、肩和髋及脚踝可见；遮挡或角度不佳时可能漏计、误计。计数只在当前相机页面保留。
- 无账号、支付、真实使用时长读取或其他 App 的限制能力。

视频中的沙漏画面需要在 iPhone 的“设置 → 屏幕使用时间 → App 限额”里单独配置；它和本 App 的倒计时没有程序联动。录像时请按实际工作方式说明，避免将剪辑呈现说成真实自动拦截。

## 开发与编译

源代码可在 Windows 上编辑和审查。iOS 编译需要 Xcode 与 macOS；GitHub Actions 的 `macos-15` 构建机可在仓库上传后执行 `.github/workflows/ios-compile.yml`。工作流先生成 Xcode 工程，再分别编译模拟器和 iPhone 设备目标，输出模拟器 ZIP 和 **未签名的 iPhone IPA**。IPA 包含 App 与实时活动所需的 Widget 扩展，但还不能直接在手机上运行。

## 免费账号安装到自己的 iPhone（Windows）

1. 按 [AltStore Classic 的 Windows 官方教程](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows) 安装 Apple 官网版本的 iTunes、iCloud，以及 AltServer。若已有 iTunes，先核对是否为 Apple 官网版本。Apple ID 和验证码只在自己的电脑、手机上输入，不要上传到 GitHub。
2. 用 USB 连接并解锁 iPhone，在手机上选择“信任这台电脑”。运行 AltServer，从系统托盘图标选择“Install AltStore”并选中 iPhone。按教程在手机的“设置 → 通用 → VPN 与设备管理”信任个人开发者，并在“设置 → 隐私与安全性 → 开发者模式”启用开发者模式。不同 iOS 版本的菜单文字可能略有差异。
3. 到本仓库 GitHub Actions 中打开成功的“Compile iOS demo”运行，下载 `FocusRepDemo-unsigned-builds`，解压后找到 `FocusRepDemo-unsigned.ipa`。在 iPhone 上用 AltStore Classic 导入这个 IPA；安装时 AltStore/AltServer 会用你的免费 Apple 账号为 App 和扩展签名。电脑运行 AltServer，手机通过 USB 或同一 Wi-Fi 与电脑连接。
4. 打开 App，手动启动 1 分钟测试倒计时，再检查锁屏与灵动岛的收起、长按展开、轻点跳转。实际显示和跳转以 iPhone 真机测试为准。

也可以从首页直接点“测试摄像头骨架识别”，允许相机权限，把手机竖放在身体侧面，让全身进入画面。先确认青色骨架是否贴合人体，再做一次下压和推起，观察手肘角度与计数变化。视频帧只在本机交给 Vision 处理，不录制或上传。

免费 Apple 账号的个人测试签名约 7 天到期，需要用 AltStore 刷新或重新安装；Apple 还限制每台设备同时安装的个人测试 App 数量。详见 [Apple 官方账号说明](https://developer.apple.com/help/account/basics/about-your-developer-account) 和 [AltStore 刷新说明](https://faq.altstore.io/altstore-classic/your-altstore)。

## 本地预检

在项目目录运行 `powershell -ExecutionPolicy Bypass -File scripts/check-project.ps1`。该检查只验证项目文件、plist 和能力配置，不代表 Swift 编译或真机功能测试。
