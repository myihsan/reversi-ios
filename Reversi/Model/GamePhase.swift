//
//  GamePhase.swift
//  Reversi
//
//  Created by Jierong Li on 2020/04/27.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

enum GamePhase {
    case ongoing(turn: Disk)
    case ended
}
