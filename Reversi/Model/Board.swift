//
//  Board.swift
//  Reversi
//
//  Created by Jierong Li on 2020/04/27.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

struct Board {

    private var disks: [[Disk?]]

    let rows: Int
    let columns: Int

    init(rows: Int, columns: Int) {
        assert(rows > 3, "The rows should greater than 3")
        assert(rows % 2 == 0, "The rows should be even")
        assert(columns > 3, "The columns should greater than 3")
        assert(columns % 2 == 0, "The columns should be even")

        disks = .init(repeating: .init(repeating: nil, count: columns), count: rows)
        self.rows = rows
        self.columns = columns

        let rowCenterIndex = rows / 2
        let columnCenterIndex = columns / 2

        disks[rowCenterIndex][columnCenterIndex] = .light
        disks[rowCenterIndex - 1][columnCenterIndex - 1] = .light
        disks[rowCenterIndex - 1][columnCenterIndex] = .dark
        disks[rowCenterIndex][columnCenterIndex - 1] = .dark
    }
}

extension Board {

    subscript(row: Int, column: Int) -> Disk? {
        get {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            return disks[row][column]
        }
        set {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            disks[row][column] = newValue
        }
    }

    private func indexIsValid(row: Int, column: Int) -> Bool {
        return 0..<rows ~= row && 0..<columns ~= column
    }
}
