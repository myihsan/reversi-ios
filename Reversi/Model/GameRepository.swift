//
//  GameRepository.swift
//  Reversi
//
//  Created by Jierong Li on 2020/05/06.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

class GameRepository {

    enum FileIOError: Error {
        case write(path: String, cause: Error?)
        case read(path: String, cause: Error?)
    }

    private let path: String

    init(path: String) {
        self.path = path
    }

    func saveGame(_ game: Game) throws {
        let output = game.symbol

        do {
            try output.write(toFile: path, atomically: true, encoding: .utf8)
        } catch let error {
            throw FileIOError.read(path: path, cause: error)
        }
    }

    /// ゲームの状態をファイルから読み込み、復元します。
    func loadGame() throws -> Game {
        let input = try String(contentsOfFile: path, encoding: .utf8)
        guard let game = Game(symbol: input) else {
            throw FileIOError.read(path: path, cause: nil)
        }
        return game
    }
}
