//
//  VolumeMainDialAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/02.
//

import Foundation
import StreamDeck

// MARK: - Action
final class VolumeMainDialAction: EncoderAction, VolumeDialActionProtocol {
    typealias Settings = NoSettings

    // MARK: VolumeDialActionProtocol Property

    static var layoutName: LayoutName = .layout(name: .volumedialMain)
    var channel: MessageBuilder.ChannelType? { .main }

    // MARK: EncoderAction Property

    static var name: String = "Volume (Main)"
    static var uuid: String = "volumemaindial.rotary"

    var context: String
    var coordinates: StreamDeck.Coordinates?

    required init(context: String, coordinates: StreamDeck.Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        configure()
    }
}
