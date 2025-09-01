//
//  SampleDialLayout.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/02.
//

import Foundation
import StreamDeck

// MARK: - Layout
var sampleDialLayout: Layout {
    Layout(id: .sampledial) {
        // The title of the layout
        Text(title: "Current Count")
            .textAlignment(.center)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 10)

        // A large counter label
        Text(key: SampleDialType.text.key, value: "0")
            .textAlignment(.center)
            .font(size: 16, weight: 600)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 30)
    }
}

// MARK: - Key
enum SampleDialType: String {
    case text

    var key: String { rawValue }
}
