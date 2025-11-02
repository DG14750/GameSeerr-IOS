//
//  ViewController.swift
//  GameSeerr
//
//  Created by Dean Goodwin on 1/11/2025.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print(">>> LOGIN VC LOADED")
        
        // couldnt find a way to this in designer sorry!
        let placeholderColor = UIColor(named: "text.secondary")

        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [.foregroundColor: placeholderColor ?? .lightGray]
        )

        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [.foregroundColor: placeholderColor ?? .lightGray]
        )

    }
    @IBAction func loginButton(_ sender: Any) {
        
    }
    
}


