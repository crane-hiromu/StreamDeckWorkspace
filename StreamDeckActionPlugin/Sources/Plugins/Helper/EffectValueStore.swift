import Foundation

/**
 * チャンネルごとのエフェクト値を保持するストア
 * 現状はリバーブの値のみ保持。将来的に他エフェクトも拡張予定。
 */
final class EffectValueStore {

    // MARK: Singleton

    static let shared = EffectValueStore()
    private init() { }

    // MARK: State

    // volume
    private var channelVolumeByChannel: [MessageBuilder.ChannelType: Int] = [:]
    // reverb
    private var reverbByChannel: [MessageBuilder.ChannelType: Int] = [:]
    // delay
    private var delayByChannel: [MessageBuilder.ChannelType: Int] = [:]

    // MARK: API (channel volume)

    func setChannelVolume(_ value: Int, for channel: MessageBuilder.ChannelType) {
        channelVolumeByChannel[channel] = value
    }

    func getChannelVolume(for channel: MessageBuilder.ChannelType) -> Int {
        channelVolumeByChannel[channel] ?? 100
    }

    // MARK: API (reverb)

    func setReverb(_ value: Int, for channel: MessageBuilder.ChannelType) {
        reverbByChannel[channel] = value
    }

    func getReverb(for channel: MessageBuilder.ChannelType) -> Int {
        reverbByChannel[channel] ?? 0
    }

    // MARK: API (delay)

    func setDelay(_ value: Int, for channel: MessageBuilder.ChannelType) {
        delayByChannel[channel] = value
    }

    func getDelay(for channel: MessageBuilder.ChannelType) -> Int {
        delayByChannel[channel] ?? 0
    }
}