import Foundation
import SwiftUI
import Combine

// MARK: - Cricket Game Model
public class CricketGameModel: ObservableObject {
    @Published public var currentOver: Int = 1
    @Published public var ballsInCurrentOver: Int = 0
    @Published public var totalBalls: Int = 0
    @Published public var totalRuns: Int = 0
    @Published public var extras: Extras = Extras()
    @Published public var ballHistory: [Ball] = []
    @Published public var maxBallsPerOver: Int = 6
    @Published public var isOverComplete: Bool = false
    
    // Current ball being tracked
    @Published public var currentBall: Ball = Ball()
    
    public init() {}
    
    public var ballsRemaining: Int {
        maxBallsPerOver - ballsInCurrentOver
    }
    
    public var overDisplay: String {
        "\(currentOver).\(ballsInCurrentOver)"
    }
    
    public func addRuns(_ runs: Int) {
        currentBall.runs = runs
        totalRuns += runs
        completeBall()
    }
    
    public func addWide() {
        currentBall.isWide = true
        extras.wides += 1
        totalRuns += 1
        // Wide doesn't count as a legal ball
        ballHistory.append(currentBall)
        resetCurrentBall()
    }
    
    public func addNoBall() {
        currentBall.isNoBall = true
        extras.noBalls += 1
        totalRuns += 1
        // No ball doesn't count as a legal ball
        ballHistory.append(currentBall)
        resetCurrentBall()
    }
    
    public func addBye(_ runs: Int) {
        currentBall.byes = runs
        extras.byes += runs
        totalRuns += runs
        completeBall()
    }
    
    public func addLegBye(_ runs: Int) {
        currentBall.legByes = runs
        extras.legByes += runs
        totalRuns += runs
        completeBall()
    }
    
    private func completeBall() {
        ballHistory.append(currentBall)
        ballsInCurrentOver += 1
        totalBalls += 1
        
        if ballsInCurrentOver >= maxBallsPerOver {
            completeOver()
        }
        
        resetCurrentBall()
    }
    
    private func completeOver() {
        currentOver += 1
        ballsInCurrentOver = 0
        isOverComplete = true
        
        // Reset over complete flag after a short delay for UI feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isOverComplete = false
        }
    }
    
    private func resetCurrentBall() {
        currentBall = Ball()
    }
    
    public func resetGame() {
        currentOver = 1
        ballsInCurrentOver = 0
        totalBalls = 0
        totalRuns = 0
        extras = Extras()
        ballHistory = []
        isOverComplete = false
        currentBall = Ball()
    }
    
    public func undoLastBall() {
        guard let lastBall = ballHistory.popLast() else { return }
        
        // Subtract runs
        totalRuns -= lastBall.totalRuns
        
        // Subtract extras
        if lastBall.isWide {
            extras.wides -= 1
        }
        if lastBall.isNoBall {
            extras.noBalls -= 1
        }
        extras.byes -= lastBall.byes
        extras.legByes -= lastBall.legByes
        
        // Adjust ball count
        if !lastBall.isWide && !lastBall.isNoBall {
            if ballsInCurrentOver > 0 {
                ballsInCurrentOver -= 1
            } else {
                // We need to go back to previous over
                currentOver -= 1
                ballsInCurrentOver = maxBallsPerOver - 1
            }
            totalBalls -= 1
        }
    }
}

// MARK: - Data Models
public struct Ball: Identifiable {
    public let id = UUID()
    public var runs: Int = 0
    public var isWide: Bool = false
    public var isNoBall: Bool = false
    public var byes: Int = 0
    public var legByes: Int = 0
    
    public init() {}
    
    public var totalRuns: Int {
        runs + (isWide ? 1 : 0) + (isNoBall ? 1 : 0) + byes + legByes
    }
    
    public var description: String {
        var components: [String] = []
        
        if isWide {
            components.append("Wd")
        }
        if isNoBall {
            components.append("Nb")
        }
        if byes > 0 {
            components.append("B\(byes)")
        }
        if legByes > 0 {
            components.append("Lb\(legByes)")
        }
        if runs > 0 {
            components.append("\(runs)")
        }
        
        return components.isEmpty ? "0" : components.joined(separator: "+")
    }
}

public struct Extras {
    public var wides: Int = 0
    public var noBalls: Int = 0
    public var byes: Int = 0
    public var legByes: Int = 0
    
    public init() {}
    
    public var total: Int {
        wides + noBalls + byes + legByes
    }
}
