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

    var board: Board

    init(board: Board) {
        self.board = board
    }
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

extension Game {
    init?<S: StringProtocol>(symbol: S) {
        var symbolParts = symbol.split(separator: "\n", maxSplits: 1)[...]

        guard var firstPart = symbolParts.popFirst() else { return nil }

        do { // turn
            guard
                let diskSymbol = firstPart.popFirst(),
                let phase = Game.Phase(symbol: diskSymbol.description)
                else { return nil }
            self.phase = phase
        }

        do { // board
            guard let secondPart = symbolParts.popFirst(),
                let board = Board(symbol: secondPart) else { return nil }
            self.board = board
        }

        // players
        for side in Disk.sides {
            guard
                let playerSymbol = firstPart.popFirst(),
                let playerNumber = Int(playerSymbol.description),
                let player = Player(rawValue: playerNumber)
                else { return nil }
            setPlayer(player, for: side)
        }
    }

    var symbol: String {
        var symbol: String = ""
        symbol += phase.symbol
        symbol += "\(darkPlayer.rawValue)\(lightPlayer.rawValue)"
        symbol += "\n"

        symbol += board.symbol
        return symbol
    }
}

private extension Disk {
    init?<S: StringProtocol>(symbol: S) {
        switch symbol {
        case "x":
            self = .dark
        case "o":
            self = .light
        default:
            return nil
        }
    }

    var symbol: String {
        switch self {
        case .dark:
            return "x"
        case .light:
            return "o"
        }
    }
}

private extension Game.Phase {
    init?<S: StringProtocol>(symbol: S) {
        switch symbol {
        case "-":
            self = .ended
        default:
            guard let disk = Disk(symbol: symbol) else { return nil }
            self = .ongoing(turn: disk)
        }
    }

    var symbol: String {
        switch self {
        case .ongoing(let turn):
            return turn.symbol
        case .ended:
            return "-"
        }
    }
}

private extension Board {
    init?<S: StringProtocol>(symbol: S) {
        var lines = symbol.split(separator: "\n")[...]
        let rows = lines.count
        guard let columns = lines.first?.count,
            rows > 3, rows % 2 == 0,
            columns > 3, columns % 2 == 0 else { return nil }
        var board = Board(rows: rows, columns: columns)
        guard lines.count == board.rows else { return nil }

        var row = 0
        while let line = lines.popFirst() {
            guard line.count == board.columns else { return nil }
            var column = 0
            for character in line {
                let disk = Disk(symbol: "\(character)").flatMap { $0 }
                board[row, column] = disk
                column += 1
            }
            row += 1
        }
        self = board
    }

    var symbol: String {
        var symbol: String = ""

        for row in 0..<rows {
            for column in 0..<columns {
                symbol += self[row, column]?.symbol ?? "-"
            }
            symbol += "\n"
        }
        return symbol
    }
}
