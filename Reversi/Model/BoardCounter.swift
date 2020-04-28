//
//  BoardCounter.swift
//  Reversi
//
//  Created by Jierong Li on 2020/04/27.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

class BoardCounter {

    /// `side` で指定された色のディスクが盤上に置かれている枚数を返します。
    /// - Parameter side: 数えるディスクの色です。
    /// - Returns: `side` で指定された色のディスクの、盤上の枚数です。
    func countDisks(of side: Disk, in board: Board) -> Int {
        var count = 0

        let board = board
        for x in 0..<board.rows {
            for y in 0..<board.columns {
                if board[x, y] == side {
                    count +=  1
                }
            }
        }

        return count
    }

    /// 盤上に置かれたディスクの枚数が多い方の色を返します。
    /// 引き分けの場合は `nil` が返されます。
    /// - Returns: 盤上に置かれたディスクの枚数が多い方の色です。引き分けの場合は `nil` を返します。
    func sideWithMoreDisks(in board: Board) -> Disk? {
        let darkCount = countDisks(of: .dark, in: board)
        let lightCount = countDisks(of: .light, in: board)
        if darkCount == lightCount {
            return nil
        } else {
            return darkCount > lightCount ? .dark : .light
        }
    }
}
