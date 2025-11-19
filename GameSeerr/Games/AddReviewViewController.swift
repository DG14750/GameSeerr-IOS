//
//  AddReviewViewController.swift
//  GameSeerr
//
//  Created by Dean Goodwin on 1/11/2025.
//

import UIKit

final class AddReviewViewController: UIViewController {

    var game: Game!   // set from GameDetailViewController

    private let reviewsRepo: ReviewsRepository = FirestoreReviewsRepository()
    private let currentUserId = "TestUser"   // TODO: replace with FirebaseAuth uid later

    @IBOutlet weak var ratingTextField: UITextField!
    @IBOutlet weak var bodyTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Review"
    }

    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func saveTapped(_ sender: Any) {
        guard
            let ratingText = ratingTextField.text,
            let rating = Double(ratingText),
            let body = bodyTextView.text,
            !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            // Basic validation
            showAlert(title: "Oops", message: "Please enter a rating and review text.")
            return
        }

        reviewsRepo.addReview(
            gameId: game.id,
            userId: currentUserId,
            rating: rating,
            body: body
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.dismiss(animated: true)
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
