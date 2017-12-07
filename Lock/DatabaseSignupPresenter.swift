// DatabaseSignupPresenter.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import SafariServices

class DatabaseSignupPresenter: Presentable, Loggable {

    let database: DatabaseConnection
    let options: Options

    var authenticator: DatabaseAuthenticatable
    var creator: DatabaseUserCreator
    var navigator: Navigable

    var messagePresenter: MessagePresenter? {
        didSet {
            self.authPresenter?.messagePresenter = self.messagePresenter
        }
    }

    var passwordManager: PasswordManager
    var authPresenter: AuthPresenter?

    var initialEmail: String? { return self.authenticator.validEmail ? self.authenticator.email : nil }
    var initialUsername: String? { return self.authenticator.validUsername ? self.authenticator.username : nil }

    convenience init(interactor: DatabaseInteractor, connection: DatabaseConnection, navigator: Navigable, options: Options) {
        self.init(authenticator: interactor, creator: interactor, connection: connection, navigator: navigator, options: options)
    }

    init(authenticator: DatabaseAuthenticatable, creator: DatabaseUserCreator, connection: DatabaseConnection, navigator: Navigable, options: Options) {
        self.authenticator = authenticator
        self.creator = creator
        self.database = connection
        self.navigator = navigator
        self.options = options
        self.passwordManager = options.passwordManager
    }

    var view: View {
        let database = DatabaseSignupView()
        self.showSignup(inView: database, username: self.initialUsername, email: self.initialEmail)
        return database
    }

    private func showSignup(inView view: DatabaseSignupView, username: String?, email: String?) {
        self.messagePresenter?.hideCurrent()
        let authCollectionView = self.authPresenter?.newViewToEmbed(withInsets: UIEdgeInsets.zero, isLogin: false)
        let interactor = self.authenticator as? DatabaseInteractor
        let passwordPolicyValidator = interactor?.passwordValidator as? PasswordPolicyValidator
        interactor?.user.reset()
        view.showSignUp(withUsername: self.database.requiresUsername, username: username, email: email, authCollectionView: authCollectionView, additionalFields: self.options.customSignupFields, passwordPolicyValidator: passwordPolicyValidator, showPassswordManager: self.passwordManager.available, showPassword: self.options.allowShowPassword, connectionOrder: self.options.connectionOrder)
        let form = view.form
        view.form?.onValueChange = self.handleInput
        let action = { [weak form, weak view] (button: PrimaryButton) in
            self.messagePresenter?.hideCurrent()
            self.logger.info("Perform sign up for email \(self.creator.email.verbatim())")
            view?.allFields?.forEach { self.handleInput($0) }
            let interactor = self.creator
            button.inProgress = true
            interactor.create { createError, loginError in
                Queue.main.async {
                    button.inProgress = false
                    guard createError != nil || loginError != nil else {
                        if !self.options.loginAfterSignup {
// TODO: Discuss
//                            let message = "Thanks for signing up.".i18n(key: "com.auth0.lock.database.signup.success.message", comment: "User signed up")
//                            if let databaseView = self.databaseView, self.options.allow.contains(.Login) {
//                                //self.databaseView?.switcher?.selected = .login
//                                self.showLogin(inView: databaseView, identifier: self.creator.identifier)
//                            }
//                            if self.options.allow.contains(.Login) || !self.options.autoClose {
//                                self.messagePresenter?.showSuccess(message)
//                            }
                        }
                        return
                    }
                    if let error = loginError, case .multifactorRequired = error {
                        self.navigator.navigate(.multifactor)
                        return
                    }
                    let error: LocalizableError = createError ?? loginError!
                    form?.needsToUpdateState()
                    self.messagePresenter?.showError(error)
                    self.logger.error("Failed with error \(error)")
                }
            }
        }

        view.form?.onReturn = { [weak view] field in
            guard let button = view?.signupButton, field.returnKey == .done else {
                self.logger.warn("Button missing")
                return
            }
            action(button)
        }
        view.signupButton?.onPress = action
        view.termsButton?.title = "By signing up, you agree to our terms of\n service and privacy policy".i18n(key: "com.auth0.lock.database.button.tos", comment: "tos & privacy")
        view.termsButton?.onPress = { button in
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.popoverPresentationController?.sourceView = button
            alert.popoverPresentationController?.sourceRect = button.bounds
            let cancel = UIAlertAction(title: "Cancel".i18n(key: "com.auth0.lock.database.tos.sheet.cancel", comment: "Cancel"), style: .cancel, handler: nil)
            let tos = UIAlertAction(title: "Terms of Service".i18n(key: "com.auth0.lock.database.tos.sheet.title", comment: "ToS"), style: .default, handler: safariBuilder(forURL: self.options.termsOfServiceURL as URL, navigator: self.navigator))
            let privacy = UIAlertAction(title: "Privacy Policy".i18n(key: "com.auth0.lock.database.tos.sheet.privacy", comment: "Privacy"), style: .default, handler: safariBuilder(forURL: self.options.privacyPolicyURL as URL, navigator: self.navigator))
            [cancel, tos, privacy].forEach { alert.addAction($0) }
            self.navigator.present(alert)
        }

        if let identifyField = view.identityField, let passwordField = view.passwordField {
            passwordManager.onUpdate = { [unowned self, unowned identifyField, unowned passwordField] identifier, password in
                identifyField.text = identifier
                passwordField.text = password
                self.handleInput(identifyField)
                self.handleInput(passwordField)
            }
        }

        view.passwordManagerButton?.onPress = { _ in
            self.passwordManager.store(withPolicy: passwordPolicyValidator?.policy.onePasswordRules(), identifier: self.creator.identifier) {
                guard $0 == nil else {
                    return self.logger.error("There was a problem with the password manager: \($0.verbatim())")
                }
            }
        }
    }

    private func handleInput(_ input: InputField) {
        self.messagePresenter?.hideCurrent()
        self.logger.verbose("new value: \(input.text.verbatim()) for type: \(input.type)")
        // FIXME: enum mapping outlived its usefulness
        let attribute: UserAttribute
        switch input.type {
        case .email:
            attribute = .email
        case .emailOrUsername:
            attribute = .emailOrUsername
        case .password:
            attribute = .password(enforcePolicy: true)
        case .username:
            attribute = .username
        case .custom(let name, _, _, _, _, _):
            attribute = .custom(name: name)
        default:
            return
        }

        do {
            try self.authenticator.update(attribute, value: input.text)
            input.showValid()
        } catch let error as InputValidationError {
            input.showError(error.localizedMessage(withConnection: self.database))
        } catch {
            input.showError()
        }
    }
}

private func safariBuilder(forURL url: URL, navigator: Navigable) -> (UIAlertAction) -> Void {
    return { _ in
        let safari = SFSafariViewController(url: url)
        navigator.present(safari)
    }
}
