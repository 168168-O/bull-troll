import SwiftUI
import WebKit
import UIKit
import AVFoundation
import PhotosUI

// 达K解围 · 系统风格版（白底表单 + 蓝色按钮）
// 一页：账号资料 → 申请方式 → 通道 → 生成（可编辑）→ 申请解封
// 右上角进「工具」和「话术」

enum Side: String {
    case cn, intl
    var title: String { self == .cn ? "中国微信" : "国外微信" }
    var url: String {
        self == .cn
            ? "https://weixin110.qq.com/cgi-bin/mmspamsupport-bin/newredirectconfirmcgi?main_type=appeal"
            : "https://help.wechat.com/cgi-bin/newreadtemplate?t=help_center/feedback_form&lang=en&Channel=WeChatOfficialWebsite"
    }
}

enum Scene: String, CaseIterable, Identifiable {
    case login = "登录受限 / 环境异常"
    case report = "被他人举报 / 内容投诉"
    case market = "误判批量注册 / 营销"
    case stolen = "账号被盗后被封"
    case device = "换机换号后被拦"
    case pay = "微信支付受限"
    case cross = "跨境登录风控锁号"
    case nofriend = "没有好友能辅助验证"
    var id: String { rawValue }

    var whyCN: String {
        switch self {
        case .login: return "设备与网络一直没变，同一个人、同一台手机、同一个城市，持续数月，这次限制属于误判。"
        case .report: return "没有发过广告、群发、投资类信息，没有索要钱财或验证码，也没有收到过投诉通知。"
        case .market: return "只有一个账号、一个号码，不开店、不做代理，没有用过群发工具、机器人、养号池或虚拟号。"
        case .stolen: return "账号曾被他人登录，随后被限制。绑定号码一直在我手上，可随时接收验证码。"
        case .device: return "旧手机已出售，SIM 卡移到新手机，号码未变，登录被拦在验证这一步。"
        case .pay: return "钱包资金来自本人银行卡与家人红包，用于日常消费，没有店铺或收款业务。"
        case .cross: return "注册地区、号码归属国与登录地点不同，系统按跨境登录处理。这是本人长期在用的正常状态。"
        case .nofriend: return "自助解封要求好友辅助验证，我这边没有符合条件的微信好友配合，这一步走不下去，申请人工核验。"
        }
    }

    var whyEN: String {
        switch self {
        case .login: return "My device and network have not changed: one person, one phone, one city, for months. This restriction is a false positive."
        case .report: return "I have sent no advertising, mass messages or investment offers, and I have asked nobody for money or codes. I received no complaint notice."
        case .market: return "I hold one account and one number, run no shop or reseller business, and use no bulk tools, bots, account farms or virtual numbers."
        case .stolen: return "My account was accessed by someone else and then restricted. The registered number is in my hands and receives SMS now."
        case .device: return "I sold my old handset and moved my SIM to a new phone; the number is unchanged. Login is blocked at the verification step."
        case .pay: return "Wallet funds come from my own bank card and family red packets, used for daily spending. The account runs no shop or collection business."
        case .cross: return "My registered region, the country of my number and my login location differ, which the system reads as cross-region login. This is my normal long-term state."
        case .nofriend: return "The self-unblock flow requires verification by a WeChat friend. No friend is available on my side, so the flow stops here; I am asking for manual verification."
        }
    }
}

final class M: ObservableObject {
    @Published var wxid = ""
    @Published var realName = ""
    @Published var cc = "+86"
    @Published var phone = ""
    @Published var email = ""
    @Published var region = ""
    @Published var location = ""
    @Published var banText = ""
    @Published var banDate = ""
    @Published var device = ""
    @Published var ios = ""
    @Published var regDate = ""
    @Published var scene: Scene = .cross
    @Published var side: Side = .intl
    @Published var out = ""

    init() {
        let d = UserDefaults.standard
        func g(_ k: String, _ def: String = "") -> String { d.string(forKey: k) ?? def }
        wxid = g("s.wxid"); realName = g("s.name"); cc = g("s.cc", "+86")
        phone = g("s.phone"); email = g("s.email"); region = g("s.region")
        location = g("s.loc"); banText = g("s.ban"); banDate = g("s.bdate")
        device = g("s.dev"); ios = g("s.ios"); regDate = g("s.rdate")
        if let sc = d.string(forKey: "s.scene"), let v = Scene(rawValue: sc) { scene = v }
    }

    func save() {
        let d = UserDefaults.standard
        d.set(wxid, forKey: "s.wxid"); d.set(realName, forKey: "s.name")
        d.set(cc, forKey: "s.cc"); d.set(phone, forKey: "s.phone")
        d.set(email, forKey: "s.email"); d.set(region, forKey: "s.region")
        d.set(location, forKey: "s.loc"); d.set(banText, forKey: "s.ban")
        d.set(banDate, forKey: "s.bdate"); d.set(device, forKey: "s.dev")
        d.set(ios, forKey: "s.ios"); d.set(regDate, forKey: "s.rdate")
        d.set(scene.rawValue, forKey: "s.scene")
    }

    var ready: Bool { !wxid.isEmpty && !phone.isEmpty }
}

@main
struct DaKApp: App {
    var body: some Scene { WindowGroup { RootView() } }
}

struct RootView: View {
    @StateObject private var m = M()
    @State private var showWeb = false
    @State private var showTool = false
    @State private var showScript = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("账号资料（填一次，自动记住）")) {
                    TextField("微信号", text: $m.wxid)
                        .disableAutocorrection(true).autocapitalization(.none)
                    TextField("微信昵称 / 姓名", text: $m.realName)
                    HStack {
                        TextField("区号", text: $m.cc).frame(width: 70).keyboardType(.phonePad)
                        TextField("手机号（不加 0）", text: $m.phone).keyboardType(.phonePad)
                    }
                    TextField("收结果的邮箱", text: $m.email)
                        .keyboardType(.emailAddress).disableAutocorrection(true).autocapitalization(.none)
                    TextField("注册地区", text: $m.region)
                    TextField("常驻登录地", text: $m.location)
                    TextField("封禁提示原文", text: $m.banText)
                    TextField("被封日期", text: $m.banDate)
                    TextField("手机型号", text: $m.device)
                    TextField("系统版本", text: $m.ios)
                    TextField("注册日期", text: $m.regDate)
                }

                Section(header: Text("申请方式")) {
                    Picker("选一种", selection: $m.scene) {
                        ForEach(Scene.allCases) { s in Text(s.rawValue).tag(s) }
                    }
                }

                Section(header: Text("选择通道")) {
                    HStack(spacing: 10) {
                        chan(.cn); chan(.intl)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button {
                        m.out = m.side == .cn ? cnText() : enText()
                        m.save()
                    } label: {
                        Text("生成")
                            .frame(maxWidth: .infinity)
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .disabled(!m.ready)

                    if !m.out.isEmpty {
                        TextEditor(text: $m.out)
                            .font(.system(size: 13))
                            .frame(height: 240)
                        HStack {
                            Button("复制") { UIPasteboard.general.string = m.out }
                            Spacer()
                            Button("清空") { m.out = "" }
                        }
                        .font(.system(size: 14))
                    }
                }

                Section {
                    Button {
                        if m.out.isEmpty { m.out = m.side == .cn ? cnText() : enText() }
                        m.save()
                        showWeb = true
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("申请解封（自动填入官网）")
                        }
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 17, weight: .bold))
                    }
                    .disabled(!m.ready)
                }
            }
            .navigationTitle("解封申请")
            .navigationBarItems(
                leading: Button("工具") { showTool = true },
                trailing: Button("话术") { showScript = true }
            )
            .sheet(isPresented: $showWeb) {
                WebFill(side: m.side, url: m.side.url, email: m.email,
                        subject: m.side == .cn ? "申诉：账号 \(m.wxid) 登录受限，申请人工核验"
                                               : "Appeal: \(m.wxid) — login restriction, manual verification requested",
                        content: m.out)
            }
            .sheet(isPresented: $showTool) { NavigationView { ToolPage() } }
            .sheet(isPresented: $showScript) { NavigationView { ScriptPage() } }
        }
    }

    private func chan(_ s: Side) -> some View {
        Button {
            m.side = s
        } label: {
            Text(s.title)
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(m.side == s ? Color.blue : Color(UIColor.secondarySystemBackground))
                .foregroundColor(m.side == s ? .white : .primary)
                .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // 文案
    private func cnText() -> String {
        """
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

    private func enText() -> String {
        """
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
}

// MARK: - 工具页

struct ToolPage: View {
    @State private var wx = EnvCheck.WeChatInfo()
    @State private var ip: IPInfo?
    @State private var region = "SG"
    @State private var busy = false
    @ObservedObject private var log = LogStore.shared

    var body: some View {
        Form {
            Section(header: Text("设备")) {
                Text("微信版本：\(wx.installed ? wx.version : "未检测到")")
                Text("容器：\(wx.dataPath.isEmpty ? "无" : "已找到")")
                Text("体积：\(wx.dataSize > 0 ? ByteCountFormatter.string(fromByteCount: wx.dataSize, countStyle: .file) : "-")")
            }
            Section(header: Text("出口 IP")) {
                if let i = ip {
                    Text("\(i.query)  \(i.country)/\(i.regionName)")
                    Text("机房 \(i.hosting ? "是" : "否")  时区 \(i.timezone)").font(.caption).foregroundColor(.secondary)
                }
                Button("检测") {
                    EnvCheck.ipInfo(proxy: SettingsStore.shared.proxy) { info in
                        ip = info; log.log("IP: \(info?.summary ?? "失败")")
                    }
                }
            }
            Section(header: Text("清指纹")) {
                Button(busy ? "执行中…" : "清理偏好 + 缓存 + WechatPrivate") {
                    guard !busy else { return }
                    busy = true
                    var o = CleanOptions()
                    o.prefs = true; o.caches = true; o.wechatPrivate = true
                    o.chatDB = false; o.group = true; o.backup = true
                    Cleaner.execute(info: wx, opts: o, log: { log.log($0) }) { _ in
                        DispatchQueue.main.async { busy = false }
                    }
                }
                .disabled(busy)
            }
            Section(header: Text("区域")) {
                Picker("目标区域", selection: $region) {
                    ForEach(Spoofer.presets) { p in Text("\(p.name) \(p.id)").tag(p.id) }
                }
                Button("写入并 respring") {
                    _ = Spoofer.apply(region: region, setLanguage: true, log: { log.log($0) })
                }
                Button("还原原始区域") { Spoofer.restore(log: { log.log($0) }) }
                    .foregroundColor(.red)
            }
            Section(header: Text("日志")) {
                Text(log.text.isEmpty ? "暂无" : String(log.text.suffix(400)))
                    .font(.system(size: 10, design: .monospaced))
            }
        }
        .navigationTitle("环境工具")
        .onAppear { wx = EnvCheck.wechat() }
    }
}

// MARK: - 话术页

struct ScriptPage: View {
    private let lines = [
        "你好，我的微信号登不上了。",
        "我的手机号在我手上，可以马上收验证码。",
        "我没有好友能帮忙验证，请人工帮我看看。"
    ]
    private let qas = [
        ("账号什么时候注册的？", "很早，一直是我自己用。"),
        ("最近在哪登录？", "在自己家，用自己的手机。"),
        ("有没有借给别人？", "没有，就我自己用。"),
        ("实名是谁的？", "实名是我本人，身份证在我手上，可以拍照发给你们。")
    ]

    var body: some View {
        Form {
            Section(header: Text("电话三句（照念）"), footer: Text("0755-83765566 ｜ 境外 +86 755 8376 5566")) {
                ForEach(lines, id: \.self) { l in
                    Button {
                        UIPasteboard.general.string = l
                    } label: {
                        Text(l).font(.system(size: 17))
                    }
                }
            }
            Section(header: Text("客服四问四答")) {
                ForEach(qas, id: \.0) { q, a in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(q).font(.caption).foregroundColor(.secondary)
                        Text(a).font(.system(size: 16))
                    }
                }
            }
            Section(header: Text("回信节奏")) {
                Text("提交后 12 小时查邮箱，24 小时再查，36 小时没回追一句。")
                Button("复制追问英文") {
                    UIPasteboard.general.string = "Please advise on the status of this appeal."
                }
            }
        }
        .navigationTitle("话术")
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
        f.style.outline='3px solid #007aff';
      });
      var bar=document.createElement('div');
      bar.textContent='已自动填好 · 截图点蓝框选一张 · 核对后提交';
      bar.style.cssText='position:fixed;left:12px;right:12px;bottom:18px;z-index:99999;background:#007aff;color:#fff;padding:12px;border-radius:12px;font:14px -apple-system;text-align:center';
      document.body.appendChild(bar);
      setTimeout(function(){bar.remove();},6000);
    }
    setTimeout(fill,1200);
    setTimeout(fill,3200);
    })();
    """
}
