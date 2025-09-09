import Foundation
import StreamDeck

/// エフェクトダイヤルアクションの共通プロトコル
protocol EffectDialActionProtocol: AnyObject {
    var channel: MessageBuilder.ChannelType { get }
    
    /// エフェクト値の更新処理
    func updateEffectValue<T: ServerMessageEntity>(entity: T)
    
    /// UIの更新処理
    func updateUI()
}

extension EffectDialActionProtocol {
    
    /// エフェクト変更通知を購読する
    /// - Parameters:
    ///   - notificationName: 通知名
    ///   - entityType: エンティティタイプ
    func addEffectChangeObserver<T: ServerMessageEntity>(
        _ notificationName: Notification.Name,
        entityType: T.Type
    ) {
        NotificationCenter.default.addObserver(
            forName: notificationName,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let data = notification.userInfo?[MessageReceiver.entityKey]
            guard let entity = data as? T else { return }
            
            let channelType = MessageBuilder.ChannelType(rawValue: entity.channel)
            guard channelType == self.channel else { return }
            
            self.updateEffectValue(entity: entity)
            self.updateUI()
        }
    }
    
    /// チャンネル変更通知を購読する
    func addChannelChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: .channelChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateUI()
        }
    }
}
