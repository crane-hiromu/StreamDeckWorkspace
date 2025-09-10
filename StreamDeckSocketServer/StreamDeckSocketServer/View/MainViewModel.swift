//
//  MainViewModel.swift
//  StreamDeckSocketServer
//
//  Created by Assistant on 2025/09/10.
//

import SwiftUI
import Combine

// MARK: - MainViewModel
@MainActor
final class MainViewModel: ObservableObject {
    @Published var highlighted: KeyCoordinates? = nil
    
    private var highlightTimer: Timer? = nil
    private let columns = 4
    private let rows = 4
    
    init() {
        setupNotificationObserver()
    }
    
    deinit {
        highlightTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func isHighlighted(col: Int, row: Int) -> Bool {
        highlighted?.column == col && highlighted?.row == row
    }
    
    // MARK: - Button Colors
    
    func squareButtonColor(col: Int, row: Int) -> Color {
        isHighlighted(col: col, row: row) ? .blue : .gray.opacity(0.4)
    }
    
    func squareButtonBackgroundColor(col: Int, row: Int) -> Color {
        isHighlighted(col: col, row: row) ? .blue.opacity(0.15) : .black.opacity(0.06)
    }
    
    func rectangleButtonColor(col: Int, row: Int) -> Color {
        isHighlighted(col: col, row: row) ? .green : .gray.opacity(0.4)
    }
    
    func rectangleButtonBackgroundColor(col: Int, row: Int) -> Color {
        isHighlighted(col: col, row: row) ? .green.opacity(0.15) : .black.opacity(0.06)
    }
    
    func circleButtonColor(col: Int, row: Int) -> Color {
        isHighlighted(col: col, row: row) ? .red : .gray.opacity(0.4)
    }
    
    func circleButtonBackgroundColor(col: Int, row: Int) -> Color {
        isHighlighted(col: col, row: row) ? .red.opacity(0.15) : .black.opacity(0.06)
    }
    
    func strokeBorderWidth(col: Int, row: Int) -> CGFloat {
        isHighlighted(col: col, row: row) ? 4 : 1
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .streamDeckCoordinatesUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleCoordinatesUpdate(notification)
        }
    }
    
    private func handleCoordinatesUpdate(_ notification: Notification) {
        let column = notification.userInfo?["column"] as? Int
        let row = notification.userInfo?["row"] as? Int
        if let column, let row {
            highlighted = KeyCoordinates(column: column, row: row)
            startHighlightTimer()
        }
    }
    
    private func startHighlightTimer() {
        // 既存のタイマーをキャンセル
        highlightTimer?.invalidate()
        
        // 2秒後にハイライトを消すタイマーを開始
        highlightTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.highlighted = nil
        }
    }
}
