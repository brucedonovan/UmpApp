import SwiftUI
import WatchKit

// All supporting views are defined above
// ...existing code for SettingsView, ScoringOption, MainScoringView, MoreOptionsSheet, OptionButton, MatchInfoView, ScoreView, QuickActionsView, ExtrasView, RunsPickerView, ExtrasPickerView...

// Move MatchInfoView above ContentView so it is in scope
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

struct ContentView: View {
    @StateObject private var gameModel = CricketGameModel()
    // Removed unused selectedOption
    @State private var showInfo = false
    var body: some View {
        TabView {
            MainScoringView(gameModel: gameModel)
                .tag(0)
            MatchInfoView(gameModel: gameModel)
                .tag(1)
            SettingsView(gameModel: gameModel)
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
    
    // MARK: - SettingsView
    struct SettingsView: View {
        @ObservedObject var gameModel: CricketGameModel
        @State private var oversInput: String = ""
        var body: some View {
            VStack(spacing: 8) {
                // Score-Wickets (e.g., 123-4 (23.2 overs))
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(gameModel.totalRuns)-\(gameModel.wickets)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("(\(gameModel.overDisplay) overs)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.yellow)
                }
                .padding(.top, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(6)
                Button("Set Overs") {
                    if let val = Int(oversInput), val > 0 {
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
        // Remove selectedOption, use new selection states:
        @State private var selectedRuns: Int? = nil // e.g. 0,1,2,3,4,5,6,7
        @State private var selectedExtra: ExtraType? = nil // .noBall, .wide, .bye, .legBye
        @State private var showMoreSheet = false
        @State private var selectedWicket: Bool = false
        
        enum ExtraType: String, CaseIterable, Identifiable {
            case noBall = "No Ball"
            case wide = "Wide"
            case bye = "Bye"
            case legBye = "Leg Bye"
            var id: String { rawValue }
        }
        
        var body: some View {
            VStack(spacing: 8) {
                // Score-Wickets (e.g., 120-2) with overs in brackets (e.g., 120-2 (3.5))
                HStack(alignment: VerticalAlignment.firstTextBaseline, spacing: 8) {
                    Text("\(gameModel.totalRuns)-\(gameModel.wickets)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("(\(overDisplayZeroBased()) overs)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.yellow)
                }
                .padding(.top, 8)

                // Main runs row (0,1,2,4)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach([0,1,2,4], id: \Int.self) { run in
                        RunButton(run: run, selectedRuns: $selectedRuns)
                    }
                }
                // Extras row (No Ball, Wide, More)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ExtraButton(extra: .noBall, selectedExtra: $selectedExtra)
                    ExtraButton(extra: .wide, selectedExtra: $selectedExtra)
                    Button(action: { showMoreSheet = true }) {
                        Text("More")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                HStack(spacing: 32) {
                    // Wicket button (selectable, requires confirm)
                    Button(action: {
                        if selectedWicket {
                            selectedWicket = false
                        } else {
                            selectedWicket = true
                            // Deselect other options
                            selectedRuns = nil
                            selectedExtra = nil
                        }
                    }) {
                        Text("W")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(selectedWicket ? .yellow : .white)
                            .frame(width: 22, height: 22)
                            .background(selectedWicket ? Color.blue : Color.gray.opacity(0.3))
                            .cornerRadius(6)
                    }
                    // Confirm button with combined label
                    Button(action: {
                        handleConfirm()
                        clearSelections()
                    }) {
                        Text(confirmLabel())
                            .font(.headline)
                            .frame(width: 48, height: 48)
                            .foregroundColor(confirmEnabled() ? .white : .gray)
                            .background(confirmEnabled() ? Color.green : Color.gray.opacity(0.2))
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(confirmEnabled() ? Color.green : Color.gray, lineWidth: 2)
                            )
                            .shadow(color: confirmEnabled() ? Color.green.opacity(0.4) : .clear, radius: confirmEnabled() ? 6 : 0)
                    }
                    .disabled(!confirmEnabled())
                }
                .padding(.top, 8)
                Spacer()
            }
            .padding()
            .background(Color.black)
            .sheet(isPresented: $showMoreSheet) {
                MoreOptionsSheet(selectedRuns: $selectedRuns, selectedExtra: $selectedExtra, showSheet: $showMoreSheet)
            }
        }

        // Confirm button label logic
        func confirmLabel() -> String {
            if selectedWicket {
                return "W"
            } else if let run = selectedRuns, let extra = selectedExtra {
                let runStr = run > 0 ? "\(run)" : ""
                switch extra {
                case .noBall: return runStr + "Nb"
                case .wide: return runStr + "Wd"
                case .bye: return runStr + "B"
                case .legBye: return runStr + "LB"
                }
            } else if let run = selectedRuns {
                return "\(run)"
            } else if let extra = selectedExtra {
                switch extra {
                case .noBall: return "Nb"
                case .wide: return "Wd"
                case .bye: return "B"
                case .legBye: return "LB"
                }
            }
            return "✓"
        }

        func confirmEnabled() -> Bool {
            return selectedWicket || selectedRuns != nil || selectedExtra != nil
        }

        // MARK: - Button Views
        struct RunButton: View {
            let run: Int
            @Binding var selectedRuns: Int?
            var body: some View {
                Button(action: {
                    selectedRuns = (selectedRuns == run) ? nil : run
                }) {
                    Text("\(run)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(selectedRuns == run ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        struct ExtraButton: View {
            let extra: ExtraType
            @Binding var selectedExtra: ExtraType?
            var body: some View {
                Button(action: {
                    selectedExtra = (selectedExtra == extra) ? nil : extra
                }) {
                    Text(extra.rawValue)
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(selectedExtra == extra ? Color.purple : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }

        // MARK: - Confirm Logic
        func handleConfirm() {
            if selectedWicket {
                gameModel.addWicket()
            } else if let run = selectedRuns, let extra = selectedExtra {
                // Only add the run value, not addative for extras
                gameModel.addRuns(run)
            } else if let run = selectedRuns {
                gameModel.addRuns(run)
            } else if let extra = selectedExtra {
                switch extra {
                case .noBall:
                    gameModel.addNoBall()
                case .wide:
                    gameModel.addWide()
                case .bye:
                    gameModel.addBye(1)
                case .legBye:
                    gameModel.addLegBye(1)
                }
            }
        }
        func clearSelections() {
            selectedRuns = nil
            selectedExtra = nil
            selectedWicket = false
        }
        
        // ...existing code...
        func overDisplayZeroBased() -> String {
            let comps = gameModel.overDisplay.split(separator: ".")
            if comps.count == 2, let over = Int(comps[0]), let balls = Int(comps[1]) {
                let zeroBasedOver = max(0, over - 1)
                return "\(zeroBasedOver).\(balls)"
            } else {
                return gameModel.overDisplay
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
        
        // MARK: - MoreOptionsSheet
        struct MoreOptionsSheet: View {
            // Now passes selection bindings to allow selection from More screen
            @Binding var selectedRuns: Int?
            @Binding var selectedExtra: ExtraType?
            @Binding var showSheet: Bool
            // To help Swift type-checker, define the runs array as a property
            let moreRuns: [Int] = [3, 5, 6, 7]
            var body: some View {
                VStack(spacing: 8) {
                    // Top row: 3, 5, 6, 7 runs (selectable)
                    HStack(spacing: 8) {
                        ForEach(moreRuns, id: \ .self) { runs in
                            Button(action: {
                                selectedRuns = (selectedRuns == runs) ? nil : runs
                            }) {
                                Text("\(runs)")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(selectedRuns == runs ? Color.blue : Color.clear)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }

                    // Bottom row: Byes, Leg Byes (selectable as extras)
                    HStack(spacing: 8) {
                        Button(action: {
                            selectedExtra = (selectedExtra == .bye) ? nil : .bye
                        }) {
                            Text("Byes")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(selectedExtra == .bye ? Color.purple : Color.clear)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        Button(action: {
                            selectedExtra = (selectedExtra == .legBye) ? nil : .legBye
                        }) {
                            Text("Leg Byes")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(selectedExtra == .legBye ? Color.purple : Color.clear)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }

                    Spacer()
                    Button(action: { showSheet = false }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                            Text("Back")
                                .font(.headline)
                        }
                        .foregroundColor(.blue)
                        .padding(.bottom, 8)
                    }
                }
                .padding()
                .background(Color.black)
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
                    // Last balls of the over (top left corner)
                    HStack(alignment: .center, spacing: 4) {
                        ForEach(lastBallsOfOver(gameModel: gameModel), id: \ .self) { ball in
                            Text(ball)
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 1)
                        }
                        Spacer()
                    }
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
                            // ...existing code for recent balls display...
                        }
                    }
                }
                .padding()
                .navigationTitle("Score")
                .alert("Over Complete!", isPresented: $gameModel.isOverComplete) {
                    Button("OK") { }
                }
            }
            
            /// Returns the last balls of the current over as display strings (e.g., [".", "4", ".", "2", "1wd"])
            private func lastBallsOfOver(gameModel: CricketGameModel) -> [String] {
                // Use a default balls per over (6) if not available in model
                let ballsPerOver = 6
                let history = gameModel.ballHistory
                // Take the last N balls (most recent at end)
                let lastBalls = history.suffix(ballsPerOver)
                // Convert each to string for display
                return lastBalls.map { displayString(for: $0) }
            }
            
            /// Converts a ball event to a display string (e.g., ".", "4", "1wd")
            private func displayString(for event: Any) -> String {
                // If ballHistory is [String], just return
                if let str = event as? String { return str }
                if let num = event as? Int { return "\(num)" }
                // Unknown type fallback
                return "?"
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
            enum ExtrasType {
                case byes, legByes
            }
            let extrasType: ExtrasType
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
        
        
    }
    // Remove extraneous closing braces at the end of the file
}
