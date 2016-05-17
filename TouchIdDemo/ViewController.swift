//
//  ViewController.swift
//  TouchIdDemo
//
//  Created by Tobias Scholze on 18.04.16.
//  Copyright © 2016 Tobias Scholze. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    // MARK: - Properties -
    
    let authenticator = Authenticator()
    
    
    // MARK: - Overriding UIViewController methods
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        authenticator.allowAlternativeLogin = true
        authenticator.originViewController  = self
        authenticator.delegate              = self
    }

    
    // MARK: - Actions -

    @IBAction func startLoginProcessTapped(sender: AnyObject)
    {
        authenticator.requestBiometricalAuthentication()
    }
}


// MARK: - AuthenticatorDelegate -

extension ViewController: AuthenticatorDelegate
{
    func evaluateAuthenticatorResult(result: AuthenticatorResult)
    {
        switch result
        {
        case AuthenticatorResult.SUCCESS:
            
            dispatch_async(dispatch_get_main_queue()) {
                self.performSegueWithIdentifier("show-data", sender: self)
            }
            
        case AuthenticatorResult.CANCLED:
            authenticator.showAlternativeLoginForm()
            
        default:
            performSegueWithIdentifier("show-no-data", sender: self)
        }
    }
    
    
    func evaluateUserInputAuthentication(input: String)
    {
        if input == "123"
        {
            performSegueWithIdentifier("show-data", sender: self)
        }
        
        else
        {
            performSegueWithIdentifier("show-no-data", sender: self)
        }
    }
}

