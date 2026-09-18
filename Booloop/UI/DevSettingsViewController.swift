import UIKit

/// Geliştirici ayarları (PLAN.md §14 madde 1–2). Yalnızca DEBUG derlemede ulaşılır;
/// Aşama 2 testinde çıkmaz göstergesinin zamanlaması ve hamle hakkı çarpanları denenir.
/// Çarpan değişikliği sonraki seviyede geçerli olur.
final class DevSettingsViewController: UITableViewController {
    private let settings = DevSettings.shared
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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Tablo

    override func numberOfSections(in tableView: UITableView) -> Int { 3 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Çıkmaz göstergesi (§2.8)"
        case 1: return "Hamle hakkı: par + max(3, par × çarpan) (§2.6)"
        default: return "İlerleme"
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1: return "Sonraki seviyeden itibaren geçerli. Hak her zaman ≥ par."
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return DeadEndTiming.allCases.count
        case 1: return DevSettings.bands.count
        default: return 3
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
        default:
            content.text = ["Ayarları varsayılana döndür", "İlerlemeyi sıfırla", "Bütün seviyeleri aç"][indexPath.row]
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
        default:
            return
        }
        tableView.reloadData()
    }

    @objc private func stepperChanged(_ stepper: UIStepper) {
        settings.setMultiplier(stepper.value, band: stepper.tag)
        tableView.reloadSections(IndexSet(integer: 1), with: .none)
    }
}
