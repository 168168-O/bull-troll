import SwiftUI
import UIKit

struct InfoRow: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct ContentView: View {
    private var rows: [InfoRow] {
        let v = UIDevice.current
        return [
            InfoRow(title: "设备型号", value: v.model),
            InfoRow(title: "设备名称", value: v.name),
            InfoRow(title: "系统版本", value: "\(v.systemName) \(v.systemVersion)"),
            InfoRow(title: "架构", value: Self.arch),
            InfoRow(title: "巨魔环境", value: Self.trollStoreDetected ? "已检测到 TrollStore" : "未检测到")
        ]
    }

    @State private var copied = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.16, green: 0.19, blue: 0.28),
                                    Color(red: 0.04, green: 0.05, blue: 0.07)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if let logo = UIImage(named: "logo") {
                        Image(uiImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200)
                            .padding(.top, 32)
                    }

                    VStack(spacing: 6) {
                        Text("牛头 BullTroll")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(.white)
                        Text("版本 \(Self.version)")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.55))
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                            HStack {
                                Text(row.title)
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text(row.value)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.trailing)
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            if index < rows.count - 1 {
                                Divider().background(Color.white.opacity(0.08))
                            }
                        }
                    }
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)

                    Button {
                        UIPasteboard.general.string = rows.map { "\($0.title): \($0.value)" }.joined(separator: "\n")
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                    } label: {
                        Text(copied ? "已复制" : "复制设备信息")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.87, green: 0.19, blue: 0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 24)
                }
            }
        }
    }

    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    static var arch: String {
        #if arch(arm64)
        return "arm64"
        #else
        return "其它"
        #endif
    }

    static var trollStoreDetected: Bool {
        UIApplication.shared.canOpenURL(URL(string: "apple-magnifier://")!)
    }
}

@main
struct BullTrollApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
