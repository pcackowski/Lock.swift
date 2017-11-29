// Header.swift
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

public class HeaderView: UIView {

    weak var logoView: UIImageView?
    weak var titleView: UILabel?
    weak var closeButton: UIButton?
    weak var backButton: UIButton?

    public var onClosePressed: () -> Void = {}

    public var showClose: Bool {
        get {
            return !(self.closeButton?.isHidden ?? true)
        }
        set {
            self.closeButton?.isHidden = !newValue
        }
    }

    public var onBackPressed: () -> Void = {}

    public var showBack: Bool {
        get {
            return !(self.backButton?.isHidden ?? true)
        }
        set {
            self.backButton?.isHidden = !newValue
        }
    }

    public var title: String? {
        get {
            return self.titleView?.text
        }
        set {
            self.titleView?.text = newValue
        }
    }

    public var titleColor: UIColor = Style.Auth0.titleColor {
        didSet {
            self.titleView?.textColor = titleColor
            self.setNeedsUpdateConstraints()
        }
    }

    public var logo: UIImage? {
        get {
            return self.logoView?.image
        }
        set {
            self.logoView?.image = newValue
            self.setNeedsUpdateConstraints()
        }
    }

    public convenience init() {
        self.init(frame: CGRect.zero)
    }

    required override public init(frame: CGRect) {
        super.init(frame: frame)
        self.layoutHeader()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layoutHeader()
    }

    private func layoutHeader() {
        let titleView = UILabel()
        let logoView = UIImageView()
        let closeButton = UIButton(type: .system)
        let backButton = UIButton(type: .system)
        let centerGuide = UILayoutGuide()

        self.addLayoutGuide(centerGuide)
        self.addSubview(titleView)
        self.addSubview(logoView)
        self.addSubview(closeButton)
        self.addSubview(backButton)

        logoView.contentMode = .scaleAspectFit
        titleView.numberOfLines = 2
        titleView.textAlignment = .center

        constraintEqual(anchor: centerGuide.centerXAnchor, toAnchor: self.centerXAnchor)

        constraintEqual(anchor: logoView.centerXAnchor, toAnchor: self.centerXAnchor)
        constraintEqual(anchor: logoView.topAnchor, toAnchor: self.topAnchor, constant: Guide.gutter)
        dimension(dimension: logoView.heightAnchor, withValue: 80)
        dimension(dimension: logoView.widthAnchor, withValue: 80)
        logoView.translatesAutoresizingMaskIntoConstraints = false

        constraintEqual(anchor: titleView.topAnchor, toAnchor: logoView.bottomAnchor, constant: 32)
        constraintEqual(anchor: titleView.leftAnchor, toAnchor: self.leftAnchor, constant: Guide.gutter)
        constraintEqual(anchor: titleView.rightAnchor, toAnchor: self.rightAnchor, constant: -Guide.gutter)
        titleView.translatesAutoresizingMaskIntoConstraints = false

        constraintEqual(anchor: closeButton.centerYAnchor, toAnchor: self.topAnchor, constant: 48)
        constraintEqual(anchor: closeButton.rightAnchor, toAnchor: self.rightAnchor, constant: -16)
        closeButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        constraintEqual(anchor: backButton.centerYAnchor, toAnchor: self.topAnchor, constant: 48)
        constraintEqual(anchor: backButton.leftAnchor, toAnchor: self.leftAnchor, constant: 16)
        backButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        backButton.translatesAutoresizingMaskIntoConstraints = false

        self.apply(style: Style.Auth0)
        titleView.font = mediumSystemFont(size: Guide.headerFontSize)
        logoView.image = image(named: "ic_auth0", compatibleWithTraitCollection: self.traitCollection)
        closeButton.setBackgroundImage(image(named: "ic_close", compatibleWithTraitCollection: self.traitCollection)?.withRenderingMode(.alwaysOriginal), for: UIControlState())
        closeButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        backButton.setBackgroundImage(image(named: "ic_back", compatibleWithTraitCollection: self.traitCollection)?.withRenderingMode(.alwaysOriginal), for: UIControlState())
        backButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)

        self.titleView = titleView
        self.logoView = logoView
        self.closeButton = closeButton
        self.backButton = backButton

        self.showBack = false
    }

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 248)
    }

    @objc func buttonPressed(_ sender: UIButton) {
        if sender == self.backButton {
            self.onBackPressed()
        }

        if sender == self.closeButton {
            self.onClosePressed()
        }
    }

}

extension HeaderView: Stylable {
    func apply(style: Style) {
        self.backgroundColor = style.headerColor
        self.title = style.hideTitle ? nil : style.title
        self.titleColor = style.titleColor
        self.logo = style.logo.image(compatibleWithTraits: self.traitCollection)
        self.backButton?.setBackgroundImage(style.headerBackIcon.image(compatibleWithTraits: self.traitCollection)?.withRenderingMode(.alwaysOriginal), for: .normal)
        self.closeButton?.setBackgroundImage(style.headerCloseIcon.image(compatibleWithTraits: self.traitCollection)?.withRenderingMode(.alwaysOriginal), for: .normal)
    }
}
