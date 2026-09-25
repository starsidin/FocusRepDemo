import SwiftUI

enum StopPasswordAction: String, Identifiable {
    case start
    case stop

    var id: String { rawValue }
}

struct StopPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: FocusSession

    let action: StopPasswordAction

    @State private var password = ""
    @State private var confirmation = ""
    @State private var message: String?

    private let mint = Color(red: 0.42, green: 0.96, blue: 0.77)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text(session.hasStopPassword ? "输入结束密码" : "设置结束密码")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text(session.hasStopPassword
                     ? "输入单独设置的 6 位数字密码，才能结束本次控制。"
                     : "设置一个 6 位数字密码；以后结束控制时需要输入它。")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.68))

                SecureField("6 位数字密码", text: $password)
                    .keyboardType(.numberPad)
                    .textContentType(.newPassword)
                    .onChange(of: password) { password = digitsOnly(password) }
                    .padding(16)
                    .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))

                if !session.hasStopPassword {
                    SecureField("再输入一次", text: $confirmation)
                        .keyboardType(.numberPad)
                        .textContentType(.newPassword)
                        .onChange(of: confirmation) { confirmation = digitsOnly(confirmation) }
                        .padding(16)
                        .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                }

                if let message {
                    Text(message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.orange)
                }

                Button(action: submit) {
                    Text(session.hasStopPassword ? "确认结束控制" : "设置密码并继续")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .foregroundStyle(Color(red: 0.05, green: 0.10, blue: 0.14))
                        .background(mint, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                if session.hasStopPassword {
                    Text("连续输错 5 次后，可以重新设置密码。")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()
            }
            .padding(24)
            .foregroundStyle(.white)
            .background(Color(red: 0.05, green: 0.10, blue: 0.14).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func digitsOnly(_ text: String) -> String {
        String(text.filter { "0123456789".contains($0) }.prefix(6))
    }

    private func submit() {
        guard password.count == 6 else {
            message = "请输入完整的 6 位数字密码。"
            return
        }

        if !session.hasStopPassword {
            guard confirmation == password else {
                message = "两次输入的密码不一致。"
                return
            }
            guard session.setStopPassword(password) else {
                message = "密码保存失败，请重试。"
                return
            }
            if action == .start { session.start() } else { session.finish() }
            dismiss()
            return
        }

        switch session.checkStopPassword(password) {
        case .accepted:
            session.finish()
            dismiss()
        case .incorrect(let remaining):
            password = ""
            message = "密码错误，还可尝试 \(remaining) 次。"
        case .resetRequired:
            password = ""
            confirmation = ""
            message = "已连续输错 5 次，请设置新的 6 位密码。"
        }
    }
}
