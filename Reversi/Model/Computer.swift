//
//  Computer.swift
//  Reversi
//
//  Created by Jierong Li on 2020/04/29.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

class Computer {

    private let ruler: Ruler

    init(ruler: Ruler) {
        self.ruler = ruler
    }

    func getMove(for side: Disk, in board: Board, completionHandler: @escaping ((Int, Int)?) -> Void) -> Canceller {
        let canceller = Canceller { completionHandler(nil) }
        let move = ruler.validMoves(for: side, in: board).randomElement()!
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            completionHandler(move)
        }
        return canceller
    }

}
