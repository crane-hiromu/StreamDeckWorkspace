//
//  PitchDialLayout.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/03.
//

import Foundation
import StreamDeck

// MARK: - Layout
var pitchDialLayout: Layout {
    Layout(id: .pitchdial) {
        Text(title: "Current Pitch")
            .textAlignment(.center)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 10)

        Text(key: PitchDialType.currentPitch.key, value: "")
            .textAlignment(.center)
            .font(size: 20, weight: 600)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 30)
    }
}

// MARK: - Key
enum PitchDialType: String {
    case currentPitch

    var key: String { rawValue }
}
