import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var gameModel = CricketGameModel()
    @State private var selectedOption: ScoringOption? = nil
    @State private var showInfo = false
    
    var body: some View {
        TabView {
            MainScoringView(gameModel: gameModel, selectedOption: $selectedOption)
                .tag(0)
            MatchInfoView(gameModel: gameModel)
                .tag(1)
            SettingsView(gameModel: gameModel)
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }

struct SettingsView: View {
    @ObservedObject var gameModel: CricketGameModel
    @State private var oversInput: String = ""
    var body: some View {
        VStack(spacing: 12) {
            Text("Settings")
                .font(.title2)
                .padding(.top, 8)
            HStack {
                Text("Overs per innings:")
                TextField("Overs", text: $oversInput)
                    .keyboardType(.numberPad)
                    .frame(width: 40)
                    .multilineTextAlignment(.center)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
            }
            Button("Set Overs") {
                if let val = Int(oversInput), val > 0 {
                    // You may want to add a property for total overs in the model
                    // For now, just store in UserDefaults or similar if needed
                    UserDefaults.standard.set(val, forKey: "oversPerInnings")
                }
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding()
        .onAppear {
            if let val = UserDefaults.standard.value(forKey: "oversPerInnings") as? Int {
                oversInput = String(val)
            }
        }
        .background(Color.black)
    }
}
}

enum ScoringOption: String, CaseIterable, Identifiable {
    case dot = "DOT"
    case one = "1"
    case two = "2"
    case four = "4"
    case six = "6"
    case noBall = "No Ball"
    case wide = "Wide"
    case more = "More"
    case wicket = "Wicket"
    var id: String { rawValue }
}

struct MainScoringView: View {
    @ObservedObject var gameModel: CricketGameModel
    @Binding var selectedOption: ScoringOption?
    
    @State private var showMoreSheet = false
    var body: some View {
        VStack(spacing: 8) {
            // Over and Score at the top (Over emphasized)
            VStack(spacing: 2) {
                // Score-Wickets (e.g., 32-1)
                Text("\(gameModel.totalRuns)-\(gameModel.wickets)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Text("Over: \(gameModel.overDisplay)")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.top, 8)
            // Scoring options grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach([ScoringOption.dot, .one, .two, .four], id: \ .self) { option in
                    OptionButton(option: option, selectedOption: $selectedOption)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                OptionButton(option: .noBall, selectedOption: $selectedOption)
                OptionButton(option: .wide, selectedOption: $selectedOption)
                Button(action: { showMoreSheet = true }) {
                    Text("More")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(selectedOption == .more ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            HStack(spacing: 32) {
                // Wicket button (cricket wicket icon)
                Button(action: { selectedOption = .wicket }) {
                    VStack(spacing: 0) {
                        Image(systemName: "sportscourt")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(selectedOption == .wicket ? .yellow : .white)
                        Text("")
                            .font(.caption2)
                    }
                }
                // Confirm button
                Button(action: {
                    if let option = selectedOption {
                        handleScoring(option)
                        selectedOption = nil
                    }
                }) {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(selectedOption == nil ? .gray : .green)
                }
                .disabled(selectedOption == nil)
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding()
        .background(Color.black)
        .sheet(isPresented: $showMoreSheet) {
            MoreOptionsSheet(gameModel: gameModel, showSheet: $showMoreSheet)
        }
    }
    
    func handleScoring(_ option: ScoringOption) {
        switch option {
        case .dot:
            gameModel.addRuns(0)
        case .one:
            gameModel.addRuns(1)
        case .two:
            gameModel.addRuns(2)
        case .four:
            gameModel.addRuns(4)
        case .six:
            gameModel.addRuns(6)
        case .noBall:
            gameModel.addNoBall()
        case .wide:
            gameModel.addWide()
        case .more:
            break // handled by sheet
        case .wicket:
            gameModel.addWicket()
        }
    }


struct MoreOptionsSheet: View {
    @ObservedObject var gameModel: CricketGameModel
    @Binding var showSheet: Bool
    var body: some View {
        VStack(spacing: 12) {
            Text("More Options")
                .font(.headline)
                .padding(.top, 8)
            // Runs 3, 5, 6
            HStack(spacing: 8) {
                ForEach([3, 5, 6], id: \ .self) { runs in
                    Button("\(runs)") {
                        gameModel.addRuns(runs)
                        showSheet = false
                    }
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            // Extras
            HStack(spacing: 8) {
                Button("Wide") {
                    gameModel.addWide()
                    showSheet = false
                }
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
                Button("Byes") {
                    gameModel.addBye(1)
                    showSheet = false
                }
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
                Button("Leg Byes") {
                    gameModel.addLegBye(1)
                    showSheet = false
                }
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            Spacer()
            Button("Close") {
                showSheet = false
            }
            .foregroundColor(.red)
            .padding(.bottom, 8)
        }
        .padding()
        .background(Color.black)
    }
}
}

struct OptionButton: View {
    let option: ScoringOption
    @Binding var selectedOption: ScoringOption?
    var body: some View {
        Button(action: { selectedOption = option }) {
            Text(option.rawValue)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(selectedOption == option ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MatchInfoView: View {
    @ObservedObject var gameModel: CricketGameModel
    var body: some View {
        VStack(spacing: 8) {
            if let otherScore = gameModel.otherTeamScore {
                Text("Other Team: \(otherScore)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text("Score: \(gameModel.totalRuns)  Wkts: \(gameModel.wickets)/10")
                .font(.title2)
                .foregroundColor(.white)
            Text("Over: \(gameModel.overDisplay)")
                .font(.headline)
                .foregroundColor(.gray)
            Divider()
            if gameModel.extras.total > 0 {
                Text("Extras: \(gameModel.extras.total)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            Spacer()
        }
        .padding()
        .background(Color.black)
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
