import Foundation

// 终极融合版专项回归：上下文/限长、槽位动态化、三 skill 话术、键盘知识库注入有界。
// 编译：swiftc tools/UltimateCheck/main.swift Shared/*.swift

var pass = 0, fail = 0
func ok(_ name: String, _ cond: Bool, _ detail: String = "") {
    if cond { pass += 1; print("✅ \(name)") }
    else { fail += 1; print("❌ \(name) \(detail)") }
}

// MARK: 三个 skill 话术必须就位且排在最前

for t in ["狗头军师", "恋爱大师", "童锦程"] {
    ok("话术存在·\(t)", !(BUILTIN_TONES[t] ?? "").isEmpty)
}
let order = orderedToneNames(custom: [:])
ok("顺序·三 skill 置顶", Array(order.prefix(3)) == ["狗头军师", "恋爱大师", "童锦程"],
   "got \(Array(order.prefix(3)))")

// 姿态要求：童锦程话术明确反舔狗、称兄弟
let tjc = BUILTIN_TONES["童锦程"] ?? ""
ok("童锦程·反舔狗", tjc.contains("不当舔狗"))
ok("童锦程·称兄弟", tjc.contains("兄弟"))
ok("童锦程·给台阶", tjc.contains("台阶"))

// MARK: 槽位动态化：去空、去重、安全上限

var c = JevConfig()
c.slots = ["狗头军师", "狗头军师", "", "恋爱大师", "童锦程"]
ok("槽位·去空去重", c.activeSlots == ["狗头军师", "恋爱大师", "童锦程"],
   "got \(c.activeSlots)")

c.slots = (0..<20).map { "不同话术\($0)" }
ok("槽位·安全上限 \(MAX_SLOTS)", c.activeSlots.count == MAX_SLOTS,
   "got \(c.activeSlots.count)")

// 全选：目录数若超过上限，activeSlots 不超过 MAX_SLOTS
let allNames = orderedToneNames(custom: c.customTones)
c.slots = allNames
ok("槽位·全选不超限", c.activeSlots.count <= MAX_SLOTS)

// MARK: 剪贴板 / 上下文限长

ok("剪贴板总上限=6000", CLIPBOARD_MAX_CHARS == 6000, "got \(CLIPBOARD_MAX_CHARS)")
ok("上下文单行上限=500", JevContext.lineCap == 500)

let huge = String(repeating: "甲", count: 5000)
let split = JevContext.lines(from: huge)
ok("拆分·超长单行被截断", split.count == 1 && split[0].count == JevContext.lineCap,
   "got count=\(split.count) len=\(split.first?.count ?? -1)")

let multi = JevContext.lines(from: "第一句\n\n第二句\n  \n第三句")
ok("拆分·多行去空行", multi == ["第一句", "第二句", "第三句"], "got \(multi)")

// clamp：条数与总字数双上限
let manyTurns = (0..<30).map { ContextTurn(role: JevContext.roleOther, text: "第\($0)条内容") }
let clamped = JevContext.clamp(manyTurns)
ok("clamp·条数上限", clamped.count <= JevContext.maxTurns, "got \(clamped.count)")
ok("clamp·字数上限", clamped.reduce(0){$0+$1.text.count} <= JevContext.maxChars)

// MARK: 键盘知识库注入有界（不把全部资料拼进 prompt）

let hits = DogHeadLibrary.hitDocs(for: String(repeating: "事实", count: 1))
ok("命中·最多2篇", hits.count <= 2, "got \(hits.count)")
let block = DogHeadLibrary.docsPromptBlock(hits: DogHeadLibrary.hitDocs(for: "事实 亲密 边界 拒绝 情绪"),
                                           language: .chinese)
ok("注入·有界长度", block.count <= 2 * (900 + 80), "got \(block.count)")
ok("核心库·20篇", DOG_HEAD_DOCS.count == 20, "got \(DOG_HEAD_DOCS.count)")

// MARK: 默认配置不带任何内置密钥

ok("默认·生成key为空", JevConfig().genKey.isEmpty)
ok("默认·判断key为空", JevConfig().judgeKey.isEmpty)

print("\n\(pass) passed, \(fail) failed")
exit(fail == 0 ? 0 : 1)
