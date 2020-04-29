//
//  Ruler.swift
//  Reversi
//
//  Created by Jierong Li on 2020/04/29.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

protocol Ruler {
    func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, atX x: Int, y: Int, in board: Board) -> [(Int, Int)]
    func canPlaceDisk(_ disk: Disk, atX x: Int, y: Int, in board: Board) -> Bool
    func validMoves(for side: Disk, in board: Board) -> [(x: Int, y: Int)]
    func nextPhase(of game: Game) -> Game.Phase
}
