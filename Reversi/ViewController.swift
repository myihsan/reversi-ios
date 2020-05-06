import UIKit

class ViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!
    
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    /// Storyboard 上で設定されたサイズを保管します。
    /// 引き分けの際は `messageDiskView` の表示が必要ないため、
    /// `messageDiskSizeConstraint.constant` を `0` に設定します。
    /// その後、新しいゲームが開始されたときに `messageDiskSize` を
    /// 元のサイズで表示する必要があり、
    /// その際に `messageDiskSize` に保管された値を使います。
    private var messageDiskSize: CGFloat!
    
    @IBOutlet private var playerControls: [UISegmentedControl]!
    @IBOutlet private var countLabels: [UILabel]!
    @IBOutlet private var playerActivityIndicators: [UIActivityIndicatorView]!

    private lazy var game: Game = Game(board: Board(rows: boardView.height, columns: boardView.width))
    private var gameRepository: GameRepository = {
        let path = (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
        return GameRepository(path: path)
    }()
    private let boardCounter = BoardCounter()
    private let reversiRuler = ReversiRuler()
    private lazy var computer = Computer(ruler: reversiRuler)
    
    private var animationCanceller: Canceller?
    private var isAnimating: Bool { animationCanceller != nil }
    
    private var playerCancellers: [Disk: Canceller] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        boardView.delegate = self
        messageDiskSize = messageDiskSizeConstraint.constant
        
        do {
            game = try gameRepository.loadGame()
        } catch _ {
            newGame()
        }

        syncViewsWithGame()
    }
    
    private var viewHasAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if viewHasAppeared { return }
        viewHasAppeared = true
        waitForPlayer()
    }
}

// MARK: Reversi logics

extension ViewController {

    /// `x`, `y` で指定されたセルに `disk` を置きます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter isAnimated: ディスクを置いたりひっくり返したりするアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーション完了時に実行されるクロージャです。
    ///     このクロージャは値を返さず、アニメーションが完了したかを示す真偽値を受け取ります。
    ///     もし `animated` が `false` の場合、このクロージャは次の run loop サイクルの初めに実行されます。
    /// - Throws: もし `disk` を `x`, `y` で指定されるセルに置けない場合、 `DiskPlacementError` を `throw` します。
    func placeDisk(_ disk: Disk, atX x: Int, y: Int, animated isAnimated: Bool, completion: ((Bool) -> Void)? = nil) throws {
        let flippedDiskCoordinates = reversiRuler.flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y, in: game.board)
        if flippedDiskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, x: x, y: y)
        }
        let diskCoordinates = [(x, y)] + flippedDiskCoordinates

        var board = game.board
        for (row, column) in diskCoordinates {
            board[row, column] = disk
        }
        game.board = board
        
        if isAnimated {
            let cleanUp: () -> Void = { [weak self] in
                self?.animationCanceller = nil
            }
            animationCanceller = Canceller(cleanUp)
            animateSettingDisks(at: diskCoordinates, to: disk) { [weak self] isFinished in
                guard let self = self else { return }
                guard let canceller = self.animationCanceller else { return }
                if canceller.isCancelled { return }
                cleanUp()

                completion?(isFinished)
                try? self.gameRepository.saveGame(self.game)
                self.updateCountLabels()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                for (x, y) in diskCoordinates {
                    self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                }
                completion?(true)
                try? self.gameRepository.saveGame(self.game)
                self.updateCountLabels()
            }
        }
    }
    
    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く。
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われる。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出される。
    private func animateSettingDisks<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void)
        where C.Element == (Int, Int)
    {
        guard let (x, y) = coordinates.first else {
            completion(true)
            return
        }
        
        let animationCanceller = self.animationCanceller!
        boardView.setDisk(disk, atX: x, y: y, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for (x, y) in coordinates {
                    self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                }
                completion(false)
            }
        }
    }
}

// MARK: Game management

extension ViewController {
    /// ゲームの状態を初期化し、新しいゲームを開始します。
    func newGame() {
        boardView.reset()
        game = Game(board: Board(rows: boardView.height, columns: boardView.width))

        try? gameRepository.saveGame(game)
    }
    
    /// プレイヤーの行動を待ちます。
    func waitForPlayer() {
        guard let player = game.currentPlayer else { return }
        switch player {
        case .manual:
            break
        case .computer:
            playTurnOfComputer()
        }
    }
    
    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    func nextTurn() {
        guard case .ongoing(let turn) = game.phase else { return }

        let nextPhase = reversiRuler.nextPhase(of: game)
        game.phase = nextPhase

        switch nextPhase {
        case .ongoing(let nextTurn):
            guard nextTurn == turn else {
                waitForPlayer()
                fallthrough
            }
            game.phase = .ongoing(turn: turn.flipped)
            let alertController = UIAlertController(
                title: "Pass",
                message: "Cannot place a disk.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { [weak self] _ in
                self?.nextTurn()
            })
            present(alertController, animated: true)
        default:
            break
        }

        updateMessageViews()
    }
    
    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    func playTurnOfComputer() {
        guard case .ongoing(let turn) = game.phase else { preconditionFailure() }

        playerActivityIndicators[turn.index].startAnimating()
        let canceller = computer.getMove(for: turn, in: game.board) { [weak self] move in
            guard let self = self else { return }
            self.playerActivityIndicators[turn.index].stopAnimating()
            self.playerCancellers[turn] = nil

            guard let (x, y) = move else { return }
            try! self.placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
                self?.nextTurn()
            }
        }
        
        playerCancellers[turn] = canceller
    }
}

// MARK: Views

extension ViewController {

    func syncViewsWithGame() {
        updateMessageViews()
        updateCountLabels()
        updatePlayerControls()
        updateBoardView()
    }

    /// 各プレイヤーの獲得したディスクの枚数を表示します。
    func updateCountLabels() {
        for side in Disk.sides {
            countLabels[side.index].text = "\(boardCounter.countDisks(of: side, in: game.board))"
        }
    }
    
    /// 現在の状況に応じてメッセージを表示します。
    func updateMessageViews() {
        switch game.phase {
        case .ongoing(let turn):
            messageDiskSizeConstraint.constant = messageDiskSize
            messageDiskView.disk = turn
            messageLabel.text = "'s turn"
        case .ended:
            if let winner = boardCounter.sideWithMoreDisks(in: game.board) {
                messageDiskSizeConstraint.constant = messageDiskSize
                messageDiskView.disk = winner
                messageLabel.text = " won"
            } else {
                messageDiskSizeConstraint.constant = 0
                messageLabel.text = "Tied"
            }
        }
    }

    /// 現在の状況に応じてプレイヤーのモードを表示します。
    func updatePlayerControls() {
        for side in Disk.sides {
            playerControls[side.index].selectedSegmentIndex = game.player(of: side).rawValue
        }
    }

    /// 現在の状況に応じて石を表示します。
    func updateBoardView() {
        let board = game.board
        for x in 0..<board.rows {
            for y in 0..<board.columns {
                let disk = board[x, y]
                boardView.setDisk(disk, atX: x, y: y, animated: false)
            }
        }
    }
}

// MARK: Inputs

extension ViewController {
    /// リセットボタンが押された場合に呼ばれるハンドラーです。
    /// アラートを表示して、ゲームを初期化して良いか確認し、
    /// "OK" が選択された場合ゲームを初期化します。
    @IBAction func pressResetButton(_ sender: UIButton) {
        let alertController = UIAlertController(
            title: "Confirmation",
            message: "Do you really want to reset the game?",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            self.animationCanceller?.cancel()
            self.animationCanceller = nil
            
            for side in Disk.sides {
                self.playerCancellers[side]?.cancel()
                self.playerCancellers.removeValue(forKey: side)
            }
            
            self.newGame()
            self.syncViewsWithGame()
            self.waitForPlayer()
        })
        present(alertController, animated: true)
    }
    
    /// プレイヤーのモードが変更された場合に呼ばれるハンドラーです。
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        let player = Player(rawValue: sender.selectedSegmentIndex)!
        let side: Disk = Disk(index: playerControls.firstIndex(of: sender)!)
        game.setPlayer(player, for: side)

        try? gameRepository.saveGame(game)
        
        if let canceller = playerCancellers[side] {
            canceller.cancel()
        }
        
        if !isAnimating, case .ongoing(let turn) = game.phase, side == turn, case .computer = player {
            playTurnOfComputer()
        }
    }
}

extension ViewController: BoardViewDelegate {
    /// `boardView` の `x`, `y` で指定されるセルがタップされたときに呼ばれます。
    /// - Parameter boardView: セルをタップされた `BoardView` インスタンスです。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        guard case .ongoing(let turn) = game.phase else { return }
        if isAnimating { return }
        guard case .manual = game.player(of: turn) else { return }
        // try? because doing nothing when an error occurs
        try? placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
            self?.nextTurn()
        }
    }
}

// MARK: Additional types

struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
}

// MARK: File-private extensions

extension Disk {
    init(index: Int) {
        for side in Disk.sides {
            if index == side.index {
                self = side
                return
            }
        }
        preconditionFailure("Illegal index: \(index)")
    }
    
    var index: Int {
        switch self {
        case .dark: return 0
        case .light: return 1
        }
    }
}
