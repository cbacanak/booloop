import UIKit

/// Macera listesi (PLAN.md §6.1): seviyeler sırayla açılır. Aşama 2 için sade ızgara;
/// harita ekranı ve bölüm başlıkları Aşama 3'te.
final class LevelListViewController: UIViewController, UICollectionViewDataSource,
                                     UICollectionViewDelegateFlowLayout {
    private var collection: UICollectionView!
    private let titleLabel = UILabel()
    private let settingsButton = UIButton(type: .system)
    private let columns = 5
    private let spacing: CGFloat = 10
    private let inset: CGFloat = 16

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.night

        titleLabel.text = "Booloop"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = Palette.hud
        titleLabel.textAlignment = .center

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: inset, bottom: 24, right: inset)
        collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.dataSource = self
        collection.delegate = self
        collection.register(LevelCell.self, forCellWithReuseIdentifier: LevelCell.reuseID)

        settingsButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        settingsButton.tintColor = Palette.hud.withAlphaComponent(0.6)
        settingsButton.accessibilityLabel = "Developer settings"
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        #if !DEBUG
        settingsButton.isHidden = true
        #endif

        for v in [titleLabel, collection!, settingsButton] {
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            settingsButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),
            collection.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            collection.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            collection.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            collection.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collection.reloadData()
    }

    @objc private func settingsTapped() {
        navigationController?.pushViewController(DevSettingsViewController(), animated: true)
    }

    // MARK: - UICollectionView

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        LevelCatalog.adventureCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LevelCell.reuseID, for: indexPath)
        let number = indexPath.item + 1
        (cell as? LevelCell)?.configure(number: number,
                                        unlocked: Progress.shared.isUnlocked(number),
                                        stars: Progress.shared.stars(for: number))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let number = indexPath.item + 1
        guard Progress.shared.isUnlocked(number) else { return }
        navigationController?.pushViewController(GameViewController(levelNumber: number), animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let available = collectionView.bounds.width - 2 * inset - CGFloat(columns - 1) * spacing
        let side = floor(available / CGFloat(columns))
        return CGSize(width: side, height: side)
    }
}

final class LevelCell: UICollectionViewCell {
    static let reuseID = "LevelCell"

    private let numberLabel = UILabel()
    private let starsLabel = UILabel()
    private let lockView = UIImageView(image: UIImage(systemName: "lock.fill"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor(white: 1, alpha: 0.08)
        contentView.layer.cornerRadius = 12

        numberLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .semibold)
        numberLabel.textColor = Palette.hud
        numberLabel.textAlignment = .center

        starsLabel.font = .systemFont(ofSize: 11)
        starsLabel.textColor = Palette.accent
        starsLabel.textAlignment = .center

        lockView.tintColor = Palette.hud.withAlphaComponent(0.4)
        lockView.contentMode = .center

        for v in [numberLabel, starsLabel, lockView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(v)
        }
        NSLayoutConstraint.activate([
            numberLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -6),
            starsLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            starsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            lockView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            lockView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) kullanılmaz") }

    func configure(number: Int, unlocked: Bool, stars: Int) {
        numberLabel.text = String(number)
        numberLabel.isHidden = !unlocked
        lockView.isHidden = unlocked
        starsLabel.text = stars > 0 ? String(repeating: "★", count: stars) : ""
        contentView.alpha = unlocked ? 1 : 0.5
        accessibilityLabel = unlocked ? "Level \(number)" : "Level \(number), locked"
    }
}
