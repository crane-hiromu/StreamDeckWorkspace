//
//  RateDialLayout.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/02.
//

import Foundation
import StreamDeck

// MARK: - Layout
var rateDialLayout: Layout {
    Layout(id: .ratedial) {
        Text(title: "Current Rate")
            .textAlignment(.center)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 10)

        Text(key: RateDialType.currentVolume.key, value: "")
            .textAlignment(.center)
            .font(size: 20, weight: 600)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 30)
    }
}

// MARK: - Key
enum RateDialType: String {
    case currentVolume

    var key: String { rawValue }
}
