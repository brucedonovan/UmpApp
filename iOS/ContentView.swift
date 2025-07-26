import SwiftUI
import UmpAppCore

struct ContentView: View {
    @StateObject private var game = CricketGameModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ScoreDisplayView(game: game)
                
                if !game.ballHistory.isEmpty {
                    BallHistoryView(ballHistory: game.ballHistory)
                }
                
                RunScoringGridView(game: game)
                
                ExtrasView(game: game)
                
                ActionButtonsView(game: game)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Cricket Umpire")
        }
    }
}

struct ScoreDisplayView: View {
    let game: CricketGameModel
    
    var body: some View {
        VStack {
            Text("Score: \(game.totalRuns)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Overs: \(game.overDisplay)")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct BallHistoryView: View {
    let ballHistory: [Ball]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("This Over:")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(ballHistory.indices, id: \.self) { index in
                        Text(ballHistory[index].description)
                            .padding(8)
                            .background(ballBackgroundColor(for: ballHistory[index]))
                            .cornerRadius(5)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func ballBackgroundColor(for ball: Ball) -> Color {
        return ball.runs == 0 ? Color.gray.opacity(0.3) : Color.blue.opacity(0.3)
    }
}

struct RunScoringGridView: View {
    let game: CricketGameModel
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
            ForEach(0...6, id: \.self) { runs in
                Button(action: {
                    game.addRuns(runs)
                }) {
                    Text("\(runs)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(minWidth: 50, minHeight: 50)
                        .background(backgroundColorForRuns(runs))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private func backgroundColorForRuns(_ runs: Int) -> Color {
        switch runs {
        case 0:
            return Color.gray.opacity(0.3)
        case 4:
            return Color.green.opacity(0.3)
        case 6:
            return Color.orange.opacity(0.3)
        default:
            return Color.blue.opacity(0.3)
        }
    }
}

struct ExtrasView: View {
    let game: CricketGameModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Extras")
                .font(.headline)
            
            HStack(spacing: 15) {
                ExtrasButton(title: "Wide", color: .red) {
                    game.addWide()
                }
                
                ExtrasButton(title: "No Ball", color: .red) {
                    game.addNoBall()
                }
                
                ExtrasButton(title: "Bye", color: .yellow) {
                    game.addBye(1)
                }
                
                ExtrasButton(title: "Leg Bye", color: .yellow) {
                    game.addLegBye(1)
                }
            }
        }
    }
}

struct ExtrasButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding()
                .background(color.opacity(0.3))
                .cornerRadius(8)
        }
    }
}

struct ActionButtonsView: View {
    let game: CricketGameModel
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: {
                game.undoLastBall()
            }) {
                Text("Undo Last Ball")
                    .padding()
                    .background(Color.orange.opacity(0.3))
                    .cornerRadius(8)
            }
            .disabled(game.ballHistory.isEmpty)
            
            Button(action: {
                game.resetGame()
            }) {
                Text("Reset Game")
                    .padding()
                    .background(Color.red.opacity(0.3))
                    .cornerRadius(8)
            }
        }
    }
}

#Preview {
    ContentView()
}
