//
//  Authenticator.swift
//  TouchIdDemo
//
//  Created by Tobias Scholze on 18.04.16.
//  Copyright © 2016 Tobias Scholze. All rights reserved.
//

import Foundation
import UIKit
import LocalAuthentication


/// Wrapper for local authentication
///
/// Works with Touch ID
class Authenticator
{
    // MARK: - Properties -
    
    /// Indicates if an alternative, pin-based login method
    /// should be available in case of no touch id is available
    /// Default value is false
    var allowAlternativeLogin = false
    
    /// Contains the optional origin view controller
    /// Required if allowAlternativeLogin is true
    var originViewController: UIViewController?
    
    /// Contains the external AuthenticatorDelegate
    var delegate: AuthenticatorDelegate?
    
    
    // MARK: - Methods -
    
    /// Trys to authenticate the user via biometrical inputs
    ///
    /// - return: AuthenticatorResult value
    func requestBiometricalAuthentication()
    {
        // MARK: - Properties -
        
        let context                 = LAContext()
        let biometricPolicy         = LAPolicy.DeviceOwnerAuthenticationWithBiometrics
        let reasonText              = "Please identify to access the app's content"
        var authenticationResult    = AuthenticatorResult.IN_PROGRESS

        var policyError: NSError?
        
        /// Check if device and its policy allows to use biometrical authentication
        guard context.canEvaluatePolicy(biometricPolicy, error: &policyError) else
        {
            /// If not, handle the policy error
            guard let _policyError = policyError else
            {
                fatalError("Error without an evaluation error raised")
            }
            
            // Call delegate method to evaluate the result
            delegate?.evaluateAuthenticatorResult(handlePolicyError(_policyError))
            return
        }
        
        // Try to use biometrical authentication
        context.evaluatePolicy(biometricPolicy, localizedReason: reasonText) { success, evaluationError in
            
            // Check if authentication was succesful
            if success
            {
                authenticationResult = AuthenticatorResult.SUCCESS
            }
                
            // If not, handle evalation error
            else
            {
                guard let _evaluationError = evaluationError else
                {
                    fatalError("Error without an evaluation error raised")
                }
            
                authenticationResult = self.handleEvaluationError(_evaluationError)
            }
            
            self.delegate?.evaluateAuthenticatorResult(authenticationResult)
        }
    }
    
    
    /// Shows an alternative, pin-based login dialog. To handle the input use the delegate
    /// method `evaluateUserInputAuthentication(input: String)`
    func showAlternativeLoginForm()
    {
        guard allowAlternativeLogin else
        {
            return
        }
        
        guard let _originViewController = originViewController else
        {
            fatalError("allowAlternativeLogin is set to true but no origin view controller is set")
        }
        
        // Create alert view controller
        let alertController = UIAlertController(title: "Enter PIN", message: "Please enter your personal PIN", preferredStyle: .Alert)
        
        // Add input field
        alertController.addTextFieldWithConfigurationHandler { pinTextField in
            pinTextField.placeholder        = "Your PIN"
            pinTextField.secureTextEntry    = true
            pinTextField.textAlignment      = .Center
            pinTextField.keyboardType       = UIKeyboardType.NumberPad
        }
        
        // Add buttons
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { action in
            
        }
        
        let loginAction = UIAlertAction(title: "Login", style: .Default) { action in
            
            // Check if data is valid
            guard let fields = alertController.textFields else
            {
                return
            }
            
            guard let pinField = fields.first else
            {
                return
            }
            
            guard let pinValue = pinField.text else
            {
                return
            }
            
            
            // Call delegate method to evaluate the result
            self.delegate?.evaluateUserInputAuthentication(pinValue)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(loginAction)
        
        // Present view controller
        _originViewController.presentViewController(alertController, animated: true, completion: nil)
    }

    
    // MARK: - Private helper -
    
    /// Handles policy errors by evaluating the error code
    /// Uses AuthenticatorResult.ALTERNATIVE_METHOD_REQUESTE in
    /// case of allowAlternativeLogin is set to true
    ///
    /// - parameter error: Raised error
    /// - returns an input related AuthenticatorResult entry
    private func handlePolicyError(error: NSError) -> AuthenticatorResult
    {
        switch error.code
        {
        case LAError.TouchIDNotAvailable.rawValue:
            print("Device has no TouchID sensor")
            
        case LAError.PasscodeNotSet.rawValue:
            print("Device has no passcode set")
            
        case LAError.TouchIDNotEnrolled.rawValue:
            print("No fingers are added to the TouchId service")
            
        default:
            print("Unchecked error code \(error.code)")
        }
        
        if allowAlternativeLogin
        {
            return AuthenticatorResult.ALTERNATIVE_METHOD_REQUESTED
        }
        
        return AuthenticatorResult.FAILED
    }
    
    
    /// Handles policy evaluation errors by evaluating the error code
    ///
    /// - parameter error: Raised error
    /// - returns an input related AuthenticatorResult entry
    func handleEvaluationError(error: NSError) -> AuthenticatorResult
    {
        switch error.code
        {
        case LAError.SystemCancel.rawValue:
            print("Action was canceled by the app")
            return AuthenticatorResult.CANCLED
            
        case LAError.UserCancel.rawValue:
            print("Action was canceled by the user")
            return AuthenticatorResult.CANCLED
            
        case LAError.UserFallback.rawValue:
            print("User wants to use fall back authentication method")
            return AuthenticatorResult.ALTERNATIVE_METHOD_REQUESTED
            
        default:
            print("Unchecked error code \(error.code)")
            return AuthenticatorResult.FAILED
        }
    }
}


/// Describes the result of an authentication process
enum AuthenticatorResult: Int
{
    /// Authentication was successful
    case SUCCESS
    
    /// Authentication has been canceld
    case CANCLED
    
    /// Authentican failed
    case FAILED
    
    /// Alternative login method requested
    case ALTERNATIVE_METHOD_REQUESTED
    
    // If the authentication process is in progress
    case IN_PROGRESS
}

// MARK: - AuthenticatorDelegate -

/// Delegate for the Authenticato class
protocol AuthenticatorDelegate
{
    /// Evaluates an AuthenticatorResult entry
    /// Override this method do apply your custom rule set
    /// for the result handling
    ///
    /// - parameter result: An AuthenticatorResult entry
    func evaluateAuthenticatorResult(result: AuthenticatorResult)
    
    
    /// Evaluate the user input of the alternative pin-based 
    /// input field. Required for alternative user login method
    ///
    /// - parameter input: User input as a string value
    func evaluateUserInputAuthentication(input: String)
}
