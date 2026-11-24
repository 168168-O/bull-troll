import SwiftUI
import WebKit
import UIKit

// 牛头解封 · 单页填写版
// 第一屏就是表单：全部要填的都在这里，选完通道、填完、生成、申请
// 两种产物：① 申诉正文  ② 官方邮件回信（14 条编号作答）

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

private enum P {
    static let accent = Color(red: 0.93, green: 0.22, blue: 0.18)
    static let accentDeep = Color(red: 0.55, green: 0.09, blue: 0.08)
    static let display = "AvenirNext-DemiBold"
}

final class Form: ObservableObject {
    @Published var side: Side = .intl
    @Published var wxid = ""
    @Published var realName = ""
    @Published var cc = "+95"
    @Published var phone = ""
    @Published var prevPhones = ""
    @Published var email = ""
    @Published var facebook = "No"
    @Published var location = ""
    @Published var region = ""
    @Published var device = "iPhone 12"
    @Published var ios = "15.3"
    @Published var regDate = ""
    @Published var banDate = ""
    @Published var lang = "English"
    @Published var delFriend = ""
    @Published var features = ""
    @Published var banText = ""
    @Published var mode = 0   // 0 申诉正文  1 邮件回信

    init() {
        let d = UserDefaults.standard
        func s(_ k: String, _ def: String) -> String { d.string(forKey: k) ?? def }
        wxid = s("f.wxid", "")
        realName = s("f.name", "")
        cc = s("f.cc", "+95")
        phone = s("f.phone", "")
        prevPhones = s("f.prev", "")
        email = s("f.email", "")
        facebook = s("f.fb", "No")
        location = s("f.loc", "")
        region = s("f.reg", "")
        device = s("f.dev", "iPhone 12")
        ios = s("f.ios", "15.3")
        regDate = s("f.regdate", "")
        banDate = s("f.bandate", "")
        lang = s("f.lang", "English")
        delFriend = s("f.del", "")
        features = s("f.feat", "")
        banText = s("f.ban", "")
    }

    func save() {
        let d = UserDefaults.standard
        d.set(wxid, forKey: "f.wxid"); d.set(realName, forKey: "f.name")
        d.set(cc, forKey: "f.cc"); d.set(phone, forKey: "f.phone")
        d.set(prevPhones, forKey: "f.prev"); d.set(email, forKey: "f.email")
        d.set(facebook, forKey: "f.fb"); d.set(location, forKey: "f.loc")
        d.set(region, forKey: "f.reg"); d.set(device, forKey: "f.dev")
        d.set(ios, forKey: "f.ios"); d.set(regDate, forKey: "f.regdate")
        d.set(banDate, forKey: "f.bandate"); d.set(lang, forKey: "f.lang")
        d.set(delFriend, forKey: "f.del"); d.set(features, forKey: "f.feat")
        d.set(banText, forKey: "f.ban")
    }

    var canGenerate: Bool { !wxid.isEmpty && !phone.isEmpty && !email.isEmpty }
}

@main
struct UnbanApp: App {
    var body: some Scene { WindowGroup { RootView().preferredColorScheme(.dark) } }
}

struct RootView: View {
    @StateObject private var f = Form()
    @State private var out = ""
    @State private var showWeb = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            bg
            VStack(spacing: 0) {
                topBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        sideRow
                        baseCard
                        linkCard
                        usageCard
                        outputCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .padding(.bottom, 24)
                }
                bottomBar
            }
        }
        .sheet(isPresented: $showWeb) {
            WebFill(side: f.side, url: f.side.url, email: f.email,
                    subject: subject(), content: f.mode == 0 ? appealText() : mailText())
        }
        .onAppear { withAnimation(.easeOut(duration: 0.5)) { appeared = true } }
    }

    private var bg: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [P.accent.opacity(0.28), P.accent.opacity(0.04), .clear],
                           center: .init(x: 0.5, y: 0.10), startRadius: 8, endRadius: 300).ignoresSafeArea()
            LinearGradient(colors: [.clear, Color.black.opacity(0.65)], startPoint: .center, endPoint: .bottom).ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            if let logo = UIImage(named: "logo") {
                Image(uiImage: logo).resizable().scaledToFit().frame(width: 30, height: 30)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("牛头解封").font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(LinearGradient(colors: [.white, Color(white: 0.72)], startPoint: .top, endPoint: .bottom))
                Text("FILL · GENERATE · APPLY").font(.custom(P.display, size: 8))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
            Spacer()
        }
        .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 6)
    }

    // 通道
    private var sideRow: some View {
        HStack(spacing: 10) {
            sideBtn(.cn); sideBtn(.intl)
        }
    }

    private func sideBtn(_ s: Side) -> some View {
        Button { f.side = s } label: {
            HStack(spacing: 7) {
                Image(systemName: s.symbol).font(.system(size: 13, weight: .bold))
                Text(s.title).font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(f.side == s ? .white : Color.white.opacity(0.55))
            .frame(maxWidth: .infinity).frame(height: 46)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(f.side == s ? P.accent.opacity(0.85) : Color.white.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(f.side == s ? 0.25 : 0.10), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // 基础
    private var baseCard: some View {
        card("账号") {
            VStack(spacing: 12) {
                row("微信号", $f.wxid, "wxid_xxx 或 xfxf77887")
                row("姓名（证件上的）", $f.realName, "full name")
                HStack(spacing: 8) {
                    smallField("区号", $f.cc, "+95", 62)
                    row("手机号", $f.phone, "可收短信，去掉开头 0")
                }
                row("收信邮箱", $f.email, "回复只到这个邮箱")
                row("注册地区", $f.region, "Chinese Taiwan")
                row("常用登录地", $f.location, "Wa State, Myanmar")
            }
        }
    }

    // 关联
    private var linkCard: some View {
        card("关联信息") {
            VStack(spacing: 12) {
                row("曾绑定的其它号码", $f.prevPhones, "没有就写 None")
                row("是否绑定 Facebook", $f.facebook, "No")
                row("注册日期", $f.regDate, "2026-04-26")
                row("被封日期", $f.banDate, "2026-11-01")
                row("设备机型", $f.device, "iPhone 12")
                row("系统版本", $f.ios, "15.3")
            }
        }
    }

    // 使用
    private var usageCard: some View {
        card("使用情况") {
            VStack(spacing: 12) {
                row("微信语言", $f.lang, "English")
                row("最近删好友（时间+地点）", $f.delFriend, "没删过写 None")
                row("最近常用功能", $f.features, "聊天 / 朋友圈 / 支付")
                row("封禁提示原文", $f.banText, "截图那句英文")
            }
        }
    }

    // 输出
    private var outputCard: some View {
        card("生成内容") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    modeBtn(0, "申诉正文")
                    modeBtn(1, "邮件回信 14 条")
                }
                Button { generate() } label: {
                    Text("生成")
                        .font(.custom(P.display, size: 15))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 46)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(colors: [P.accent, P.accentDeep],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)))
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(f.canGenerate ? 1 : 0.45)
                .disabled(!f.canGenerate)

                if !out.isEmpty {
                    ScrollView {
                        Text(out).font(.system(size: 11)).foregroundStyle(Color.white.opacity(0.75))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 220)
                    HStack(spacing: 8) {
                        Button("复制") { UIPasteboard.general.string = out }
                        Button("清空") { out = "" }
                    }
                    .font(.system(size: 12)).foregroundStyle(P.accent)
                }
            }
        }
    }

    private func modeBtn(_ i: Int, _ t: String) -> some View {
        Button { f.mode = i } label: {
            Text(t).font(.system(size: 12, weight: .semibold))
                .foregroundStyle(f.mode == i ? .white : Color.white.opacity(0.5))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Capsule().fill(f.mode == i ? P.accent.opacity(0.85) : Color.white.opacity(0.06)))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var bottomBar: some View {
        Button {
            if out.isEmpty { generate() }
            f.save()
            showWeb = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "paperplane.fill").font(.system(size: 13, weight: .bold))
                Text("申请解封（自动填入官网）").font(.custom(P.display, size: 14))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [P.accent, P.accentDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(LinearGradient(colors: [Color.white.opacity(0.2), .clear], startPoint: .top, endPoint: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
            .shadow(color: P.accent.opacity(0.4), radius: 18, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(f.canGenerate ? 1 : 0.45)
        .disabled(!f.canGenerate)
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }

    // 组件
    private func card<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.custom(P.display, size: 10))
                .foregroundStyle(Color.white.opacity(0.34))
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)
            content().padding(.horizontal, 16).padding(.bottom, 16)
        }
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }

    private func row(_ title: String, _ text: Binding<String>, _ hint: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 11)).foregroundStyle(Color.white.opacity(0.45))
            TextField(hint, text: text)
                .font(.system(size: 15))
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .foregroundStyle(.white)
                .padding(11)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        }
    }

    private func smallField(_ title: String, _ text: Binding<String>, _ hint: String, _ w: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 11)).foregroundStyle(Color.white.opacity(0.45))
            TextField(hint, text: text)
                .font(.system(size: 15)).foregroundStyle(.white)
                .padding(11)
                .frame(width: w)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        }
    }

    // 文案
    private func generate() {
        out = f.mode == 0 ? appealText() : mailText()
        f.save()
    }

    private func subject() -> String {
        f.side == .cn
            ? "申诉：账号 \(f.wxid) 登录受限，申请人工核验"
            : "Appeal: \(f.wxid) — login restriction, manual verification requested"
    }

    private func appealText() -> String {
        if f.side == .cn {
            return """
            微信安全中心：

            我的微信账号 \(f.wxid)（姓名 \(f.realName)，绑定手机 \(f.cc) \(f.phone)，注册地区 \(f.region)，常用登录地 \(f.location)），在 \(f.banDate) 登录时提示“\(f.banText)”，此后一直登不上。

            一、账号情况
            1. 账号由本人使用，设备为 \(f.device)（iOS \(f.ios)），无外借、出租、买卖。
            2. 绑定手机 \(f.cc) \(f.phone) 在本人手上，可接收验证码。
            3. 未群发、未加粉、未使用外挂或改版客户端。

            二、申请事项
            1. 请人工核验账号归属，解除 \(f.wxid) 的登录限制。
            2. 验证码可发送至 \(f.cc) \(f.phone)。
            3. 处理结果请回信至 \(f.email)。

            姓名：\(f.realName)
            联系电话：\(f.cc) \(f.phone)
            """
        }
        return """
        Dear WeChat Support Team,

        I am writing to appeal the login restriction on my WeChat account.

        ACCOUNT DETAILS
        - WeChat ID: \(f.wxid)
        - Full name: \(f.realName)
        - Mobile number that receives SMS: \(f.cc) \(f.phone)
        - Contact email: \(f.email)
        - Registered region: \(f.region)
        - Regular login location: \(f.location)
        - Device: \(f.device), iOS \(f.ios)
        - Registration date: \(f.regDate)
        - Date of restriction: \(f.banDate)
        - Restriction message: \(f.banText)

        WHY THIS IS A FALSE POSITIVE
        I live in \(f.location) and use my own local number \(f.cc) \(f.phone). My registered region, the country of the number and my login location differ, which the system reads as abnormal. For me it is normal: one person, one device, one city, for months. The account has never been sold, rented or shared.

        MY USE OF THE ACCOUNT
        1. Personal account: family chats, one work group and payments.
        2. No advertising, no mass messages, no investment offers.
        3. No bulk-add tools, bots, account farms, virtual numbers or modified clients.
        4. No complaint notice received before this restriction.

        WHAT I AM ASKING FOR
        1. Please verify ownership manually and lift the restriction on \(f.wxid).
        2. Please send the verification code to \(f.cc) \(f.phone).
        3. Please reply to \(f.email).

        Sincerely,
        \(f.realName)
        WeChat ID \(f.wxid)
        """
    }

    private func mailText() -> String {
        """
        Dear WeChat Support,

        Thank you for your reply. Please find my answers below, numbered as in your email.

        1. Reason for appeal: appeal for a restricted account; the self-unblock flow came to a stop at friend verification.
        2. WeChat ID: \(f.wxid)
        3. Mobile number that can receive SMS now: \(f.cc) \(f.phone)
        4. Full name: \(f.realName)
        5. Current linked mobile number: \(f.cc) \(f.phone)
        6. Other numbers previously linked: \(f.prevPhones.isEmpty ? "None." : f.prevPhones)
        7. Linked email address: \(f.email)
        8. Linked to Facebook: \(f.facebook)
        9. Locations where I use WeChat frequently: \(f.location)
        10. Latest login device and model: \(f.device), iOS \(f.ios)
        11. Registration date: \(f.regDate)
        12. WeChat app language: \(f.lang)
        13. Last friend deletion: \(f.delFriend.isEmpty ? "None recently." : f.delFriend)
        14. Features used lately: \(f.features.isEmpty ? "Chats, Moments, WeChat Pay." : f.features)

        Additional notes:
        - The account is registered with \(f.region) as the region because I registered it while travelling there. I live in \(f.location) and use my local \(f.cc) number.
        - No friend is available on my side to complete the friend verification, which is why the automated flow stops.

        Sincerely,
        \(f.realName)
        WeChat ID \(f.wxid)
        """
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
        ucc.addUserScript(WKUserScript(source: WebBox.js(payload),
                                       injectionTime: .atDocumentEnd,
                                       forMainFrameOnly: false))
        cfg.userContentController = ucc
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Mobile/15E148 Safari/604.1"
        if let u = URL(string: url) { wv.load(URLRequest(url: u)) }
        return wv
    }

    func updateUIView(_ v: WKWebView, context: Context) {}

    static func js(_ json: String) -> String {
        let head = "(function(){var D=" + json + ";"
        return head + body
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
      var ins=[].slice.call(document.querySelectorAll('input,textarea')).filter(function(e){
        return e.offsetParent!==null&&e.type!=='hidden'&&e.type!=='file';
      });
      ins.forEach(function(el){
        var k=lab(el);
        if(/e-?mail/.test(k)){setVal(el,D.email);return;}
        if(/wechat\\s*id|wxid|account id/.test(k)){setVal(el,D.wxid);return;}
        if(el.tagName==='TEXTAREA'){setVal(el,D.content);return;}
      });
      [].slice.call(document.querySelectorAll('select')).forEach(function(s){
        var k=lab(s);
        if(/platform/.test(k)){choose(s,/ios|iphone/);return;}
        if(/contact/.test(k)){choose(s,/email/);return;}
        if(/categor/.test(k)){choose(s,/account security|account/);return;}
      });
      if(typeof D.wxid==='undefined'){D.wxid='';}
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
