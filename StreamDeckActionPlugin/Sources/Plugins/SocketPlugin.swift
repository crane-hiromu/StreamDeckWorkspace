import Foundation
import StreamDeck

// MARK: - Plugin
@main
final class SocketPlugin: Plugin {
    static var name: String = "SocketPlugin"
    static var description: String = "socket plugin"
    static var author: String = "Hiromu"
    static var icon: String = "Icons/pluginIcon"
    static var version: String = "1.0"

    @ActionBuilder
    static var actions: [any Action.Type] {
        // Sample Action
        SampleTapAction.self
        SampleDialAction.self

        // MARK: Socket Server Tap Action
        iOSDCTrackTapAction.self
        BeatTrackTapAction.self
        LoopTapAction.self
        StopTapAction.self
        // Drum Tap Actions
        DrumBassTapAction.self
        DrumCymbalTapAction.self
        DrumHatTapAction.self
        DrumSnareTapAction.self
        DrumSnareWTapAction.self
        DrumTomTapAction.self
        DrumEl1TapAction.self
        DrumEl2TapAction.self
        DrumEl3TapAction.self
        EffectPufTapAction.self
        // Tone Tap Actions
        ToneCTapAction.self
        ToneDTapAction.self
        ToneETapAction.self
        ToneFTapAction.self
        ToneGTapAction.self
        ToneATapAction.self
        ToneBTapAction.self

        // MARK: Socket Server Dial Action
        DelayDialAction.self
        FlangerDialAction.self
        IsolatorDialAction.self
        PitchDialAction.self
        RateDialAction.self
        ReverbDialAction.self
        ScratchDialAction.self
        VolumeDialAction.self
    }

    // ダイアルで使うディスプレイのレイアウトのみ
    static var layouts: [Layout] {
        // Sample Layout
        sampleDialLayout
        // Socket Server Layout
        delayDialLayout
        flangerDialLayout
        isolatorDialLayout
        pitchDialLayout
        rateDialLayout
        reverbDialLayout
        scratchDialLayout
        volumeDialLayout
    }

    required init() {
        logMessage(#function)
        // Unix socketクライアントを接続
        UnixSocketClient.shared.connect()
    }
}

