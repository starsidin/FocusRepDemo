# 专注深蹲：iPhone 版本

这是一款仅用于演示的原生 iOS App。它在灵动岛显示预设倒计时、运动提示和时间进度；长按灵动岛查看展开内容，轻点进入下蹲任务页面。

## 已实现的边界

- 首页提供“30 分钟”和“60 分钟（1）”两个选项。前者实际运行 30 分钟；后者为录屏用的加速模式，实际运行 1 分钟，并非真实 60 分钟控制。
- 灵动岛收起、展开、最小化和锁屏画面。
- 倒计时与时间进度条使用系统视图显示。
- 点击实时活动跳到下蹲任务页。
- 完成 8 次下蹲后，画面显示 10 秒休息，然后自动启动下一轮实时活动。App 需要在这段休息期间保持运行；若系统将它挂起，自动重启可能延后。
- 首次开始前在 App 内设置独立的 6 位数字结束密码；结束控制需输入密码。密码保存在本机 Keychain。连续输错 5 次会删除旧密码并允许直接设置新密码，因此它仅适合演示，不构成防他人退出的安全保护。
- 任务页打开前置摄像头，用 Apple Vision 在本机识别人体关节点；自拍画面叠加骨架。先站直校准，以髋、膝、踝的相对高度识别下蹲和起立，完成一个完整周期才计数。
- 检测是供真机验证的初版规则：需要固定手机、全身入镜，并让髋、膝和脚踝可见；遮挡或角度不佳时可能漏计、误计。下蹲幅度是相对校准站姿的画面高度变化，并非标准动作深度评分。计数只在当前相机页面保留。
- 无账号、支付、真实使用时长读取或其他 App 的限制能力。

视频中的沙漏画面需要在 iPhone 的“设置 → 屏幕使用时间 → App 限额”里单独配置；它和本 App 的倒计时没有程序联动。录像时请按实际工作方式说明，避免将剪辑呈现说成真实自动拦截。

## 开发与编译

源代码可在 Windows 上编辑和审查。iOS 编译需要 Xcode 与 macOS；GitHub Actions 的 `macos-15` 构建机可在仓库上传后执行 `.github/workflows/ios-compile.yml`。工作流先生成 Xcode 工程，再分别编译模拟器和 iPhone 设备目标，输出模拟器 ZIP 和 **未签名的 iPhone IPA**。IPA 包含 App 与实时活动所需的 Widget 扩展，但还不能直接在手机上运行。

## 免费账号安装到自己的 iPhone（Windows）

1. 按 [AltStore Classic 的 Windows 官方教程](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows) 安装 Apple 官网版本的 iTunes、iCloud，以及 AltServer。若已有 iTunes，先核对是否为 Apple 官网版本。Apple ID 和验证码只在自己的电脑、手机上输入，不要上传到 GitHub。
2. 用 USB 连接并解锁 iPhone，在手机上选择“信任这台电脑”。运行 AltServer，从系统托盘图标选择“Install AltStore”并选中 iPhone。按教程在手机的“设置 → 通用 → VPN 与设备管理”信任个人开发者，并在“设置 → 隐私与安全性 → 开发者模式”启用开发者模式。不同 iOS 版本的菜单文字可能略有差异。
3. 到本仓库 GitHub Actions 中打开成功的“Compile iOS demo”运行，下载 `FocusRepDemo-unsigned-builds`，解压后找到 `FocusRepDemo-unsigned.ipa`。在 iPhone 上用 AltStore Classic 导入这个 IPA；安装时 AltStore/AltServer 会用你的免费 Apple 账号为 App 和扩展签名。电脑运行 AltServer，手机通过 USB 或同一 Wi-Fi 与电脑连接。
4. 打开 App，选择“60 分钟（1）”并点“开始运动屏幕时间控制”，先设置自己的 6 位结束密码，再检查 1 分钟加速模式下锁屏与灵动岛的收起、长按展开、轻点跳转。完成 8 次下蹲后，留在 App 中观察 10 秒休息与下一轮启动。实际显示和跳转以 iPhone 真机测试为准。

也可以从首页直接点“开始下蹲检测”，允许相机权限，把手机竖直固定在正前方、屏幕朝向自己，让头到脚进入画面。先站直约半秒完成校准，确认骨架贴合，再蹲下并站直，观察下蹲幅度和计数。视频帧只在本机交给 Vision 处理，不录制或上传。

免费 Apple 账号的个人测试签名约 7 天到期，需要用 AltStore 刷新或重新安装；Apple 还限制每台设备同时安装的个人测试 App 数量。详见 [Apple 官方账号说明](https://developer.apple.com/help/account/basics/about-your-developer-account) 和 [AltStore 刷新说明](https://faq.altstore.io/altstore-classic/your-altstore)。

## 本地预检

在项目目录运行 `powershell -ExecutionPolicy Bypass -File scripts/check-project.ps1`。该检查只验证项目文件、plist 和能力配置，不代表 Swift 编译或真机功能测试。

## Windows 界面预览

可直接用浏览器打开 `preview/index.html`，在电脑上切换首页、动作检测和灵动岛草图，调整主题色、卡片透明度、字体大小、目标次数与模拟下蹲状态。参数保存在本机浏览器；使用“复制当前参数”把调整结果发给开发者，再同步到 SwiftUI。这个页面模拟界面与骨架，不运行 iPhone 相机、Apple Vision 或真正的灵动岛。修改预览页面不会自动修改 iOS App；SwiftUI 真机效果仍需最终安装验证。
