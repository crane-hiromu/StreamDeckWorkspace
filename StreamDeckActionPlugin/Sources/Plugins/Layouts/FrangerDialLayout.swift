//
//  FlangerDialLayout.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/05.
//
import Foundation
import StreamDeck

// MARK: - Layout
var flangerDialLayout: Layout {
    Layout(id: .delayDial) {
        Text(title: "Current Flanger")
            .textAlignment(.center)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 10)

        Text(key: FlangerDialType.currentValue.key, value: "")
            .textAlignment(.center)
            .font(size: 16, weight: 600)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 30)
    }
}

// MARK: - Key
enum FlangerDialType: String {
    case currentValue

    var key: String { rawValue }
}
