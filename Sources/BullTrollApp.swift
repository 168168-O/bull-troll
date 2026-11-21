import SwiftUI
import UIKit

// MARK: - 数据

struct Metric: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let value: String
}

struct MetricGroup: Identifiable {
    let id = UUID()
    let caption: String
    let metrics: [Metric]
}

// MARK: - 样式

private enum Palette {
    static let accent = Color(red: 0.93, green: 0.22, blue: 0.18)
    static let accentDeep = Color(red: 0.55, green: 0.09, blue: 0.08)
    static let base = Color(red: 0.035, green: 0.04, blue: 0.055)
}

private struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - 视图

struct ContentView: View {
    @State private var appeared = false
    @State private var copied = false

    private var groups: [MetricGroup] {
        let device = UIDevice.current
        return [
            MetricGroup(caption: "设备", metrics: [
                Metric(symbol: "iphone", title: "机型", value: device.model),
                Metric(symbol: "tag", title: "名称", value: device.name),
                Metric(symbol: "cpu", title: "架构", value: Self.arch)
            ]),
            MetricGroup(caption: "系统", metrics: [
                Metric(symbol: "apple.logo", title: "系统", value: "\(device.systemName) \(device.systemVersion)"),
                Metric(symbol: "shippingbox", title: "内核", value: Self.kernel),
                Metric(symbol: "checkmark.shield", title: "巨魔环境", value: Self.trollStoreDetected ? "已就绪" : "未检测到")
            ])
        ]
    }

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: 26) {
                    hero
                    statusChip
                    ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                        card(for: group)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 18)
                            .animation(.easeOut(duration: 0.55).delay(0.12 + Double(index) * 0.08),
                                       value: appeared)
                    }
                    actionButton
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.7)) { appeared = true } }
    }

    // MARK: 背景

    private var background: some View {
        ZStack {
            Palette.base.ignoresSafeArea()

            RadialGradient(
                colors: [Palette.accent.opacity(0.34), Palette.accent.opacity(0.06), .clear],
                center: .init(x: 0.5, y: 0.16),
                startRadius: 8,
                endRadius: 340
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(red: 0.24, green: 0.28, blue: 0.42).opacity(0.30), .clear],
                center: .init(x: 0.9, y: 0.0),
                startRadius: 10,
                endRadius: 420
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: 主视觉

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Palette.accent.opacity(0.22))
                    .frame(width: 210, height: 210)
                    .blur(radius: 60)

                if let logo = UIImage(named: "logo") {
                    Image(uiImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 178)
                        .shadow(color: Palette.accent.opacity(0.55), radius: 28, x: 0, y: 12)
                }
            }
            .scaleEffect(appeared ? 1 : 0.9)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.85, dampingFraction: 0.78), value: appeared)

            VStack(spacing: 6) {
                Text("牛头")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, Color.white.opacity(0.72)],
                                       startPoint: .top, endPoint: .bottom)
                    )

                Text("B U L L T R O L L")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.42))
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.easeOut(duration: 0.6).delay(0.1), value: appeared)
        }
        .padding(.bottom, 2)
    }

    // MARK: 状态胶囊

    private var statusChip: some View {
        let ready = Self.trollStoreDetected
        return HStack(spacing: 8) {
            Circle()
                .fill(ready ? Color(red: 0.36, green: 0.85, blue: 0.55) : Color.white.opacity(0.35))
                .frame(width: 7, height: 7)
                .shadow(color: ready ? Color(red: 0.36, green: 0.85, blue: 0.55).opacity(0.9) : .clear,
                        radius: 6)

            Text(ready ? "T R O L L S T O R E 已就绪" : "未检测到 TROLLSTORE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.78))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
    }

    // MARK: 卡片

    private func card(for group: MetricGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(group.caption)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.38))
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 10)

            ForEach(Array(group.metrics.enumerated()), id: \.element.id) { index, metric in
                HStack(spacing: 13) {
                    Image(systemName: metric.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                    Text(metric.title)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.55))

                    Spacer(minLength: 8)

                    Text(metric.value)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.94))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)

                if index < group.metrics.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)
                        .padding(.leading, 61)
                }
            }
            .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.035))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.03)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.45), radius: 26, x: 0, y: 14)
    }

    // MARK: 按钮

    private var actionButton: some View {
        Button {
            UIPasteboard.general.string = groups
                .flatMap { $0.metrics }
                .map { "\($0.title)：\($0.value)" }
                .joined(separator: "\n")
            withAnimation(.easeOut(duration: 0.2)) { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeOut(duration: 0.25)) { copied = false }
            }
        } label: {
            HStack(spacing: 9) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 14, weight: .bold))
                Text(copied ? "已复制到剪贴板" : "复制设备信息")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(colors: [Palette.accent, Palette.accentDeep],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Palette.accent.opacity(0.45), radius: 22, x: 0, y: 12)
        }
        .buttonStyle(PressableStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(.easeOut(duration: 0.55).delay(0.34), value: appeared)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Text("v\(Self.version)")
            Circle().fill(Color.white.opacity(0.2)).frame(width: 3, height: 3)
            Text("arm64")
            Circle().fill(Color.white.opacity(0.2)).frame(width: 3, height: 3)
            Text("iOS 15+")
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(Color.white.opacity(0.3))
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.42), value: appeared)
    }

    // MARK: 环境信息

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

    static var kernel: String {
        ProcessInfo.processInfo.operatingSystemVersionString
            .replacingOccurrences(of: "Version ", with: "")
            .replacingOccurrences(of: " (Build ", with: " · ")
            .replacingOccurrences(of: ")", with: "")
    }

    static var trollStoreDetected: Bool {
        UIApplication.shared.canOpenURL(URL(string: "apple-magnifier://")!)
    }
}

// MARK: - 入口

@main
struct BullTrollApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
