// PrimaryButton.swift
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

class PrimaryButton: UIView, Stylable {

    weak var button: UIButton?
    weak var indicator: UIActivityIndicatorView?

    var hideTitle: Bool = false {
        didSet {
            guard let button = self.button else { return }
            self.layout(title: self.title, inButton: button)
        }
    }

    var title: String? = nil {
        didSet {
            guard let button = self.button else { return }
            self.layout(title: self.title, inButton: button)
        }
    }

    var onPress: (PrimaryButton) -> Void = {_ in }

    var inProgress: Bool {
        get {
            return !(self.button?.isEnabled ?? true)
        }
        set {
            self.button?.isEnabled = !newValue
            if newValue {
                self.indicator?.startAnimating()
            } else {
                self.indicator?.stopAnimating()
            }
        }
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required override init(frame: CGRect) {
        super.init(frame: frame)
        self.layoutButton()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layoutButton()
    }

    private func layoutButton() {
        let button = UIButton(type: .custom)
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)

        self.addSubview(button)
        self.addSubview(indicator)

        constraintEqual(anchor: button.leftAnchor, toAnchor: self.leftAnchor)
        constraintEqual(anchor: button.topAnchor, toAnchor: self.topAnchor)
        constraintEqual(anchor: button.rightAnchor, toAnchor: self.rightAnchor)
        constraintEqual(anchor: button.bottomAnchor, toAnchor: self.bottomAnchor)
        button.translatesAutoresizingMaskIntoConstraints = false

        constraintEqual(anchor: indicator.centerXAnchor, toAnchor: self.centerXAnchor)
        constraintEqual(anchor: indicator.centerYAnchor, toAnchor: self.centerYAnchor)
        indicator.translatesAutoresizingMaskIntoConstraints = false

        layout(title: self.title, inButton: button)
        button.addTarget(self, action: #selector(pressed), for: .touchUpInside)

        indicator.hidesWhenStopped = true
        button.titleLabel?.font = mediumSystemFont(size: Guide.inputFontSize)
        button.layer.cornerRadius = 3
        button.layer.masksToBounds = true

        apply(style: Style.Auth0)

        self.button = button
        self.indicator = indicator
    }

    private func layout(title: String?, inButton button: UIButton) {
        button.setTitle(title, for: .normal)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: Guide.inputHeight)
    }

    @objc func pressed(_ sender: Any) {
        self.onPress(self)
    }

    func apply(style: Style) {
        self.button?.backgroundColor = style.primaryColor
        self.button?.tintColor = style.buttonTintColor
        self.indicator?.color = style.disabledTextColor
    }
}
