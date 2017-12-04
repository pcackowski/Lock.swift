// DatabaseLoginView.swift
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

import UIKit

class DatabaseLoginView: UIView, View {

    private var style: Style!

    weak var form: Form?
    weak var resetButton: SecondaryButton?
    weak var loginButton: PrimaryButton?
    weak var signupButton: SecondaryButton?
    weak var authCollectionView: AuthCollectionView?
    weak var passwordManagerButton: IconButton?
    weak var showPasswordButton: IconButton?

    weak var identityField: InputField?
    weak var passwordField: InputField?

    private weak var container: UIStackView?
    let allowedModes: DatabaseMode

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(allowedModes: DatabaseMode = [.Login, .Signup, .ResetPassword]) {
        let container = UIStackView()

        self.allowedModes = allowedModes
        self.container = container

        super.init(frame: CGRect.zero)

        self.addSubview(container)

        container.alignment = .fill
        container.axis = .vertical
        container.distribution = .equalSpacing
        container.spacing = Guide.inputFieldSpacing * 2.0

        constraintEqual(anchor: container.leftAnchor, toAnchor: self.leftAnchor, constant: Guide.gutter)
        constraintEqual(anchor: container.topAnchor, toAnchor: self.topAnchor)
        constraintEqual(anchor: container.rightAnchor, toAnchor: self.rightAnchor, constant: -Guide.gutter)
        container.translatesAutoresizingMaskIntoConstraints = false
    }

    func showLogin(withIdentifierStyle style: DatabaseIdentifierStyle, identifier: String? = nil, authCollectionView: AuthCollectionView? = nil, showPassswordManager: Bool, showPassword: Bool, connectionOrder: ConnectionType) {
        let form = CredentialView()
        let loginButton = PrimaryButton()
        let resetButton = SecondaryButton()
        var views: [UIView?] = []

        let type: InputField.InputType
        switch style {
        case [.Email, .Username]:
            type = .emailOrUsername
        case [.Username]:
            type = .username
        default:
            type = .email
        }

        form.identityField.text = identifier
        form.identityField.type = type
        form.identityField.returnKey = .next
        form.identityField.nextField = form.passwordField
        form.passwordField.returnKey = .done
        loginButton.title = "LOG IN".i18n(key: "com.auth0.lock.submit.login.title", comment: "Login Button title")
        resetButton.title = "Forgot Password?".i18n(key: "com.auth0.lock.database.button.forgot_password", comment: "Forgot password")

        self.form = form
        self.loginButton = loginButton
        self.resetButton = resetButton
        self.identityField = form.identityField
        self.passwordField = form.passwordField
        self.authCollectionView = authCollectionView

        if connectionOrder == .directory {
            views += [form, loginButton]
            if authCollectionView != nil { views += [SeparatorView(), authCollectionView] }
        } else {
            if authCollectionView != nil { views += [authCollectionView, SeparatorView()] }
            views += [form, loginButton]
        }

        if self.allowedModes.contains(.ResetPassword) {
            views.append(resetButton)
        }

        self.layoutInStack(views)

        if self.allowedModes.contains(.Signup) {
            self.addSignupFooter()
        }

        if showPassswordManager {
            self.passwordManagerButton = form.passwordField.addFieldButton(withIcon: "ic_onepassword", color: Style.Auth0.onePasswordIconColor)
        } else if showPassword, let passwordInput = form.passwordField.textField {
            self.showPasswordButton = form.passwordField.addFieldButton(withIcon: "ic_show_password_hidden", color: Style.Auth0.inputIconColor)
            self.showPasswordButton?.onPress = { [unowned self] button in
                passwordInput.isSecureTextEntry = !passwordInput.isSecureTextEntry
                button.icon = LazyImage(name: passwordInput.isSecureTextEntry ? "ic_show_password_hidden" : "ic_show_password_visible", bundle: Lock.bundle).image(compatibleWithTraits: self.traitCollection)
            }
        }
    }

    private func layoutInStack(_ views: [UIView?]) {
        views.forEach {
            if let view = $0 { self.container?.addArrangedSubview(view) }
        }
        if let style = self.style {
            self.container?.styleSubViews(style: style)
        }
    }

    private func addSignupFooter() {
        let signupButton = SecondaryButton()
        let message = UILabel()

        self.signupButton = signupButton

        self.addSubview(signupButton)
        self.addSubview(message)

        signupButton.title = "Sign Up".i18n(key: "com.auth0.lock.submit.signup.title", comment: "Signup Button title")
        message.text = "Don't have an account?".i18n(key: "com.auth0.lock.database.message.signup", comment: "Signup message")
        message.textColor = UIColor.Auth0.night
        message.font = mediumSystemFont(size: Guide.inputFontSize)

        // TODO: Tidy up
        let spacer = ((signupButton.button?.intrinsicContentSize.width)! * 0.5)
        constraintEqual(anchor: signupButton.bottomAnchor, toAnchor: self.bottomAnchor, constant: -Guide.gutterFooter)
        constraintEqual(anchor: signupButton.leftAnchor, toAnchor: message.rightAnchor, constant: Guide.inputFieldSpacing)
        dimension(dimension: signupButton.widthAnchor, withValue: (signupButton.button?.intrinsicContentSize.width)!)
        signupButton.translatesAutoresizingMaskIntoConstraints = false

        constraintEqual(anchor: message.centerXAnchor, toAnchor: self.centerXAnchor, constant: -spacer)
        constraintEqual(anchor: message.centerYAnchor, toAnchor: signupButton.centerYAnchor)
        message.translatesAutoresizingMaskIntoConstraints = false
    }

    func apply(style: Style) {
        self.style = style
        self.passwordManagerButton?.color = style.onePasswordIconColor
    }

    override var intrinsicContentSize: CGSize {
        self.container?.layoutIfNeeded()
        return CGSize(width: UIViewNoIntrinsicMetric, height: UIViewNoIntrinsicMetric)
    }

}
