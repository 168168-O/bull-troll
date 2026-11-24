import SwiftUI
import WebKit
import UIKit

// 达K解围 · 全合并版
// 四个页签：申请 / 模板 / 工具 / 话术

enum Side: String {
    case cn, intl
    var title: String { self == .cn ? "中国微信" : "国外微信" }
    var symbol: String { self == .cn ? "message.fill" : "globe" }
    var url: String {
        self == .cn
            ? "https://weixin110.qq.com/cgi-bin/mmspamsupport-bin/newredirectconfirmcgi?main_type=appeal"
            : "https://help.wechat.com/cgi-bin/newreadtemplate?t=help_center/feedback_form&lang=en&Channel=WeChatOfficialWebsite"
    }
}

enum Scene: String, CaseIterable, Identifiable {
    case cross = "跨境风控（默认）"
    case login = "登录受限 / 环境异常"
    case report = "被他人举报"
    case market = "误判营销 / 批量注册"
    case stolen = "账号被盗"
    case device = "换机换号"
    case pay = "支付受限"
    case nofriend = "没有好友辅助"
    var id: String { rawValue }

    var whyCN: String {
        switch self {
        case .cross: return "我的注册地区与号码归属国、登录地点不同，系统按跨境登录处理。这是本人长期在用的正常状态，不是买卖账号或代登录。"
        case .login: return "我的设备与网络一直没变，同一个人、同一台手机、同一个城市，持续数月，这次限制属于误判。"
        case .report: return "我没有发过广告、群发、投资类信息，没有向任何人索要钱财、密码或验证码，也没有收到过投诉通知。"
        case .market: return "我只有这一个账号、一个号码，不开店、不做代理，没有使用群发工具、机器人、养号池或虚拟号。"
        case .stolen: return "账号曾被他人登录，随后被限制。绑定号码一直在我手上，可随时接收验证码。"
        case .device: return "旧手机已出售，SIM 卡移到新手机，号码未变，登录被拦在验证这一步。"
        case .pay: return "钱包资金来自本人银行卡与家人红包，用于日常消费，没有店铺或收款业务。"
        case .nofriend: return "自助解封要求好友辅助验证，我这边没有符合条件的微信好友可以配合，这一步走不下去，申请人工核验。"
        }
    }

    var whyEN: String {
        switch self {
        case .cross: return "My registered region, the country of my number and my login location differ, which the system reads as cross-region login. This is my normal long-term state, not a traded or shared account."
        case .login: return "My device and network have not changed: one person, one phone, one city, for months. This restriction is a false positive."
        case .report: return "I have sent no advertising, mass messages or investment offers, and I have asked nobody for money, passwords or codes. I received no complaint notice."
        case .market: return "I hold one account and one number. I run no shop, no agency, no reseller business, and I use no bulk tools, bots, account farms or virtual numbers."
        case .stolen: return "My account was accessed by someone else and then restricted. The registered number is in my hands and receives SMS right now."
        case .device: return "I sold my old handset and moved my SIM to a new phone; the number is unchanged. Login is blocked at the verification step."
        case .pay: return "Wallet funds come from my own bank card and family red packets, used for daily spending. The account runs no shop or collection business."
        case .nofriend: return "The self-unblock flow requires verification by a WeChat friend. No friend is available on my side to confirm, so the flow stops here; I am asking for manual verification."
        }
    }
}

private enum P {
    static let accent = Color(red: 0.93, green: 0.22, blue: 0.18)
    static let accentDeep = Color(red: 0.55, green: 0.09, blue: 0.08)
    static let display = "AvenirNext-DemiBold"
}

final class ApplyModel: ObservableObject {
    @Published var side: Side = .intl
    @Published var scene: Scene = .cross
    @Published var wxid = ""
    @Published var realName = ""
    @Published var cc = ""
    @Published var phone = ""
    @Published var prevPhones = ""
    @Published var email = ""
    @Published var facebook = ""
    @Published var location = ""
    @Published var region = ""
    @Published var device = ""
    @Published var ios = ""
    @Published var regDate = ""
    @Published var banDate = ""
    @Published var lang = "English"
    @Published var delFriend = ""
    @Published var features = ""
    @Published var banText = ""
    @Published var mode = 0

    init() {
        let d = UserDefaults.standard
        func s(_ k: String) -> String? { d.string(forKey: k) }
        if let v = s("a.wxid") { wxid = v }
        if let v = s("a.name") { realName = v }
        if let v = s("a.cc") { cc = v }
        if let v = s("a.phone") { phone = v }
        if let v = s("a.prev") { prevPhones = v }
        if let v = s("a.email") { email = v }
        if let v = s("a.fb") { facebook = v }
        if let v = s("a.loc") { location = v }
        if let v = s("a.reg") { region = v }
        if let v = s("a.dev") { device = v }
        if let v = s("a.ios") { ios = v }
        if let v = s("a.regdate") { regDate = v }
        if let v = s("a.bandate") { banDate = v }
        if let v = s("a.lang") { lang = v }
        if let v = s("a.del") { delFriend = v }
        if let v = s("a.feat") { features = v }
        if let v = s("a.ban") { banText = v }
    }

    func save() {
        let d = UserDefaults.standard
        d.set(wxid, forKey: "a.wxid"); d.set(realName, forKey: "a.name")
        d.set(cc, forKey: "a.cc"); d.set(phone, forKey: "a.phone")
        d.set(prevPhones, forKey: "a.prev"); d.set(email, forKey: "a.email")
        d.set(facebook, forKey: "a.fb"); d.set(location, forKey: "a.loc")
        d.set(region, forKey: "a.reg"); d.set(device, forKey: "a.dev")
        d.set(ios, forKey: "a.ios"); d.set(regDate, forKey: "a.regdate")
        d.set(banDate, forKey: "a.bandate"); d.set(lang, forKey: "a.lang")
        d.set(delFriend, forKey: "a.del"); d.set(features, forKey: "a.feat")
        d.set(banText, forKey: "a.ban")
    }

    var ready: Bool { !wxid.isEmpty && !phone.isEmpty }
}

@main
struct DaKApp: App {
    var body: some Scene { WindowGroup { RootView().preferredColorScheme(.dark) } }
}

struct RootView: View {
    @StateObject private var m = ApplyModel()
    @State private var tab = 0
    @State private var out = ""
    @State private var showWeb = false

    var body: some View {
        ZStack {
            bg
            VStack(spacing: 0) {
                topBar
                tabBar
                Group {
                    if tab == 0 { applyPage }
                    else if tab == 1 { templatePage }
                    else if tab == 2 { toolPage }
                    else { scriptPage }
                }
            }
        }
        .sheet(isPresented: $showWeb) {
            WebFill(side: m.side, url: m.side.url, email: m.email,
                    subject: subject(), content: out.isEmpty ? appealText() : out)
        }
    }

    private var bg: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [P.accent.opacity(0.26), P.accent.opacity(0.04), .clear],
                           center: .init(x: 0.5, y: 0.10), startRadius: 8, endRadius: 300).ignoresSafeArea()
            LinearGradient(colors: [.clear, Color.black.opacity(0.65)], startPoint: .center, endPoint: .bottom).ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            if let logo = UIImage(named: "logo") {
                Image(uiImage: logo).resizable().scaledToFit().frame(width: 28, height: 28)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("达K解围").font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(LinearGradient(colors: [.white, Color(white: 0.72)], startPoint: .top, endPoint: .bottom))
                Text("UNBAN · ALL IN ONE").font(.custom(P.display, size: 8))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            tabBtn(0, "申请", "paperplane.fill")
            tabBtn(1, "模板", "doc.text.fill")
            tabBtn(2, "工具", "wrench.and.screwdriver.fill")
            tabBtn(3, "话术", "phone.fill")
        }
        .padding(.horizontal, 14).padding(.bottom, 8)
    }

    private func tabBtn(_ i: Int, _ t: String, _ s: String) -> some View {
        Button { tab = i; Speaker.shared.say(t) } label: {
            VStack(spacing: 3) {
                Image(systemName: s).font(.system(size: 13, weight: .bold))
                Text(t).font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(tab == i ? .white : Color.white.opacity(0.5))
            .frame(maxWidth: .infinity).frame(height: 46)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tab == i ? P.accent.opacity(0.85) : Color.white.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(tab == i ? 0.25 : 0.10), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // ───── 申请 ─────

    private var applyPage: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    sideRow
                    card("账号") {
                        VStack(spacing: 10) {
                            row("微信号", $m.wxid, "填你的微信号")
                            row("姓名", $m.realName, "证件上的名字")
                            HStack(spacing: 8) { small("区号", $m.cc, "+86", 58); row("手机号", $m.phone, "去掉开头 0") }
                            row("收信邮箱", $m.email, "回复只到这里")
                            row("注册地区", $m.region, "注册时选的地区")
                            row("常用登录地", $m.location, "常登录的城市")
                        }
                    }
                    card("关联与使用") {
                        VStack(spacing: 10) {
                            row("曾绑定号码", $m.prevPhones, "没有就写 None")
                            row("注册日期", $m.regDate, "注册年-月-日")
                            row("被封日期", $m.banDate, "被封年-月-日")
                            row("机型", $m.device, "iPhone")
                            row("微信语言", $m.lang, "English / 简体中文")
                            row("封禁提示原文", $m.banText, "截图那句話")
                        }
                    }
                    card("生成") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) { modeBtn(0, "申诉正文"); modeBtn(1, "邮件回信") }
                            Button { out = m.mode == 0 ? appealText() : mailText(); m.save() } label: {
                                Text("生成").font(.custom(P.display, size: 14)).foregroundStyle(.white)
                                    .frame(maxWidth: .infinity).frame(height: 42)
                                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(LinearGradient(colors: [P.accent, P.accentDeep],
                                                             startPoint: .topLeading, endPoint: .bottomTrailing)))
                            }.buttonStyle(PlainButtonStyle())
                            if !out.isEmpty {
                                ScrollView {
                                    Text(out).font(.system(size: 11)).foregroundStyle(Color.white.opacity(0.75))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }.frame(maxHeight: 180)
                                HStack(spacing: 10) {
                                    Button("复制") { UIPasteboard.general.string = out }
                                    Button("清空") { out = "" }
                                }.font(.system(size: 12)).foregroundStyle(P.accent)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 18)
            }
            Button {
                if out.isEmpty { out = m.mode == 0 ? appealText() : mailText() }
                m.save(); showWeb = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill").font(.system(size: 13, weight: .bold))
                    Text("申请解封（自动填入官网）").font(.custom(P.display, size: 14))
                }
                .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(LinearGradient(colors: [P.accent, P.accentDeep],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)))
                .shadow(color: P.accent.opacity(0.4), radius: 16, x: 0, y: 6)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(m.ready ? 1 : 0.45).disabled(!m.ready)
            .padding(.horizontal, 16).padding(.bottom, 10)
        }
    }

    private var sideRow: some View {
        HStack(spacing: 8) { sideBtn(.cn); sideBtn(.intl) }
    }

    private func sideBtn(_ s: Side) -> some View {
        Button { m.side = s } label: {
            HStack(spacing: 6) {
                Image(systemName: s.symbol).font(.system(size: 12, weight: .bold))
                Text(s.title).font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(m.side == s ? .white : Color.white.opacity(0.55))
            .frame(maxWidth: .infinity).frame(height: 42)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(m.side == s ? P.accent.opacity(0.85) : Color.white.opacity(0.05)))
        }.buttonStyle(PlainButtonStyle())
    }

    // ───── 模板 ─────

    private var templatePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                Text("选一种情况，自动写进申诉正文")
                    .font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(Scene.allCases) { s in
                    Button {
                        m.scene = s
                        out = m.mode == 0 ? appealText() : mailText()
                        Speaker.shared.say(s.rawValue)
                    } label: {
                        HStack {
                            Text(s.rawValue).font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                            Spacer()
                            if m.scene == s {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(P.accent)
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(m.scene == s ? 0.10 : 0.04)))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(m.scene == s ? 0.28 : 0.08), lineWidth: 1))
                    }.buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 20)
        }
    }

    // ───── 工具 ─────

    @State private var wx = EnvCheck.WeChatInfo()
    @State private var ip: IPInfo?
    @State private var region = "SG"
    @State private var busy = false
    @State private var wipePrefs = true
    @State private var wipeCache = true
    @State private var wipePrivate = true
    @ObservedObject private var log = LogStore.shared

    private var toolPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                card("设备") {
                    VStack(spacing: 8) {
                        kv("微信版本", wx.installed ? wx.version : "未检测到")
                        kv("数据容器", wx.dataPath.isEmpty ? "无" : "已找到")
                        kv("体积", wx.dataSize > 0 ? ByteCountFormatter.string(fromByteCount: wx.dataSize, countStyle: .file) : "-")
                    }
                }
                card("出口 IP") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let i = ip {
                            Text("\(i.query)  \(i.country)/\(i.regionName)").font(.system(size: 12)).foregroundStyle(.white)
                            Text("机房 \(i.hosting ? "是" : "否")  时区 \(i.timezone)").font(.system(size: 10)).foregroundStyle(Color.white.opacity(0.45))
                        } else {
                            Text("未测").font(.system(size: 11)).foregroundStyle(Color.white.opacity(0.4))
                        }
                        redBtn("检测", "antenna.radiowaves.left.and.right") {
                            EnvCheck.ipInfo(proxy: SettingsStore.shared.proxy) { info in
                                ip = info; log.log("IP: \(info?.summary ?? "失败")")
                            }
                        }
                    }
                }
                card("清指纹") {
                    VStack(alignment: .leading, spacing: 8) {
                        toggle("偏好", $wipePrefs); toggle("缓存", $wipeCache); toggle("WechatPrivate", $wipePrivate)
                        redBtn(busy ? "执行中…" : "开始清理", "trash") {
                            guard !busy else { return }
                            busy = true
                            var o = CleanOptions()
                            o.prefs = wipePrefs; o.caches = wipeCache; o.wechatPrivate = wipePrivate
                            o.chatDB = false; o.group = true; o.backup = true
                            Cleaner.execute(info: wx, opts: o, log: { log.log($0) }) { _ in
                                DispatchQueue.main.async { busy = false }
                            }
                        }
                    }
                }
                card("区域") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("目标").font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.5))
                            Spacer()
                            Picker("", selection: $region) {
                                ForEach(Spoofer.presets) { p in Text("\(p.name) \(p.id)").tag(p.id) }
                            }.pickerStyle(MenuPickerStyle())
                        }
                        redBtn("写入并 respring", "globe") {
                            _ = Spoofer.apply(region: region, setLanguage: true, log: { log.log($0) })
                        }
                        Button("还原") { Spoofer.restore(log: { log.log($0) }) }
                            .font(.system(size: 11)).foregroundStyle(P.accent)
                    }
                }
                card("入口") {
                    VStack(spacing: 8) {
                        link("国外 · 提交申诉", Side.intl.url)
                        link("国内 · 安全中心", "https://weixin110.qq.com/")
                    }
                }
                card("日志") {
                    Text(log.text.isEmpty ? "暂无" : String(log.text.suffix(400)))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 20)
        }
        .onAppear { wx = EnvCheck.wechat() }
    }

    // ───── 话术 ─────

    private var scriptPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                card("电话三句（照念）") {
                    VStack(alignment: .leading, spacing: 10) {
                        sayLine("你好，我的微信号登不上了。")
                        sayLine("我的手机号在我手上，可以马上收验证码。")
                        sayLine("我没有好友能帮忙验证，请人工帮我看看。")
                        Text("0755-83765566 ｜ 境外 +86 755 8376 5566")
                            .font(.system(size: 10)).foregroundStyle(Color.white.opacity(0.4))
                    }
                }
                card("客服四问四答") {
                    VStack(alignment: .leading, spacing: 10) {
                        qa("账号什么时候注册的？", "很早，一直是我自己用。")
                        qa("最近在哪登录？", "在自己家，用自己的手机。")
                        qa("有没有借给别人？", "没有，就我自己用。")
                        qa("实名是谁的？", "实名是我本人，身份证在我手上，可以拍照发给你们。")
                    }
                }
                card("回信 12 / 24 小时") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("提交后 12 小时查邮箱，24 小时再查一次，36 小时没回就追一句。")
                            .font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.7))
                        sayLine("Please advise on the status of this appeal.")
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 20)
        }
    }

    // ───── 组件 ─────

    private func card<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.custom(P.display, size: 9.5)).foregroundStyle(Color.white.opacity(0.34))
                .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 8)
            content().padding(.horizontal, 14).padding(.bottom, 13)
        }
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }

    private func row(_ t: String, _ b: Binding<String>, _ h: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(t).font(.system(size: 10)).foregroundStyle(Color.white.opacity(0.45))
            TextField(h, text: b).font(.system(size: 14))
                .disableAutocorrection(true).autocapitalization(.none)
                .foregroundStyle(.white).padding(9)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        }
    }

    private func small(_ t: String, _ b: Binding<String>, _ h: String, _ w: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(t).font(.system(size: 10)).foregroundStyle(Color.white.opacity(0.45))
            TextField(h, text: b).font(.system(size: 14)).foregroundStyle(.white)
                .padding(9).frame(width: w)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        }
    }

    private func modeBtn(_ i: Int, _ t: String) -> some View {
        Button { m.mode = i } label: {
            Text(t).font(.system(size: 11, weight: .semibold))
                .foregroundStyle(m.mode == i ? .white : Color.white.opacity(0.5))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(m.mode == i ? P.accent.opacity(0.85) : Color.white.opacity(0.06)))
        }.buttonStyle(PlainButtonStyle())
    }

    private func redBtn(_ t: String, _ s: String, _ act: @escaping () -> Void) -> some View {
        Button(action: act) {
            HStack(spacing: 6) {
                Image(systemName: s).font(.system(size: 11, weight: .bold))
                Text(t).font(.custom(P.display, size: 13))
            }
            .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 40)
            .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(LinearGradient(colors: [P.accent, P.accentDeep],
                                     startPoint: .topLeading, endPoint: .bottomTrailing)))
        }.buttonStyle(PlainButtonStyle())
    }

    private func kv(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(.system(size: 11)).foregroundStyle(Color.white.opacity(0.5))
            Spacer()
            Text(v).font(.system(size: 11, weight: .medium)).foregroundStyle(.white).lineLimit(1)
        }
    }

    private func toggle(_ t: String, _ b: Binding<Bool>) -> some View {
        Toggle(t, isOn: b).font(.system(size: 12))
            .toggleStyle(SwitchToggleStyle(tint: P.accent))
            .foregroundStyle(Color.white.opacity(0.8))
    }

    private func link(_ t: String, _ u: String) -> some View {
        Button { if let url = URL(string: u) { UIApplication.shared.open(url) } } label: {
            HStack {
                Text(t).font(.system(size: 12)).foregroundStyle(.white)
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .bold)).foregroundStyle(P.accent)
            }.padding(10)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }.buttonStyle(PlainButtonStyle())
    }

    private func sayLine(_ t: String) -> some View {
        Button { UIPasteboard.general.string = t; Speaker.shared.say(t) } label: {
            HStack(alignment: .top) {
                Text(t).font(.system(size: 15)).foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "speaker.wave.2.fill").font(.system(size: 11)).foregroundStyle(P.accent)
            }
            .padding(11)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }.buttonStyle(PlainButtonStyle())
    }

    private func qa(_ q: String, _ a: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(q).font(.system(size: 10)).foregroundStyle(Color.white.opacity(0.45))
            Text(a).font(.system(size: 14)).foregroundStyle(.white)
        }
    }

    // ───── 文案 ─────

    private func subject() -> String {
        m.side == .cn ? "申诉：账号 \(m.wxid) 登录受限，申请人工核验"
                      : "Appeal: \(m.wxid) — login restriction, manual verification requested"
    }

    private func appealText() -> String {
        if m.side == .cn {
            return """
            微信安全中心：

            我的微信账号 \(m.wxid)（姓名 \(m.realName)，绑定手机 \(m.cc) \(m.phone)，注册地区 \(m.region)，常用登录地 \(m.location)），在 \(m.banDate) 登录时提示“\(m.banText)”，此后一直登不上。

            一、情况说明
            \(m.scene.whyCN)

            二、账号情况
            1. 账号由本人使用，设备 \(m.device)（iOS \(m.ios)），无外借、出租、买卖。
            2. 绑定手机 \(m.cc) \(m.phone) 在本人手上，可接收验证码。
            3. 未群发、未加粉、未使用外挂或改版客户端。

            三、申请事项
            1. 请人工核验账号归属，解除 \(m.wxid) 的登录限制。
            2. 验证码可发至 \(m.cc) \(m.phone)。
            3. 结果请回信至 \(m.email)。

            姓名：\(m.realName)
            联系电话：\(m.cc) \(m.phone)
            """
        }
        return """
        Dear WeChat Support Team,

        I am writing to appeal the login restriction on my WeChat account.

        ACCOUNT DETAILS
        - WeChat ID: \(m.wxid)
        - Full name: \(m.realName)
        - Mobile number that receives SMS: \(m.cc) \(m.phone)
        - Contact email: \(m.email)
        - Registered region: \(m.region)
        - Regular login location: \(m.location)
        - Device: \(m.device), iOS \(m.ios)
        - Registration date: \(m.regDate)
        - Date of restriction: \(m.banDate)
        - Restriction message: \(m.banText)

        WHY THIS IS A FALSE POSITIVE
        \(m.scene.whyEN)

        MY USE OF THE ACCOUNT
        1. Personal account: family chats, one work group and payments.
        2. No advertising, no mass messages, no investment offers.
        3. No bulk-add tools, bots, account farms, virtual numbers or modified clients.
        4. No complaint notice received before this restriction.

        WHAT I AM ASKING FOR
        1. Please verify ownership manually and lift the restriction on \(m.wxid).
        2. Please send the verification code to \(m.cc) \(m.phone).
        3. Please reply to \(m.email).

        Sincerely,
        \(m.realName)
        WeChat ID \(m.wxid)
        """
    }

    private func mailText() -> String {
        """
        Dear WeChat Support,

        Thank you for your reply. Please find my answers below, numbered as in your email.

        1. Reason for appeal: \(m.scene.whyEN)
        2. WeChat ID: \(m.wxid)
        3. Mobile number that can receive SMS now: \(m.cc) \(m.phone)
        4. Full name: \(m.realName)
        5. Current linked mobile number: \(m.cc) \(m.phone)
        6. Other numbers previously linked: \(m.prevPhones)
        7. Linked email address: \(m.email)
        8. Linked to Facebook: \(m.facebook)
        9. Locations where I use WeChat frequently: \(m.location)
        10. Latest login device and model: \(m.device), iOS \(m.ios)
        11. Registration date: \(m.regDate)
        12. WeChat app language: \(m.lang)
        13. Last friend deletion: \(m.delFriend)
        14. Features used lately: \(m.features)

        Additional notes:
        - The account is registered with \(m.region) because I registered it while travelling there. I live in \(m.location) and use my local \(m.cc) number.
        - No friend is available on my side to complete the friend verification.

        Sincerely,
        \(m.realName)
        WeChat ID \(m.wxid)
        """
    }
}

// MARK: - 语音

final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()
    func say(_ t: String) {
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: t)
        u.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        u.rate = 0.45
        synth.speak(u)
    }
}

// MARK: - 官网 + 自动填

struct WebFill: View {
    let side: Side
    let url: String
    let email: String
    let subject: String
    let content: String
    @Environment(\.presentationMode) private var presentation

    var body: some View {
        NavigationView {
            WebBox(url: url, payload: payload)
                .navigationTitle(side == .cn ? "中国微信 · 解封" : "国外微信 · 解封")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: Button("关闭") { presentation.wrappedValue.dismiss() })
        }
    }

    private var payload: String {
        let d: [String: String] = ["email": email, "subject": subject, "content": content]
        let data = (try? JSONSerialization.data(withJSONObject: d, options: [])) ?? Data()
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

struct WebBox: UIViewRepresentable {
    let url: String
    let payload: String

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .default()
        let ucc = WKUserContentController()
        ucc.addUserScript(WKUserScript(source: WebBox.js(payload), injectionTime: .atDocumentEnd, forMainFrameOnly: false))
        cfg.userContentController = ucc
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Mobile/15E148 Safari/604.1"
        if let u = URL(string: url) { wv.load(URLRequest(url: u)) }
        return wv
    }

    func updateUIView(_ v: WKWebView, context: Context) {}

    static func js(_ json: String) -> String {
        "(function(){var D=" + json + ";" + body
    }

    private static let body = """
    function setVal(el,v){
      if(!el||v===undefined)return;
      var tag=el.tagName;
      var proto=tag==='TEXTAREA'?HTMLTextAreaElement.prototype:(tag==='SELECT'?HTMLSelectElement.prototype:HTMLInputElement.prototype);
      var d=Object.getOwnPropertyDescriptor(proto,'value');
      try{d.set.call(el,v);}catch(e){el.value=v;}
      ['input','change','keyup','blur'].forEach(function(t){el.dispatchEvent(new Event(t,{bubbles:true}));});
    }
    function lab(el){
      var s=[el.name,el.id,el.placeholder,el.getAttribute('aria-label')].filter(Boolean).join(' ');
      var l=el.closest('label'); if(l) s+=' '+l.textContent;
      var w=el.closest('div,li,tr,section,fieldset,form'); if(w&&w.textContent) s+=' '+w.textContent.slice(0,200);
      return s.toLowerCase();
    }
    function choose(sel,re){
      if(!sel||!sel.options)return false;
      for(var i=0;i<sel.options.length;i++){
        var t=(sel.options[i].text||'').toLowerCase();
        if(re.test(t)){setVal(sel,sel.options[i].value);return true;}
      }
      return false;
    }
    function fill(){
      [].slice.call(document.querySelectorAll('input,textarea')).filter(function(e){
        return e.offsetParent!==null&&e.type!=='hidden'&&e.type!=='file';
      }).forEach(function(el){
        var k=lab(el);
        if(/e-?mail/.test(k)){setVal(el,D.email);return;}
        if(/wechat\\s*id|wxid|account id/.test(k)){setVal(el,D.wxid||'');return;}
        if(el.tagName==='TEXTAREA'){setVal(el,D.content);return;}
      });
      [].slice.call(document.querySelectorAll('select')).forEach(function(s){
        var k=lab(s);
        if(/platform/.test(k)){choose(s,/ios|iphone/);return;}
        if(/contact/.test(k)){choose(s,/email/);return;}
        if(/categor/.test(k)){choose(s,/account security|account/);return;}
      });
      [].slice.call(document.querySelectorAll('input[type=file]')).forEach(function(f){
        f.style.outline='3px solid #ed3833';
      });
      var bar=document.createElement('div');
      bar.textContent='已自动填好 · 截图点红框选一张 · 核对后提交';
      bar.style.cssText='position:fixed;left:12px;right:12px;bottom:18px;z-index:99999;background:#ed3833;color:#fff;padding:12px;border-radius:12px;font:14px -apple-system;text-align:center';
      document.body.appendChild(bar);
      setTimeout(function(){bar.remove();},6000);
    }
    setTimeout(fill,1200);
    setTimeout(fill,3200);
    })();
    """
}
