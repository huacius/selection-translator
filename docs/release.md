# Release Guide

这个项目现在支持两条打包路径：

- 本地测试包：ad-hoc 签名，适合自己机器上快速验证
- 正式分发包：`Developer ID Application` 签名 + notarization，适合上传 GitHub Release 和后续接入 Homebrew Cask

## Prerequisites

正式分发前需要准备：

- Apple Developer Program 账号
- 一个可用的 `Developer ID Application` 证书
- 已安装 Xcode Command Line Tools，并且可用 `xcrun`
- 一种 notarytool 鉴权方式：
  - 推荐：`KEYCHAIN_PROFILE`
  - 备选：`APPLE_ID` + app-specific password + `TEAM_ID`

## 1. Build A Local Test App

```bash
./scripts/package-app.sh
```

输出：

- `dist/Selection Translator.app`
- `dist/Selection Translator.app.zip`

说明：

- 未设置 `CODESIGN_IDENTITY` 时会自动使用 ad-hoc 签名
- ad-hoc 包适合本地测试，不适合正式分发

## 2. Build A Signed Distribution App

先确认本机可看到正确证书：

```bash
security find-identity -v -p codesigning
```

然后执行：

```bash
export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
./scripts/package-app.sh
```

这个流程会：

- 构建 release 二进制
- 生成 `.app`
- 使用 hardened runtime + timestamp 签名
- 做 `codesign` 校验
- 生成 zip 归档

## 3. Notarize The Signed App

推荐先把 notarytool profile 存进钥匙串：

```bash
xcrun notarytool store-credentials "selection-translator-notary" \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID" \
  --password "YOUR_APP_SPECIFIC_PASSWORD"
```

然后执行：

```bash
export KEYCHAIN_PROFILE="selection-translator-notary"
./scripts/notarize-app.sh
```

如果不使用钥匙串 profile，也可以直接传环境变量：

```bash
export APPLE_ID="YOUR_APPLE_ID"
export APPLE_APP_PASSWORD="YOUR_APP_SPECIFIC_PASSWORD"
export TEAM_ID="YOUR_TEAM_ID"
./scripts/notarize-app.sh
```

这个流程会：

- 提交 `dist/Selection Translator.app.zip` 到 Apple notarization
- 等待结果返回
- 对 `.app` 执行 `stapler staple`
- 用 `stapler validate` 和 `spctl` 做最终校验

## 4. Publish Release Asset

建议上传这个文件到 GitHub Release：

- `dist/Selection Translator.app.zip`

如果已经 notarize 并且 staple 成功，zip 里的 `.app` 会带上 stapled ticket。

## 5. Homebrew Cask Readiness

要接 Homebrew Cask，至少需要这些条件：

- 稳定仓库名和 release tag 约定
- 可复现的 `.app.zip` 发布产物
- 正式签名 + notarization 完成
- 固定下载 URL 和 `sha256`

建议顺序：

1. 先把签名和 notarization 流程跑通
2. 再固定 release 命名
3. 最后新增 Cask 仓库或向已有 tap 提交
