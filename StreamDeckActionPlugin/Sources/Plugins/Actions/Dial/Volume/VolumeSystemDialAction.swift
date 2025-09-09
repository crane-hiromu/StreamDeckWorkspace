//
//  VolumeSystemDialAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/07.
//

import Foundation
import StreamDeck

// MARK: - Action
final class VolumeSystemDialAction: EncoderAction, VolumeDialActionProtocol {
    typealias Settings = NoSettings

    // MARK: VolumeDialActionProtocol Property

    static var layoutName: LayoutName = .layout(name: .volumedialSystem)
    var channel: MessageBuilder.ChannelType { .other }

    // MARK: EncoderAction Property

    static var name: String = "Volume (System)"
    static var uuid: String = "volumesystemdial.rotary"

    var context: String
    var coordinates: StreamDeck.Coordinates?

    required init(context: String, coordinates: StreamDeck.Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        configure()
    }
}
