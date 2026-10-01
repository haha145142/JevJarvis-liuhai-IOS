import SwiftUI

/// 话术页：从全量目录里自由勾选槽位（可全选），并管理自定义话术。
/// 勾选结果按目录顺序写回 config.slots；键盘候选按此顺序展示。
struct TonesView: View {
    @EnvironmentObject private var store: ConfigStore
    @State private var showAdd = false

    /// 全量话术（内置按固定顺序 + 自定义排后面）。
    private var catalog: [String] {
        orderedToneNames(custom: store.config.customTones)
    }
    private var selected: Set<String> { Set(store.config.activeSlots) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(catalog, id: \.self) { name in
                        row(for: name)
                    }
                    .onDelete(perform: deleteCustom)
                } header: {
                    HStack {
                        Text(jevLocalized(store.language, zh: "话术目录（勾选即加入槽位）", en: "Tone catalog (tap to toggle a slot)"))
                        Spacer()
                        Text(jevLocalized(store.language, zh: "已选 \(selected.count)/\(catalog.count)", en: "Selected \(selected.count)/\(catalog.count)"))
                    }
                } footer: {
                    Text(jevLocalized(store.language,
                                      zh: "每个话术每次出 2 条候选；槽位可自由增减，最多 \(MAX_SLOTS) 个。含狗头军师、恋爱大师、童锦程。",
                                      en: "2 suggestions per tone; freely add/remove up to \(MAX_SLOTS). Includes Dog-Head, Love Master and Tong Jincheng."))
                }

                Section {
                    Button { showAdd = true } label: {
                        Label(jevLocalized(store.language, zh: "添加自定义话术", en: "Add custom tone"), systemImage: "plus")
                    }
                }
            }
            .navigationTitle(jevLocalized(store.language, zh: "话术", en: "Tones"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(jevLocalized(store.language, zh: "全部选中", en: "Select all")) { apply(Set(Array(catalog.prefix(MAX_SLOTS)))) }
                        Button(jevLocalized(store.language, zh: "全部取消", en: "Clear all")) { apply([]) }
                    } label: {
                        Image(systemName: "checklist")
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddToneView() }
        }
    }

    private func row(for name: String) -> some View {
        let isOn = selected.contains(name)
        let isCustom = store.config.customTones[name] != nil
        return Button {
            toggle(name)
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(localizedToneName(name, language: store.language)).font(.subheadline.weight(.medium))
                        if isCustom {
                            Text(jevLocalized(store.language, zh: "自定义", en: "Custom"))
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Capsule().fill(Color.secondary.opacity(0.18)))
                        }
                    }
                    Text(store.language == .english ? toneEnglishDescription(name)
                         : (allTones(custom: store.config.customTones)[name] ?? ""))
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ name: String) {
        var s = selected
        if s.contains(name) { s.remove(name) } else {
            if s.count >= MAX_SLOTS { return }   // 已到安全上限，不再增加
            s.insert(name)
        }
        apply(s)
    }

    /// 按目录顺序把选中集合写回槽位（顺序确定、键盘展示稳定）。
    private func apply(_ s: Set<String>) {
        store.config.slots = catalog.filter { s.contains($0) }
    }

    private func deleteCustom(_ offsets: IndexSet) {
        let names = offsets.map { catalog[$0] }
        for name in names where store.config.customTones[name] != nil {
            store.config.customTones[name] = nil
            store.config.slots.removeAll { $0 == name }
        }
    }
}

private struct AddToneView: View {
    @EnvironmentObject private var store: ConfigStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var desc = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(jevLocalized(store.language, zh: "名字（目录里显示的）", en: "Name (shown in catalog)"), text: $name)
                TextField(jevLocalized(store.language, zh: "说明（什么语气 + 别变成什么）", en: "Description (tone + what to avoid)"), text: $desc, axis: .vertical)
                    .lineLimit(3...6)
            }
            .navigationTitle(jevLocalized(store.language, zh: "自定义话术", en: "Custom tone"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(jevLocalized(store.language, zh: "取消", en: "Cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(jevLocalized(store.language, zh: "保存", en: "Save")) {
                        let n = name.trimmingCharacters(in: .whitespaces)
                        let d = desc.trimmingCharacters(in: .whitespaces)
                        guard !n.isEmpty, !d.isEmpty, n != NONE_LABEL else { return }
                        store.config.customTones[n] = d
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty ||
                              desc.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
