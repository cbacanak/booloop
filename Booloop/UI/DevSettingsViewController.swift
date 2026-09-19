import UIKit

/// Geliştirici ayarları (PLAN.md §14 madde 1–2). Yalnızca DEBUG derlemede ulaşılır;
/// Aşama 2 testinde çıkmaz göstergesinin zamanlaması ve hamle hakkı çarpanları denenir.
/// Çarpan değişikliği sonraki seviyede geçerli olur. Test oturumu kaydı da buradan açılır (§8.3).
final class DevSettingsViewController: UITableViewController {
    private let settings = DevSettings.shared
    private let recorder = TestRecorder.shared
    private var pastSessions: [TestRecorder.Session] = []
    private let cellID = "cell"

    init() { super.init(style: .insetGrouped) }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) kullanılmaz") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Geliştirici ayarları"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        reload()
    }

    private func reload() {
        pastSessions = recorder.sessions()
        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Tablo

    private enum TestRow: Int, CaseIterable { case status, start, export, stop }

    override func numberOfSections(in tableView: UITableView) -> Int { 5 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Çıkmaz göstergesi (§2.8)"
        case 1: return "Hamle hakkı: par + max(3, par × çarpan) (§2.6)"
        case 2: return "İlerleme"
        case 3: return "Test oturumu (§8.3)"
        default: return pastSessions.isEmpty ? nil : "Kayıtlı oturumlar"
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return "FTUE 4. seviyede her zaman anında (§5)."
        case 1: return "Sonraki seviyeden itibaren geçerli. Hak her zaman ≥ par."
        case 3: return "Yeni oturum ilerlemeyi sıfırlar ve 1. seviyeyi açar. Olaylar yalnızca bu "
            + "cihazda bir dosyaya yazılır; ağ yok. Kayıt yalnızca burada başlatılan oturum sürerken yapılır."
        case 4: return pastSessions.isEmpty ? nil : "Dokununca CSV + JSON olarak paylaşılır. Eski oturumlar silinmez."
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return DeadEndTiming.allCases.count
        case 1: return DevSettings.bands.count
        case 2: return 3
        case 3: return TestRow.allCases.count
        default: return pastSessions.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        cell.accessoryView = nil
        cell.accessoryType = .none
        var content = cell.defaultContentConfiguration()
        switch indexPath.section {
        case 0:
            let timing = DeadEndTiming.allCases[indexPath.row]
            content.text = timing.title
            cell.accessoryType = settings.deadEndTiming == timing ? .checkmark : .none
        case 1:
            let band = DevSettings.bands[indexPath.row]
            let value = settings.multipliers[indexPath.row]
            content.text = band.title
            content.secondaryText = String(format: "× %.2f  (varsayılan %.2f)", value, DevSettings.defaultMultipliers[indexPath.row])
            let stepper = UIStepper()
            stepper.minimumValue = 0
            stepper.maximumValue = 2
            stepper.stepValue = 0.25
            stepper.value = value
            stepper.tag = indexPath.row
            stepper.addTarget(self, action: #selector(stepperChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper
        case 2:
            content.text = ["Ayarları varsayılana döndür", "İlerlemeyi sıfırla", "Bütün seviyeleri aç"][indexPath.row]
        case 3:
            configureTestRow(TestRow(rawValue: indexPath.row)!, content: &content)
        default:
            let session = pastSessions[indexPath.row]
            content.text = session.id
            content.secondaryText = "\(session.events.count) olay"
                + (session.id == recorder.current?.id ? " · kayıtta" : "")
        }
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            settings.deadEndTiming = DeadEndTiming.allCases[indexPath.row]
        case 2:
            switch indexPath.row {
            case 0: settings.resetToDefaults()
            case 1: Progress.shared.reset()
            default: Progress.shared.unlockAll(upTo: LevelCatalog.adventureCount)
            }
        case 3:
            switch TestRow(rawValue: indexPath.row)! {
            case .status: return
            case .start: askTesterAndStart()
            case .export:
                if let session = recorder.current ?? pastSessions.first { share(session, from: indexPath) }
            case .stop: recorder.stop()
            }
        case 4:
            share(pastSessions[indexPath.row], from: indexPath)
        default:
            return
        }
        reload()
    }

    // MARK: - Test oturumu

    private func configureTestRow(_ row: TestRow, content: inout UIListContentConfiguration) {
        let dim = UIColor.secondaryLabel
        switch row {
        case .status:
            if let current = recorder.current {
                content.text = "Kayıtta: \(current.id)"
                content.secondaryText = "\(current.events.count) olay"
            } else {
                content.text = "Kayıt kapalı"
            }
        case .start:
            content.text = "Yeni oturum başlat"
            content.textProperties.color = .systemBlue
        case .export:
            content.text = "Oturumu dışa aktar"
            let target = recorder.current ?? pastSessions.first
            content.secondaryText = target?.id
            content.textProperties.color = target == nil ? dim : .systemBlue
        case .stop:
            content.text = "Kaydı durdur"
            content.textProperties.color = recorder.isRecording ? .systemRed : dim
        }
    }

    private func askTesterAndStart() {
        let alert = UIAlertController(title: "Yeni test oturumu", message: "Testçi numarası", preferredStyle: .alert)
        alert.addTextField { field in
            field.keyboardType = .numberPad
            field.placeholder = "1"
        }
        alert.addAction(UIAlertAction(title: "Vazgeç", style: .cancel))
        alert.addAction(UIAlertAction(title: "Başlat", style: .default) { [weak self, weak alert] _ in
            let tester = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) ?? ""
            self?.startSession(tester: tester.isEmpty ? "0" : tester)
        })
        present(alert, animated: true)
    }

    private func startSession(tester: String) {
        do {
            try recorder.start(tester: tester, settings: settings)
        } catch {
            let alert = UIAlertController(title: "Oturum başlatılamadı", message: "\(error)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
            return
        }
        Progress.shared.reset()
        guard let nav = navigationController else { return }
        let list = nav.viewControllers.first { $0 is LevelListViewController } ?? LevelListViewController()
        nav.setViewControllers([list, GameViewController(levelNumber: 1)], animated: true)
    }

    private func share(_ session: TestRecorder.Session, from indexPath: IndexPath) {
        let files: [URL]
        do {
            files = try recorder.exportFiles(for: session)
        } catch {
            let alert = UIAlertController(title: "Dışa aktarılamadı", message: "\(error)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
            return
        }
        let sheet = UIActivityViewController(activityItems: files, applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath) ?? tableView
        present(sheet, animated: true)
    }

    @objc private func stepperChanged(_ stepper: UIStepper) {
        settings.setMultiplier(stepper.value, band: stepper.tag)
        tableView.reloadSections(IndexSet(integer: 1), with: .none)
    }
}
