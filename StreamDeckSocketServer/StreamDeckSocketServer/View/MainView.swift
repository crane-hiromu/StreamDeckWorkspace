//
//  MainView.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/05/09.
//

import SwiftUI

// MARK: - MainView
struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
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
                viewModel.squareButtonColor(col: col, row: row),
                lineWidth: viewModel.strokeBorderWidth(col: col, row: row)
            )
            .background(
                RoundedRectangle(cornerRadius: min(width, height) * 0.18)
                    .fill(viewModel.squareButtonBackgroundColor(col: col, row: row))
            )
            .frame(width: width, height: height)
            .scaleEffect(viewModel.isHighlighted(col: col, row: row) ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: viewModel.highlighted)
    }

    // MARK: rectangleButton

    func rectangleButton(width: CGFloat,
                         height: CGFloat,
                         col: Int,
                         row: Int) -> some View {
        Rectangle()
            .strokeBorder(
                viewModel.rectangleButtonColor(col: col, row: row),
                lineWidth: viewModel.strokeBorderWidth(col: col, row: row)
            )
            .background(
                Rectangle()
                    .fill(viewModel.rectangleButtonBackgroundColor(col: col, row: row))
            )
            .frame(width: width, height: height)
            .scaleEffect(viewModel.isHighlighted(col: col, row: row) ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: viewModel.highlighted)
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
                    viewModel.circleButtonColor(col: col, row: row),
                    lineWidth: viewModel.strokeBorderWidth(col: col, row: row)
                )
                .background(
                    Circle().fill(viewModel.circleButtonBackgroundColor(col: col, row: row))
                )
                .frame(width: diameter, height: diameter)
        }
        .frame(width: frameW, height: frameH)
        .scaleEffect(viewModel.isHighlighted(col: col, row: row) ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: viewModel.highlighted)
    }
}

#Preview {
    MainView()
}
