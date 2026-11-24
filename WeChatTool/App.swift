import SwiftUI
import UIKit

// 跨境解封助手 · 牛头视觉版
// 保留原功能：环境检测 / 清指纹 / 区域伪装 / 官方入口

private enum P {
    static let accent = Color(red: 0.93, green: 0.22, blue: 0.18)
    static let accentDeep = Color(red: 0.55, green: 0.09, blue: 0.08)
    static let display = "AvenirNext-DemiBold"
}

private struct Card<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.custom(P.display, size: 10))
                .foregroundStyle(Color.white.opacity(0.34))
                .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 10)
            content.padding(.horizontal, 18).padding(.bottom, 16)
        }
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(LinearGradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.03)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 22, x: 0, y: 12)
    }
}

private struct RedButton: View {
    let title: String
    let symbol: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol).font(.system(size: 14, weight: .bold))
                Text(title).font(.custom(P.display, size: 15))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [P.accent, P.accentDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(LinearGradient(colors: [Color.white.opacity(0.2), .clear], startPoint: .top, endPoint: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
            .shadow(color: P.accent.opacity(0.35), radius: 18, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@main
struct ToolApp: App {
    var body: some Scene { WindowGroup { ToolView().preferredColorScheme(.dark) } }
}

struct ToolView: View {
    @ObservedObject private var log = LogStore.shared
    @State private var wx = EnvCheck.WeChatInfo()
    @State private var ip: IPInfo?
    @State private var region = "SG"
    @State private var busy = false
    @State private var wipePrefs = true
    @State private var wipeCache = true
    @State private var wipePrivate = true
    @State private var appeared = false

    var body: some View {
        ZStack {
            bg
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    hero
                    deviceCard
                    netCard
                    wipeCard
                    regionCard
                    entryCard
                    logCard
                    footer
                }
                .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 40)
            }
        }
        .onAppear {
            wx = EnvCheck.wechat()
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
        }
    }

    private var bg: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [P.accent.opacity(0.30), P.accent.opacity(0.05), .clear],
                           center: .init(x: 0.5, y: 0.12), startRadius: 8, endRadius: 320).ignoresSafeArea()
            LinearGradient(colors: [.clear, Color.black.opacity(0.6)], startPoint: .center, endPoint: .bottom).ignoresSafeArea()
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(P.accent.opacity(0.22)).frame(width: 150, height: 150).blur(radius: 46)
                if let logo = UIImage(named: "logo") {
                    Image(uiImage: logo).resizable().scaledToFit().frame(width: 118)
                        .shadow(color: P.accent.opacity(0.5), radius: 20, x: 0, y: 8)
                }
            }
            Text("跨境解封助手")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(LinearGradient(colors: [.white, Color(white: 0.68)], startPoint: .top, endPoint: .bottom))
            Text("UNBAN TOOLKIT")
                .font(.custom(P.display, size: 10))
                .foregroundStyle(Color.white.opacity(0.35))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
        }
        .opacity(appeared ? 1 : 0)
    }

    private var deviceCard: some View {
        Card(title: "设备状态") {
            VStack(spacing: 10) {
                kv("微信版本", wx.installed ? wx.version : "未检测到")
                kv("容器", wx.dataPath.isEmpty ? "无" : "已找到")
                kv("体积", wx.dataSize > 0 ? ByteCountFormatter.string(fromByteCount: wx.dataSize, countStyle: .file) : "-")
            }
        }
    }

    private var netCard: some View {
        Card(title: "出口环境") {
            VStack(alignment: .leading, spacing: 12) {
                if let i = ip {
                    Text("\(i.query)  \(i.country)/\(i.regionName)")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
                    Text("机房 \(i.hosting ? "是" : "否")    时区 \(i.timezone)")
                        .font(.system(size: 11)).foregroundStyle(Color.white.opacity(0.45))
                } else {
                    Text("还没测过").font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.4))
                }
                RedButton(title: "检测出口 IP", symbol: "antenna.radiowaves.left.and.right") {
                    EnvCheck.ipInfo(proxy: SettingsStore.shared.proxy) { info in
                        ip = info
                        log.log("出口 IP: \(info?.summary ?? "失败")")
                    }
                }
            }
        }
    }

    private var wipeCard: some View {
        Card(title: "清设备指纹") {
            VStack(alignment: .leading, spacing: 12) {
                toggle("偏好设置", $wipePrefs)
                toggle("缓存与临时文件", $wipeCache)
                toggle("WechatPrivate 指纹库", $wipePrivate)
                RedButton(title: busy ? "执行中…" : "开始清理", symbol: "trash") {
                    guard !busy else { return }
                    busy = true
                    var o = CleanOptions()
                    o.prefs = wipePrefs; o.caches = wipeCache
                    o.wechatPrivate = wipePrivate; o.chatDB = false
                    o.group = true; o.backup = true
                    Cleaner.execute(info: wx, opts: o, log: { log.log($0) }) { _ in
                        DispatchQueue.main.async { busy = false }
                    }
                }
            }
        }
    }

    private var regionCard: some View {
        Card(title: "系统区域") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("目标区域").font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.5))
                    Spacer()
                    Picker("", selection: $region) {
                        ForEach(Spoofer.presets) { p in Text("\(p.name) \(p.id)").tag(p.id) }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                RedButton(title: "写入并 respring", symbol: "globe") {
                    _ = Spoofer.apply(region: region, setLanguage: true, log: { log.log($0) })
                }
                Button("还原原始区域") { Spoofer.restore(log: { log.log($0) }) }
                    .font(.system(size: 12)).foregroundStyle(P.accent)
            }
        }
    }

    private var entryCard: some View {
        Card(title: "官方入口") {
            VStack(spacing: 10) {
                link("国外微信 · 提交申诉", "https://help.wechat.com/cgi-bin/newreadtemplate?t=help_center/feedback_form&lang=en&Channel=WeChatOfficialWebsite")
                link("国内微信 · 安全中心", "https://weixin110.qq.com/")
            }
        }
    }

    private var logCard: some View {
        Card(title: "日志") {
            VStack(alignment: .leading, spacing: 6) {
                Text(log.text.isEmpty ? "暂无" : String(log.text.suffix(600)))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var footer: some View {
        Text("arm64 · iOS 15+ · TrollStore")
            .font(.custom(P.display, size: 10))
            .foregroundStyle(Color.white.opacity(0.28))
    }

    private func kv(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.5))
            Spacer()
            Text(v).font(.system(size: 12, weight: .medium)).foregroundStyle(.white).lineLimit(1)
        }
    }

    private func toggle(_ t: String, _ b: Binding<Bool>) -> some View {
        Toggle(t, isOn: b)
            .font(.system(size: 13))
            .toggleStyle(SwitchToggleStyle(tint: P.accent))
            .foregroundStyle(Color.white.opacity(0.8))
    }

    private func link(_ t: String, _ u: String) -> some View {
        Button {
            if let url = URL(string: u) { UIApplication.shared.open(url) }
        } label: {
            HStack {
                Text(t).font(.system(size: 13)).foregroundStyle(.white)
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .bold))
                    .foregroundStyle(P.accent)
            }
            .padding(12)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
