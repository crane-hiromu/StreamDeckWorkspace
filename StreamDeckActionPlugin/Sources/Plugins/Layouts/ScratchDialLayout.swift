//
//  ScratchDialLayout.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/05.
//

import Foundation
import StreamDeck

// MARK: - Layout
var scratchDialLayout: Layout {
    Layout(id: .scratchDial) {
        Text(title: "Current Scratchr")
            .textAlignment(.center)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 10)

        Text(key: ScratchDialType.currentValue.key, value: "")
            .textAlignment(.center)
            .font(size: 16, weight: 600)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 30)
    }
}

// MARK: - Key
enum ScratchDialType: String {
    case currentValue

    var key: String { rawValue }
}
