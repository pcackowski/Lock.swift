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

class DatabaseSignupView: UIView, View {

    private var style: Style!

    weak var form: Form?
    weak var signupButton: PrimaryButton?
    weak var termsButton: SecondaryButton?
    weak var authCollectionView: AuthCollectionView?
    weak var passwordManagerButton: IconButton?
    weak var showPasswordButton: IconButton?

    weak var identityField: InputField?
    weak var passwordField: InputField?

    var allFields: [InputField]?

    private weak var container: UIStackView?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(allowedModes: DatabaseMode = [.Login, .Signup, .ResetPassword]) {
        let container = UIStackView()
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

    // swiftlint:disable:next function_parameter_count
    func showSignUp(withUsername showUsername: Bool, username: String?, email: String?, authCollectionView: AuthCollectionView? = nil, additionalFields: [CustomTextField], passwordPolicyValidator: PasswordPolicyValidator? = nil, showPassswordManager: Bool, showPassword: Bool, connectionOrder: ConnectionType) {
        let form = SignUpView(additionalFields: additionalFields)
        let signupButton = PrimaryButton()
        let termsButton = SecondaryButton()
        var views: [UIView?] = []

        self.form = form
        self.identityField = showUsername ? form.usernameField : form.emailField
        self.passwordField = form.passwordField
        self.signupButton = signupButton
        self.termsButton = termsButton

        form.showUsername = showUsername
        form.emailField.text = email
        form.emailField.nextField = showUsername ? form.usernameField : form.passwordField
        form.usernameField?.text = username
        form.usernameField?.nextField = form.passwordField

        self.allFields = form.stackView.arrangedSubviews.map { $0 as? InputField }.filter { $0 != nil }.map { $0! }

        signupButton.title = "SIGN UP".i18n(key: "com.auth0.lock.submit.signup.title", comment: "Signup Button title")

        if connectionOrder == .directory {
            views += [form, signupButton]
            if authCollectionView != nil { views += [SeparatorView(), authCollectionView] }
        } else {
            if authCollectionView != nil { views += [authCollectionView, SeparatorView()] }
            views += [form, signupButton]
        }
        views += [termsButton]
        self.layoutInStack(views)

        if let passwordPolicyValidator = passwordPolicyValidator {
            let passwordPolicyView = PolicyView(rules: passwordPolicyValidator.policy.rules)
            passwordPolicyValidator.delegate = passwordPolicyView
            let passwordIndex = form.stackView.arrangedSubviews.index(of: form.passwordField)
            form.stackView.insertArrangedSubview(passwordPolicyView, at: passwordIndex!)
            passwordPolicyView.isHidden = true
            form.passwordField.errorLabel?.removeFromSuperview()
            form.passwordField.onBeginEditing = { [weak self, weak passwordPolicyView] _ in
                guard let view = passwordPolicyView else { return }
                Queue.main.async {
                    view.isHidden = false
                    //self?.navigator?.scroll(toPosition: CGPoint(x: 0, y: view.intrinsicContentSize.height), animated: false)
                }
            }

            form.passwordField.onEndEditing = { [weak passwordPolicyView] _ in
                guard let view = passwordPolicyView else { return }
                view.isHidden = true
            }
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

    func apply(style: Style) {
        self.style = style
        self.passwordManagerButton?.color = style.onePasswordIconColor
    }

    override var intrinsicContentSize: CGSize {
        self.container?.layoutIfNeeded()
        return CGSize(width: UIViewNoIntrinsicMetric, height: (self.container?.intrinsicContentSize.height)!)
    }

}
