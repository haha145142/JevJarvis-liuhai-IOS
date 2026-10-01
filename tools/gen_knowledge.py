#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 Shared/JevKnowledge.swift：狗头军师文献库（知识20篇 + 精选实战10篇）。
数据来源：shengjidaguai-china/goutoujunshi (MIT) references/。勿手改产物。"""
import os, re, sys

REPO = "/home/user/Doubao/chats/36146384345357058/goutoujunshi/references"
OUT = "/home/user/Doubao/chats/36146384345357058/jev-chat-jarvis-ios/Shared/JevKnowledge.swift"

TAGS = {
    # knowledge/20
    "01-证据分级与内容边界.md": ["事实", "推测", "未知", "证据", "边界"],
    "02-亲密关系心理学总论.md": ["亲密", "回应性", "尊重", "可靠", "关心"],
    "03-依恋理论与情绪调节.md": ["依恋", "焦虑", "回避", "安全感", "追"],
    "04-MBTI人格与匹配.md": ["mbti", "人格", "性格"],
    "05-PUA操控与伦理替代.md": ["操控", "煤气灯", "服从测试", "贬低", "打压", "推拉", "pua"],
    "06-吸引约会与关系启动.md": ["吸引", "心动", "追求", "约会", "邀约", "第一次见", "开场白", "表白"],
    "07-沟通冲突与修复.md": ["吵架", "冲突", "修复", "冷战", "道歉", "哄", "争吵", "争论", "抬杠"],
    "08-同意边界性与亲密.md": ["同意", "上床", "亲密", "性"],
    "09-在线约会与数字关系.md": ["已读不回", "网聊", "不回消息", "忽冷忽热", "杀猪盘", "诈骗"],
    "10-恋爱哲学.md": ["恋爱", "爱情", "想你", "心动", "喜欢"],
    "11-婚姻家庭与生命周期.md": ["结婚", "离婚", "婆婆", "彩礼", "双方父母", "家务", "婚姻"],
    "12-金钱家务育儿与双方家庭.md": ["借钱", "金钱", "育儿", "家务", "钱"],
    "13-现代婚姻变迁史.md": ["婚姻", "变迁"],
    "14-社会发展与家庭变迁.md": ["社会", "家庭", "催婚"],
    "15-分手背叛与关系修复.md": ["分手", "失恋", "前任", "复合", "出轨", "背叛", "挽回", "断联"],
    "16-多元关系与反刻板印象.md": ["多偶", "开放关系", "双性恋", "同性", "跨性别", "多元"],
    "17-中国法律安全与危机转介.md": ["家暴", "跟踪", "威胁", "报警", "自杀", "暴力", "勒索", "骗钱"],
    "18-实用练习与对话卡.md": ["练习", "对话", "演练", "怎么聊"],
    "19-核心书单与论文索引.md": ["书单", "论文", "研究", "推荐"],
    "20-经典社交体系的机制、证据与风险边界.md": ["冷读", "蓝图", "自然流", "社交", "拿捏"],
    # practical/ 精选 10 篇
    "实战话术编排器：从一句回复到后续分支.md": ["怎么回", "话术", "回复", "怎么接"],
    "场景感、松弛感与社交校准：从接话到关系推进.md": ["松弛", "接话", "尴尬", "救场", "没话聊", "冷场"],
    "主动表达、第一次见面与自然接触.md": ["主动", "邀约", "约她", "约他", "第一次见", "见面"],
    "关系投入失衡：互惠判断、降级投入与退出决策.md": ["失衡", "投入", "冷淡", "降级", "退出", "忽冷忽热"],
    "万能吵架技巧：理性冲突处理指南.md": ["吵架", "争吵", "争论", "抬杠", "冷战", "发火"],
    "万能夸人的话术技巧：真诚认可的实用指南.md": ["夸", "表扬", "赞美", "夸奖"],
    "为他人提供情绪价值：温暖且有效的回应指南.md": ["情绪价值", "委屈", "难受", "烦", "心情", "哄"],
    "高情商拒绝他人：体面护边界的实用指南.md": ["拒绝", "不好意思", "不想去", "怎么拒", "难为情"],
    "废话文学回复指南：轻松应对各类场景.md": ["敷衍", "没话", "回消息", "已读乱回"],
    "聊天化被动为主动：引导互动的实用指南.md": ["被动", "尬聊", "没话聊", "接话", "冷场"],
}

MAX_BODY = 9000  # 每篇正文上限（字符），超出截断避免二进制过度膨胀

def swift_escape(s):
    out = []
    for ch in s:
        if ch == "\\": out.append("\\\\")
        elif ch == '"': out.append('\\"')
        elif ch == "\n": out.append("\\n")
        elif ch == "\r": out.append("\\r")
        elif ch == "\t": out.append("\\t")
        else: out.append(ch)
    return "".join(out)

def parse_md(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    lines = text.split("\n")
    title = ""
    for ln in lines:
        s = ln.strip()
        if s.startswith("# "):
            title = s[2:].strip()
            break
    body = "\n".join(lines)
    # 去掉标题行
    body = re.sub(r"^# .*\n?", "", body, count=1).strip()
    return title, body[:MAX_BODY]

def main():
    docs = []
    # knowledge 20 篇（按文件名排序保证稳定顺序）
    kdir = os.path.join(REPO, "knowledge")
    for fn in sorted(os.listdir(kdir)):
        if not fn.endswith(".md") or fn not in TAGS:
            continue
        title, body = parse_md(os.path.join(kdir, fn))
        docs.append(("knowledge/" + fn, fn[:-3], title, TAGS[fn], body))
    # practical 精选
    pdir = os.path.join(REPO, "practical")
    for fn in sorted(os.listdir(pdir)):
        if not fn.endswith(".md") or fn not in TAGS:
            continue
        title, body = parse_md(os.path.join(pdir, fn))
        docs.append(("practical/" + fn, fn[:-3], title, TAGS[fn], body))

    parts = []
    parts.append("// 自动生成（tools/gen_knowledge.py），勿手改。")
    parts.append("// 数据来源：狗头军师开源项目 shengjidaguai-china/goutoujunshi (MIT)")
    parts.append("// references/knowledge（20 篇）+ references/practical（精选 10 篇）。")
    parts.append("// 运行时按标签命中 1-2 篇注入生成层；常驻四步口径见 JevPrompts.BUILTIN_KNOWLEDGE。")
    parts.append("")
    parts.append("import Foundation")
    parts.append("")
    parts.append("struct DogHeadDoc {")
    parts.append("    let id: String")
    parts.append("    let title: String")
    parts.append("    let tags: [String]")
    parts.append("    let body: String")
    parts.append("}")
    parts.append("")
    parts.append("let DOG_HEAD_DOCS: [DogHeadDoc] = [")
    for path, ident, title, tags, body in docs:
        taglist = ", ".join('"%s"' % t for t in tags)
        parts.append('    DogHeadDoc(id: "%s", title: "%s", tags: [%s], body: "%s"),'
                     % (ident, swift_escape(title), taglist, swift_escape(body)))
    parts.append("]")
    parts.append("")
    parts.append("enum DogHeadLibrary {")
    parts.append("    /// 按标签命中：消息文本包含任一标签即命中，最多 2 篇。")
    parts.append("    static func hitDocs(for message: String) -> [DogHeadDoc] {")
    parts.append("        let text = message.lowercased()")
    parts.append("        var hits: [DogHeadDoc] = []")
    parts.append("        for doc in DOG_HEAD_DOCS {")
    parts.append("            if hits.count >= 2 { break }")
    parts.append("            if doc.tags.contains(where: { !$0.isEmpty && text.contains($0.lowercased()) }) {")
    parts.append("                hits.append(doc)")
    parts.append("            }")
    parts.append("        }")
    parts.append("        return hits")
    parts.append("    }")
    parts.append("")
    parts.append("    /// 命中文献的注入文本：把原则化进回复，不照抄不提及。")
    parts.append("    static func docsPromptBlock(hits: [DogHeadDoc], language: JevLanguage) -> String {")
    parts.append("        guard !hits.isEmpty else { return \"\" }")
    parts.append("        var lines: [String] = []")
    parts.append("        if language == .english {")
    parts.append("            lines.append(\"[Dog-Head Strategist library · matched] These materials relate to the message; fold their principles into the reply without copying or mentioning them:\")")
    parts.append("        } else {")
    parts.append("            lines.append(\"【狗头军师方法库·按需命中】以下资料与当前消息相关，把其中的原则与步骤化进回复，不要照抄或提及资料本身：\")")
    parts.append("        }")
    parts.append("        for doc in hits {")
    parts.append("            let body = String(doc.body.prefix(900))")
    parts.append("            lines.append(language == .english ? \"《\\(doc.title)》\\n\\(body)\" : \"《\\(doc.title)》\\n\\(body)\")")
    parts.append("        }")
    parts.append("        return lines.joined(separator: \"\\n\\n\")")
    parts.append("    }")
    parts.append("}")
    parts.append("")

    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(parts))
    print("生成完成：%s，共 %d 篇" % (OUT, len(docs)))
    for path, ident, title, tags, body in docs:
        print("  %-14s %s  (%d字)  tags=%s" % (path, ident, len(body), tags))

if __name__ == "__main__":
    main()
