import UIKit

final class GameCardCell: UICollectionViewCell {
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var platformStack: UIStackView!
    @IBOutlet weak var wishlistButton: UIButton!

    private var imageTask: URLSessionDataTask?
    var onToggleWishlist: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        // 1) Always hook the tap in code (even if IB action gets disconnected)
        wishlistButton.addTarget(self, action: #selector(wishlistTapped(_:)), for: .touchUpInside)

        // 2) Define Normal/Selected images once so we can flip isSelected
        wishlistButton.setImage(UIImage(systemName: "heart"), for: .normal)
        wishlistButton.setImage(UIImage(systemName: "heart.fill"), for: .selected)

        // 3) Gradient (kept)
        if coverImage.layer.sublayers?.first(where: { $0.name == "gradient" }) == nil {
            let g = CAGradientLayer()
            g.name = "gradient"
            g.colors = [
                UIColor.black.withAlphaComponent(0.0).cgColor,
                UIColor.black.withAlphaComponent(0.35).cgColor
            ]
            g.startPoint = CGPoint(x: 0.2, y: 0.5)
            g.endPoint   = CGPoint(x: 1.0, y: 0.5)
            coverImage.layer.addSublayer(g)
        }
    }

    @objc @IBAction func wishlistTapped(_ sender: UIButton) {
        // sanity print to confirm tap path
        print("GameCardCell.wishlistTapped")
        onToggleWishlist?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        coverImage.layer.sublayers?.first(where: { $0.name == "gradient" })?.frame = coverImage.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImage.image = nil
        imageTask?.cancel()
        platformStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        // don't leave button disabled from a previous tap
        wishlistButton.isEnabled = true
    }

    func configure(with game: Game, wishlisted: Bool = false) {
        titleLabel.text = game.title
        genreLabel.text = game.genres.isEmpty ? nil : game.genres.joined(separator: "  •  ")
        ratingLabel.text = String(format: "%.1f", game.ratingAvg)

        // use isSelected to drive the icon
        wishlistButton.isSelected = wishlisted
        wishlistButton.tintColor = wishlisted ? .systemPink : (UIColor(named: "text.secondary") ?? .lightText)

        if let url = URL(string: game.coverUrl) {
            imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self, let data = data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self.coverImage.image = img }
            }
            imageTask?.resume()
        }

        platformStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for p in game.platforms.prefix(4) {
            platformStack.addArrangedSubview(makeChip(title: p))
        }
    }

    private func makeChip(title: String) -> UIView {
        let label = PaddingLabel(insets: UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8))
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(named: "chip.text") ?? .white
        label.backgroundColor = UIColor(named: "chip.bg") ?? UIColor.white.withAlphaComponent(0.10)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }

    final class PaddingLabel: UILabel {
        private let insets: UIEdgeInsets
        init(insets: UIEdgeInsets) { self.insets = insets; super.init(frame: .zero) }
        required init?(coder: NSCoder) { self.insets = .zero; super.init(coder: coder) }
        override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: insets)) }
        override var intrinsicContentSize: CGSize {
            let s = super.intrinsicContentSize
            return CGSize(width: s.width + insets.left + insets.right,
                          height: s.height + insets.top + insets.bottom)
        }
    }
}
