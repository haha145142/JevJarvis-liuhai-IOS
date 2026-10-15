import Foundation

/// 便利属性：去掉两端空白和换行。项目里反复用到，统一在这里定义。
extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - 狗头军师大脑（移植自 goutou-keyboard-ios，接在 Jev 的简单界面后面）
//
// 这层只负责「拼什么话给模型」，不碰 UIKit、不联网：
//   - systemPrompt：军师人格（GoutouSkill.md）+ 一段 JSON 输出契约
//   - userMessage：把剪贴板自动拆出的带说话人段落拼成 `对方：…` / `我：…`
// 网络请求在 GoutouBrainClient.swift，自动分段在 GoutouSegmentBuilder.swift。

/// 一段对话的归属（沿用 skill 里写死的「对方 / 我 / 背景」）。
enum GoutouSpeaker: String {
    case opponent
    case me
    case background

    var promptLabel: String {
        switch self {
        case .opponent: return "对方"
        case .me: return "我"
        case .background: return "背景"
        }
    }
}

struct GoutouSegment: Equatable {
    let speaker: GoutouSpeaker
    let text: String
}

/// 军师一次分析的完整结果。
struct GoutouBrainResult: Equatable {
    /// relationship 的第一句（≤20 字），结果页头部那行「人话判断」。
    let headline: String
    let meaning: String
    let relationship: String
    /// 6~8 条可直接发送的成品回复。
    let replies: [String]
    let reason: String
}

enum GoutouBrain {

    /// 一次给多少条回复。skill 里写 2~3 条，这里按 6~8 条要，并要求角度拉开。
    static let minReplies = 6
    static let maxReplies = 8
    static let headlineLimit = 20

    /// 写死成狗头军师面板的默认值（简化界面不放任务/风格选择器）。
    static let task = "分析她/他说什么意思"
    static let tone = "自然"

    static func systemPrompt(skill: String) -> String {
        let contract = """
        仅返回 JSON 对象，不要 Markdown 或代码围栏。字段：meaning（对方可能的意思）、\
        relationship（关系/氛围分析）、replies（\(minReplies)～\(maxReplies) 条可直接发送的中文成品字符串，\
        按推荐顺序排列，角度要拉开：几条稳稳接住、几条稍微推进、几条直接问清楚，\
        不要一堆同义改写）、reason（回复理由）。\
        relationship 的第一句必须是一句不超过 \(headlineLimit) 字的判断（例如「对方在试探你会不会主动」），\
        后面再展开依据。无法确定时明确说明。
        """
        return [
            skill.trimmed,
            "当前任务：\(task)。回复风格：\(tone)。",
            contract,
        ].joined(separator: "\n\n")
    }

    /// 把几段带说话人的内容拼成 skill 认得的格式：`对方：…` / `我：…` / `背景：…`。
    /// `extraRequirement` 附在最后——离答案最近的一句，模型最听。
    static func userMessage(
        segments: [GoutouSegment],
        extraRequirement: String? = nil
    ) -> String {
        let body = segments
            .map { "\($0.speaker.promptLabel)：\($0.text.trimmed)" }
            .filter { $0.count > 3 }
            .joined(separator: "\n")
        var sections: [String] = ["聊天内容：\n\(body)"]
        if let extraRequirement = extraRequirement, !extraRequirement.trimmed.isEmpty {
            sections.append(extraRequirement.trimmed)
        }
        return sections.joined(separator: "\n\n")
    }

    /// 放在最后「再强调一次」的要求，模型才会给够条数、并通读整段话。
    static var replyRequirement: String {
        "本次要求：先通读并按顺序回应全部句子（不要只回最后一句）；replies 给 \(minReplies)～\(maxReplies) 条可直接发送的成品，角度拉开；不要把候选压到 2～3 条。"
    }

    /// 只取 relationship 的第一句，超过 20 字就截断加省略号。
    static func headline(fromRelationship text: String) -> String {
        let flattened = text.trimmed.replacingOccurrences(of: "\n", with: " ")
        guard !flattened.isEmpty else { return "" }

        var sentence = flattened
        for mark in ["。", "！", "？", "；", "!", "?", ";", "."] {
            guard let range = flattened.range(of: mark) else { continue }
            let candidate = String(flattened[flattened.startIndex..<range.upperBound]).trimmed
            if !candidate.isEmpty, candidate.count < sentence.count {
                sentence = candidate
            }
        }

        if sentence.count <= headlineLimit { return sentence }
        return String(sentence.prefix(headlineLimit)) + "…"
    }
}
