//
//  SignUpViewController.swift
//  GameSeerr
//

import UIKit

class SignUpViewController: UIViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmTextField: UITextField!

    private var spinner: UIActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("SignUpViewController loaded")

        let placeholderColor = UIColor(named: "text.secondary")
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Email:",
            attributes: [.foregroundColor: placeholderColor ?? .lightGray]
        )
        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Password:",
            attributes: [.foregroundColor: placeholderColor ?? .lightGray]
        )
        usernameTextField.attributedPlaceholder = NSAttributedString(
            string: "Username:",
            attributes: [.foregroundColor: placeholderColor ?? .lightGray]
        )
        confirmTextField.attributedPlaceholder = NSAttributedString(
            string: "Confirm Password:",
            attributes: [.foregroundColor: placeholderColor ?? .lightGray]
        )
    }

    @IBAction func signUpButton(_ sender: Any) {
        view.endEditing(true)

        // Validation via your Extensions.swift
        guard usernameTextField.text?.isBlank == false else {
            showAlertMessage(title: "Validation", message: "Username is mandatory"); return
        }
        guard emailTextField.text?.isBlank == false else {
            showAlertMessage(title: "Validation", message: "Email is mandatory"); return
        }
        guard emailTextField.text?.isValidEmail == true else {
            showAlertMessage(title: "Validation", message: "Please enter a valid email address"); return
        }
        guard passwordTextField.text?.isBlank == false else {
            showAlertMessage(title: "Validation", message: "Password is mandatory"); return
        }
        guard confirmTextField.text?.isBlank == false else {
            showAlertMessage(title: "Validation", message: "Confirm Password is mandatory"); return
        }
        if let pwd = passwordTextField.text, pwd.count < 6 {
            showAlertMessage(title: "Validation", message: "Password must be at least 6 characters"); return
        }
        guard passwordTextField.text == confirmTextField.text else {
            showAlertMessage(title: "Validation", message: "Passwords do not match"); return
        }

        // Inputs
        guard let username = usernameTextField.text,
              let email = emailTextField.text,
              let password = passwordTextField.text else { return }

        setBusy(true)
        FirebaseManager.shared.createUser(username: username, email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.setBusy(false)

                switch result {
                case .success:
                    self.showAlertMessage(
                        title: "Account Created",
                        message: "Welcome, \(username)! Please check your email to verify your account."
                    ) { _ in
                        if let nav = self.navigationController {
                            nav.popViewController(animated: true)
                        } else {
                            self.dismiss(animated: true)
                        }
                    }

                case .failure(let error):
                    let msg = FirebaseManager.shared.friendlyMessage(for: error)
                    self.showAlertMessage(title: "Sign Up Failed", message: msg)
                }
            }
        }
    }

    // Minimal busy spinner
    private func setBusy(_ busy: Bool) {
        view.isUserInteractionEnabled = !busy
        if busy {
            if spinner == nil {
                let s = UIActivityIndicatorView(style: .large)
                s.translatesAutoresizingMaskIntoConstraints = false
                s.hidesWhenStopped = true
                view.addSubview(s)
                NSLayoutConstraint.activate([
                    s.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    s.centerYAnchor.constraint(equalTo: view.centerYAnchor)
                ])
                spinner = s
            }
            spinner?.startAnimating()
        } else {
            spinner?.stopAnimating()
        }
    }
}
