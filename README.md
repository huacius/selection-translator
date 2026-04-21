# Selection Translator

一个极简的 macOS 划词翻译应用，聚焦英文阅读与学习场景。

Selection Translator is a minimal macOS selection-translation app focused on English reading and learning.

[GitHub Repository](https://github.com/huacius/selection-translator) · [Latest Release](https://github.com/huacius/selection-translator/releases/latest)

## Overview

- Translate selected text from any macOS app with a global shortcut
- Built for English reading, vocabulary lookup, pronunciation, and quick comprehension
- Uses a configurable OpenAI-compatible LLM endpoint
- Supports UK/US pronunciation display, favorites, and a lightweight popup card

## Why This Project

- Some in-browser or embedded input areas do not reliably expose selected text to existing tools
- Built-in translation in large products is often either too basic for sentence-level translation or locked behind paid AI tiers
- This project stays intentionally narrow: fast selection translation, pronunciation help, and a lightweight reading companion

## 中文介绍

特点：

- 在任意应用中先选中文本
- 按全局快捷键触发翻译，默认 `Command+E`
- 使用可配置的 OpenAI 兼容 LLM 接口
- 英文单词和短语支持英式/美式音标与发音
- 支持收藏词条
- 极简弹层展示，适合边读边查

技术方案：

- `SwiftUI + AppKit` 菜单栏应用
- `Carbon` 注册全局快捷键
- 通过辅助功能权限 + 模拟 `Cmd+C` 抓取当前选中文本
- 通过 OpenAI 兼容 `chat/completions` 接口做翻译
- 通过 `dictionaryapi.dev` 补充英语词条音标和音频

运行：

```bash
cd /Users/sengo/sengo/codex/selection-translator
swift build
swift run SelectionTranslator
```

打包 `.app`：

```bash
cd /Users/sengo/sengo/codex/selection-translator
chmod +x scripts/package-app.sh
./scripts/package-app.sh
open "dist/Selection Translator.app"
```

推荐安装方式：

1. 从 [Latest Release](https://github.com/huacius/selection-translator/releases/latest) 下载 `.app.zip`
2. 解压后把 `Selection Translator.app` 移到 `Applications`
3. 首次打开后完成权限和接口配置

GitHub 发布建议：

- 仓库里提交源码、脚本和 README 即可
- `dist/` 是本地打包产物，默认不建议提交
- `Selection Translator.app` 更适合作为 GitHub Release 附件，而不是直接放进仓库

首次使用：

1. 在设置页填写 `API Endpoint`、`API Key`、`Model`
2. 根据需要设置快捷键，默认是 `Command+E`
3. 为应用开启 macOS “辅助功能”权限
4. 在任意应用中选中文本后按快捷键翻译

权限排障：

- 如果“辅助功能授权”没有成功，或应用没有出现在授权列表里，请先使用菜单里的 `重置授权`
- 重置后，再点击菜单、设置页或翻译页中的“去授权”重新走一遍授权流程
- 如果授权状态看起来不对，回到应用后等 1 到 2 秒，状态会自动刷新
- 如果还是没有成功，请先完全退出应用，再重新打开后重试

当前限制：

- 当前采用“模拟复制 + 读取剪贴板”的方式抓取选中文本，兼容性高，但部分受限应用可能抓不到
- 开启 `IPA` 时，只显示词典查到的标准 IPA；关闭 `IPA` 时，显示更常见的英式/美式学习音标
- 音标和发音目前对英文单词、短语效果最好；长句更多还是以翻译为主
- 发音优先使用词典音频，拿不到时回退到系统朗读
- 重新打包后的 ad-hoc 签名版本，可能需要重新授权辅助功能

## English

Selection Translator is a lightweight macOS menu bar app for translating selected text, with a strong focus on English reading and vocabulary learning.

Features:

- Select text in any app
- Trigger translation with a global shortcut, default `Command+E`
- Use any configurable OpenAI-compatible LLM endpoint
- Show UK/US pronunciation hints and audio for English words and short phrases
- Favorite useful entries
- Minimal popup UI for fast lookup while reading

Architecture:

- `SwiftUI + AppKit` menu bar app
- `Carbon` for global hotkey registration
- Accessibility permission + simulated `Cmd+C` for selection capture
- OpenAI-compatible `chat/completions` for translation
- `dictionaryapi.dev` for pronunciation and audio lookup

Run locally:

```bash
cd /Users/sengo/sengo/codex/selection-translator
swift build
swift run SelectionTranslator
```

Build a local `.app` bundle:

```bash
cd /Users/sengo/sengo/codex/selection-translator
chmod +x scripts/package-app.sh
./scripts/package-app.sh
open "dist/Selection Translator.app"
```

Recommended installation:

1. Download the `.app.zip` from [Latest Release](https://github.com/huacius/selection-translator/releases/latest)
2. Unzip and move `Selection Translator.app` into `Applications`
3. Launch it once and complete permission and API setup

Suggested GitHub publishing workflow:

- Commit source files, scripts, and documentation
- Do not commit `dist/` by default
- Upload `Selection Translator.app` as a GitHub Release asset if you want to share a test build

Getting started:

1. Fill in `API Endpoint`, `API Key`, and `Model` in Settings
2. Set your preferred shortcut if needed; the default is `Command+E`
3. Grant macOS Accessibility permission
4. Select text in any app and press the shortcut

Accessibility troubleshooting:

- If Accessibility authorization does not succeed, or the app does not appear in the permission list, use `Reset Permission` first
- Then try the authorization flow again from the menu, Settings page, or translation popup
- If the permission status looks stale, return to the app and wait 1 to 2 seconds for automatic refresh
- If it still fails, fully quit the app and try again

Current limitations:

- Selection capture currently relies on simulated copy + clipboard restore, which works well in many apps but may fail in restricted environments
- When `IPA` is enabled, the app only shows dictionary-backed IPA; when `IPA` is disabled, it shows more common UK/US learner-friendly pronunciations returned by the LLM
- Pronunciation support works best for English words and short phrases
- Dictionary audio is preferred; system speech is used as fallback
- Rebuilt ad-hoc signed app bundles may lose Accessibility permission after packaging
