// DatabaseLoginPresenter.swift
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

class DatabaseLoginPresenter: Presentable, Loggable {

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
    var enterpriseInteractor: EnterpriseDomainInteractor?

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
        let allow = self.options.allow
        let database = DatabaseLoginView(allowedModes: allow)
        showLogin(inView: database, identifier: self.initialEmail)
        return database
    }

    private func showLogin(inView view: DatabaseLoginView, identifier: String?) {
        self.messagePresenter?.hideCurrent()
        let authCollectionView = self.authPresenter?.newViewToEmbed(withInsets: UIEdgeInsets.zero, isLogin: true)
        let style = self.database.requiresUsername ? self.options.usernameStyle : [.Email]
        view.showLogin(withIdentifierStyle: style, identifier: identifier, authCollectionView: authCollectionView, showPassswordManager: self.passwordManager.available, showPassword: self.options.allowShowPassword, connectionOrder: self.options.connectionOrder)
        let form = view.form
        form?.onValueChange = self.handleInput
        let action = { [weak form] (button: PrimaryButton) in
            self.messagePresenter?.hideCurrent()
            self.logger.info("Perform login for email: \(self.authenticator.email.verbatim())")
            button.inProgress = true

            let errorHandler: (LocalizableError?) -> Void = { error in
                Queue.main.async {
                    button.inProgress = false
                    guard let error = error else {
                        self.logger.debug("Logged in!")
                        let message = "You have logged in successfully.".i18n(key: "com.auth0.lock.database.login.success.message", comment: "User logged in")
                        if !self.options.autoClose {
                            self.messagePresenter?.showSuccess(message)
                        }
                        return
                    }
                    if case CredentialAuthError.multifactorRequired = error {
                        self.navigator.navigate(.multifactor)
                    } else {
                        form?.needsToUpdateState()
                        self.messagePresenter?.showError(error)
                        self.logger.error("Failed with error \(error)")
                    }
                }
            }

            if let connection = self.enterpriseInteractor?.connection, let domain = self.enterpriseInteractor?.domain {
                if self.options.enterpriseConnectionUsingActiveAuth.contains(connection.name) {
                    self.navigator.navigate(.enterpriseActiveAuth(connection: connection, domain: domain))
                } else {
                    self.enterpriseInteractor?.login(errorHandler)
                }
            } else {
                self.authenticator.login(errorHandler)
            }

        }

        let primaryButton = view.loginButton
        view.form?.onReturn = { [weak primaryButton] field in
            guard let button = primaryButton, field.returnKey == .done else { return } // FIXME: Log warn
            action(button)
        }
        view.loginButton?.onPress = action
        view.resetButton?.title = "Don’t remember your password?".i18n(key: "com.auth0.lock.database.button.forgot_password", comment: "Forgot password")
        view.resetButton?.color = .clear
        view.resetButton?.onPress = { _ in
            self.navigator.navigate(.forgotPassword)
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
            self.passwordManager.login {
                guard $0 == nil else {
                    return self.logger.error("There was a problem with the password manager: \($0.verbatim())")
                }
            }
        }

        view.signupButton?.onPress = { _ in
            self.navigator.navigate(.databaseSignup)
        }
    }

    private func handleInput(_ input: InputField) {
        self.messagePresenter?.hideCurrent()

        self.logger.verbose("new value: \(input.text.verbatim()) for type: \(input.type)")
        var updateHRD: Bool = false

        // TODO: enum mapping outlived its usefulness
        let attribute: UserAttribute
        switch input.type {
        case .email:
            attribute = .email
            updateHRD = true
        case .emailOrUsername:
            attribute = .emailOrUsername
            updateHRD = true
        case .password:
            attribute = .password(enforcePolicy: false)
        case .username:
            attribute = .username
        default:
            return
        }

        do {
            try self.authenticator.update(attribute, value: input.text)
            input.showValid()
            if updateHRD { // TODO: SSO Bar
                try? self.enterpriseInteractor?.updateEmail(input.text)
                if let connection = self.enterpriseInteractor?.connection {
                    self.logger.verbose("Enterprise connection detected: \(connection)")
                }
            }
        } catch let error as InputValidationError {
            input.showError(error.localizedMessage(withConnection: self.database))
        } catch {
            input.showError()
        }
    }
}
