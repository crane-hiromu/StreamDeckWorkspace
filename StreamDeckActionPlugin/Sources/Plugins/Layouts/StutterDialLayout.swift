//
//  StutterDialLayout.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import StreamDeck

// MARK: - Layout
var stutterDialLayout: Layout {
    Layout(id: .stutterDial) {
        Text(title: "Segment Length")
            .textAlignment(.center)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 10)

        Text(key: StutterDialType.segmentLength.key, value: "0.25s")
            .textAlignment(.center)
            .font(size: 16, weight: 600)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 30)
    }
}

// MARK: - Key
enum StutterDialType: String {
    case segmentLength

    var key: String { rawValue }
}
