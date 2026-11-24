import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        statusLabel.text = "Importando o billete…"
        statusLabel.textColor = .label
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        importSharedFile()
    }

    private func importSharedFile() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first,
              let identifier = supportedIdentifier(in: provider) else {
            finish(with: "Non se recibiu ningún ficheiro compatible.", openApp: false)
            return
        }

        provider.loadFileRepresentation(forTypeIdentifier: identifier) { [weak self] url, error in
            guard let self else { return }
            guard let url, error == nil else {
                self.finish(
                    with: error?.localizedDescription ?? "Non se puido ler o ficheiro compartido.",
                    openApp: false
                )
                return
            }
            do {
                let destination = try Self.saveInSharedInbox(from: url)
                DispatchQueue.main.async {
                    self.finish(with: "Billete gardado. Abrindo ADIF Connect…", openApp: true)
                    _ = destination
                }
            } catch {
                self.finish(with: error.localizedDescription, openApp: false)
            }
        }
    }

    private func supportedIdentifier(in provider: NSItemProvider) -> String? {
        let identifiers = [
            "com.apple.pkpass",
            "com.adobe.pdf",
            "com.apple.pdf",
            UTType.pdf.identifier
        ]
        return identifiers.first(where: provider.hasItemConformingToTypeIdentifier)
    }

    private static func saveInSharedInbox(from source: URL) throws -> URL {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.es.adifconnect.app"
        ) else {
            throw NSError(
                domain: "ADIFConnect.ShareExtension",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Non está dispoñible o espazo compartido."]
            )
        }
        let ext = source.pathExtension.lowercased()
        guard ext == "pkpass" || ext == "pdf" else {
            throw NSError(
                domain: "ADIFConnect.ShareExtension",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "O ficheiro non é un billete PKPass ou PDF."]
            )
        }
        let inbox = container.appendingPathComponent("SharedInbox", isDirectory: true)
        try FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
        let destination = inbox.appendingPathComponent("\(UUID().uuidString).\(ext)")
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }

    private func finish(with message: String, openApp: Bool) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
            guard openApp, let context = self.extensionContext,
                  let url = URL(string: "adifconnect://import-inbox") else {
                self.extensionContext?.completeRequest(returningItems: nil)
                return
            }
            context.open(url) { _ in
                context.completeRequest(returningItems: nil)
            }
        }
    }
}
