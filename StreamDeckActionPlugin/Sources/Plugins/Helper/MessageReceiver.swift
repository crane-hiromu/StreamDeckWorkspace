import Foundation
import StreamDeck
import OSLog

/**
 * アクション側でサーバーからのメッセージを受信・処理するクラス
 */
final class MessageReceiver {
    
    // MARK: Singleton
    
    static let shared = MessageReceiver()
    private init() { }

    // MARK: Properties

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    static let entityKey = "\(String(describing: MessageReceiver.self))_entity"

    // MARK: Methods
    
    /// メッセージ受信を開始する
    func startReceiving() {
        UnixSocketClient.shared.startReceivingMessages { [weak self] message in
            self?.handleReceivedMessage(message)
        }
    }
    
    /// 受信したメッセージを処理する
    /// - Parameter message: 受信したメッセージ
    private func handleReceivedMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else {
            logMessage("Failed to convert message to data")
            return
        }
        
        do {
            let serverMessage = try decoder.decode(ServerMessage.self, from: data)
            handleServerMessage(serverMessage)
        } catch {
            logMessage("Failed to parse message: \(error.localizedDescription), message: \(message)")
        }
    }
    
    /// サーバーメッセージを処理する
    /// - Parameter message: パースされたサーバーメッセージ
    private func handleServerMessage(_ message: ServerMessage) {
        switch message.message {
        case .volumeChange(let entity):
            updateEffectValueStore(entity: entity) { channelType in
                EffectValueStore.shared.setChannelVolume(entity.volume, for: channelType)
            }
            post(.volumeChanged, entity: entity)
        case .reverbChange(let entity):
            updateEffectValueStore(entity: entity) { channelType in
                EffectValueStore.shared.setReverb(entity.reverb, for: channelType)
            }
            post(.reverbChanged, entity: entity)
        case .delayChange(let entity):
            updateEffectValueStore(entity: entity) { channelType in
                EffectValueStore.shared.setDelay(entity.delay, for: channelType)
            }
            post(.delayChanged, entity: entity)
        case .flangerChange(let entity):
            updateEffectValueStore(entity: entity) { channelType in
                EffectValueStore.shared.setFlanger(entity.flanger, for: channelType)
            }
            post(.flangerChanged, entity: entity)
        case .pitchChange(let entity):
            updateEffectValueStore(entity: entity) { channelType in
                EffectValueStore.shared.setPitch(entity.pitch, for: channelType)
            }
            post(.pitchChanged, entity: entity)
        case .isolatorChange(let entity):
            updateEffectValueStore(entity: entity) { channelType in
                EffectValueStore.shared.setIsolator(entity.isolator, for: channelType)
            }
            post(.isolatorChanged, entity: entity)
        }
    }
    
    /// EffectValueStoreを更新する共通処理
    /// - Parameters:
    ///   - entity: エンティティ
    ///   - updateAction: 更新処理
    private func updateEffectValueStore<T: ServerMessageEntity>(
        entity: T,
        updateAction: (MessageBuilder.ChannelType) -> Void
    ) {
        if let channelType = MessageBuilder.ChannelType(rawValue: entity.channel) {
            updateAction(channelType)
        }
    }

    // NotificationCenterで通知
    private func post(_ name: Notification.Name, entity: some ServerMessageEntity) {
        NotificationCenter.default.post(
            name: name,
            object: nil,
            userInfo: [MessageReceiver.entityKey: entity]
        )
    }

    /// ログメッセージを出力する
    /// - Parameter message: ログメッセージ
    private func logMessage(_ message: String) {
        Task {
            await PluginCommunication.shared.sendEvent(
                .logMessage,
                context: nil,
                payload: ["message": "[MessageReceiver] \(message)"]
            )
        }
    }
}
