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
        // Socket Server Tap Action
        iOSDCTrackTapAction.self
        BeatTrackTapAction.self
        LongBeatTrackTapAction.self
        LoopTapAction.self
        StopTapAction.self
        // Socket Server Dial Action
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

