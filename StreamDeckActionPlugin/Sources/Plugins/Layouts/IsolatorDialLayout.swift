//
//  IsolatorDialLayout.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/03.
//

import Foundation
import StreamDeck

// MARK: - Layout
var isolatorDialLayout: Layout {
    Layout(id: .isolatorDial) {
        Text(title: "Current Frequency")
            .textAlignment(.center)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 10)

        Text(key: IsolatorDialType.currentValue.key, value: "")
            .textAlignment(.center)
            .font(size: 16, weight: 600)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 30)
    }
}

// MARK: - Key
enum IsolatorDialType: String {
    case currentValue

    var key: String { rawValue }
}
