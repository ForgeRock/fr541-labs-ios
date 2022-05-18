//
//  ViewController.swift
//  tutorial
//
//  Created by Geza Simon on 2022. 04. 12..
//

import UIKit
//DONE INIT: import FRAuth
import FRAuth

//TODO WEBAUTHN: protocols
class ViewController: UIViewController {

    //TODO SUSPENDED: variable

    //DONE FOLLOW: variable
    private var currentNode: Node?

    //TODO SELFSERVICE: variable


    //MARK WEBAUTHN: implement necessary registration functions
    func excludeCredentialDescriptorConsent(consentCallback: @escaping WebAuthnUserConsentCallback) {
        let alert = UIAlertController(title: "Exclude Credentials", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            consentCallback(.reject)
        })
        let allowAction = UIAlertAction(title: "Allow", style: .default) { (_) in
            consentCallback(.allow)
        }
        alert.addAction(cancelAction)
        alert.addAction(allowAction)

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

    func createNewCredentialConsent(keyName: String, rpName: String, rpId: String?, userName: String, userDisplayName: String, consentCallback: @escaping WebAuthnUserConsentCallback) {
        let alert = UIAlertController(title: "Create Credentials", message: "KeyName: \(keyName) | Relying Party Name: \(rpName) | User Name: \(userName)", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            consentCallback(.reject)
        })
        let allowAction = UIAlertAction(title: "Allow", style: .default) { (_) in
            consentCallback(.allow)
        }
        alert.addAction(cancelAction)
        alert.addAction(allowAction)


        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

    //MARK WEBAUTHN: implement necessary authentication functions
    func selectCredential(keyNames: [String], selectionCallback: @escaping WebAuthnCredentialsSelectionCallback) {
        let actionSheet = UIAlertController(title: "Select Credentials", message: nil, preferredStyle: .actionSheet)

        for keyName in keyNames {
            actionSheet.addAction(UIAlertAction(title: keyName, style: .default, handler: { (action) in
                selectionCallback(keyName)
            }))
        }

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            selectionCallback(nil)
        }))


        if actionSheet.popoverPresentationController != nil {
            actionSheet.popoverPresentationController?.sourceView = self.view
            actionSheet.popoverPresentationController?.sourceRect = self.view.bounds
        }

        DispatchQueue.main.async {
            self.present(actionSheet, animated: true, completion: nil)
        }
    }

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var centralizedButton: UIButton!
    @IBOutlet weak var chgPwdButton: UIButton!
    @IBOutlet weak var loginStackView: UIStackView!

    private var textFieldArray = [UITextField]()
    private var providersArray: [IdPValue]?

    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        //TODO SUSPENDED: observer
        

        //TODO SELFSERVICE: interceptor

        do {
            //DONE AUTH: init
            FRLog.setLogLevel(.all)
            try FRAuth.start()
            FRLog.i("SDK started")
            print("SDK initialized successfully")

            //TODO DEVICE: manually


            //TODO TAMPER


        }
        catch {
            FRLog.e(error.localizedDescription)
            print(String(describing: error))
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //DONE AUTH: updateAppear
        updateStatus()
    }

    //TODO SUSPENDED: resume


    func updateStatus() {
        DispatchQueue.main.async {
            //TODO SELFSERVICE: state 1

            //DONE CENTRAL: buttondefault
            self.centralizedButton.isEnabled = false
            //TODO SUSPENDED: status


            //DONE CENTRAL: status
            if let _ = FRUser.currentUser /* TODO SELFSERVICE: state 2 */     {
                self.statusLabel?.text = "User is authenticated"
                self.nextButton.setTitle("Logout", for: .normal)
                //TODO SELFSERVICE: state 3

            } else {
                self.centralizedButton.isEnabled = true
                self.statusLabel?.text = "User is not authenticated"
                self.nextButton.setTitle("Next", for: .normal)
            }
        }
    }

    @IBAction func nextButtonPressed(sender: UIButton) {
        print("Next button is pressed")

        //DONE AUTH: login or logout
        if let user = FRUser.currentUser /* TODO SELFSERVICE: state 4 */    {
            user.logout()
            self.updateStatus()
        } else {
            if currentNode == nil { //MARK AUTH: startLogin
                FRUser.login {(user: FRUser?, node, error) in
                    self.handleNode(user: user, node: node, error: error)
                }
            } else { //MARK AUTH: inProgress
                guard let thisNode = currentNode else { return }
                var index = 0
                for textField in textFieldArray {
                    if let thisCallback: SingleValueCallback = thisNode.callbacks[index] as? SingleValueCallback {
                        thisCallback.setValue(textField.text)
                    }
                    index += 1
                }

                self.textFieldArray = [UITextField]()
                self.loginStackView.removeAllArrangedSubviews()

                thisNode.next { (user: FRUser?, node, error) in
                    self.handleNode(user: user, node: node, error: error)
                }
            }
        }
    }
    
    @IBAction func centralizedButtonPressed(sender: UIButton) {
        //DONE CENTR: browser
        FRUser.browser()?
            .set(presentingViewController: self)
            .set(browserType: .authSession)
            .build()
            .login { (user, error) in
                if let error = error {
                    FRLog.e(error.localizedDescription)
                } else if let user = user {
                    //Handle authenticated status
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    if let token = user.token, let data = try? encoder.encode(token), let jsonAccessToken = String(data: data, encoding: .utf8) {
                        FRLog.i("accesstoken: \(jsonAccessToken)")
                    }
                    DispatchQueue.main.async {
                        self.updateStatus()
                    }
                }
            }
    }

    @IBAction func chgPwdButtonPressed(sender: UIButton) {
        //TODO SELFSERVICE: init




    }


    func handleNode(user: FRUser?, node: Node?, error: Error?) {

        //DONE FOLLOW: currentnode
        self.currentNode = node

        //DONE CENTRAL: success
        if let _ = user {
            print("User is authenticated")

            //TODO SELFSERVICE: state 5


            DispatchQueue.main.async {
                self.updateStatus()
            }
        }

        //DONE AUTH: handleCallbacks
        else if let node = node {

            print("Node object received, handle the node, first callback \(String(describing: node.callbacks.first?.type))")
            DispatchQueue.main.async {


                //DONE STAGE: if
                if let stage = node.stage {

                    if stage == "namepass" {

                        if let nameCallback = node.callbacks.first(where: {c in c.type == "NameCallback"}) as? NameCallback {

                            let nameField = UITextField(frame: CGRect.zero)
                            nameField.autocorrectionType = .no
                            nameField.translatesAutoresizingMaskIntoConstraints = false
                            nameField.backgroundColor = .white
                            nameField.textColor = .black
                            nameField.autocapitalizationType = .none
                            nameField.borderStyle = .roundedRect
                            nameField.placeholder = nameCallback.prompt

                            self.loginStackView.addArrangedSubview(nameField)
                            self.textFieldArray.append(nameField)
                        }
                        if let passwordCallback = node.callbacks.first(where: {c in c.type == "PasswordCallback"}) as? PasswordCallback {

                            let pwdField = UITextField(frame: CGRect.zero)
                            pwdField.autocorrectionType = .no
                            pwdField.translatesAutoresizingMaskIntoConstraints = false
                            pwdField.backgroundColor = .white
                            pwdField.textColor = .black
                            pwdField.autocapitalizationType = .none
                            pwdField.borderStyle = .roundedRect
                            pwdField.placeholder = passwordCallback.prompt



                            //pwdField.isSecureTextEntry = true
                            self.loginStackView.addArrangedSubview(pwdField)
                            self.textFieldArray.append(pwdField)
                        }
                    }

                    //TODO SELFSERVICE: handle

                    

                }

                else {

                    //MARK AUTH:
                    for callback: Callback in node.callbacks {
                        if let nameCallback = callback as? NameCallback {

                            let textField = UITextField(frame: CGRect.zero)
                            textField.autocorrectionType = .no
                            textField.translatesAutoresizingMaskIntoConstraints = false
                            textField.backgroundColor = .white
                            textField.textColor = .black
                            textField.autocapitalizationType = .none
                            textField.borderStyle = .roundedRect

                            textField.placeholder = nameCallback.prompt
                            self.loginStackView.addArrangedSubview(textField)
                            self.textFieldArray.append(textField)

                        }
                        else if let passwordCallback = callback as? PasswordCallback {
                            let textField = UITextField(frame: CGRect.zero)
                            textField.autocorrectionType = .no
                            textField.translatesAutoresizingMaskIntoConstraints = false
                            textField.backgroundColor = .white
                            textField.textColor = .black
                            textField.autocapitalizationType = .none
                            textField.borderStyle = .roundedRect
                            //textField.isSecureTextEntry = true
                            textField.placeholder = passwordCallback.prompt
                            self.loginStackView.addArrangedSubview(textField)
                            self.textFieldArray.append(textField)
                        }
                        //DONE REGISTER: attributes
                        else if let attrCallback = callback as? StringAttributeInputCallback {

                            let textField = UITextField(frame: CGRect.zero)
                            textField.autocorrectionType = .no
                            textField.translatesAutoresizingMaskIntoConstraints = false
                            textField.backgroundColor = .white
                            textField.textColor = .black
                            textField.autocapitalizationType = .none
                            textField.borderStyle = .roundedRect

                            textField.placeholder = attrCallback.prompt
                            self.loginStackView.addArrangedSubview(textField)
                            self.textFieldArray.append(textField)

                        }

                        //TODO SOCIAL: handle selectidpcallback


                        //TODO SOCIAL: handle IdPCallback


                        //TODO DEVICE: we need a choiceCallback to simulate 2nd factor





                        //TODO WEBAUTHN: handle registration



                        //TODO WEBATUHN: handle authentication
                        

                        //TODO DEVICE: add handler

                            //TODO CUSTOMDEVICE




                        //TODO SUSPENDED: add handler



                    }

                //DONE STAGE: else ends here
                }

            }

        } else {
            print ("Something went wrong: \(String(describing: error))")
        }


    }
}

