import XCTest
@testable import UmpAppCore

final class CricketGameModelTests: XCTestCase {
    
    var gameModel: CricketGameModel!
    
    override func setUp() {
        super.setUp()
        gameModel = CricketGameModel()
    }
    
    override func tearDown() {
        gameModel = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(gameModel.currentOver, 1)
        XCTAssertEqual(gameModel.ballsInCurrentOver, 0)
        XCTAssertEqual(gameModel.totalBalls, 0)
        XCTAssertEqual(gameModel.totalRuns, 0)
        XCTAssertEqual(gameModel.ballsRemaining, 6)
        XCTAssertEqual(gameModel.overDisplay, "1.0")
    }
    
    func testAddRuns() {
        gameModel.addRuns(4)
        
        XCTAssertEqual(gameModel.totalRuns, 4)
        XCTAssertEqual(gameModel.ballsInCurrentOver, 1)
        XCTAssertEqual(gameModel.totalBalls, 1)
        XCTAssertEqual(gameModel.ballHistory.count, 1)
        XCTAssertEqual(gameModel.ballHistory[0].runs, 4)
    }
    
    func testAddWide() {
        gameModel.addWide()
        
        XCTAssertEqual(gameModel.totalRuns, 1)
        XCTAssertEqual(gameModel.ballsInCurrentOver, 0) // Wide doesn't count as legal ball
        XCTAssertEqual(gameModel.totalBalls, 0)
        XCTAssertEqual(gameModel.extras.wides, 1)
        XCTAssertEqual(gameModel.ballHistory.count, 1)
        XCTAssertTrue(gameModel.ballHistory[0].isWide)
    }
    
    func testAddNoBall() {
        gameModel.addNoBall()
        
        XCTAssertEqual(gameModel.totalRuns, 1)
        XCTAssertEqual(gameModel.ballsInCurrentOver, 0) // No ball doesn't count as legal ball
        XCTAssertEqual(gameModel.totalBalls, 0)
        XCTAssertEqual(gameModel.extras.noBalls, 1)
        XCTAssertEqual(gameModel.ballHistory.count, 1)
        XCTAssertTrue(gameModel.ballHistory[0].isNoBall)
    }
    
    func testAddByes() {
        gameModel.addBye(2)
        
        XCTAssertEqual(gameModel.totalRuns, 2)
        XCTAssertEqual(gameModel.ballsInCurrentOver, 1) // Byes count as legal balls
        XCTAssertEqual(gameModel.totalBalls, 1)
        XCTAssertEqual(gameModel.extras.byes, 2)
        XCTAssertEqual(gameModel.ballHistory.count, 1)
        XCTAssertEqual(gameModel.ballHistory[0].byes, 2)
    }
    
    func testAddLegByes() {
        gameModel.addLegBye(3)
        
        XCTAssertEqual(gameModel.totalRuns, 3)
        XCTAssertEqual(gameModel.ballsInCurrentOver, 1) // Leg byes count as legal balls
        XCTAssertEqual(gameModel.totalBalls, 1)
        XCTAssertEqual(gameModel.extras.legByes, 3)
        XCTAssertEqual(gameModel.ballHistory.count, 1)
        XCTAssertEqual(gameModel.ballHistory[0].legByes, 3)
    }
    
    func testOverCompletion() {
        // Add 6 legal balls
        for i in 1...6 {
            gameModel.addRuns(i)
        }
        
        XCTAssertEqual(gameModel.currentOver, 2)
        XCTAssertEqual(gameModel.ballsInCurrentOver, 0)
        XCTAssertEqual(gameModel.totalBalls, 6)
        XCTAssertEqual(gameModel.ballHistory.count, 6)
        XCTAssertEqual(gameModel.totalRuns, 21) // 1+2+3+4+5+6
    }
    
    func testOverCompletionWithExtras() {
        // Add 6 legal balls with some extras
        gameModel.addRuns(1)
        gameModel.addWide() // Extra, doesn't count toward over
        gameModel.addRuns(2)
        gameModel.addNoBall() // Extra, doesn't count toward over
        gameModel.addRuns(3)
        gameModel.addRuns(4)
        gameModel.addBye(1)
        gameModel.addLegBye(2)
        
        XCTAssertEqual(gameModel.currentOver, 2)
        XCTAssertEqual(gameModel.ballsInCurrentOver, 0)
        XCTAssertEqual(gameModel.totalBalls, 6) // Only legal balls count
        XCTAssertEqual(gameModel.ballHistory.count, 8) // All balls including extras
        XCTAssertEqual(gameModel.totalRuns, 15) // 1+1+2+1+3+4+1+2
    }
    
    func testUndoLastBall() {
        gameModel.addRuns(4)
        gameModel.addWide()
        
        XCTAssertEqual(gameModel.totalRuns, 5)
        XCTAssertEqual(gameModel.ballHistory.count, 2)
        
        gameModel.undoLastBall() // Undo wide
        
        XCTAssertEqual(gameModel.totalRuns, 4)
        XCTAssertEqual(gameModel.extras.wides, 0)
        XCTAssertEqual(gameModel.ballHistory.count, 1)
        
        gameModel.undoLastBall() // Undo runs
        
        XCTAssertEqual(gameModel.totalRuns, 0)
        XCTAssertEqual(gameModel.ballsInCurrentOver, 0)
        XCTAssertEqual(gameModel.ballHistory.count, 0)
    }
    
    func testResetGame() {
        gameModel.addRuns(4)
        gameModel.addWide()
        gameModel.addBye(2)
        
        gameModel.resetGame()
        
        XCTAssertEqual(gameModel.currentOver, 1)
        XCTAssertEqual(gameModel.ballsInCurrentOver, 0)
        XCTAssertEqual(gameModel.totalBalls, 0)
        XCTAssertEqual(gameModel.totalRuns, 0)
        XCTAssertEqual(gameModel.extras.total, 0)
        XCTAssertEqual(gameModel.ballHistory.count, 0)
        XCTAssertFalse(gameModel.isOverComplete)
    }
    
    func testBallDescription() {
        var ball = Ball()
        XCTAssertEqual(ball.description, "0")
        
        ball.runs = 4
        XCTAssertEqual(ball.description, "4")
        
        ball.isWide = true
        XCTAssertEqual(ball.description, "Wd+4")
        
        ball.byes = 2
        XCTAssertEqual(ball.description, "Wd+B2+4")
        
        ball = Ball()
        ball.isNoBall = true
        ball.legByes = 1
        XCTAssertEqual(ball.description, "Nb+Lb1")
    }
    
    func testExtrasTotal() {
        var extras = Extras()
        XCTAssertEqual(extras.total, 0)
        
        extras.wides = 2
        extras.noBalls = 1
        extras.byes = 3
        extras.legByes = 4
        
        XCTAssertEqual(extras.total, 10)
    }
}
