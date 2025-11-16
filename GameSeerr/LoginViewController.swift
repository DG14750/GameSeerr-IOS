//
//  LoginViewController.swift
//  GameSeerr
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    
    private var spinner: UIActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        print(">>> LOGIN VC LOADED")
        
        let placeholderColor = UIColor(named: "text.secondary")
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Email:",
            attributes: [.foregroundColor: placeholderColor ?? .lightGray]
        )
        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Password:",
            attributes: [.foregroundColor: placeholderColor ?? .lightGray]
        )
    }
   
    // MARK: - Forgot password
    @IBAction func forgotPasswordButton(_ sender: Any) {
        view.endEditing(true)
        
        guard let email = emailTextField.text, !email.isBlank else {
            showAlertMessage(title: "Validation", message: "Please enter your email first.")
            return
        }
        
        guard email.isValidEmail else {
            showAlertMessage(title: "Validation", message: "Please enter a valid email address.")
            return
        }
        
        FirebaseManager.shared.sendPasswordReset(email: email) { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    let msg = FirebaseManager.shared.friendlyMessage(for: error)
                    self.showAlertMessage(title: "Error", message: msg)
                } else {
                    self.showAlertMessage(
                        title: "Password Reset",
                        message: "A password reset link has been sent to \(email). Please check your inbox."
                    )
                }
            }
        }
    }

    
    // MARK: - Actions
    @IBAction func loginButton(_ sender: Any) {
        view.endEditing(true)

        guard emailTextField.text?.isBlank == false else {
            showAlertMessage(title: "Validation", message: "Email is required"); return
        }
        guard emailTextField.text?.isValidEmail == true else {
            showAlertMessage(title: "Validation", message: "Please enter a valid email address"); return
        }
        guard passwordTextField.text?.isBlank == false else {
            showAlertMessage(title: "Validation", message: "Password is required"); return
        }
        if let pwd = passwordTextField.text, pwd.count < 6 {
            showAlertMessage(title: "Validation", message: "Password must be at least 6 characters"); return
        }

        // Inputs
        guard let email = emailTextField.text, let password = passwordTextField.text else { return }

        setBusy(true)
        FirebaseManager.shared.signIn(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.setBusy(false)
                
                switch result {
                case .success(let user):
                    // Optional: check email verification (comment out if not required)
                    if !user.isEmailVerified {
                        self.showAlertMessage(
                            title: "Verify Email",
                            message: "Please verify your email before continuing."
                        )
                        return
                    }
                    // Success — close login screen
                    print("Login OK for: \(user.email ?? "unknown")")
                    self.performSegue(withIdentifier: "presentMain", sender: self)

                case .failure(let error):
                    let msg = FirebaseManager.shared.friendlyMessage(for: error)
                    self.showAlertMessage(title: "Login Failed", message: msg)
                }
            }
        }
    }

    // MARK: - Busy state UI
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
