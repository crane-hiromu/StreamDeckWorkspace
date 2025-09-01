//
//  SystemVolumeManager.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/09/01.
//

import Foundation
import CoreAudio
import CoreAudioTypes

// MARK: - Manager
final class SystemVolumeManager {

    // MARK: Singleton

    static let shared = SystemVolumeManager()
    private init() {}

    // MARK: Property
    private var previousVolume: Float? = nil // ミュート前の音量を記憶

    // MARK: Method

    func getVolume() -> Float? {
        guard let deviceID = defaultOutputDeviceID() else { return nil }

        var left: Float = 0
        var right: Float = 0
        var size = UInt32(MemoryLayout<Float>.size)

        var leftAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 1
        )
        var rightAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 2
        )

        let leftStatus = withUnsafePointer(to: &leftAddress) { addrPtr in
            AudioObjectGetPropertyData(deviceID, addrPtr, 0, nil, &size, &left)
        }

        let rightStatus = withUnsafePointer(to: &rightAddress) { addrPtr in
            AudioObjectGetPropertyData(deviceID, addrPtr, 0, nil, &size, &right)
        }

        if leftStatus == noErr && rightStatus == noErr {
            return (left + right) / 2
        } else {
            return nil
        }
    }
    @discardableResult
    func setVolume(_ value: Float) -> Bool {
        guard let deviceID = defaultOutputDeviceID() else { return false }

        var volume = min(max(value, 0.0), 1.0)
        let size = UInt32(MemoryLayout<Float>.size)

        var leftAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 1
        )
        var rightAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 2
        )

        let leftStatus = withUnsafePointer(to: &leftAddress) { addrPtr in
            AudioObjectSetPropertyData(deviceID, addrPtr, 0, nil, size, &volume)
        }
        let rightStatus = withUnsafePointer(to: &rightAddress) { addrPtr in
            AudioObjectSetPropertyData(deviceID, addrPtr, 0, nil, size, &volume)
        }

        return leftStatus == noErr && rightStatus == noErr
    }

    func adjustVolume(by delta: Float) {
        // ミュート中 → previousVolume を基準に増減
        if let prev = previousVolume {
            let newVolume = min(max(prev + delta, 0.0), 1.0)
            setVolume(newVolume)
            previousVolume = nil

        // 通常状態 → 現在の音量に delta を加算
        } else if let current = getVolume() {
            let newVolume = min(max(current + delta, 0.0), 1.0)
            setVolume(newVolume)
        }
    }

    func toggleMute() {
        if let current = getVolume(), current > 0 {
            // ミュートする前に音量を保存
            previousVolume = current
            setVolume(0.0)
        } else if let prev = previousVolume {
            // 前の音量に戻す
            setVolume(prev)
            previousVolume = nil
        }
    }

    private func defaultOutputDeviceID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize,
            &deviceID
        )
        return (status == noErr) ? deviceID : nil
    }
}
