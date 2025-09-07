//
//  VolumeDialLayout.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/02.
//

import Foundation
import StreamDeck

// todo
// サーバーでチャンネル０（main）しか返していない。
// チャンネルを分けて音量設定できるようにする

// MARK: - Layout

func dialLayout(_ id: LayoutName,
                title: String,
                key: String) -> Layout {

    Layout(id: id) {
        Text(title: title)
            .textAlignment(.center)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 10)

        Text(key: key, value: "-")
            .textAlignment(.center)
            .font(size: 16, weight: 600)
            .frame(width: 180, height: 24)
            .position(x: (200 - 180) / 2, y: 30)
    }
}

var volumeSystemDialLayout: Layout {
    dialLayout(.volumedialSystem, title: "Current Volume", key: VolumeDialType.currentVolume.key)
}

var volumeMainDialLayout: Layout {
    dialLayout(.volumedialMain, title: "Current Volume", key: VolumeDialType.currentVolume.key)
}

var volumeSubDialLayout: Layout {
    dialLayout(.volumedialSub, title: "Current Volume", key: VolumeDialType.currentVolume.key)
}


// MARK: - Key
enum VolumeDialType: String {
    case currentVolume

    var key: String { rawValue }
}
