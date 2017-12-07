// Colors.swift
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

extension UIColor {

    struct Auth0 {

        static let orange: UIColor = UIColor(red: 0.922, green: 0.329, blue: 0.141, alpha: 1.00)
        static let night: UIColor = UIColor(red: 0.133, green: 0.133, blue: 0.157, alpha: 1.00) // OK
        static let grey: UIColor = UIColor(red: 0.890, green: 0.898, blue: 0.906, alpha: 1.00)  // OK
        static let steel: UIColor = UIColor(red: 0.608, green: 0.608, blue: 0.608, alpha: 1.00) // OK
        static let dark: UIColor = UIColor(red: 0.200, green: 0.200, blue: 0.200, alpha: 1.00)
        static let success: UIColor = UIColor(red: 0.384, green: 0.835, blue: 0.200, alpha: 1.00)
        static let alert: UIColor = UIColor(red: 0.384, green: 0.835, blue: 0.200, alpha: 1.00)
        static let link: UIColor = UIColor(red: 0.035, green: 0.576, blue: 0.757, alpha: 1.00)

        static let active: UIColor = UIColor(red: 0.267, green: 0.780, blue: 0.957, alpha: 1.00) // Not In Color Guide

        static func from(rgb: String, defaultColor: UIColor = UIColor.black) -> UIColor {
            guard rgb.hasPrefix("#") else { return defaultColor }

            let hexString: String = String(rgb[rgb.index(rgb.startIndex, offsetBy: 1)...])
            var hexValue: UInt32 = 0

            guard Scanner(string: hexString).scanHexInt32(&hexValue) else {
                return defaultColor
            }

            let divisor = CGFloat(255)
            let red = CGFloat((hexValue & 0xFF0000) >> 16) / divisor
            let green = CGFloat((hexValue & 0x00FF00) >>  8) / divisor
            let blue = CGFloat(hexValue & 0x0000FF) / divisor
            return  UIColor(red: red, green: green, blue: blue, alpha: 1)
        }
    }
}

struct Design {

    static var guide: DesignGuide {
        if UIDevice.current.userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
                //            case 1136:
                //                self.size = .compact
                //            case 1334:
                //                self.size = .regular
                //            case 2208:
                //                self.size = .plus
                //            case 2436:
            //                self.size = .tall
            default:
                 return Design.Regular()
            }
        }
        return Design.Regular()
    }

    private struct Regular: DesignGuide {
        let generalFontSize: CGFloat = 14.0
        let headerFontSize: CGFloat = 16.0
        let fieldSpacing: CGFloat = 8.0
        let stackSpacing: CGFloat = 16.0
        let topMargin: CGFloat = 64.0
        let sideMargin: CGFloat = 64.0
        let bottomMargin: CGFloat = 40.0
        let fieldHeight: CGFloat = 48
        let oAuthMaxButtons: Int = 2
    }
}

protocol DesignGuide {
    var generalFontSize: CGFloat { get }
    var headerFontSize: CGFloat { get }
    var fieldSpacing: CGFloat { get }
    var stackSpacing: CGFloat { get }
    var topMargin: CGFloat { get }
    var sideMargin: CGFloat { get }
    var bottomMargin: CGFloat { get }
    var fieldHeight: CGFloat { get }
    var oAuthMaxButtons: Int { get }
}
