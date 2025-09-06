//
//  DelayDialLayout.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Layout
var delayDialLayout: Layout {
    Layout(id: .delayDial) {
        Text(title: "Current Delay")
            .textAlignment(.center)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 10)

        Text(key: DelayDialType.currentValue.key, value: "-")
            .textAlignment(.center)
            .font(size: 16, weight: 600)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 30)
    }
}

// MARK: - Key
enum DelayDialType: String {
    case currentValue

    var key: String { rawValue }
}
