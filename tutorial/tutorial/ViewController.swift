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

    //TODO FOLLOW: variable


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
            //TODO AUTH: init
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
        //TODO AUTH: updateAppear
        updateStatus()
    }

    //TODO SUSPENDED: resume


    func updateStatus() {
        DispatchQueue.main.async {
            //TODO SELFSERVICE: state 1

            //TODO CENTRAL: buttondefault

            //TODO SUSPENDED: status


            //TODO CENTRAL: status
                        /* TODO SELFSERVICE: state 2 */


                //TODO SELFSERVICE: state 3


        }
    }

    @IBAction func nextButtonPressed(sender: UIButton) {
        print("Next button is pressed")

        //TODO AUTH: login or logout
        if let user = FRUser.currentUser /* TODO SELFSERVICE: state 4 */    {


        } else {
            //            if currentNode == nil { //MARK AUTH: startLogin



            //            } else { //MARK AUTH: inProgress





            //            }
        }
    }
    
    @IBAction func centralizedButtonPressed(sender: UIButton) {
        //TODO CENTR: browser


    }

    @IBAction func chgPwdButtonPressed(sender: UIButton) {
        //TODO SELFSERVICE: init




    }


    func handleNode(user: FRUser?, node: Node?, error: Error?) {

        //TODO FOLLOW: currentnode


        //TODO CENTRAL: success
//        if let _ = user {


            //TODO SELFSERVICE: state 5


            DispatchQueue.main.async {
                self.updateStatus()
            }
 

        //TODO AUTH: handleCallbacks
 //      } else if let node = node {

            //            print("Node object received, handle the node, first callback \(String(describing: node.callbacks.first?.type))")
            //            DispatchQueue.main.async {


            //TODO STAGE: if


            //TODO SELFSERVICE: handle





            //MARK AUTH:
            // for loop will come here


            //TODO REGISTER: attributes

            //TODO SOCIAL: handle selectidpcallback

            //TODO SOCIAL: handle IdPCallback

            //TODO DEVICE: we need a choiceCallback to simulate 2nd factor

            //TODO WEBAUTHN: handle registration

            //TODO WEBATUHN: handle authentication

            //TODO DEVICE: add handler

            //TODO CUSTOMDEVICE

            //TODO SUSPENDED: add handler


            //end of for loop:             }

            //TODO STAGE: else ends here:   }

        } else {
            print ("Something went wrong: \(String(describing: error))")
        }


    }
}

