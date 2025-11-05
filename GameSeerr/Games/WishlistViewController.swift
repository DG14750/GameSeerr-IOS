//
//  WishlistViewController.swift
//  GameSeerr
//
//  shows the games I saved in wishlist
//

import UIKit
import FirebaseFirestore

final class WishlistViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyLabel: UILabel!

    // repos
    private let gamesRepo: GamesRepository = FirestoreGamesRepository()
    private let usersRepo: UsersRepository = FirestoreUsersRepository()

    // local data
    private var games: [Game] = []
    private var wishlistIds: [String] = []   // keeps order

    // live updates
    private var wishlistListener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Wishlist"

        // wired in storyboard
        collectionView.dataSource = self
        collectionView.delegate = self

        // hide until we know
        emptyLabel.isHidden = true

        // flow layout (no auto size)
        if let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.estimatedItemSize = .zero
            flow.minimumLineSpacing = 12
            flow.minimumInteritemSpacing = 0
            flow.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // listen to users/{uid}/wishlist/*
        wishlistListener?.remove()
        wishlistListener = usersRepo.observeWishlist { [weak self] ids in
            guard let self else { return }
            // simple sort for now (can switch to addedAt later)
            self.wishlistIds = Array(ids).sorted()
            self.reloadWishlist()
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

    // fetch game docs for ids and refresh UI
    private func reloadWishlist() {
        if wishlistIds.isEmpty {
            games = []
            collectionView.reloadData()
            emptyLabel.isHidden = false
            return
        }
        emptyLabel.isHidden = true

        gamesRepo.fetchMany(ids: wishlistIds) { [weak self] result in
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

    // MARK: data source
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        games.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cv.dequeueReusableCell(withReuseIdentifier: "GameCardCell", for: indexPath) as? GameCardCell else {
            return UICollectionViewCell()
        }

        let game = games[indexPath.item]
        let isWishlisted = wishlistIds.contains(game.id)

        // fill UI
        cell.configure(with: game, wishlisted: isWishlisted)

        // toggle here too (compute state at tap time)
        cell.onToggleWishlist = { [weak self, weak cell, weak cv] in
            guard let self else { return }

            let currentlyIn = self.wishlistIds.contains(game.id)

            // instant visual flip
            cell?.wishlistButton.isEnabled = false
            cell?.wishlistButton.isSelected = !currentlyIn

            // if removing, drop the card immediately
            if currentlyIn {
                if let idIdx = self.wishlistIds.firstIndex(of: game.id) {
                    self.wishlistIds.remove(at: idIdx)
                }
                if let gIdx = self.games.firstIndex(where: { $0.id == game.id }) {
                    self.games.remove(at: gIdx)
                    let path = IndexPath(item: gIdx, section: 0)
                    cv?.performBatchUpdates({
                        self.collectionView.deleteItems(at: [path])
                    }, completion: { _ in
                        self.emptyLabel.isHidden = !self.games.isEmpty
                    })
                }
            }

            // write to Firestore (listener keeps truth in sync)
            self.usersRepo.toggleWishlist(gameId: game.id, isCurrentlyIn: currentlyIn) { error in
                DispatchQueue.main.async {
                    cell?.wishlistButton.isEnabled = true
                    if let error = error {
                        // revert by reloading if failed
                        self.showAlertMessage(title: "Wishlist", message: error.localizedDescription)
                        self.reloadWishlist()
                    }
                }
            }
        }

        // same card style as Home
        cell.contentView.backgroundColor = UIColor(named: "card.background") ?? UIColor(white: 1, alpha: 0.08)
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

    // MARK: layout (card height = 16:9 image + labels)
    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flow = cv as? UICollectionViewFlowLayout
              ?? collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            let w = collectionView.bounds.width - 24
            let imgH = (w - 24) * 9.0 / 16.0
            return CGSize(width: w, height: imgH + 110)
        }
        let width = collectionView.bounds.width - flow.sectionInset.left - flow.sectionInset.right
        let imageHeight = (width - 24) * 9.0 / 16.0
        return CGSize(width: width, height: imageHeight + 110)
    }
}
