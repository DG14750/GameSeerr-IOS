//
//  GameDetailViewController.swift
//  GameSeerr
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

final class GameDetailViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var gameTitle: UILabel!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var genreButton: UIButton!
    @IBOutlet weak var genreButton2: UIButton!
    @IBOutlet weak var genreButton3: UIButton!
    @IBOutlet weak var platformLabel: UILabel!
    @IBOutlet weak var ratingButton: UIButton!
    @IBOutlet weak var platformButton: UIButton!
    @IBOutlet weak var platformButton2: UIButton!
    @IBOutlet weak var aboutLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var wishlistButton: UIButton!
    @IBOutlet weak var reviewsTableView: UITableView!
    
    // MARK: - Data
    var game: Game!
    
    private let usersRepo: UsersRepository = FirestoreUsersRepository()
    private var isWishlisted = false
    private var wishlistListener: ListenerRegistration?
    
    private let reviewsRepo: ReviewsRepository = FirestoreReviewsRepository()
    fileprivate var reviews: [Review] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Game Details"
        
        reviewsTableView.dataSource = self
        reviewsTableView.delegate   = self
        reviewsTableView.rowHeight = UITableView.automaticDimension
        reviewsTableView.estimatedRowHeight = 80
        reviewsTableView.backgroundColor = .clear
        
        fillUI()
        startWishlistListener()
        loadReviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // In case a review was added/edited and this VC re-appears
        loadReviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ratingButton.layer.cornerRadius = ratingButton.bounds.height / 2
        ratingButton.clipsToBounds = true
    }
    
    deinit {
        wishlistListener?.remove()
    }
    
    // MARK: - UI Fill
    private func fillUI() {
        guard let game = game else { return }
        
        gameTitle.text = game.title
        bodyLabel.text = game.description
        
        ratingButton.setTitle(String(format: "%.1f ★", game.ratingAvg), for: .normal)
        
        if let dateStr = game.releaseDate, !dateStr.isEmpty {
            dateButton.setTitle(dateStr, for: .normal)
        } else {
            dateButton.setTitle("Unknown", for: .normal)
        }
        
        if let url = URL(string: game.coverUrl) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self,
                      let data = data,
                      let img = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self.coverImage.image = img
                }
            }.resume()
        }
        
        let genres = game.genres
        genreButton.setTitle(genres.indices.contains(0) ? genres[0] : "", for: .normal)
        genreButton2.setTitle(genres.indices.contains(1) ? genres[1] : "", for: .normal)
        genreButton3.setTitle(genres.indices.contains(2) ? genres[2] : "", for: .normal)
        
        let platforms = game.platforms
        platformButton.setTitle(platforms.indices.contains(0) ? platforms[0] : "", for: .normal)
        platformButton2.setTitle(platforms.indices.contains(1) ? platforms[1] : "", for: .normal)
    }
    
    // MARK: - Wishlist
    private func startWishlistListener() {
        wishlistListener?.remove()
        wishlistListener = usersRepo.observeWishlist { [weak self] ids in
            guard let self = self, let game = self.game else { return }
            let wish = ids.contains(game.id)
            
            DispatchQueue.main.async {
                self.isWishlisted = wish
                if self.isViewLoaded {
                    self.applyWishlistIcon()
                }
            }
        }
    }
    
    private func applyWishlistIcon() {
        let icon = isWishlisted ? "heart.fill" : "heart"
        wishlistButton?.setImage(UIImage(systemName: icon), for: .normal)
        wishlistButton?.tintColor = isWishlisted
            ? .systemPink
            : (UIColor(named: "text.secondary") ?? .lightText)
    }
    
    @IBAction func wishButton(_ sender: UIButton) {
        guard let game = game else { return }
        sender.isEnabled = false
        let currentlyIn = isWishlisted
        
        isWishlisted.toggle()
        applyWishlistIcon()
        
        usersRepo.toggleWishlist(gameId: game.id, isCurrentlyIn: currentlyIn) { [weak self] error in
            DispatchQueue.main.async {
                sender.isEnabled = true
                if let error = error {
                    self?.isWishlisted = currentlyIn
                    self?.applyWishlistIcon()
                    self?.showAlertMessage(title: "Wishlist",
                                           message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Steam link
    @IBAction func steamButton(_ sender: Any) {
        guard let game = game else { return }
        let urlStr = "https://store.steampowered.com/app/\(game.steamAppId)"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: - Reviews loading
    private func loadReviews() {
        guard let game = game else { return }

        print("loadReviews(): requesting reviews for game id:", game.id)

        reviewsRepo.fetchForGame(gameId: game.id) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let reviews):
                    print("loadReviews(): got \(reviews.count) reviews")
                    self.reviews = reviews
                    self.reviewsTableView.reloadData()

                    // 🔢 Recalculate local average and update the rating pill
                    let ratings = reviews.map { $0.rating }
                    let count = ratings.count

                    let avg: Double
                    if count == 0 {
                        avg = 0.0
                    } else {
                        avg = ratings.reduce(0.0, +) / Double(count)
                    }

                    // Round to 1 decimal for display
                    let rounded = (avg * 10).rounded() / 10.0
                    self.ratingButton.setTitle(String(format: "%.1f ★", rounded), for: .normal)

                case .failure(let error):
                    print("loadReviews(): error =", error)
                }
            }
        }
    }

    
    /// Called by AddReviewViewController after a review is added / edited (extra safety)
    func refreshReviewsFromChild() {
        loadReviews()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAddReview",
           let dest = segue.destination as? AddReviewViewController {
            
            dest.game = game
            
            // Editing case (when we pass a Review as sender)
            if let reviewToEdit = sender as? Review {
                dest.existingReview = reviewToEdit
            }
            
            // Callback so this screen refreshes when a review is saved
            dest.onReviewSaved = { [weak self] in
                self?.loadReviews()
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension GameDetailViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewCell",
                                                 for: indexPath)
        
        let review = reviews[indexPath.row]
        
        let currentUserId = Auth.auth().currentUser?.uid
        let niceUsername: String
        if let currentUserId, review.userId == currentUserId {
            niceUsername = "You"
        } else {
            niceUsername = review.userId
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
        }
        
        cell.textLabel?.text = "\(review.rating) ★ — \(niceUsername)"
        cell.textLabel?.numberOfLines = 1
        
        cell.detailTextLabel?.text = review.body
        cell.detailTextLabel?.numberOfLines = 0
        
        cell.backgroundColor = UIColor(named: "bg.canvas") ?? .clear
        cell.textLabel?.textColor = UIColor(named: "text.primary") ?? .white
        cell.detailTextLabel?.textColor = UIColor(named: "text.secondary") ?? .lightGray
        cell.selectionStyle = .none
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension GameDetailViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        
        let review = reviews[indexPath.row]
        let currentUserId = Auth.auth().currentUser?.uid
        
        // Only allow actions on your own reviews
        guard let currentUserId, review.userId == currentUserId else {
            return nil
        }
        
        // Delete
        let deleteAction = UIContextualAction(style: .destructive,
                                              title: "Delete") { [weak self] _, _, done in
            guard let self = self else { return }
            self.reviewsRepo.deleteReview(id: review.id, gameId: review.gameId)
            { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.reviews.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    case .failure(let error):
                        self.showAlertMessage(title: "Error",
                                              message: error.localizedDescription)
                    }
                    done(true)
                }
            }
        }
        
        // Edit
        let editAction = UIContextualAction(style: .normal,
                                            title: "Edit") { [weak self] _, _, done in
            self?.performSegue(withIdentifier: "showAddReview", sender: review)
            done(true)
        }
        editAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
}
