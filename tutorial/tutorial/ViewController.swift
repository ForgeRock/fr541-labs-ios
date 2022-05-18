//
//  ViewController.swift
//  tutorial
//
//  Created by Geza Simon on 2022. 04. 12..
//

import UIKit
//DONE INIT: import FRAuth
import FRAuth

//DONE WEBAUTHN: protocols
class ViewController: UIViewController, PlatformAuthenticatorRegistrationDelegate, PlatformAuthenticatorAuthenticationDelegate {

    //DONE SUSPENDED: variable
    var isSuspended = false

    //DONE FOLLOW: variable
    private var currentNode: Node?

    //DONE SELFSERVICE: variable
    var isChangingPwd = false

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

        //DONE SUSPENDED: observer
        NotificationCenter.default.addObserver(self, selector: #selector(resumeFromEmail), name: NSNotification.Name("resumeFromEmail"), object: nil)

        //DONE SELFSERVICE: interceptor
        FRRequestInterceptorRegistry.shared.registerInterceptors(interceptors: [ForceAuthInterceptor()])

        do {
            //DONE AUTH: init
            FRLog.setLogLevel(.all)
            try FRAuth.start()
            FRLog.i("SDK started")
            print("SDK initialized successfully")

            //DONE DEVICE: manually
            FRDevice.currentDevice?.getProfile() { deviceProfile in
                print(deviceProfile)
            }

            //DONE TAMPER
            let jailbrokenScore = FRJailbreakDetector.shared.analyze()
            FRLog.i("Jailbreak Score: \(jailbrokenScore)")
            print("Jailbreak Score: \(jailbrokenScore)")
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

    //DONE SUSPENDED: resume
    @objc func resumeFromEmail() {
        self.isSuspended = false
        updateStatus()
    }

    func updateStatus() {
        DispatchQueue.main.async {
            //DONE SELFSERVICE: state 1
            self.chgPwdButton.isEnabled = false
            //DONE CENTRAL: buttondefault
            self.centralizedButton.isEnabled = false
            //DONE SUSPENDED: status
            if self.isSuspended {
                self.statusLabel?.text = "Check your email"
                self.nextButton.isEnabled = false
                self.nextButton.setTitle("suspended", for: .disabled)
            }
            //DONE CENTRAL: status
            else if let _ = FRUser.currentUser /* DONE SELFSERVICE: state 2 */, !self.isChangingPwd {
                self.statusLabel?.text = "User is authenticated"
                self.nextButton.setTitle("Logout", for: .normal)
                //DONE SELFSERVICE: state 3
                self.chgPwdButton.isEnabled = true
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
        if let user = FRUser.currentUser /* DONE SELFSERVICE: state 4 */, !isChangingPwd {
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
        //DONE SELFSERVICE: init

        if !isChangingPwd {
            isChangingPwd = true
            self.nextButton.setTitle("Next", for: .normal)

            FRSession.authenticate(authIndexValue: "fr541-password-ios", authIndexType: "service") {(token: Token?, node, error) in
                if let _ = token {
                    DispatchQueue.main.async {
                        self.statusLabel.text = "Password changed"
                        self.isChangingPwd = false
                    }
                    FRLog.i("password change success, token: \(String(describing: token))")
                } else {
                    self.handleNode(user: nil , node: node, error: error)
                }
            }
        }
    }


    func handleNode(user: FRUser?, node: Node?, error: Error?) {

        //DONE FOLLOW: currentnode
        self.currentNode = node

        //DONE CENTRAL: success
        if let _ = user {
            print("User is authenticated")

            //DONE SELFSERVICE: state 5
            self.isChangingPwd = false

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

                    //DONE SELFSERVICE: handle
                    else if stage == "pwdchange" {
                        let oldPwdField = UITextField(frame: CGRect.zero)
                        oldPwdField.autocorrectionType = .no
                        oldPwdField.translatesAutoresizingMaskIntoConstraints = false
                        oldPwdField.backgroundColor = .white
                        oldPwdField.textColor = .black
                        oldPwdField.autocapitalizationType = .none
                        oldPwdField.borderStyle = .roundedRect

                        oldPwdField.placeholder = "Enter current password"
                        //oldPwdField.isSecureTextEntry = true

                        self.loginStackView.addArrangedSubview(oldPwdField)
                        self.textFieldArray.append(oldPwdField)

                        let newPwdField = UITextField(frame: CGRect.zero)
                        newPwdField.autocorrectionType = .no
                        newPwdField.translatesAutoresizingMaskIntoConstraints = false
                        newPwdField.backgroundColor = .white
                        newPwdField.textColor = .black
                        newPwdField.autocapitalizationType = .none
                        newPwdField.borderStyle = .roundedRect
                        newPwdField.placeholder = "Enter new password"

                        //newPwdField.isSecureTextEntry = true
                        self.loginStackView.addArrangedSubview(newPwdField)
                        self.textFieldArray.append(newPwdField)
                    }

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

                        //DONE SOCIAL: handle selectidpcallback
                        else if let selectIdPCallback = callback as? SelectIdPCallback {
                            let providersArray = selectIdPCallback.providers
                            //OPTIONAL: let users select
                            print("Provider:  \(providersArray[1].provider)")
                            selectIdPCallback.setProvider(provider: providersArray[1])
                            node.next { (user: FRUser?, node, error) in
                                self.handleNode(user: user, node: node, error: error)
                            }
                        }

                        //DONE SOCIAL: handle IdPCallback
                        else if let idPCallback = node.callbacks.first as? IdPCallback {
                            idPCallback.signIn (handler: nil, presentingViewController: self) { (token: String?, tokenType: String?, error: Error?) in
                                node.next { (user: FRUser?, node, error) in
                                    self.handleNode(user: user, node: node, error: error)
                                }
                            }

                        }

                        //DONE DEVICE: we need a choiceCallback to simulate 2nd factor
                        else if let choiceCallback = callback as? ChoiceCallback {
                            let alert = UIAlertController(title: "Choice", message: choiceCallback.prompt, preferredStyle: .alert)
                            for choice in choiceCallback.choices {
                                let action = UIAlertAction(title: choice, style: .default) { (action) in
                                    if let title = action.title, let index = choiceCallback.choices.firstIndex(of: title) {
                                        choiceCallback.setValue(index)
                                        node.next { (user: FRUser?, node, error) in
                                            self.handleNode(user: user, node: node, error: error)
                                        }
                                    }
                                }
                                alert.addAction(action)
                            }

                            DispatchQueue.main.async {
                                self.present(alert, animated: true, completion: nil)
                            }
                        }




                        //DONE WEBAUTHN: handle registration
                        else if let webAuthnRegistrationCallback = callback as? WebAuthnRegistrationCallback {
                            webAuthnRegistrationCallback.delegate = self
                            webAuthnRegistrationCallback.register(node: node) { (attestation) in
                                node.next { (user: FRUser?, node, error) in
                                    self.handleNode(user: user, node: node, error: error)
                                }
                            } onError: { (error) in
                                let alert = UIAlertController(title: "WebAuthnError", message: "Something went wrong registering the device", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                    node.next { (user: FRUser?, node, error) in
                                        self.handleNode(user: user, node: node, error: error)
                                    }
                                })
                                alert.addAction(okAction)
                                DispatchQueue.main.async {
                                    self.present(alert, animated: true, completion: nil)
                                }
                            }
                        }

                        //DONE WEBATUHN: handle authentication
                        else if let authenticationCallback = callback as? WebAuthnAuthenticationCallback {
                            authenticationCallback.delegate = self
                            authenticationCallback.authenticate(node: node) { (assertion) in
                                node.next { (user: FRUser?, node, error) in
                                    self.handleNode(user: user, node: node, error: error)
                                }
                            } onError: { error in
                                let alert = UIAlertController(title: "WebAuthnError", message: "Something went wrong authenticating the device", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                    node.next { (user: FRUser?, node, error) in
                                        self.handleNode(user: user, node: node, error: error)
                                    }
                                })
                                alert.addAction(okAction)
                                DispatchQueue.main.async {
                                    self.present(alert, animated: true, completion: nil)
                                }
                            }
                        }

                        //DONE DEVICE: add handler
                        else if let deviceProfileCallback = callback as? DeviceProfileCallback {

                            //DONE CUSTOMDEVICE
                            deviceProfileCallback.profileCollector.collectors.append(MyDeviceCollector())

                            deviceProfileCallback.execute { _ in
                                node.next { (user: FRUser?, node, error) in
                                    self.handleNode(user: user, node: node, error: error)
                                }
                            }

                        }

                        //DONE SUSPENDED: add handler
                        else if let _ = callback as? SuspendedTextOutputCallback {
                            self.isSuspended = true
                            self.updateStatus()
                        }


                    }

                //DONE STAGE: else ends here
                }

            }

        } else {
            print ("Something went wrong: \(String(describing: error))")
        }


    }
}

