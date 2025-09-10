//
//  MainView.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/05/09.
//

import SwiftUI

// MARK: - view
struct MainView: View {
    @State private var highlighted: (column: Int, row: Int)? = nil
    private let columns = 4
    private let rows = 4

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.clear

                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .frame(width: min(proxy.size.width, proxy.size.height) * 0.8,
                           height: min(proxy.size.width, proxy.size.height) * 0.8)
                    .shadow(radius: 8)
                    .overlay { gridOverlay }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: .streamDeckCoordinatesUpdated)) { notification in
            let column = notification.userInfo?["column"] as? Int
            let row = notification.userInfo?["row"] as? Int
            if let column, let row { highlighted = (column, row) }
        }
    }
}

// MARK: - Private
private extension MainView {
    // 4x4 表示のオーバーレイ
    var gridOverlay: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let padding: CGFloat = 24  // 固定のpadding
            let spacing: CGFloat = 8
            let totalSpacing = spacing * (CGFloat(rows - 1) + CGFloat(columns - 1) * CGFloat(rows))
            let contentSize = size - padding * 2 - totalSpacing
            let minCellSize: CGFloat = 40  // 最小ボタンサイズ
            let cellW = max(contentSize / CGFloat(columns), minCellSize)
            let cellH = max(contentSize / CGFloat(rows), minCellSize)

            VStack(spacing: 8) {
                // 上 2 行（正方形ボタン）
                ForEach(0..<2, id: \.self) { r in
                    HStack(spacing: 16) {
                        ForEach(0..<columns, id: \.self) { c in
                            squareButton(width: cellW, height: cellH, col: c, row: r)
                        }
                    }
                }
                .padding(.bottom, 16)

                // 3 行目（1 行 4 列 長方形、横に連結）
                HStack(spacing: 0) {
                    ForEach(0..<columns, id: \.self) { c in
                        rectangleButton(width: cellW * 1.2, height: cellH * 0.8, col: c, row: 2)
                    }
                }
                .padding(.bottom, 16)

                // 4 行目（丸ボタン）
                HStack(spacing: 16) {
                    ForEach(0..<columns, id: \.self) { c in
                        circleButton(diameter: min(cellW, cellH) * 0.8, frameW: cellW, frameH: cellH, col: c, row: 3)
                    }
                }
            }
            .frame(width: contentSize, height: contentSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: squareButton

    func squareButton(width: CGFloat,
                      height: CGFloat,
                      col: Int,
                      row: Int) -> some View {

        RoundedRectangle(cornerRadius: min(width, height) * 0.18)
            .strokeBorder(
                squareButtonColor(col: col, row: row),
                lineWidth: strokeBorderWidth(col: col, row: row)
            )
            .background(
                RoundedRectangle(cornerRadius: min(width, height) * 0.18)
                    .fill(squareButtonBackgroundColor(col: col, row: row))
            )
            .frame(width: width, height: height)
    }

    func squareButtonColor(col: Int, row: Int) -> Color {
        isHighlighted(col: col, row: row) ? .blue : .gray.opacity(0.4)
    }

    func squareButtonBackgroundColor(col: Int, row: Int) -> Color {
        isHighlighted(col: col, row: row) ? .blue.opacity(0.15) : .black.opacity(0.06)
    }

    func strokeBorderWidth(col: Int, row: Int) -> CGFloat {
        isHighlighted(col: col, row: row) ? 4 : 1
    }

    // MARK: rectangleButton

    func rectangleButton(width: CGFloat,
                         height: CGFloat,
                         col: Int,
                         row: Int) -> some View {
        Rectangle()
            .strokeBorder(
                rectangleButtonColor(col: col, row: row),
                lineWidth: strokeBorderWidth(col: col, row: row)
            )
            .background(
                Rectangle()
                    .fill(rectangleButtonBackgroundColor(col: col, row: row))
            )
            .frame(width: width, height: height)
    }

    func rectangleButtonColor(col: Int, row: Int) -> Color {
        isHighlighted(col: col, row: row) ? .green : .gray.opacity(0.4)
    }

    func rectangleButtonBackgroundColor(col: Int, row: Int) -> Color {
        isHighlighted(col: col, row: row) ? .green.opacity(0.15) : .black.opacity(0.06)
    }

    // MARK: circleButton

    func circleButton(diameter: CGFloat,
                      frameW: CGFloat,
                      frameH: CGFloat,
                      col: Int,
                      row: Int) -> some View {
        ZStack {
            Circle()
                .strokeBorder(
                    circleButtonColor(col: col, row: row),
                    lineWidth: strokeBorderWidth(col: col, row: row)
                )
                .background(
                    Circle().fill(circleButtonBackgroundColor(col: col, row: row))
                )
                .frame(width: diameter, height: diameter)
        }
        .frame(width: frameW, height: frameH)
    }

    func circleButtonColor(col: Int, row: Int) -> Color {
        isHighlighted(col: col, row: row) ? .red : .gray.opacity(0.4)
    }

    func circleButtonBackgroundColor(col: Int, row: Int) -> Color {
        isHighlighted(col: col, row: row) ? .red.opacity(0.15) : .black.opacity(0.06)
    }

    func isHighlighted(col: Int, row: Int) -> Bool {
        highlighted?.column == col && highlighted?.row == row
    }
}

#Preview {
    MainView()
}
