import UIKit

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmTextField: UITextField!
    
    override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    print("SignUpViewController loaded") // Remove when everything is good!!!
  }
    
    @IBAction func signUpButton(_ sender: Any) {
            guard !(usernameTextField.text?.isBlank ?? true) else {
                print("Username is mandatory")
                return
            }
            
            guard !(emailTextField.text?.isBlank ?? true) else {
                print("Email is mandatory")
                return
            }
            
            guard !(passwordTextField.text?.isBlank ?? true) else {
                print("Password is mandatory")
                return
            }
            
            guard !(confirmTextField.text?.isBlank ?? true) else {
                print("Confirm Password is mandatory")
                return
            }
//            guard !(confirmTextField.text?.isBlank ?? true) else {
//                showAlertMessage(title: "Validation", message: "Confirm Password is mandatory")
//                return
//            }
            
            print("Everything is valid")
        }
    }
