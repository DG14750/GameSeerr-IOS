//
//  HomeViewController.swift
//  GameSeerr
//

import UIKit
import FirebaseFirestore

final class HomeViewController: UIViewController,
                                UICollectionViewDataSource,
                                UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - Data source
    private let repo: GamesRepository = FirestoreGamesRepository()
    private let usersRepo: UsersRepository = FirestoreUsersRepository()

    private var games: [Game] = []
    private var wishlist: Set<String> = []

    // Live listener
    private var wishlistListener: ListenerRegistration?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Discover Games"

        collectionView.dataSource = self
        collectionView.delegate = self

        // layout
        if let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.minimumLineSpacing = 12
            flow.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            flow.estimatedItemSize = .zero
        }

        loadTopRated()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        wishlistListener?.remove()
        wishlistListener = usersRepo.observeWishlist { [weak self] ids in
            self?.wishlist = ids
            self?.collectionView.reloadData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        wishlistListener?.remove()
        wishlistListener = nil
    }

    deinit {
        wishlistListener?.remove()
    }

    // MARK: - Load data
    private func loadTopRated() {
        repo.fetchTopRated(limit: 30) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let list):
                    self?.games = list
                    self?.collectionView.reloadData()
                case .failure(let err):
                    self?.showAlertMessage(title: "Error", message: err.localizedDescription)
                }
            }
        }
    }

    // MARK: - Data source
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        games.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cv.dequeueReusableCell(withReuseIdentifier: "GameCardCell", for: indexPath)
                as? GameCardCell else {
            return UICollectionViewCell()
        }

        let game = games[indexPath.item]
        let isWishlisted = wishlist.contains(game.id)

        cell.configure(with: game, wishlisted: isWishlisted)

        cell.onToggleWishlist = { [weak self, weak cell] in
            guard let self else { return }

            let currentlyIn = self.wishlist.contains(game.id)

            cell?.wishlistButton.isEnabled = false
            cell?.wishlistButton.isSelected = !currentlyIn

            self.usersRepo.toggleWishlist(gameId: game.id,
                                          isCurrentlyIn: currentlyIn) { error in
                DispatchQueue.main.async {
                    cell?.wishlistButton.isEnabled = true

                    if let error = error {
                        cell?.wishlistButton.isSelected = currentlyIn
                        self.showAlertMessage(title: "Wishlist", message: error.localizedDescription)
                    }
                }
            }
        }

        // styling
        cell.contentView.backgroundColor = UIColor(named: "card.background")
            ?? UIColor(white: 1, alpha: 0.08)
        cell.contentView.layer.cornerRadius = 14
        cell.contentView.layer.masksToBounds = true

        cell.layer.cornerRadius = 14
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOpacity = 0.25
        cell.layer.shadowRadius = 8
        cell.layer.shadowOffset = CGSize(width: 0, height: 4)
        cell.layer.masksToBounds = false

        return cell
    }

    func collectionView(_ cv: UICollectionView,
                        layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flow = cv.collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        let width = cv.bounds.width - flow.sectionInset.left - flow.sectionInset.right
        let imageHeight = (width - 24) * 9.0 / 16.0
        return CGSize(width: width, height: imageHeight + 110)
    }

    // MARK: - Navigation (Storyboard handles segue)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showGameDetail",
           let vc = segue.destination as? GameDetailViewController,
           let indexPath = collectionView.indexPathsForSelectedItems?.first {

            let selectedGame = games[indexPath.item]
            vc.game = selectedGame
        }
    }
}
