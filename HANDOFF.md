# Project Handoff

## Project

- Name: `selection-translator`
- Local path: `/Users/sengo/Projects/selection-translator`
- GitHub: [huacius/selection-translator](https://github.com/huacius/selection-translator)

## Product Goal

一个极简的 macOS 划词翻译工具，重点服务英文阅读与学习场景。

核心目标：

- 在任意应用中选中文本后，用全局快捷键触发翻译
- 使用可配置的 OpenAI 兼容 LLM 接口
- 对英文单词和短语展示英式/美式音标与发音
- 弹层极简，适合边读边查
- 支持收藏词条

明确不做大而全：

- 不做截图翻译
- 不做整页翻译
- 不做账号体系
- 不做复杂历史记录系统

## Current State

当前已经可用，并已发布到 GitHub。

已完成：

- 菜单栏应用
- 全局快捷键
- 划词抓取
- LLM 翻译
- 发音按钮
- 英/美音标展示
- 收藏功能
- 设置页
- About 页
- GitHub 仓库
- GitHub Release 附件

当前默认：

- 默认快捷键：`Command+E`
- 默认 `IPA`：关闭

## Pronunciation Strategy

音标与发音策略已经定稿：

### IPA 开启时

- 只显示词典查到的标准 IPA
- 查不到就不显示
- 不让 LLM 补 IPA

### IPA 关闭时

- 不显示标准 IPA
- 由 LLM 在翻译结果中一次性返回更常见的英式/美式学习音标
- 使用方括号样式

### 发音

- 优先词典音频
- 没有词典音频时，系统朗读兜底
- 不让 LLM 参与发音生成

## Permission Flow

授权相关行为已经统一：

- `重置授权`：只重置，不自动打开系统设置
- 菜单 / 设置页 / 翻译页 的“去授权”行为已统一
- 授权完成后，菜单 / 设置 / 翻译页状态会自动刷新

注意：

- 当前仍是 ad-hoc 打包
- 重新打包后，辅助功能授权可能失效
- 正式解决方案是后续接入 Apple Developer 签名与 notarization

## UI / UX Decisions

### Result Popup

- 点击弹层外区域关闭
- 无复制按钮，支持手动选中复制
- 保留刷新按钮
- 收藏星标保留
- 尽量贴近选中文字附近弹出

### Long Content

长内容弹层已做这些处理：

- 适当加宽
- 限制最大高度
- 内容区超出时可滚动
- 长原文支持 `展开原文 / 收起原文`
- 展开的完整原文放在译文上面

### Dark Mode

这些页面已经适配明暗模式：

- 菜单
- 翻译弹层
- 收藏页
- About 页

原则：

- 不做“半浅半深”的混搭
- 明暗模式分别使用明确配色

## Release State

已发布：

- GitHub repo 已建立
- Release 已建立：`v0.1.0`
- `.app.zip` 已作为 Release 附件上传

版本统一来源：

- 文件：`/Users/sengo/Projects/selection-translator/VERSION`

当前分发链路补充状态：

- 已补本地打包增强：`scripts/package-app.sh`
- 已新增 notarization 脚本：`scripts/notarize-app.sh`
- 已新增发布说明：`docs/release.md`
- `package-app.sh` 现在会：
  - 自动生成 `.app.zip`
  - 做 `codesign` 校验
  - 做 `spctl` 检查
  - 在 SwiftPM 因旧路径缓存导致 release build 失败时，自动清理 `.build` 后重试一次

当前决策：

- 因当前没有 Apple Developer Program 账号，先不继续做正式签名 / notarization / Homebrew Cask
- 下次恢复这条线时，优先参考：
  - `/Users/sengo/Projects/selection-translator/scripts/package-app.sh`
  - `/Users/sengo/Projects/selection-translator/scripts/notarize-app.sh`
  - `/Users/sengo/Projects/selection-translator/docs/release.md`
- 在没有开发者账号期间，继续使用本地 ad-hoc 打包做迁移和功能验证

## Files Worth Reading First

建议新会话先读这些文件：

1. `/Users/sengo/Projects/selection-translator/HANDOFF.md`
2. `/Users/sengo/Projects/selection-translator/README.md`
3. `/Users/sengo/Projects/selection-translator/Sources/SelectionTranslator/AppState.swift`
4. `/Users/sengo/Projects/selection-translator/Sources/SelectionTranslator/Views.swift`
5. `/Users/sengo/Projects/selection-translator/Sources/SelectionTranslator/SelectionTranslatorApp.swift`
6. `/Users/sengo/Projects/selection-translator/Sources/SelectionTranslator/TranslationService.swift`
7. `/Users/sengo/Projects/selection-translator/Sources/SelectionTranslator/DictionaryService.swift`
8. `/Users/sengo/Projects/selection-translator/scripts/package-app.sh`

## Recommended Next Steps

优先级建议：

1. 先继续验证本地迁移后的 ad-hoc 包是否稳定
2. Apple Developer Program
3. Developer ID 签名
4. notarization
5. Homebrew Cask

不建议当前继续扩太多功能，先把分发链路做好。

## Notes For New Codex Chat

如果在新窗口继续，建议先说：

“先阅读 `HANDOFF.md`，理解项目当前状态后继续。正式分发链路的脚本已经补到一半，但因为目前没有开发者账号，先暂停。当前优先是继续验证本地 ad-hoc 包迁移是否稳定；等有账号后，再继续签名 / notarization / Homebrew Cask。”
