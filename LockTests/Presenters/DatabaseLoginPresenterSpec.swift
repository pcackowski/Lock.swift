// DatabaseLoginPresenterSpec.swift
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

import Quick
import Nimble

@testable import Lock

class DatabaseLoginPresenterSpec: QuickSpec {

    override func spec() {
        var enterpriseInteractor: EnterpriseDomainInteractor!
        var oauth2: MockOAuth2!
        var connections: OfflineConnections!
        var interactor: MockDBInteractor!
        var presenter: DatabaseLoginPresenter!
        var view: DatabaseLoginView!
        var messagePresenter: MockMessagePresenter!
        var authPresenter: MockAuthPresenter!
        var navigator: MockNavigator!
        var options: OptionBuildable!
        var user: User!
        var passwordManager: MockPasswordManager!

        beforeEach {
            oauth2 = MockOAuth2()
            connections = OfflineConnections()
            options = LockOptions()
            user = User()
            passwordManager = MockPasswordManager()
            enterpriseInteractor = EnterpriseDomainInteractor(connections: connections, user: user, authentication: oauth2)
            authPresenter = MockAuthPresenter(connections: [], interactor: MockAuthInteractor(), customStyle: [:])
            messagePresenter = MockMessagePresenter()
            interactor = MockDBInteractor()
            navigator = MockNavigator()
            presenter = DatabaseLoginPresenter(authenticator: interactor, creator: interactor, connection: DatabaseConnection(name: connection, requiresUsername: true), navigator: navigator, options: options)
            presenter.messagePresenter = messagePresenter
            view = presenter.view as! DatabaseLoginView
        }

        describe("auth buttons") {

            it("should init view with social view") {
                presenter.authPresenter = authPresenter
                let view = presenter.view as? DatabaseLoginView
                expect(view?.authCollectionView) == authPresenter.authView
            }

            it("should init view with not social view") {
                presenter.authPresenter = nil
                let view = presenter.view as? DatabaseLoginView
                expect(view?.authCollectionView).to(beNil())
            }

            it("should set message presenter") {
                let messagePresenter = MockMessagePresenter()
                presenter.authPresenter = authPresenter
                presenter.messagePresenter = messagePresenter
                expect(authPresenter.messagePresenter).toNot(beNil())
            }
        }

        describe("user state") {

            it("should return initial valid email") {
                interactor.validEmail = true
                interactor.email = email
                expect(presenter.initialEmail) == email
            }

            it("should not return initial invalid email") {
                interactor.validEmail = false
                interactor.email = email
                expect(presenter.initialEmail).to(beNil())
            }

            it("should return initial valid username") {
                interactor.validUsername = true
                interactor.username = username
                expect(presenter.initialUsername) == username
            }

            it("should not return initial invalid email") {
                interactor.validUsername = false
                interactor.username = username
                expect(presenter.initialUsername).to(beNil())
            }

        }

        describe("allowed modes & initial screen") {

            it("should remove forgot button if it's not allowed") {
                var options = LockOptions()
                options.allow = [.Login]
                presenter = DatabaseLoginPresenter(authenticator: interactor, creator: interactor, connection: DatabaseConnection(name: connection, requiresUsername: true), navigator: navigator, options: options)
                view = presenter.view as! DatabaseLoginView
                expect(view.resetButton).to(beNil())
            }

            it("should show login if is allowed and is initial screen") {
                var options = LockOptions()
                options.allow = [.Login]
                options.initialScreen = .login
                presenter = DatabaseLoginPresenter(authenticator: interactor, creator: interactor, connection: DatabaseConnection(name: connection, requiresUsername: true), navigator: navigator, options: options)
                view = presenter.view as! DatabaseLoginView
                expect(view.form as? CredentialView).toNot(beNil())
            }

// TODO: Move to Router
//            it("should show signup if login is not allowed") {
//                var options = LockOptions()
//                options.allow = [.Signup]
//                presenter = DatabaseLoginPresenter(authenticator: interactor, creator: interactor, connection: DatabaseConnection(name: connection, requiresUsername: true), navigator: navigator, options: options)
//                view = presenter.view as! DatabaseLoginView
//                expect(view.form as? SignUpView).toNot(beNil())
//            }
//
//            it("should show signup if is the initial screen") {
//                var options = LockOptions()
//                options.allow = [.Signup, .Login]
//                options.initialScreen = .signup
//                presenter = DatabaseLoginPresenter(authenticator: interactor, creator: interactor, connection: DatabaseConnection(name: connection, requiresUsername: true), navigator: navigator, options: options)
//                view = presenter.view as! DatabaseLoginView
//                expect(view.form as? SignUpView).toNot(beNil())
//            }
//
//            it("should always show terms button in signup") {
//                var options = LockOptions()
//                options.allow = [.Signup]
//                presenter = DatabaseLoginPresenter(authenticator: interactor, creator: interactor, connection: DatabaseConnection(name: connection, requiresUsername: true), navigator: navigator, options: options)
//                view = presenter.view as! DatabaseLoginView
//                expect(view.resetButton).toNot(beNil())
//            }

        }

        describe("login") {

            it("should set title for secondary button") {
                expect(view.resetButton?.title) == "Forgot Password?".i18n(key: "com.auth0.lock.database.button.forgot_password", comment: "Forgot password")
            }


            it("should set button title") {
                expect(view.loginButton?.title) == "LOG IN"
            }

            it("should not show password manager button") {
                expect(view.passwordManagerButton).to(beNil())
            }

            it("should have show password button") {
                expect(view.showPasswordButton).toNot(beNil())
            }

            context("with password manager available") {

                beforeEach {
                    presenter.passwordManager = passwordManager
                    view = presenter.view as! DatabaseLoginView
                }

                it("should show password manager button") {
                    expect(view.passwordManagerButton).toNot(beNil())
                }

                it("should not show password manager when disabled") {
                    presenter.passwordManager.enabled = false
                    view = presenter.view as! DatabaseLoginView
                    expect(view.passwordManagerButton).to(beNil())
                }

                it("should not have show password button") {
                    expect(view.showPasswordButton).to(beNil())
                }
            }

            describe("user input") {

                it("should clear global message") {
                    messagePresenter.showError(CredentialAuthError.couldNotLogin)
                    let input = mockInput(.email, value: email)
                    view.form?.onValueChange(input)
                    expect(messagePresenter.error).to(beNil())
                    expect(messagePresenter.message).to(beNil())
                }

                it("should update email") {
                    let input = mockInput(.email, value: email)
                    view.form?.onValueChange(input)
                    expect(interactor.email) == email
                }

                it("should update username") {
                    let input = mockInput(.username, value: username)
                    view.form?.onValueChange(input)
                    expect(interactor.username) == username
                }

                it("should update password") {
                    let input = mockInput(.password, value: password)
                    view.form?.onValueChange(input)
                    expect(interactor.password) == password
                }

                it("should update username or email") {
                    let input = mockInput(.emailOrUsername, value: username)
                    view.form?.onValueChange(input)
                    expect(interactor.username) == username
                }

                it("should not update if type is not valid for db connection") {
                    let input = mockInput(.phone, value: "+1234567890")
                    view.form?.onValueChange(input)
                    expect(interactor.username).to(beNil())
                    expect(interactor.email).to(beNil())
                    expect(interactor.password).to(beNil())
                }

                it("should hide the field error if value is valid") {
                    let input = mockInput(.username, value: username)
                    view.form?.onValueChange(input)
                    expect(input.valid) == true
                }

                it("should show field error if value is invalid") {
                    let input = mockInput(.username, value: "invalid")
                    view.form?.onValueChange(input)
                    expect(input.valid) == false
                }

                it("should toggle show password") {
                    expect(view.passwordField?.textField?.isSecureTextEntry).to(beTrue())
                    view.showPasswordButton?.onPress(view.showPasswordButton!)
                    expect(view.passwordField?.textField?.isSecureTextEntry).to(beFalse())
                }

            }

            // MARK:- Log In
            describe("login action") {

                it("should trigger action on return of last field") {
                    let input = mockInput(.password, value: password)
                    input.returnKey = .done
                    waitUntil { done in
                        interactor.onLogin = {
                            done()
                            return nil
                        }
                        view.form?.onReturn(input)
                    }
                }

                it("should not trigger action if return key is not .Done") {
                    let input = mockInput(.password, value: password)
                    input.returnKey = .next
                    interactor.onLogin = {
                        return .couldNotLogin
                    }
                    view.form?.onReturn(input)
                    expect(messagePresenter.message).toEventually(beNil())
                    expect(messagePresenter.error).toEventually(beNil())
                }

                it("should clear global message") {
                    messagePresenter.showError(CredentialAuthError.couldNotLogin)
                    interactor.onLogin = {
                        return nil
                    }
                    view.loginButton?.onPress(view.loginButton!)
                    expect(messagePresenter.error).toEventually(beNil())
                    expect(messagePresenter.message).toEventually(beNil())
                }

                it("should show global error message") {
                    interactor.onLogin = {
                        return .couldNotLogin
                    }
                    view.loginButton?.onPress(view.loginButton!)
                    expect(messagePresenter.error).toEventually(beError(error: CredentialAuthError.couldNotLogin))
                }

                it("should show no success message") {
                    interactor.onLogin = {
                        return nil
                    }
                    view.loginButton?.onPress(view.loginButton!)
                    expect(messagePresenter.error).toEventually(beNil())
                    expect(messagePresenter.message).toEventually(beNil())
                }

                it("should navigate to multifactor required screen") {
                    interactor.onLogin = {
                        return .multifactorRequired
                    }
                    view.loginButton?.onPress(view.loginButton!)
                    expect(navigator.route).toEventually(equal(Route.multifactor))
                }

                it("should trigger login on button press") {
                    waitUntil { done in
                        interactor.onLogin = {
                            done()
                            return nil
                        }
                        view.loginButton?.onPress(view.loginButton!)
                    }
                }

                it("should set button in progress on button press") {
                    let button = view.loginButton!
                    waitUntil { done in
                        interactor.onLogin = {
                            expect(button.inProgress) == true
                            done()
                            return nil
                        }
                        button.onPress(button)
                    }
                }

                it("should set button to normal after login") {
                    let button = view.loginButton!
                    button.onPress(button)
                    expect(button.inProgress).toEventually(beFalse())
                }

                it("should navigate to forgot password") {
                    let button = view.resetButton!
                    button.onPress(button)
                    expect(navigator.route).toEventually(equal(Route.forgotPassword))
                }

                it("should always show terms button in signup") {
                    var options = LockOptions()
                    options.autoClose = false
                    presenter = DatabaseLoginPresenter(authenticator: interactor, creator: interactor, connection: DatabaseConnection(name: connection, requiresUsername: true), navigator: navigator, options: options)
                    presenter.messagePresenter = messagePresenter
                    view = presenter.view as! DatabaseLoginView
                    interactor.onLogin = {
                        return nil
                    }
                    view.loginButton?.onPress(view.loginButton!)
                    expect(messagePresenter.error).toEventually(beNil())
                    expect(messagePresenter.message).toEventuallyNot(beNil())
                }
            }

            context("password manager") {

                var username: String?
                var password: String?

                beforeEach {
                    username = nil
                    password = nil
                    presenter.passwordManager = passwordManager
                    view = presenter.view as! DatabaseLoginView
                    presenter.passwordManager.onUpdate = { username = $0; password = $1 }
                }

                it("should trigger password manager and return username and password") {
                    view.passwordManagerButton?.pressed(view.passwordManagerButton!)
                    expect(username).toNot(beNil())
                    expect(password).toNot(beNil())
                }
            }
        }


        describe("enterprise support") {

            beforeEach {
                connections = OfflineConnections()
                connections.enterprise(name: "validAD", domains: ["valid.com"])

                enterpriseInteractor = EnterpriseDomainInteractor(connections: connections, user: user, authentication: oauth2)
                presenter.enterpriseInteractor = enterpriseInteractor

                view = presenter.view as! DatabaseLoginView
            }

            it("should modify email attribute") {
                let input = mockInput(.email, value: "user@valid.com")
                view.form?.onValueChange(input)
                expect(enterpriseInteractor.email) == "user@valid.com"
                expect(interactor.email) == "user@valid.com"
            }

            it("should modify email attribute when username is allowed") {
                let input = mockInput(.emailOrUsername, value: "user@valid.com")
                view.form?.onValueChange(input)
                expect(enterpriseInteractor.email) == "user@valid.com"
                expect(interactor.email) == "user@valid.com"
                expect(interactor.username) == "user@valid.com"
            }

            it("should ignore password input") {
                let input = mockInput(.password, value: "random password")
                view.form?.onValueChange(input)
                expect(enterpriseInteractor.email).to(beNil())
                expect(interactor.email).to(beNil())
                expect(interactor.username).to(beNil())
            }

// TODO: Restore (Once SSO Added)
//            context("enterprise mode") {
//
//                beforeEach {
//                    let input = mockInput(.email, value: "user@valid.com")
//                    view.form?.onValueChange(input)
//                }
//
//                it("should return identity returntype as .Done") {
//                    let form = view.form as! CredentialView
//                    expect(form.identityField.returnKey).to(equal(UIReturnKeyType.done))
//                }
//
//                it("should restore identity returntype as .Next") {
//                    let input = mockInput(.email, value: "user@invalid.com")
//                    view.form?.onValueChange(input)
//
//                    let form = view.form as! CredentialView
//                    expect(form.identityField.returnKey).to(equal(UIReturnKeyType.next))
//                }
//
//                it("should show no error on success") {
//                    let input = mockInput(.email, value: "user@valid.com")
//                    view.form?.onValueChange(input)
//                    view.loginButton?.onPress(view.loginButton!)
//                    expect(messagePresenter.error).toEventually(beNil())
//                }
//
//            }

            context("enterprise mode with credential auth enabled") {

                beforeEach {
                    var options = LockOptions()
                    options.enterpriseConnectionUsingActiveAuth = ["validAD"]

                    connections = OfflineConnections()
                    connections.enterprise(name: "validAD", domains: ["valid.com"])

                    presenter = DatabaseLoginPresenter(authenticator: interactor, creator: interactor, connection: DatabaseConnection(name: connection, requiresUsername: true), navigator: navigator, options: options)
                    enterpriseInteractor = EnterpriseDomainInteractor(connections: connections, user: user, authentication: oauth2)
                    presenter.enterpriseInteractor = enterpriseInteractor

                    view = presenter.view as! DatabaseLoginView

                    let input = mockInput(.email, value: "user@valid.com")
                    view.form?.onValueChange(input)

                }

                it("should navigate to enterprise password presenter") {
                    view.loginButton?.onPress(view.loginButton!)
                    let connection = presenter.enterpriseInteractor?.connection!
                    expect(connection).toNot(beNil())
                    expect(navigator.route).toEventually(equal(Route.enterpriseActiveAuth(connection: connection!, domain: "valid.com")))
                }

            }

        }

    }
}


func haveAction(_ title: String, style: UIAlertActionStyle) -> Predicate<[UIAlertAction]> {
    return Predicate<[UIAlertAction]>.define("have action with title \(title) and style \(style)") { expression, failureMessage -> PredicateResult in
        if let actions = try expression.evaluate() {
            if actions.contains(where: { alert in
                return alert.title == title && alert.style == style
            }) { return PredicateResult(status: .matches, message: failureMessage) }
        }
        return PredicateResult(status: .doesNotMatch, message: failureMessage)
    }
}
