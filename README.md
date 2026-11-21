# 牛头 BullTroll

基于 SwiftUI 的 iOS 小工具，打包成未签名 IPA，可直接用 **TrollStore（巨魔）** 安装。

- 最低系统：iOS 15.0（arm64）
- 未签名，不需要证书、不需要 Apple ID，由 TrollStore 自行签名安装
- 图标为牛头 logo

## 功能

首页展示设备信息（机型、系统版本、架构、是否检测到 TrollStore），并支持一键复制。

## 安装

1. 打开 [Releases](../../releases) 页面，下载最新的 `BullTroll.ipa`
2. 在 TrollStore 中点击右上角 `+` → 选择 `Install IPA File` → 选中下载好的 ipa
3. 装好后点击图标启动

也可以在 TrollStore 里用 `Install from URL` 粘贴 Release 里 ipa 的直链。

## 自行构建

推送到 `main` 分支会自动触发 GitHub Actions：macOS runner 上用 `swiftc` 直接编译出 arm64 二进制，打包成 `Payload/BullTroll.app` → `BullTroll.ipa`，并发布到 Release。

本地编译（macOS）：

```bash
SDK=$(xcrun --sdk iphoneos --show-sdk-path)
mkdir -p build/Payload/BullTroll.app
xcrun --sdk iphoneos swiftc -parse-as-library -target arm64-apple-ios15.0 \
  -sdk "$SDK" -O Sources/BullTrollApp.swift -o build/Payload/BullTroll.app/BullTroll
cp Assets/Info.plist Assets/Icons/*.png Assets/logo.png build/Payload/BullTroll.app/
cd build && zip -qry BullTroll.ipa Payload
```

## 目录

```
Sources/BullTrollApp.swift      应用源码
Assets/Info.plist               应用配置
Assets/Icons/*.png              App 图标（多尺寸）
Assets/logo.png                 应用内 logo
.github/workflows/build.yml     自动构建 + 发布 IPA
```
