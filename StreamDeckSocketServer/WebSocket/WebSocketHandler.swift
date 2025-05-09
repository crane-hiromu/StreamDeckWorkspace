//
//  WebSocketHandler.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/05/09.
//

import NIO
import NIOHTTP1
import NIOWebSocket

// MARK: - Handler
final class WebSocketHandler {

}

// MARK: - ChannelInboundHandler
extension WebSocketHandler: ChannelInboundHandler {

    typealias InboundIn = WebSocketFrame

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        
        switch frame.opcode {
        case .text:
            if let text = frame.data.getString(at: 0, length: frame.data.readableBytes) {
                print("🎧 Received: \(text)")
                // 受け取ったメッセージに応じて処理（例：音を鳴らす、アプリを制御）
            }
        default:
            break
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        print("エラー: \(error)")
        context.close(promise: nil)
    }
}

// MARK: - Extension
extension WebSocketHandler {

    static func startServer() {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        let upgrader = NIOWebSocketServerUpgrader(
            shouldUpgrade: { _, _ in
                return group.next().makeSucceededFuture([:])
            },
            upgradePipelineHandler: { channel, _ in
                channel.pipeline.addHandler(WebSocketHandler())
            })

        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .childChannelInitializer { channel in
                let config = NIOHTTPServerUpgradeConfiguration(upgraders: [upgrader]) { _ in }
                return channel.pipeline.configureHTTPServerPipeline(withServerUpgrade: config)
            }
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

        do {
            let channel = try bootstrap.bind(host: "127.0.0.1", port: 3000).wait()
            print("🟢 WebSocket server started on ws://127.0.0.1:8080")
            try channel.closeFuture.wait()
        } catch {
            print("❌ Server error: \(error)")
        }
    }
}
