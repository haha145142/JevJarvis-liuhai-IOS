import Foundation

// MARK: - 剪贴板自动分段（替代狗头军师面板里的手动「对方/我/背景」按钮）
//
// 简化交互：用户长按「对方」的消息 → 复制，这里把复制来的文本
//   ① 先按换行拆成多行（一次复制多条消息时）
//   ② 每行再按句末标点（。！？!?…）拆成句子
// 全部标成「对方」，最后一句就是要回复的最新消息。
// 这样模型拿到的是一段逐句编号的对话，会通读全部内容，而不是只回最后一句。
//
// 前提假设：复制来的内容是聊天对象说的（主路径，也是 Jev 文档里的用法）。
// 如果要混合双方历史，可用 App 侧/键盘侧的上下文功能（高级用法），主流程不需要。

enum GoutouSegmentBuilder {

    /// 单条句子/行的最大长度，超长截断，避免一段非聊天长文撑爆 prompt。
    static let segmentCap = 300

    /// 一段剪贴板文本 → 有序「对方」段落。
    static func segments(from raw: String) -> [GoutouSegment] {
        var out: [GoutouSegment] = []
        let lines = raw.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmed
            guard !trimmedLine.isEmpty else { continue }
            for sentence in sentences(in: trimmedLine) {
                let capped = String(sentence.prefix(segmentCap))
                if !capped.trimmed.isEmpty {
                    out.append(GoutouSegment(speaker: .opponent, text: capped))
                }
            }
        }
        return out
    }

    /// 把一行拆成句子（保留标点）；没有句末标点时整行作为一句。
    static func sentences(in text: String) -> [String] {
        let terminators: Set<Character> = ["。", "！", "？", "!", "?", "…"]
        var result: [String] = []
        var current = ""

        for ch in text {
            current.append(ch)
            // 省略号不单独断句：它通常不是一句的结束。
            if terminators.contains(ch), ch != "…" {
                let s = current.trimmed
                if !s.isEmpty { result.append(s) }
                current = ""
            }
        }
        let tail = current.trimmed
        if !tail.isEmpty { result.append(tail) }

        return result.isEmpty ? [text.trimmed] : result
    }
}
