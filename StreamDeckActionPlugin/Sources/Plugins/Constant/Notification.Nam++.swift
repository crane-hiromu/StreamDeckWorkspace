//
//  Notification.Nam++.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/07.
//

import Foundation

// MARK: - Name
extension Notification.Name {
    static let volumeChanged = Self(String(describing: VolumeChangeEntity.self))
    static let reverbChanged = Self(String(describing: ReverbChangeEntity.self))
    static let delayChanged = Self(String(describing: DelayChangeEntity.self))
    static let flangerChanged = Self(String(describing: FlangerChangeEntity.self))
    static let pitchChanged = Self(String(describing: PitchChangeEntity.self))
    static let isolatorChanged = Self(String(describing: IsolatorChangeEntity.self))
    static let channelChanged = Self(String(describing: ChannelManager.self))
}
