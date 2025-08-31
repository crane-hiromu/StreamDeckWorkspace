import Foundation
import StreamDeck

// MARK: - Plugin
@main
final class SamplePlugin: Plugin {
    static var name: String = "SamplePlugin"
    static var description: String = "A simple test plugin"
    static var author: String = "Hiromu"
    static var icon: String = "Icons/pluginIcon"
    static var version: String = "1.0"
//    static var os: [PluginOS] = [.macOS(.v11)]

//    @GlobalSetting(\.count) var count

    @ActionBuilder
    static var actions: [any Action.Type] {
        SampleTapAction.self
        SampleDialAction.self
    }

    // ダイアルで使うディスプレイのレイアウトのみ
    static var layouts: [Layout] {
        Layout(id: .dialsample) {
            // The title of the layout
            Text(title: "Current Count")
                .textAlignment(.center)
                .frame(width: 180, height: 24)
                .position(x: (200 - 180) / 2, y: 10)

            // A large counter label
            Text(key: "dial-text", value: "0")
                .textAlignment(.center)
                .font(size: 16, weight: 600)
                .frame(width: 180, height: 24)
                .position(x: (200 - 180) / 2, y: 30)

//            // A bar that shows the current count
//            Bar(key: "dial-bar", value: 0, range: -50..<50)
//                .frame(width: 180, height: 20)
//                .position(x: (200 - 180) / 2, y: 60)
//                .barBackground(.black)
//                .barStyle(.doubleTrapezoid)
//                .barBorder("#943E93")
        }
    }

    required init() {
        logMessage(#function)
    }
}
