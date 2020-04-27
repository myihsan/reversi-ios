//
//  Game.swift
//  Reversi
//
//  Created by Jierong Li on 2020/04/27.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

struct Game {

    enum Phase {
        case ongoing(turn: Disk)
        case ended
    }

    var phase: Phase = .ongoing(turn: .dark)
    var darkPlayer: Player = .manual
    var lightPlayer: Player = .manual
}

extension Game {
    var currentPlayer: Player? {
        switch phase {
        case .ongoing(let turn):
            return player(of: turn)
        case .ended:
            return nil
        }
    }

    func player(of side: Disk) -> Player {
        switch side {
        case .dark:
            return darkPlayer
        case .light:
            return lightPlayer
        }
    }

    mutating func setPlayer(_ player: Player, for side: Disk) {
        switch side {
        case .dark:
            darkPlayer = player
        case .light:
            lightPlayer = player
        }
    }
}
