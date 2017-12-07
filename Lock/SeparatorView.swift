// SeparatorView.swift
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

class SeparatorView: UIView {

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required override init(frame: CGRect) {
        super.init(frame: frame)
        self.layout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layout()
    }

    private func layout() {
        let label = UILabel()
        label.font = mediumSystemFont(size: Design.guide.generalFontSize)
        label.textColor = UIColor.Auth0.steel
        label.text = "OR".i18n(key: "com.auth0.lock.database.separator", comment: "Form separator")

        let lineLeft = UIView()
        let lineRight = UIView()
        lineLeft.backgroundColor = UIColor.Auth0.steel
        lineRight.backgroundColor = UIColor.Auth0.steel

        self.addSubview(label)
        self.addSubview(lineLeft)
        self.addSubview(lineRight)

        constraintEqual(anchor: lineLeft.leftAnchor, toAnchor: self.leftAnchor)
        constraintEqual(anchor: lineLeft.rightAnchor, toAnchor: label.leftAnchor, constant: -Design.guide.fieldHeight * 0.5)
        constraintEqual(anchor: lineLeft.centerYAnchor, toAnchor: self.centerYAnchor)
        dimension(dimension: lineLeft.heightAnchor, withValue: 1)
        lineLeft.translatesAutoresizingMaskIntoConstraints = false

        constraintEqual(anchor: lineRight.leftAnchor, toAnchor: label.rightAnchor, constant: Design.guide.fieldHeight * 0.5)
        constraintEqual(anchor: lineRight.rightAnchor, toAnchor: self.rightAnchor)
        constraintEqual(anchor: lineRight.centerYAnchor, toAnchor: self.centerYAnchor)
        dimension(dimension: lineRight.heightAnchor, withValue: 1)
        lineRight.translatesAutoresizingMaskIntoConstraints = false

        constraintEqual(anchor: label.centerXAnchor, toAnchor: self.centerXAnchor)
        constraintEqual(anchor: label.centerYAnchor, toAnchor: self.centerYAnchor)
        label.translatesAutoresizingMaskIntoConstraints = false
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: Design.guide.fieldSpacing * 2.0)
    }
}
