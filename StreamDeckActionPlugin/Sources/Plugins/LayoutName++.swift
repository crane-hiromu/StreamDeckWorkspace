//
//  LayoutName++.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/08/31.
//

import Foundation
import StreamDeck

// MARK: - Extension
extension LayoutName {
    static let sampledial: LayoutName = "sampledial"
    static let volumedial: LayoutName = "volumedial"
    static let ratedial: LayoutName = "ratedial"
    static let pitchdial: LayoutName = "pitchdial"
    static let isolatorDial: LayoutName = "isolatordial"
    static let delayDial: LayoutName = "delaydial"
    static let flangerDial: LayoutName = "flangerdial"

    static func layout(name: LayoutName) -> Self {
        .init("Layouts/\(name).json")
    }
}
