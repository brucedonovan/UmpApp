import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var gameModel = CricketGameModel()
    @State private var currentTab = 0
    
    var body: some View {
        TabView(selection: $currentTab) {
            // Main Score Tab
            ScoreView(gameModel: gameModel)
                .tag(0)
            
            // Quick Actions Tab
            QuickActionsView(gameModel: gameModel)
                .tag(1)
            
            // Extras Tab
            ExtrasView(gameModel: gameModel)
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

struct ScoreView: View {
    @ObservedObject var gameModel: CricketGameModel
    
    var body: some View {
        VStack(spacing: 8) {
            // Total Runs
            Text("\(gameModel.totalRuns)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Total Runs")
                .font(.caption2)
                .foregroundColor(.gray)
            
            Divider()
            
            // Over Information
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Over")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(gameModel.overDisplay)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Remaining")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("\(gameModel.ballsRemaining)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            
            // Extras (if any)
            if gameModel.extras.total > 0 {
                Divider()
                
                VStack(spacing: 4) {
                    Text("Extras: \(gameModel.extras.total)")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        if gameModel.extras.wides > 0 {
                            Text("W:\(gameModel.extras.wides)")
                                .font(.caption2)
                        }
                        if gameModel.extras.noBalls > 0 {
                            Text("Nb:\(gameModel.extras.noBalls)")
                                .font(.caption2)
                        }
                        if gameModel.extras.byes > 0 {
                            Text("B:\(gameModel.extras.byes)")
                                .font(.caption2)
                        }
                        if gameModel.extras.legByes > 0 {
                            Text("Lb:\(gameModel.extras.legByes)")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // Recent balls
            if !gameModel.ballHistory.isEmpty {
                VStack(spacing: 2) {
                    Text("Recent")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        ForEach(Array(gameModel.ballHistory.suffix(4).enumerated()), id: \.element.id) { _, ball in
                            Text(ball.description)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(2)
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Score")
        .alert("Over Complete!", isPresented: $gameModel.isOverComplete) {
            Button("OK") { }
        }
    }
}

struct QuickActionsView: View {
    @ObservedObject var gameModel: CricketGameModel
    @State private var showingRunsPicker = false
    @State private var selectedRuns = 1
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Quick Runs")
                .font(.headline)
                .padding(.bottom, 4)
            
            // Common run buttons
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach([1, 2, 3, 4, 6, 0], id: \.self) { runs in
                    Button(action: {
                        gameModel.addRuns(runs)
                        #if os(watchOS)
                        WKInterfaceDevice.current().play(.click)
                        #endif
                    }) {
                        Text("\(runs)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(runs == 0 ? Color.gray : Color.blue)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer()
            
            // Other runs button
            Button("Other Runs") {
                showingRunsPicker = true
            }
            .font(.caption)
            .foregroundColor(.blue)
            
            // Undo button
            Button("Undo Last") {
                gameModel.undoLastBall()
                #if os(watchOS)
                WKInterfaceDevice.current().play(.click)
                #endif
            }
            .font(.caption)
            .foregroundColor(.red)
            .disabled(gameModel.ballHistory.isEmpty)
        }
        .padding()
        .navigationTitle("Runs")
        .sheet(isPresented: $showingRunsPicker) {
            RunsPickerView(gameModel: gameModel)
        }
    }
}

struct ExtrasView: View {
    @ObservedObject var gameModel: CricketGameModel
    @State private var showingByesPicker = false
    @State private var showingLegByesPicker = false
    @State private var extrasType: ExtrasType = .byes
    
    enum ExtrasType {
        case byes, legByes
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Extras")
                .font(.headline)
                .padding(.bottom, 4)
            
            // Wide and No Ball
            VStack(spacing: 8) {
                Button("Wide") {
                    gameModel.addWide()
                    #if os(watchOS)
                    WKInterfaceDevice.current().play(.click)
                    #endif
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("No Ball") {
                    gameModel.addNoBall()
                    #if os(watchOS)
                    WKInterfaceDevice.current().play(.click)
                    #endif
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // Byes and Leg Byes
            VStack(spacing: 8) {
                Button("Byes") {
                    extrasType = .byes
                    showingByesPicker = true
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Leg Byes") {
                    extrasType = .legByes
                    showingLegByesPicker = true
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Spacer()
            
            // Reset button
            Button("Reset Game") {
                gameModel.resetGame()
                #if os(watchOS)
                WKInterfaceDevice.current().play(.click)
                #endif
            }
            .font(.caption)
            .foregroundColor(.red)
        }
        .padding()
        .navigationTitle("Extras")
        .sheet(isPresented: $showingByesPicker) {
            ExtrasPickerView(
                gameModel: gameModel,
                extrasType: extrasType,
                title: "Byes"
            )
        }
        .sheet(isPresented: $showingLegByesPicker) {
            ExtrasPickerView(
                gameModel: gameModel,
                extrasType: extrasType,
                title: "Leg Byes"
            )
        }
    }
}

struct RunsPickerView: View {
    @ObservedObject var gameModel: CricketGameModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Select Runs")
                .font(.headline)
                .padding()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(5...20, id: \.self) { runs in
                    Button("\(runs)") {
                        gameModel.addRuns(runs)
                        #if os(watchOS)
                        WKInterfaceDevice.current().play(.click)
                        #endif
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

struct ExtrasPickerView: View {
    @ObservedObject var gameModel: CricketGameModel
    let extrasType: ExtrasView.ExtrasType
    let title: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .padding()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(1...6, id: \.self) { runs in
                    Button("\(runs)") {
                        if extrasType == .byes {
                            gameModel.addBye(runs)
                        } else {
                            gameModel.addLegBye(runs)
                        }
                        #if os(watchOS)
                        WKInterfaceDevice.current().play(.click)
                        #endif
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(extrasType == .byes ? Color.purple : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
