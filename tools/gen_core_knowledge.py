#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 Shared/JevKnowledge.swift：仅 20 篇核心方法（键盘只加载这 20 篇，保证稳定）。
数据来源：本地 Resources/GoutouKnowledge/knowledge（蒸馏自 shengjidaguai-china/goutoujunshi, MIT）。
23 篇实战范文不编译进键盘，仅由主 App 的 KnowledgeLibrary 文件夹提供。勿手改产物。"""
import os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KDIR = os.path.join(ROOT, "Resources", "GoutouKnowledge", "knowledge")
OUT = os.path.join(ROOT, "Shared", "JevKnowledge.swift")

TAGS = {
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
}

MAX_BODY = 9000

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
    text = open(path, encoding="utf-8").read()
    lines = text.split("\n")
    title = ""
    for ln in lines:
        s = ln.strip()
        if s.startswith("#"):
            title = s.lstrip("#").strip()
            break
    body = re.sub(r"^#.*\n?", "", text, count=1).strip()
    return title, body[:MAX_BODY]

def main():
    docs = []
    for fn in sorted(os.listdir(KDIR)):
        if fn.endswith(".md") and fn in TAGS:
            title, body = parse_md(os.path.join(KDIR, fn))
            docs.append((fn[:-3], title, TAGS[fn], body))
    assert len(docs) == 20, "核心应为 20 篇，实际 %d" % len(docs)

    p = []
    p.append("// 自动生成（tools/gen_core_knowledge.py），勿手改。")
    p.append("// 数据来源：狗头军师开源项目 shengjidaguai-china/goutoujunshi (MIT) —— 仅核心 20 篇。")
    p.append("// 键盘只加载这 20 篇并按需命中 1-2 篇注入；23 篇实战范文仅在主 App 内查阅，不进键盘。")
    p.append("")
    p.append("import Foundation")
    p.append("")
    p.append("struct DogHeadDoc {")
    p.append("    let id: String")
    p.append("    let title: String")
    p.append("    let tags: [String]")
    p.append("    let body: String")
    p.append("}")
    p.append("")
    p.append("let DOG_HEAD_DOCS: [DogHeadDoc] = [")
    for ident, title, tags, body in docs:
        taglist = ", ".join('"%s"' % t for t in tags)
        p.append('    DogHeadDoc(id: "%s", title: "%s", tags: [%s], body: "%s"),'
                 % (ident, swift_escape(title), taglist, swift_escape(body)))
    p.append("]")
    p.append("")
    p.append("enum DogHeadLibrary {")
    p.append("    /// 按标签命中：消息文本包含任一标签即命中，最多 2 篇。")
    p.append("    static func hitDocs(for message: String) -> [DogHeadDoc] {")
    p.append("        let text = message.lowercased()")
    p.append("        var hits: [DogHeadDoc] = []")
    p.append("        for doc in DOG_HEAD_DOCS {")
    p.append("            if hits.count >= 2 { break }")
    p.append("            if doc.tags.contains(where: { !$0.isEmpty && text.contains($0.lowercased()) }) {")
    p.append("                hits.append(doc)")
    p.append("            }")
    p.append("        }")
    p.append("        return hits")
    p.append("    }")
    p.append("")
    p.append("    /// 命中文献的注入文本：把原则化进回复，不照抄不提及；每篇正文截断 900 字保持有界。")
    p.append("    static func docsPromptBlock(hits: [DogHeadDoc], language: JevLanguage) -> String {")
    p.append("        guard !hits.isEmpty else { return \"\" }")
    p.append("        var lines: [String] = []")
    p.append("        if language == .english {")
    p.append("            lines.append(\"[Dog-Head Strategist library · matched] Fold the principles into the reply without copying or mentioning them:\")")
    p.append("        } else {")
    p.append("            lines.append(\"【狗头军师方法库·按需命中】把其中原则与步骤化进回复，不要照抄或提及资料本身：\")")
    p.append("        }")
    p.append("        for doc in hits {")
    p.append("            let body = String(doc.body.prefix(900))")
    p.append("            lines.append(\"《\\(doc.title)》\\n\\(body)\")")
    p.append("        }")
    p.append("        return lines.joined(separator: \"\\n\\n\")")
    p.append("    }")
    p.append("}")
    p.append("")

    open(OUT, "w", encoding="utf-8").write("\n".join(p))
    print("生成完成：%s，核心 %d 篇" % (OUT, len(docs)))

if __name__ == "__main__":
    main()
