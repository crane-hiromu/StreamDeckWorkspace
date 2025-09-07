//
//  VolumeSubDialAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import StreamDeck

// MARK: - Action
final class VolumeSubDialAction: EncoderAction, VolumeDialActionProtocol {
    typealias Settings = NoSettings

    // MARK: VolumeDialActionProtocol Property

    static var layoutName: LayoutName = .layout(name: .volumedialSub)
    var channel: MessageBuilder.ChannelType? { .sub }

    // MARK: EncoderAction Property

    static var name: String = "Volume (Sub)"
    static var uuid: String = "volumesubdial.rotary"

    var context: String
    var coordinates: StreamDeck.Coordinates?

    required init(context: String, coordinates: StreamDeck.Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        configure()
    }
}
