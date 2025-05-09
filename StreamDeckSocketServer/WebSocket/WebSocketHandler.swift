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
            var data = frame.unmaskedData
            if let text = data.readString(length: data.readableBytes) {
                print("Received text: \(text)")
            } else {
                print("Text frame, but failed to decode string")
            }
        default:
            print("Received: something")
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        print("error: \(error)")
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
