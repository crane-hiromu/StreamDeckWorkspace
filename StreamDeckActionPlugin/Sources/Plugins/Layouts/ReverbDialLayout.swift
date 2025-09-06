//
//  ReverbDialLayout.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/05.
//

import Foundation
import StreamDeck

// MARK: - Layout
var reverbDialLayout: Layout {
    Layout(id: .reverbDial) {
        Text(title: "Current Reverb")
            .textAlignment(.center)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 10)

        Text(key: ReverbDialType.currentValue.key, value: "-")
            .textAlignment(.center)
            .font(size: 16, weight: 600)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 30)
    }
}

// MARK: - Key
enum ReverbDialType: String {
    case currentValue

    var key: String { rawValue }
}
