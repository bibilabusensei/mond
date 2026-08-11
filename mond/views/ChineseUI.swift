import SwiftUI
import PartyUI

// PartyUI 的 PlainToggle / PlainAlert 接收的是普通 String，系统本地化不会自动翻译。
// 在本 App 模块内提供同名实现，让原有调用无需大改即可显示中文。

private func cnText(_ text: String) -> String {
    let map: [String: String] = [
        "Dynamic Island": "灵动岛",
        "Always On Display": "全天候显示",
        "AOD Vibrancy": "AOD 鲜艳效果",
        "Charge Limit": "充电上限",
        "Boot Chime": "开机提示音",
        "Liquid Glass LPM": "液态玻璃低电量模式",
        "Camera Control": "相机控制",
        "Action Button": "操作按钮",
        "Crash Detection": "车祸检测",
        "Enable Tap to Wake": "轻点唤醒",
        "Pulse Width Modulation": "PWM 调光",
        "Security Research Device UI": "安全研究设备界面",
        "Disable Region Restrictions": "解除地区限制",
        "Apple Intelligence": "Apple Intelligence",
        "Allow Installing iPadOS Apps": "允许安装 iPadOS 应用",
        "Apple Pencil Settings": "Apple Pencil 设置",
        "Stage Manager": "台前调度",
        "iPadOS UI": "iPadOS 界面",
        "Internal Storage": "内部存储",
        "Internal Features": "内部功能",
        "Metal HUD in All Apps": "在所有 App 中显示 Metal HUD",
        "Do not reboot!": "不要重启！",
        "Your MobileGestalt.plist seems to be empty.": "MobileGestalt.plist 似乎是空文件。",
        "Your MobileGestalt.plist seems to be invalid.": "MobileGestalt.plist 似乎已损坏或格式无效。",
        "Information": "说明",
        "Warning!": "警告"
    ]
    return map[text] ?? text
}

struct PlainToggle: View {
    var text: String
    var icon: String
    var infoType: ToggleInfoType
    var infoTitle: String
    var infoMessage: String
    var minSupportedVersion: Double
    var maxSupportedVersion: Double
    @Binding var isOn: Bool

    init(
        text: String,
        icon: String = "",
        infoType: ToggleInfoType = .none,
        infoTitle: String = "Information",
        infoMessage: String = "",
        minSupportedVersion: Double = 0.0,
        maxSupportedVersion: Double = 100.0,
        isOn: Binding<Bool>
    ) {
        self.text = text
        self.icon = icon
        self.infoType = infoType
        self.infoTitle = infoTitle
        self.infoMessage = infoMessage
        self._isOn = isOn
        self.minSupportedVersion = minSupportedVersion
        self.maxSupportedVersion = maxSupportedVersion
    }

    var body: some View {
        if doubleSystemVersion() >= minSupportedVersion && doubleSystemVersion() <= maxSupportedVersion {
            Toggle(isOn: $isOn) {
                HStack(spacing: 10) {
                    if !icon.isEmpty {
                        Image(systemName: icon)
                            .frame(width: 22, height: 22, alignment: .center)
                    }
                    Text(cnText(text))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if infoType == .info || infoType == .warning {
                        Button {
                            let translatedBody: String
                            if text == "iPadOS UI" {
                                translatedBody = "这是高风险修改。错误设置可能造成界面异常、应用数据异常，严重时可能导致设备无法正常进入系统。使用字母数字密码时不要启用，并保留可恢复的 MobileGestalt 备份。"
                            } else {
                                translatedBody = infoMessage
                            }
                            Alertinator.shared.alert(title: cnText(infoTitle), body: translatedBody)
                        } label: {
                            Image(systemName: infoType == .info ? "info.circle" : "exclamationmark.triangle")
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 6)
                    }
                }
            }
        }
    }
}

struct PlainAlert: View {
    var title: String
    var icon: String
    var text: String
    var color: Color

    init(title: String = "", icon: String = "", text: String, color: Color = Color(.label)) {
        self.title = title
        self.icon = icon
        self.text = text
        self.color = color
    }

    var body: some View {
        HStack(spacing: 10) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .imageScale(.large)
            }
            VStack(alignment: .leading) {
                if !title.isEmpty {
                    Text(cnText(title))
                        .fontWeight(.medium)
                }
                Text(cnText(text))
                    .font(!title.isEmpty ? .subheadline : .body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
