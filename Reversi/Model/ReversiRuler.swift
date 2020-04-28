//
//  ReversiRuler.swift
//  Reversi
//
//  Created by Jierong Li on 2020/04/28.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

class ReversiRuler {

    func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, atX x: Int, y: Int, in board: Board) -> [(Int, Int)] {
        let directions = [
            (x: -1, y: -1),
            (x:  0, y: -1),
            (x:  1, y: -1),
            (x:  1, y:  0),
            (x:  1, y:  1),
            (x:  0, y:  1),
            (x: -1, y:  0),
            (x: -1, y:  1),
        ]

        guard board[x, y] == nil else {
            return []
        }

        var diskCoordinates: [(Int, Int)] = []

        for direction in directions {
            var x = x
            var y = y

            var diskCoordinatesInLine: [(Int, Int)] = []
            flipping: while true {
                x += direction.x
                y += direction.y

                guard 0..<board.rows ~= x && 0..<board.columns ~= y else { break flipping }
                switch (disk, board[x, y]) { // Uses tuples to make patterns exhaustive
                case (.dark, .some(.dark)), (.light, .some(.light)):
                    diskCoordinates.append(contentsOf: diskCoordinatesInLine)
                    break flipping
                case (.dark, .some(.light)), (.light, .some(.dark)):
                    diskCoordinatesInLine.append((x, y))
                case (_, .none):
                    break flipping
                }
            }
        }

        return diskCoordinates
    }

    /// `x`, `y` で指定されたセルに、 `disk` が置けるかを調べます。
    /// ディスクを置くためには、少なくとも 1 枚のディスクをひっくり返せる必要があります。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Returns: 指定されたセルに `disk` を置ける場合は `true` を、置けない場合は `false` を返します。
    func canPlaceDisk(_ disk: Disk, atX x: Int, y: Int, in board: Board) -> Bool {
        !flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y, in: board).isEmpty
    }

    /// `side` で指定された色のディスクを置ける盤上のセルの座標をすべて返します。
    /// - Returns: `side` で指定された色のディスクを置ける盤上のすべてのセルの座標の配列です。
    func validMoves(for side: Disk, in board: Board) -> [(x: Int, y: Int)] {
        var coordinates: [(Int, Int)] = []

        for x in 0..<board.rows {
            for y in 0..<board.columns {
                if canPlaceDisk(side, atX: x, y: y, in: board) {
                    coordinates.append((x, y))
                }
            }
        }

        return coordinates
    }
}
