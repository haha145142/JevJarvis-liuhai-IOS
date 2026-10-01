import Foundation

// 跨平台垫片：autoreleasepool 是 Objective-C 运行时能力，仅 Apple 平台提供；
// Linux 上做类型检查时用一个直接执行的等价物（无操作池），不影响真机逻辑。
#if !canImport(ObjectiveC)
@discardableResult
func autoreleasepool<T>(_ body: () throws -> T) rethrows -> T { try body() }
#endif

// MARK: - 配置模型

/// 生成层 API 形状。key 所在的组决定请求形状（与 macOS 版同一规则）。
enum APIKind: String, Codable, CaseIterable, Identifiable {
    case openai
    case anthropic

    var id: String { rawValue }
    var label: String {
        switch self {
        case .openai: return "OpenAI 兼容（/chat/completions）"
        case .anthropic: return "Anthropic 兼容（/v1/messages）"
        }
    }
}

struct ProviderPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let kind: APIKind
    let base: String
    let model: String
    let keyHint: String

    /// DeepSeek 国内直连、智谱 glm-4-flash、OpenRouter、通义与本地 Ollama。
    static let all: [ProviderPreset] = [
        .init(id: "zhipu", name: "智谱（glm-4-flash）", kind: .openai,
              base: "https://open.bigmodel.cn/api/paas/v4", model: "glm-4-flash", keyHint: "open.bigmodel.cn 的 API Key"),
        .init(id: "deepseek", name: "DeepSeek 官方", kind: .openai,
              base: "https://api.deepseek.com", model: "deepseek-chat", keyHint: "platform.deepseek.com 的 sk-…"),
        .init(id: "openrouter", name: "OpenRouter", kind: .openai,
              base: "https://openrouter.ai/api/v1", model: "deepseek/deepseek-chat-v3.1", keyHint: "sk-or-…"),
        .init(id: "dashscope", name: "阿里通义（兼容模式）", kind: .openai,
              base: "https://dashscope.aliyuncs.com/compatible-mode/v1", model: "qwen-flash", keyHint: "sk-…"),
        .init(id: "moonshot", name: "月之暗面 Kimi", kind: .openai,
              base: "https://api.moonshot.cn/v1", model: "moonshot-v1-8k", keyHint: "sk-…"),
        .init(id: "siliconflow", name: "硅基流动", kind: .openai,
              base: "https://api.siliconflow.cn/v1", model: "Qwen/Qwen2.5-7B-Instruct", keyHint: "sk-…"),
        .init(id: "ollama", name: "Ollama（Mac 局域网）", kind: .openai,
              base: "http://127.0.0.1:11434/v1", model: "qwen2.5:7b", keyHint: "随便填，如 ollama"),
        .init(id: "custom", name: "自定义…", kind: .openai, base: "", model: "", keyHint: ""),
    ]
}

/// 判断层预设。Jev native 在 waitlist，网关同形状只换地址+模型+key。
struct JudgePreset: Identifiable, Hashable {
    let id: String
    let name: String
    let base: String
    let model: String
    let keyHint: String

    static let all: [JudgePreset] = [
        .init(id: "typesafe", name: "TypeSafe 直连",
              base: "https://api.typesafe.ai", model: "jev-latest",
              keyHint: "api.typesafe.ai 的 key"),
        .init(id: "openrouter", name: "OpenRouter 网关",
              base: "https://openrouter.ai/api/alpha/decisions", model: "typesafe/jev-1.13",
              keyHint: "OpenRouter 的 sk-or-…"),
        .init(id: "vercel", name: "Vercel AI Gateway",
              base: "https://ai-gateway.vercel.sh/v1/evaluate", model: "typesafe-ai/jev",
              keyHint: "Vercel AI Gateway 的 key"),
        .init(id: "custom", name: "自定义…", base: "", model: "", keyHint: ""),
    ]
}

/// 生成层实际生效的那一组。URL / key / 模型同源，不跨来源混搭——
/// 混搭就是拿 A 家的 key 调 B 家的端点，换来一个看不懂的 401。
struct GenCredentials {
    var kind: APIKind
    var base: String
    var key: String
    var model: String
    var extraJSON: String
}

/// 话术槽安全上限。槽位可自由增减、可全选；为保证键盘稳定（并发起请求的内存压力），
/// 设一个较高的硬上限 12（×2 条 = 最多 24 条候选，面板可滚动）。
let MAX_SLOTS = 12

/// 全部配置。存 App Group，键盘扩展与主 App 共享同一份。
struct JevConfig: Codable, Equatable {
    // 生成层（必须配置自己的服务地址、API Key 和模型）
    var genKind: APIKind = .openai
    var genBase: String = "https://open.bigmodel.cn/api/paas/v4"
    var genKey: String = ""
    var genModel: String = "glm-4-flash"
    /// 额外请求体字段（JSON），端点要靠额外字段关思考模式时填，如 {"enable_thinking":false}
    var genExtraJSON: String = ""

    // 判断层（Jev：意图 + 风险 + 排序，核心判断引擎）。
    // 没配 key 时管线自动退化为「盲起草」——只出候选、无意图/风险，运行时兜底而非配置开关。
    var judgeBase: String = "https://api.typesafe.ai"
    var judgeKey: String = ""
    var judgeModel: String = "jev-latest"

    /// 话术槽位。空串 = 不用（与 macOS 版 NONE_LABEL 同语义）。最多 3 槽。
    /// 三个名字都必须是 BUILTIN_TONES 里真实存在的话术；早期融合版第三个槽写的是
    /// 「轻松版」，它并不是内置话术（compactMap 时被丢弃，第三槽等于白开），已改为「情绪价值」。
    var slots: [String] = ["高情商话术", "稳如老狗", "情绪价值"]

    /// 用户自定义话术（名字 = 说明），同名覆盖内置。
    var customTones: [String: String] = [:]

    /// 内置恋爱知识库（狗头军师 · 恋爱大师）开关。默认开启：每次分析自动携带
    /// 「先接住情绪 → 分清事实 → 给下一步 → 停止条件」到判断层与生成层。
    /// 用可选项是为了兼容旧存档：老配置没有这个键，解码缺键时保持 nil（= 默认开启），
    /// 不会因为新增字段把整份配置重置掉。
    var builtinSkillsEnabled: Bool? = nil

    /// 实际生效值（nil = 老存档，视为开启）。
    var skillsOn: Bool { builtinSkillsEnabled ?? true }

    /// 实际生效槽位：去空、去重（保持首次出现顺序），再套安全上限。
    var activeSlots: [String] {
        var seen = Set<String>()
        let kept = slots.filter { !$0.isEmpty }.filter { seen.insert($0).inserted }
        return Array(kept.prefix(MAX_SLOTS))
    }

    /// 生成层凭据完全来自用户配置，不会回退到项目提供的服务。
    var generation: GenCredentials {
        GenCredentials(kind: genKind, base: genBase, key: genKey,
                       model: genModel, extraJSON: genExtraJSON)
    }
}

/// 键盘侧回写的运行状态，主 App 的引导页用它判断「键盘装没装、全访问给没给」。
struct KeyboardStatus: Codable, Equatable {
    var lastSeen: Date
    var hasFullAccess: Bool
}

// MARK: - App Group 存储

/// 配置与状态的唯一存放点。键值放 App Group UserDefaults：
/// 键盘扩展只有拿到「允许完全访问」后才能读共享容器，正好与联网条件一致。
enum JevStore {
    static let appGroupID = "group.com.jevchat.jarvis"
    private static let configKey = "jev.config.v1"
    private static let removedGenerationBase = "http://101.132.131.220:11111/v1"
    private static let statusKey = "jev.kbstatus.v1"
    private static let canaryKey = "jev.canary.v1"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    /// App Group 容器是否真的可写可读（签名没带上 entitlement 时 suite 会静默退化为私有容器）。
    static var groupWritable: Bool {
        let stamp = "t\(Date().timeIntervalSince1970)"
        defaults.set(stamp, forKey: canaryKey)
        return defaults.string(forKey: canaryKey) == stamp
    }

    /// 旧存档归一化：把历史上无效的话术名替换成等价的内置话术，避免某个槽位静默失效。
    private static func normalize(_ cfg: JevConfig) -> JevConfig {
        var cfg = cfg
        let legacyMap: [String: String] = ["轻松版": "情绪价值"]
        cfg.slots = cfg.slots.map { legacyMap[$0] ?? $0 }
        return cfg
    }

    static func loadConfig() -> JevConfig {
        guard let data = defaults.data(forKey: configKey),
              var cfg = try? JSONDecoder().decode(JevConfig.self, from: data) else {
            return normalize(JevConfig())
        }
        cfg = normalize(cfg)
        if cfg.genBase == removedGenerationBase {
            let preset = ProviderPreset.all.first { $0.id == "zhipu" }
            cfg.genKind = preset?.kind ?? .openai
            cfg.genBase = preset?.base ?? ""
            cfg.genKey = ""
            cfg.genModel = preset?.model ?? ""
            cfg.genExtraJSON = ""
            saveConfig(cfg)
        }
        return cfg
    }

    static func saveConfig(_ cfg: JevConfig) {
        if let data = try? JSONEncoder().encode(cfg) {
            defaults.set(data, forKey: configKey)
        }
    }

    static func loadKeyboardStatus() -> KeyboardStatus? {
        guard let data = defaults.data(forKey: statusKey),
              let s = try? JSONDecoder().decode(KeyboardStatus.self, from: data) else { return nil }
        return s
    }

    static func saveKeyboardStatus(_ s: KeyboardStatus) {
        if let data = try? JSONEncoder().encode(s) {
            defaults.set(data, forKey: statusKey)
        }
    }

    /// 密钥展示用掩码
    static func masked(_ key: String) -> String {
        guard !key.isEmpty else { return "（未配置）" }
        if key.count <= 8 { return String(repeating: "•", count: max(key.count - 2, 2)) + String(key.suffix(2)) }
        return String(key.prefix(4)) + "…" + String(key.suffix(4))
    }

#if DEBUG
    private static let diagKey = "jev.diag.v1"

    /// 键盘侧自检日志。键盘扩展连不上 Xcode 看控制台，所以写进 App Group，
    /// 再用 `xcrun devicectl device copy from --domain-type appGroupDataContainer` 拉出来看。
    static func diag(_ line: String) {
        let stamp = String(format: "%.3f", Date().timeIntervalSince1970)
        let prev = defaults.string(forKey: diagKey) ?? ""
        defaults.set(String((prev + "[\(stamp)] \(line)\n").suffix(6000)), forKey: diagKey)
    }
#endif
}

// MARK: - 键盘本地配置兜底（App Group 不可共享时）

/// 自签 / 全能签等重签环境下，App Group 可能不共享（App 里配置测试都成功，
/// 但键盘读不到——两个进程各落各的容器）。此时键盘在面板上直接填一份
/// 「键盘本地配置」，存在键盘自己的 UserDefaults.standard 里，与 App Group
/// 完全无关、永远可读可写。App 侧的配置原样保留，互不覆盖。
extension JevStore {
    private static let keyboardLocalKey = "jev.keyboard-local.v1"

    struct KeyboardLocalConfig: Codable, Equatable {
        var genBase: String = ""
        var genKey: String = ""
        var genModel: String = ""
        var judgeBase: String = ""
        var judgeKey: String = ""
        var judgeModel: String = ""
    }

    static func loadKeyboardLocal() -> KeyboardLocalConfig {
        guard let data = UserDefaults.standard.data(forKey: keyboardLocalKey),
              let c = try? JSONDecoder().decode(KeyboardLocalConfig.self, from: data) else {
            return KeyboardLocalConfig()
        }
        return c
    }

    static func saveKeyboardLocal(_ c: KeyboardLocalConfig) {
        if let data = try? JSONEncoder().encode(c) {
            UserDefaults.standard.set(data, forKey: keyboardLocalKey)
        }
    }

    /// 键盘实际生效的配置：以 App Group 共享配置为底，键盘本地字段**整组非空**时覆盖
    /// （生成层三个字段都填了才覆盖生成层，判断层同理——避免半填状态混用两端）。
    static func mergedConfigForKeyboard() -> JevConfig {
        var cfg = loadConfig()
        let local = loadKeyboardLocal()
        if !local.genKey.isEmpty && !local.genBase.isEmpty && !local.genModel.isEmpty {
            cfg.genBase = local.genBase
            cfg.genKey = local.genKey
            cfg.genModel = local.genModel
        }
        if !local.judgeKey.isEmpty && !local.judgeBase.isEmpty && !local.judgeModel.isEmpty {
            cfg.judgeBase = local.judgeBase
            cfg.judgeKey = local.judgeKey
            cfg.judgeModel = local.judgeModel
        }
        return cfg
    }

    /// App 侧「复制配置到剪贴板」：编码一份键盘能直接导入的 JSON（剪贴板是系统级共享，
    /// 与 App Group 无关——自签/全能签环境下的第二通道）。
    static func clipboardConfigJSON(from cfg: JevConfig) -> String? {
        let c = KeyboardLocalConfig(genBase: cfg.genBase, genKey: cfg.genKey, genModel: cfg.genModel,
                                    judgeBase: cfg.judgeBase, judgeKey: cfg.judgeKey, judgeModel: cfg.judgeModel)
        guard let data = try? JSONEncoder().encode(c) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 键盘侧「从剪贴板导入配置」：解析 App 复制来的 JSON；**整组字段都非空**才接受，
    /// 避免半填数据污染键盘本地配置。
    static func clipboardConfig(from text: String) -> KeyboardLocalConfig? {
        guard let data = text.data(using: .utf8),
              let c = try? JSONDecoder().decode(KeyboardLocalConfig.self, from: data) else { return nil }
        let ok = !c.genKey.isEmpty && !c.genBase.isEmpty && !c.genModel.isEmpty
            && !c.judgeKey.isEmpty && !c.judgeBase.isEmpty && !c.judgeModel.isEmpty
        return ok ? c : nil
    }
}

// MARK: - 多消息上下文（iOS 键盘读不到整屏，只能靠"累积/粘贴"得到上下文）
//
// iOS 自定义键盘没有 Android 那种无障碍读屏能力，拿不到聊天窗口里的历史消息。
// 它能拿到的只有：① 剪贴板（用户长按复制）；② 当前输入框里已有的文字。
// 所以"结合上下文"在 iOS 上的做法是：让用户把前面的消息一条条（或一次多行）
// 加进一个滚动的上下文缓冲，分析最新消息时把缓冲一并喂给判断层和生成层。
// 缓冲持久化，键盘重新唤起仍在；上限 12 条 / 1800 字，避免 prompt 过长。

struct ContextTurn: Codable, Equatable {
    /// "对方" 或 "我"
    var role: String
    var text: String
}

enum JevContext {
    private static let storageKey = "jev.context.v1"
    static let maxTurns = 12
    static let maxChars = 1800

    static let roleOther = "对方"
    static let roleMe = "我"

    /// 与配置同放一个存储点：App Group 共享时两端都能读；自签导致 App Group 不共享时，
    /// 键盘进程内仍持久化（上下文本来就是键盘侧使用）。
    private static var store: UserDefaults { JevStore.defaults }

    static func load() -> [ContextTurn] {
        guard let data = store.data(forKey: storageKey),
              let turns = try? JSONDecoder().decode([ContextTurn].self, from: data) else { return [] }
        return clamp(turns)
    }

    static func save(_ turns: [ContextTurn]) {
        if let data = try? JSONEncoder().encode(clamp(turns)) {
            store.set(data, forKey: storageKey)
        }
    }

    static func clear() { store.removeObject(forKey: storageKey) }

    static var count: Int { load().count }

    /// 追加一条；同角色、同内容的连续重复自动忽略。
    static func append(role: String, text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        var turns = load()
        if let last = turns.last, last.role == role, last.text == t { return }
        turns.append(ContextTurn(role: role, text: t))
        save(turns)
    }

    /// 一次追加多条（用于多行粘贴）。
    static func appendMany(role: String, texts: [String]) {
        var turns = load()
        for raw in texts {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { continue }
            if let last = turns.last, last.role == role, last.text == t { continue }
            turns.append(ContextTurn(role: role, text: t))
        }
        save(turns)
    }

    /// 条数与总字数双上限：先按条数保留最近 N 条，再从头删到总字数达标。
    static func clamp(_ turns: [ContextTurn]) -> [ContextTurn] {
        var arr = Array(turns.suffix(maxTurns))
        var total = arr.reduce(0) { $0 + $1.text.count }
        while total > maxChars, !arr.isEmpty {
            total -= arr.removeFirst().text.count
        }
        return arr
    }

    /// 渲染成模型可读的上下文文本（带说话人）。
    static func promptBlock(_ turns: [ContextTurn], language: JevLanguage) -> String {
        if language == .english {
            return turns.map { ($0.role == roleMe ? "User (me)" : "The other person") + ": " + $0.text }
                .joined(separator: "\n")
        }
        return turns.map { $0.role + "：" + $0.text }.joined(separator: "\n")
    }

    /// 单行最大长度：复制到超长段落（或非聊天内容）时截断，避免后续 prompt/内存暴涨。
    static let lineCap = 500

    /// 把一段复制来的文本按行拆成多条；每行截断到 lineCap，过滤空行。
    static func lines(from blob: String) -> [String] {
        return blob
            .components(separatedBy: .newlines)
            .map { String($0.trimmingCharacters(in: .whitespaces).prefix(lineCap)) }
            .filter { !$0.isEmpty }
    }
}

/// 剪贴板读取的总长度上限（字符）。键盘只处理聊天文本，超出截断，杜绝大内容触发 jetsam。
let CLIPBOARD_MAX_CHARS = 6000
