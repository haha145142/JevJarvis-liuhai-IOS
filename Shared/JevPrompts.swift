import Foundation

// MARK: - 判断层题目（与 macOS 版 src/judge.py 同口径，改这里要三端一起改）

/// 8 类意图：Jev choice 题的 criteria，同时是界面上的意图标签。
let INTENTS: [String: String] = [
    "派活": "对方要我做一件事或接一个任务",
    "催进度": "对方在催促我尽快完成某个已在办的事",
    "问进度": "对方在询问某件事的进展或状态",
    "批评": "对方对我的工作或结果表达不满、指出错误",
    "要解释": "对方要求我说明原因或给出解释",
    "闲聊": "对方只是在聊天、分享或表达感受，没有具体要求",
    "约会议": "对方想安排一次会议或通话",
    "夸奖": "对方在肯定、称赞我的成果",
]

/// 风险 0-9 分级（Jev score 题的 criteria，文案即量表）。
let RISK_LEVELS: [String] = [
    "完全没风险，怎么回都行",
    "基本没风险",
    "平淡，正常回就好",
    "需要稍微留神",
    "有点敏感，措辞注意",
    "需要谨慎，可能被挑刺",
    "比较危险，容易得罪人或踩坑",
    "很危险，说错要出问题",
    "非常危险，涉及责任或利益",
    "极度危险，先别回，想清楚再说",
]

/// 每个意图的行动建议（界面直接展示）。
let ACTION_MAP: [String: [String]] = [
    "派活": ["接住", "问清交付标准和期限", "先给个时间点"],
    "催进度": ["先给当前状态", "给明确的完成时间", "别解释太多"],
    "问进度": ["直接说事实", "给下个节点", "有卡点就说卡点"],
    "批评": ["先认下来", "别急着辩解", "给补救方案"],
    "要解释": ["说清原因", "别找借口", "给改进措施"],
    "闲聊": ["轻松回应", "可以互动", "不用当真"],
    "约会议": ["确认时间", "说清议程", "准备好材料"],
    "夸奖": ["接住并感谢", "别过度谦虚", "可以顺带提下一步"],
]

func riskLabel(for score: Double) -> String {
    let idx = min(max(Int(score.rounded()), 0), RISK_LEVELS.count - 1)
    return RISK_LEVELS[idx]
}

// MARK: - 话术库（与 macOS 版 src/styles.py 逐字一致）

/// 每条话术产出的候选条数：前一条稳妥可直接发，后一条把语气做足。
let PER_TONE = 2

/// 话术槽位的「关掉」哨兵值（沿用了 macOS 面板的语义）。
let NONE_LABEL = "不用"

/// 内置话术。说明写成「人设 + 口头禅 + 上限约束」而不是形容词——这是 macOS 版实测出的写法。
let BUILTIN_TONES: [String: String] = [
    // —— 三个 skill 人设（狗头军师 / 恋爱大师 / 童锦程）——
    "狗头军师": "狗头军师：头脑清楚的关系军师。先接住对方情绪，再分清事实与关系阶段，给出下一步和明确的停止条件；不卑不亢、不讨好不跪舔，该拒绝就体面拒绝、该提条件就提条件。句子短、像真人说话，不堆术语、不写小作文，整句能直接发。",
    "恋爱大师": "恋爱大师：懂关系心理、会拿捏分寸的好朋友。按关系阶段（初识/暧昧/矛盾/修复）给打法，先共情、再给一个具体动作；姿态平等，不卑微、不控制，不替对方做决定、留有余地。口语自然，给的话能直接发，不说教不写小作文。",
    "童锦程": "童锦程（深情祖师爷）：直接、口语化，称呼用「兄弟」。核心：真诚才是最高级的套路，不卑不亢、绝不当舔狗；想要人配合就先给个台阶（一个体面理由），不考验人性。先给结论再举例，偶尔自嘲；不说鸡汤、不炫耀、不点名骂人。句子短，整句能直接发。",
    "高情商话术": "像公司里那个谁都说好的老同事：先接住对方情绪（「我理解」「确实」），再说事实和下一步，拒绝也带替代方案加一个具体时间点。不说教、不绕圈子、句尾不堆「呢/哦/啦」。",
    "贴吧老哥 v1.0": "贴吧老哥：一口网感口语，「有一说一」「绷不住了」「搁这」「这就去整」随手就来，自称我、管对方叫「哥/兄弟」，可以自嘲玩梗甚至摆烂，但不骂人。禁止「您好」「感谢」这类书面客套。",
    "拒绝加班": "态度平和但把话说死：明确今天做不完，**不给**「我尽量」「看情况」这种会被继续压的口子；必须给一个具体替代时间（比如「明早九点前」），并说清不用等今晚。道歉不超过一句，理由不超过一句。",
    "卑微乙方": "极度卑微的乙方：「好的好的」「收到收到」「实在抱歉」「麻烦您了」张口就来，全程称「您」，任何问题先认在自己头上，随叫随到。夸张到一眼看出是梗，但整句仍然能直接发出去。",
    "稳如老狗": "十年老工程师那种稳：不解释、不铺垫、不道歉，只给结论加一个时间点，句子短、主语是事不是情绪（「三点前给你」「已确认，没问题」），让对方觉得事情已经稳了。",
    "已读乱回": "敷衍但不失礼：一到六个字把对方接住（「在忙，你说」「嗯嗯」「好」），不承诺、不展开、不给时间点，让对方觉得回了又没法接着追问。",
    // iOS 版改写过（macOS styles.py 里是旧版）：把「推拉」写成可执行的规则，
    // 且尽量不给整句示例——给了它就会原样串起来（实测踩过）
    "鱼塘主": "海王海后式的推拉。每条回复里都要有一推一拉：先用一句淡淡的调侃把距离拉开，紧接着给一点真心的甜头，让人想再追问一句；对方提要求时先接住、再讲条件，事情不说死，收尾留个悬念。惜字如金，不解释、不道歉、不讨好，不揽活不背锅，嘴甜心硬。推是让对方多想一步，不是把人推开：不冷嘲热讽、不居高临下、不连环追问；对方好好说话时就别用推拉。不油腻、不露骨，整句要能直接发出去。不要照抄这段话里的任何措辞。",
    "职场黑话": "把简单的事说得很专业：对齐、抓手、闭环、颗粒度、拉通、复盘、赋能、沉淀、打法轮着用，一句话里至少两个；但整句要能看懂，不要堆到不知所云。",
    "阴阳怪气": "表面客气、话里带刺：多用「哦」「呢」「那就」「辛苦你了」配反问或夸张的客气，让对方不好发作又不能说你没礼貌。不要升级成直接骂人或人身攻击。",
    // 换掉「理科直男」：那个风格的定义就是"零情绪、只回答被问到的"，恰恰是本产品要治的病，
    // 功能上也和「稳如老狗」（极简给结论）、「已读乱回」（敷衍）重叠。
    // 这个新话术补的是另一个常见缺口：对方在诉苦/想要认同，别急着讲道理给方案。
    // （macOS styles.py 里还是「理科直男」，要同步的话一起换）
    "情绪价值": "情绪价值为先。认同的是对方的感受和处境（累、委屈、烦），不是对方话里的结论——绝不顺着别人对 ta 的否定说话（「你妈说得对」这种最伤人）；对方和别人有冲突时站到对方这边，不评判谁对谁错。对方没问「怎么办」就别急着给方案、别总结、别讲道理，也绝不说「别想太多」「这没什么」「想开点」。认同要具体（点出对方做的哪一点），但不空泛吹捧、不说教、不写小作文；不知道关系就别加「宝贝」「亲爱的」，也不堆 emoji。整句要能直接发出去，不要照抄这段话里的任何措辞。",
    "夸夸": "像夸夸群里的金牌群友：夸人夸具体——抓住对方消息里的细节往高了夸（眼光、效率、品位都行），语气真诚热络，「绝了」「这也太强了」「服了」随手就来，可以带感叹号；夸完顺势把正事接住（该答应的答应、该给时间的给时间）。不空泛、不谄媚、不连用三个感叹号，别把夸说成阴阳怪气。",
    // 只在 iOS 版：macOS / Windows 还没有这个话术（要同步的话记得补给 styles.py）
    "讨好型人格": "把对方的心情放在自己前面：先问清需求再表态顺从（「都听你的」「你说怎样就怎样」），习惯性先自贬一句（「是我笨」「我反应慢」），末尾爱追一句「这样行吗」「你没生气吧」。答应得比能做到的快，宁可自己加班也不想让对方失望。语气软、句尾带语气词，但不卖惨、不写小作文、不真把自己说成一无是处，整句仍然要能直接发出去。",
]

/// 内置话术的展示顺序，与 macOS 版 `src/styles.py` 的书写顺序一致。
/// 字典本身是无序的，顺序必须显式写出来——靠 `Array(dict.keys)` 会得到每次运行都可能不同的顺序。
let BUILTIN_TONE_ORDER: [String] = [
    "狗头军师", "恋爱大师", "童锦程",
    "高情商话术", "贴吧老哥 v1.0", "拒绝加班", "卑微乙方", "稳如老狗",
    "已读乱回", "鱼塘主", "职场黑话", "阴阳怪气", "情绪价值", "夸夸",
    "讨好型人格",
]

/// 内置 + 自定义合并（同名覆盖）。顺序 = 界面下拉顺序。
func allTones(custom: [String: String]) -> [String: String] {
    var merged = BUILTIN_TONES
    for (k, v) in custom where k != NONE_LABEL && !v.isEmpty {
        merged[k] = v
    }
    return merged
}

/// 话术展示顺序：内置按 styles.py 的顺序，自定义排后面（App 与键盘共用同一份顺序）。
func orderedToneNames(custom: [String: String]) -> [String] {
    var names = BUILTIN_TONE_ORDER.filter { BUILTIN_TONES[$0] != nil }
    // 兜底：万一有内置话术漏写进顺序表，也别把它从界面上弄丢
    names += BUILTIN_TONES.keys.filter { !BUILTIN_TONE_ORDER.contains($0) }.sorted()
    names += custom.keys
        .filter { !BUILTIN_TONES.keys.contains($0) && $0 != NONE_LABEL && !(custom[$0] ?? "").isEmpty }
        .sorted()
    return names
}

// MARK: - 起草 prompt（沿用 macOS 版结构，面向通用聊天场景）

/// {n} 出现两次是刻意的：「只要 n 行」的要求必须与条数一致，否则模型会自己凑一行。
let PROMPT_ONE = """
刚收到一条聊天消息，你要帮我回。

{context_line}消息：「{message}」
{intent_line}
请写 {n} 条回复候选，语气统一成下面这一种，但两条的胆量要有差别：
「{tone}」{instruction}

硬性要求：
- 前一条稳妥、可以直接发出去；后一条把这个语气做足，更皮、更夸张一点也行
- 每条不超过 40 个字，像日常聊天时打字的语气，不要客套话、不要解释
- 不编造见面时间、共同经历、自己做过的事或做不到的承诺
- 先区分可见事实、暂定推测与仍未知；一轮回复只做一个主动作
- 回复像用户平时发的一句话；不把分析术语、理由、代价塞进可发送文本
- 对方意图只是可能的解释，别在回复里宣称看穿了 TA
- 尊重拒绝与边界，不使用操控、施压、贬低或虚假时间限制
- 只输出 {n} 行，每行一条，不要编号、不要引号、不要任何前后缀
- 不要写出语气名称（不要写「{tone}：」这类前缀），直接从回复内容开始
"""

let PROMPT_ONE_EN = """
You just received a chat message and need to reply.

{context_line}Message: “{message}”
{intent_line}
Write {n} reply candidates in the same tone below, with different levels of boldness:
“{tone}” {instruction}

Hard requirements:
- Write every reply in English, regardless of the language of the message
- The first reply should be safe to send; the second should use the tone more strongly and may be more playful
- Keep each reply under 40 words, like everyday chat. No formal filler or explanations
- Never invent meeting times, shared history, things you did, or promises you cannot keep
- Separate visible facts from guesses and unknowns; one primary move per reply
- Sound like the user's normal one-line messages; do not put analysis jargon, reasons, or costs into the sendable text
- The other person's intent is only a possible explanation; never claim to have seen through them
- Respect refusal and boundaries; no manipulation, pressure, belittling, or fake time limits
- Output only {n} lines, one reply per line, with no numbering, quotes, or prefixes
- Do not write the tone name (do not add a prefix such as “{tone}:”); start with the reply itself
"""

// MARK: - 内置技能知识库（狗头军师 · 恋爱大师）
//
// 每次分析自动携带，同时注入判断层 state 与生成层 prompt。
// 内容蒸馏自两个 MIT 开源 skill（详见 README「内置技能」一节）：
//   - 狗头军师   https://github.com/shengjidaguai-china/goutoujunshi
//   - 恋爱大师   https://github.com/tomwong001/qingsheng-skill
// 核心流程（用户锁定口径）：先接住情绪 → 分清事实 → 给下一步 → 停止条件。

let BUILTIN_KNOWLEDGE_ZH = """
【内置知识库 · 狗头军师＋恋爱大师】分析每一段聊天必须按下述顺序执行：
1. 先接住情绪：先处理对方和用户当下的感受、触发点与冲突，认可感受；不替未经证实的解释背书，高情绪时先缩小到眼下这一步。
2. 再分清事实：只把聊天里的原文、说话人、顺序、间隔与表情当事实；列出已知事实、合理推测、关键未知，缺失信息保持未知，不虚构。不凭单次回复、表情或标签给人定性；优先看持续主动、兑现、投入、边界和冲突修复。
3. 给下一步：先给一句首选建议和理由；有真实权衡时给不超过三个版本（稳健／会撩策略／强势），强势是边界和筛选，不是羞辱、威胁或控制。
4. 给停止条件：给一个现在能做的小动作、观察窗口或停止条件，以及值得回来反馈的具体信号。

回复话术要求（恋爱大师）：
- 用户问「这句怎么回」时先给一条可复制成品，再补发送时机、主要代价与积极／含糊／不回应的后续。
- 每条只承载一个主动作，不堆叠承接、邀约、澄清和收线；口语自然、像真人在打字，不写小作文、不 AI 味、不油腻、不堆表情。
- 话术里的理由、情绪、叙事必须来自对话中已有的信息，禁止编造不存在的经历、档期或地点；真诚优先，不装高价值、不玩套路包装。
- 先判互动目的再判阶段：事务互动不升级为恋爱信号；没有兴趣信号就明说没有，不凑数。
- 明确拒绝或要求不要联系时立即停止推进，不反复施压；不协助性胁迫、偷拍、跟踪、威胁、勒索、冒充、散布隐私或诈骗。
- 出现家暴、跟踪、强迫、人身威胁、自伤或伤人风险时，先确认安全并联系可信支持或当地紧急服务。
"""

let BUILTIN_KNOWLEDGE_EN = """
[Built-in knowledge base · Dog-Head Strategist + Love Master] Analyze every chat message in this order:
1. Acknowledge feelings first: name both sides' emotions, triggers and conflict, and validate them; do not back unverified explanations.
2. Separate facts: treat only the visible text, speaker, order, timing and emoji as facts; list knowns, reasonable guesses and key unknowns, and keep unknowns unknown. Never judge someone by a single reply, emoji or label; prioritize sustained initiative, follow-through, investment, boundaries and conflict repair.
3. Give the next step: lead with one recommended move and its reasons; at most three variants when trade-offs are real (steady / playful-strategic / assertive). Assertive is a boundary and filter, not humiliation, threat or control.
4. Give stop conditions: one small action to take now, an observation window or a stop condition, and a concrete signal worth reporting back.

Reply-drafting rules (Love Master):
- When asked "how should I reply to this?", give one copy-paste-ready line first, then timing, the main cost, and follow-ups for positive / vague / no response.
- One primary move per message; do not stack acknowledgment, invitation, clarification and closure. Natural, human typing: no essays, no AI flavor, no oiliness, no emoji spam.
- Every reason, emotion and narrative in a draft must come from facts already in the conversation; never invent experiences, schedules or places. Authenticity first: no fake high-value persona, no packaged game.
- Judge the interaction purpose before the stage: transactional chats are not romantic signals; say plainly when there are no signs of interest.
- Stop immediately when they clearly refuse or ask not to be contacted; never assist coercion, filming, stalking, threats, blackmail, impersonation, doxxing or fraud.
- In danger (abuse, stalking, coercion, threats, self-harm or harm to others), prioritize safety and contact trusted support or local emergency services.
"""

func builtinKnowledgeText(_ language: JevLanguage) -> String {
    language == .english ? BUILTIN_KNOWLEDGE_EN : BUILTIN_KNOWLEDGE_ZH
}

/// 知识库注入到 prompt 的引导行。
func builtinKnowledgeLine(_ language: JevLanguage) -> String {
    language == .english
        ? "Follow these built-in rules first (knowledge base):\n"
        : "先遵守下面的内置知识库规则：\n"
}

func buildDraftPrompt(message: String, intent: String?, context: String?,
                      knowledge: String? = nil,
                      tone: String, instruction: String, n: Int,
                      language: JevLanguage? = nil) -> String {
    let selectedLanguage = language ?? JevStore.loadLanguage()
    let contextLine: String
    let intentLine: String
    if selectedLanguage == .english {
        contextLine = context != nil && !(context ?? "").isEmpty ? "Recent conversation:\n\(context!)\n\n" : ""
        intentLine = intent != nil && !(intent ?? "").isEmpty ? "Detected intent: \(localizedIntent(intent!, language: .english))\n" : ""
    } else {
        contextLine = context != nil && !(context ?? "").isEmpty ? "最近的对话：\n\(context!)\n\n" : ""
        intentLine = intent != nil && !(intent ?? "").isEmpty ? "判断出的意图：\(intent!)\n" : ""
    }
    let template = selectedLanguage == .english ? PROMPT_ONE_EN : PROMPT_ONE
    let promptInstruction = selectedLanguage == .english && BUILTIN_TONES[tone] == instruction
        ? toneEnglishDescription(tone) : instruction
    var knowledgeLine = ""
    if let k = knowledge, !k.isEmpty {
        knowledgeLine = builtinKnowledgeLine(selectedLanguage) + k + "\n\n"
    }
    return knowledgeLine + template
        .replacingOccurrences(of: "{context_line}", with: contextLine)
        .replacingOccurrences(of: "{message}", with: message)
        .replacingOccurrences(of: "{intent_line}", with: intentLine)
        .replacingOccurrences(of: "{tone}", with: tone)
        .replacingOccurrences(of: "{instruction}", with: promptInstruction)
        .replacingOccurrences(of: "{n}", with: String(n))
}

// MARK: - 候选清洗（移植自 generate.py _parse：模型「通常会」守规矩，所以要兜底）

enum CandidateParser {
    private static let numbering = try! NSRegularExpression(pattern: #"^[\d]+[.、)．]\s*"#)

    /// 「稳妥：」「轻松版：」这类模型偶尔回显的语气/风格前缀。冒号前只允许少量非标点填充。
    private static let styleLabel = try! NSRegularExpression(
        pattern: #"^[*_#\s]*(稳妥|轻松|简短|简洁)[^，。！？；、,.!?;：:]{0,5}[*_#\s]*[:：]\s*"#)
    private static let styleLabelShort = try! NSRegularExpression(
        pattern: #"^[*_#\s]*(简|稳|轻)\s*(型|洁)?[*_#\s]*[:：]\s*"#)

    private static func strip(_ s: String, _ re: NSRegularExpression) -> String {
        let range = NSRange(s.startIndex..<s.endIndex, in: s)
        guard let m = re.firstMatch(in: s, range: range),
              let r = Range(m.range, in: s) else { return s }
        return String(s[r.upperBound...])
    }

    private static let quotePairs: [(Character, Character)] = [
        ("\"", "\""), ("'", "'"), ("“", "”"), ("‘", "’"), ("「", "」"), ("『", "』"),
    ]

    private static func stripQuotes(_ s: String) -> String {
        var t = s
        for (open, close) in quotePairs where t.first == open && t.last == close && t.count >= 2 {
            t.removeFirst(); t.removeLast()
        }
        return t
    }

    /// 一行原始输出 → 一条干净候选。编号 → 引号 → 风格前缀 → 引号，与 macOS 版同顺序。
    static func parseLine(_ raw: String) -> String? {
        var s = raw.trimmingCharacters(in: .whitespaces)
        if s.isEmpty { return nil }
        s = strip(s, numbering)
        s = stripQuotes(s)
        s = strip(s, styleLabel)
        s = strip(s, styleLabelShort)
        s = stripQuotes(s)
        s = s.trimmingCharacters(in: .whitespaces)
        return s.isEmpty ? nil : s
    }

    static func parse(_ raw: String, limit: Int = PER_TONE) -> [String] {
        var out: [String] = []
        for line in raw.split(separator: "\n") {
            if let t = parseLine(String(line)), !out.contains(t) {
                out.append(t)
                if out.count >= limit { break }
            }
        }
        return out
    }
}

// MARK: - 判断层兜底（Jev 未配置时用生成模型推测意图/风险/动作）
//
// 症状：自签重签后 App Group 不共享，键盘读不到 App 里配好的判断层 Key，
// 或用户根本没配 Jev。此时不再是「盲起草」——用生成层模型推测一版
// 意图 + 风险 + 建议动作，结果标注「模型推测」，仅供判断参考。

/// 让生成层模型输出一行 JSON。Jev 的意图/风险题目本身是中文，所以兜底 prompt 固定中文。
let JUDGE_FALLBACK_PROMPT = """
{knowledge_line}你是一个聊天意图与风险判断器。刚收到一条聊天消息，判断它的真实意图、直接回复的风险和该怎么做。

{context_line}消息：「{message}」

意图只从这些里面选一个最贴切的：{intents}
风险打 0-9 分：0=完全没风险随便回；9=极高风险（涉及责任、利益、人身安全、越界）。
建议动作给 1-3 个简短短语（如「先接住」「给个时间点」「别急着辩解」）。

只输出一行 JSON，不要任何其他文字、不要代码块：
{"intent":"意图","risk":0,"actions":["动作1","动作2"]}
"""

func judgeFallbackPrompt(message: String, context: String?, knowledge: String?, language: JevLanguage) -> String {
    let contextLine = context != nil && !(context ?? "").isEmpty ? "最近的对话：\n\(context!)\n\n" : ""
    let knowledgeLine: String
    if let k = knowledge, !k.isEmpty {
        knowledgeLine = "先遵守下面的内置知识库规则（判断时也要按它的四步顺序）：\n\(k)\n\n"
    } else {
        knowledgeLine = ""
    }
    return JUDGE_FALLBACK_PROMPT
        .replacingOccurrences(of: "{knowledge_line}", with: knowledgeLine)
        .replacingOccurrences(of: "{context_line}", with: contextLine)
        .replacingOccurrences(of: "{message}", with: message)
        .replacingOccurrences(of: "{intents}", with: INTENTS.keys.joined(separator: "/"))
}

/// 解析兜底推测的一行 JSON。模型不守规矩（不输出 JSON/意图不在表里）时返回 nil，不影响出候选。
func parseJudgeFallback(_ raw: String) -> JudgeResult? {
    let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let start = text.firstIndex(of: "{"),
          let end = text.lastIndex(of: "}"),
          start < end else { return nil }
    let json = String(text[start...end])
    guard let data = json.data(using: .utf8),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
    let rawIntent = (obj["intent"] as? String) ?? ""
    var intent = rawIntent
    if !INTENTS.keys.contains(intent) {
        intent = INTENTS.keys.first { intent.contains($0) } ?? "闲聊"
    }
    let riskRaw = (obj["risk"] as? Double) ?? ((obj["risk"] as? Int).map(Double.init)) ?? 0
    let risk = min(max(riskRaw, 0), 9)
    let actions = (obj["actions"] as? [String]) ?? ACTION_MAP[intent] ?? []
    return JudgeResult(intent: intent, confidence: 0, intentProbs: [:],
                       risk: risk, riskProbs: [:], actions: actions)
}
