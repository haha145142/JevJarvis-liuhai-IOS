import SwiftUI

/// 主 App 全量知识库浏览：
/// - 核心方法 20 篇（编译内置，键盘也会按需命中）
/// - 实战范文 23 篇（仅主 App，键盘不加载，保证键盘稳定）
/// - 童锦程 skill（核心方法 + 6 篇研究，仅主 App）
struct KnowledgeLibraryView: View {
    @EnvironmentObject private var store: ConfigStore

    private var practical: [BundledLibrary.Doc] { BundledLibrary.docs(subdir: "practical") }
    private var tong: [BundledLibrary.Doc] { BundledLibrary.docs(subdir: "tong") }

    var body: some View {
        List {
            Section {
                ForEach(DOG_HEAD_DOCS, id: \.id) { doc in
                    NavigationLink {
                        Reader(title: doc.title, content: doc.body)
                    } label: {
                        Text("《\(doc.title)》").font(.subheadline)
                    }
                }
            } header: {
                Text(jevLocalized(store.language,
                                  zh: "核心方法 · \(DOG_HEAD_DOCS.count) 篇（键盘按需命中）",
                                  en: "Core methods · \(DOG_HEAD_DOCS.count) (used by the keyboard)"))
            }

            Section {
                ForEach(practical) { doc in
                    NavigationLink {
                        Reader(title: doc.title, content: doc.body)
                    } label: {
                        Text("《\(doc.title)》").font(.subheadline)
                    }
                }
            } header: {
                Text(jevLocalized(store.language,
                                  zh: "实战范文 · \(practical.count) 篇（仅主 App，键盘不加载）",
                                  en: "Practical guides · \(practical.count) (App only, not in the keyboard)"))
            }

            Section {
                ForEach(tong) { doc in
                    NavigationLink {
                        Reader(title: doc.title, content: doc.body)
                    } label: {
                        Text("《\(doc.title)》").font(.subheadline)
                    }
                }
            } header: {
                Text(jevLocalized(store.language,
                                  zh: "童锦程 skill · \(tong.count) 篇（仅主 App）",
                                  en: "Tong Jincheng skill · \(tong.count) (App only)"))
            }
        }
        .navigationTitle(jevLocalized(store.language, zh: "知识库", en: "Knowledge"))
    }
}

/// 纯文本阅读页（等宽排版、可滚动）。
private struct Reader: View {
    let title: String
    let content: String
    var body: some View {
        ScrollView {
            Text(content)
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 从 App 专属蓝色文件夹 KnowledgeLibrary/<subdir> 读取 .md。
enum BundledLibrary {
    struct Doc: Identifiable {
        let id: String
        let title: String
        let body: String
    }

    static func docs(subdir: String) -> [Doc] {
        guard let base = Bundle.main.url(forResource: "KnowledgeLibrary", withExtension: nil)?
            .appendingPathComponent(subdir),
              let urls = try? FileManager.default.contentsOfDirectory(at: base, includingPropertiesForKeys: nil)
            .filter({ $0.pathExtension == "md" }) else { return [] }
        return urls
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { url -> Doc? in
                guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
                let name = url.deletingPathExtension().lastPathComponent
                return Doc(id: url.path, title: title(from: raw, fallback: name), body: raw)
            }
    }

    /// 标题取正文第一个 markdown 一级/二级标题；没有就用文件名。
    private static func title(from body: String, fallback: String) -> String {
        for line in body.components(separatedBy: .newlines) {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("#") {
                return t.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
            }
        }
        return fallback
    }
}
