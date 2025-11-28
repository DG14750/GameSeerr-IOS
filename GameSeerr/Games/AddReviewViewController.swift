import UIKit
import FirebaseAuth

final class AddReviewViewController: UIViewController {
    
    // MARK: - Inputs
    var game: Game!
    var existingReview: Review?
    
    /// Called when a review is successfully added/edited
    var onReviewSaved: (() -> Void)?
    
    private let reviewsRepo: ReviewsRepository = FirestoreReviewsRepository()
    
    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? "anonymous"
    }
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var ratingTextField: UITextField!
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    
    private let placeholderText = "Write your review here..."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = true
        
        ratingTextField.text = ""                  // ensure empty
        ratingTextField.placeholder = "0–5"
        ratingTextField.keyboardType = .decimalPad
        ratingTextField.delegate = self
        
        bodyTextView.delegate = self
        
        ratingTextField.attributedPlaceholder = NSAttributedString(
            string: "0–5",
            attributes: [
                .foregroundColor: UIColor(named: "text.accent") ?? .systemYellow
            ]
        )
        
        if let review = existingReview {
            title = "Edit Review"
            ratingTextField.text = String(review.rating)
            bodyTextView.text = review.body
            bodyTextView.textColor = .label
            submitButton.setTitle("Save", for: .normal)
        } else {
            title = "Add Review"
            bodyTextView.text = placeholderText
            bodyTextView.textColor = .secondaryLabel
            submitButton.setTitle("Submit", for: .normal)
        }
        
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        guard let game = game else { return }
        
        // Validate rating
        guard
            let ratingText = ratingTextField.text,
            let rating = Double(ratingText),
            rating >= 0, rating <= 5
        else {
            showAlert(title: "Invalid rating",
                      message: "Please enter a number between 0 and 5.")
            return
        }
        
        // Validate body
        let rawBody = bodyTextView.text ?? ""
        let body = rawBody.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !body.isEmpty, body != placeholderText else {
            showAlert(title: "Empty review",
                      message: "Please write something about the game.")
            return
        }
        
        sender.isEnabled = false
        
        let completionHandler: (Result<Void, Error>) -> Void = { [weak self] result in
            DispatchQueue.main.async {
                sender.isEnabled = true
                switch result {
                case .success:
                    self?.showSuccessAndDismiss()
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
        
        if let existing = existingReview {
            // EDIT
            reviewsRepo.updateReview(
                id: existing.id,
                rating: rating,
                body: body,
                completion: completionHandler
            )
        } else {
            // ADD
            reviewsRepo.addReview(
                gameId: game.id,
                userId: currentUserId,
                rating: rating,
                body: body,
                completion: completionHandler
            )
        }
    }
    
    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title,
                                   message: message,
                                   preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    private func showSuccessAndDismiss() {
        let ac = UIAlertController(
            title: "Review submitted",
            message: "Thanks for sharing your thoughts!",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // Tell whoever presented us that a review was saved
            self.onReviewSaved?()
            
            self.dismiss(animated: true)
        })
        present(ac, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension AddReviewViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = placeholderText
            textView.textColor = .secondaryLabel
        }
    }
}

// MARK: - UITextFieldDelegate
extension AddReviewViewController: UITextFieldDelegate {}
