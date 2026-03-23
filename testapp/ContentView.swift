//
//  ContentView.swift
//  testapp
//
//  Created by Lucia Liu on 3/21/26.
//

/**
 Notes:
 - VStack: Stacks views vertically
     VStack {
         Text("Top")
         Text("Middle")
         Text("Bottom")
     }
 - HStack: Stacks views horizontally
 - ZStack: Stacks views on top of each other (layers)
 
 - @State variable
     @State private var score: Double = 0
     
     var body: some View {
         Text("Score: \(score)")
         Button("Add 10") {
             score += 10
         }
     }
 - use @State to change the UI view since SwiftUI is immutable by default
 - var = can change later
 - let = never changes
 - use clamp() so values don't go out of range
 
 Text("Hello")
     .font(.system(size: 18, weight: .bold))
     .foregroundColor(.white)
     .padding(12)
 can chain modifiers --> each modifier wraps the view above (order matters!!)
 
 - steps: Int(steps) ?? 0 --> ?? means default to 0 if no value provided (null/nil)
 - use try? to catch exceptions, return nil instead of crashing
     try?  // swallow the error, return nil if it fails — what we've been using
     try!  // crash the app if it fails — only use when you're 100% certain it won't fail
     do { try ... } catch { }  // handle the error explicitly — most control
 - guard let --> exits early if it fails (if no default)
 
 - apps have a private DOCUMENTS directory --> where app stores data, stays there forever until app is deleted
 
 - private func means only that struct can call the function
 - internal func means anything in same file can call (default)
 - public func means anywhere can call this
 - utf8 is encoding for text and emojis and ios
 
 Chart(myData) { item in
     LineMark(
         x: .value("Date", item.date),
         y: .value("Score", item.score)
     )
 }
 - Chart(myData) loops through array and draws LineMark (or BarMark, PointMark, AreaMark) and labels each value
 
 - .filter { !$0.isEmpty } is the same as .filter({ !$0.isEmpty })
 - compactMap - automatically removes nil results
 
 - underscore allows you to not explicitly state the type every time: parseLine("string") --> basically underscore is used whenever you want to ignore a value
 - if you don't add underscore, you need to explicitly state the type: parseLine(line: "String")
 func parseLine(_ line: String, dateIdx: Int, stepsIdx: Int) {}
 
 - let variable_name = value --> assigns value to variable
 - let variable_name: Type --> declaring the variable's type

 */


import SwiftUI
import Charts

struct ContentView: View {
    var body: some View {
        TabView {
            SyncView().tabItem {
                Label("Score", systemImage: "heart.fill")
            }
            
            DataView().tabItem {
                Label("Data", systemImage: "tablecells")
            }
        }
        .preferredColorScheme(.dark)
    }
}

func computeScore(steps: Int, restingHR: Int, exerciseMinutes: Int, sleepHours: Double) -> Double {
    // normalize each metric to 0.0 - 1.0
    let stepsNorm = min(Double(steps) / 10000.0, 1.0)
    let exerciseNorm = min(Double(exerciseMinutes) / 60.0, 1.0)
    let sleepNorm = min(max((sleepHours - 4.0) / 4.0, 0.0), 1.0) // anything under 4h --> 0h
    
    if restingHR > 0 { // otherwise score would return 25
        let hrNorm = 1.0 - (max(50.0, min(Double(restingHR), 90.0)) - 50.0) / 40.0
        return (stepsNorm + hrNorm + exerciseNorm + sleepNorm) / 4.0 * 100.0
    } else {
        return (stepsNorm + exerciseNorm + sleepNorm) / 3.0 * 100.0
    }
}

struct DayScore: Identifiable {
    var id: Date { date } // each date is uniquely identified by its date
    let date: Date
    let score: Double
    let steps: Int
    let restingHR: Int
    let exerciseMinutes: Int
    let sleepHours: Double
}

// MARK: SYNC TAB
struct SyncView: View {
    @State private var steps = "0"
    @State private var exerciseMinutes = "0"
    @State private var sleepHours = "0.0"
    @State private var restingHR = "0"
    @State private var score: Double = 0.0
    @State private var history: [DayScore] = []
    @State private var selectedDate = Date()
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.11, blue: 0.16).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    Text("VitaMetric")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Score ring
                    ScoreRingView(score: score)
                    
                    // Date picker
                    DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date) // show all dates up to today
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                        .labelsHidden()
                    
                    // Input fields
                    VStack(spacing: 12) {
                        MetricInputRow(label: "Steps", icon: "figure.walk", value: $steps)
                        MetricInputRow(label: "Exercise", icon: "flame.fill", value: $exerciseMinutes)
                        MetricInputRow(label: "Sleep", icon: "moon.fill", value: $sleepHours)
                        MetricInputRow(label: "Resting HR", icon: "heart.fill", value: $restingHR)
                    }
                    .padding(.horizontal)
                    
                    // Calculate button
                    Button("Calculate Score") {
                        score = computeScore(
                            steps: Int(steps) ?? 0,
                            restingHR: Int(restingHR) ?? 0,
                            exerciseMinutes: Int(exerciseMinutes) ?? 0,
                            sleepHours: Double(sleepHours) ?? 0
                        )
                        // save to csv file after calculating
                        saveDay(
                            date: selectedDate,
                            steps: Int(steps) ?? 0,
                            restingHR: Int(restingHR) ?? 0,
                            exerciseMinutes: Int(exerciseMinutes) ?? 0,
                            sleepHours: Double(sleepHours) ?? 0
                        )
                        history = loadAllScoresFromCSV()
                    }
                    .font(.system(size: 15, weight: .semibold)) // style text
                    .foregroundColor(.black) // style text color
                    .frame(maxWidth: .infinity) // stretch button wide
                    .padding(.vertical, 14) // add height for button
                    .background(Color.yellow) // fill background
                    .cornerRadius(12) // round corners of the background
                    .padding(.horizontal) // push away from screen edges
                    
                    if history.count > 0 {
                        ScoreChartView(history: history)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .onAppear { // load data when screen opens
                history = loadAllScoresFromCSV()
                loadFromCSV()
            }
            .onChange(of: selectedDate) { _ in
                // clear fields first, that way if one day has missing data, the numbers will default to 0
                steps = "0"
                exerciseMinutes = "0"
                sleepHours = "0.0"
                restingHR = "0"
                
                // load date for new date + recalculate score
                loadFromCSV()
                score = computeScore(
                    steps: Int(steps) ?? 0,
                    restingHR: Int(restingHR) ?? 0,
                    exerciseMinutes: Int(exerciseMinutes) ?? 0,
                    sleepHours: Double(sleepHours) ?? 0
                )
            }
        }
    }
    
    // load today's data into input values
    private func loadFromCSV() {
        let url = csvURL()
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateStr = df.string(from: selectedDate)
        
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard lines.count > 1 else { return }
        
        let headers = lines[0].components(separatedBy: ",")
        // finds index of each column by name
        let dateIdx = headers.firstIndex(of: "date") ?? 0
        let stepsIdx = headers.firstIndex(of: "steps") ?? 1
        let hrIdx = headers.firstIndex(of: "resting_heart_rate_bpm") ?? 2
        let exIdx = headers.firstIndex(of: "exercise_minutes") ?? 3
        let sleepIdx = headers.firstIndex(of: "sleep_hours") ?? 4
        
        // loops through every line except the header
        for line in lines.dropFirst() {
            let cols = line.components(separatedBy: ",") // "2024-01-15,8000,62,45,7.5" becomes ["2024-01-15", "8000", "62", "45", "7.5"]
            guard cols[dateIdx] == dateStr else { continue } // checks if this row's date matches today, otherwise continue
            steps = cols[stepsIdx]
            exerciseMinutes = cols[exIdx]
            sleepHours = cols[sleepIdx]
            restingHR = cols[hrIdx]
            break
        }
    }
}

struct MetricInputRow: View {
    let label: String
    let icon: String
    @Binding var value: String // connects to parent's @State, pass with $
    
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.yellow)
            Text(label).foregroundColor(.white)
            Spacer()
            TextField("0", text: $value)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.white)
                .frame(width: 80)
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ScoreRingView: View {
    let score: Double
    
    var body: some View {
        ZStack {
            // background circle outline
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 12)
                .frame(width: 150, height: 150)
            
            // outline fill (based on score)
            Circle()
                .trim(from: 0, to: Double(score / 100.0)) // fills amount of circle based on score
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.92, green: 0.32, blue: 0.28),  // red
                            Color(red: 0.98, green: 0.72, blue: 0.22),  // amber
                            Color(red: 0.22, green: 0.78, blue: 0.45)   // green
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(351)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 150, height: 150) // same as background circle outline
                .rotationEffect(.degrees(-87)) // start at top instead of right
                .animation(.easeInOut(duration: 0.8), value: score) // makes ring animate smoothly when score changes
                
            // score number
            VStack(spacing: 2) {
                Text("\(Int(score))")
                    .font(.system(size: 50, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("SCORE")
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct ScoreChartView: View {
    let history: [DayScore]
    
    private let gold = Color(red: 0.79, green: 0.66, blue: 0.30)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Score Trend")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(white: 0.45))
                .tracking(1)
                .textCase(.uppercase)
            
            if history.count > 1 {
                Chart(history) { day in
                    LineMark(
                        x: .value("Date", day.date),
                        y: .value("Score", day.score)
                    )
                    .foregroundStyle(gold)
                    //.interpolationMethod(.catmullRom) // makes line curve smoothly b/w points
                    
                    AreaMark( // fills area under line
                        x: .value("Date", day.date),
                        y: .value("Score", day.score)
                    )
                    .foregroundStyle(
                        LinearGradient( // creates gradient
                            colors: [gold.opacity(0.25), Color.clear],
                            startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom) // makes line curve smoothly b/w points
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel() // tick marks
                            .foregroundStyle(Color.white.opacity(0.75))
                            .font(.system(size: 11, design: .monospaced))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.75))
                            .font(.system(size: 11, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
            } else {
                Text("No history yet - add more days!")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(white: 0.35))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 80)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
    }
}

func csvURL() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("health_log.csv")
}

func saveDay(date: Date, steps: Int, restingHR: Int, exerciseMinutes: Int, sleepHours: Double) {
    let df = DateFormatter() // DateFormatter converts b/w Date objects and strings
    df.dateFormat = "yyyy-MM-dd"
    let dateStr = df.string(from: date)
    
    let url = csvURL()
    
    // read existing content, otherwise make new one
    var content = (try? String(contentsOf: url, encoding: .utf8)) ?? "date,steps,resting_heart_rate_bpm,exercise_minutes,sleep_hours\n"
    
    // if there's already a row for today's date, remove it since we're going to rewrite it
    // each entry is separated by a \n, $0 means current item, filters out empty strings
    var lines = content.components(separatedBy: "\n").filter { !$0.isEmpty}
    lines = lines.filter { !$0.hasPrefix(dateStr) } // removes any row that starts w/ today's date
    lines.append("\(dateStr),\(steps),\(restingHR),\(exerciseMinutes),\(sleepHours)") // add new row
    
    let updated = lines.joined(separator: "\n") + "\n"
    try? updated.write(to: url, atomically: true, encoding: .utf8) // atomically is for safety, writes to temporary file first and if that succeeds, replace w/ real file
}

// need to return all rows from CSV to draw charts
func loadAllScoresFromCSV() -> [DayScore] {
    let url = csvURL()
    guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
    
    let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }
    guard lines.count > 1 else { return [] }
    
    let headers = lines[0].components(separatedBy: ",")
    // finds index of each column by name
    let dateIdx = headers.firstIndex(of: "date") ?? 0
    let stepsIdx = headers.firstIndex(of: "steps") ?? 1
    let hrIdx = headers.firstIndex(of: "resting_heart_rate_bpm") ?? 2
    let exIdx = headers.firstIndex(of: "exercise_minutes") ?? 3
    let sleepIdx = headers.firstIndex(of: "sleep_hours") ?? 4
    
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd"
    
    // compactMap - automatically removes nil results
    return lines.dropFirst().compactMap { line -> DayScore? in
        let cols = line.components(separatedBy: ",")
        guard cols.count > max(dateIdx, stepsIdx, hrIdx, exIdx, sleepIdx) else { return nil }
        guard let date = df.date(from: cols[dateIdx]) else { return nil }
        let s = Int(cols[stepsIdx]) ?? 0
        let hr = Int(cols[hrIdx]) ?? 0
        let ex = Int(cols[exIdx]) ?? 0
        let sl = Double(cols[sleepIdx]) ?? 0
        return DayScore(
            date: date,
            score: computeScore(steps: s, restingHR: hr, exerciseMinutes: ex, sleepHours: sl),
            steps: s,
            restingHR: hr,
            exerciseMinutes: ex,
            sleepHours: sl
        )
    }.sorted { $0.date < $1.date } // first date is less than second date
}

// MARK: DATA VIEW
struct DataView: View {
    @State private var rows: [[String]] = []
    @State private var headers: [String] = []
    
    private let gold = Color(red: 0.79, green: 0.66, blue: 0.30)
    
    private let abbrev: [String: String] = [
        "date": "Date",
        "steps": "Steps",
        "resting_heart_rate_bpm": "RHR",
        "exercise_minutes": "Ex.Min",
        "sleep_hours": "Sleep"
    ]
    
    var body: some View {
        ZStack{
            Color(red: 0.05, green: 0.11, blue: 0.16).ignoresSafeArea()
            
            VStack() {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) { // .leading: left-aligned
                        Text("History")
                            .font(.system(size: 17, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                        Text("\(rows.count) rows")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color(white: 0.4)) // similar to opacity, but makes it actually gray while opacity makes it slightly transparent
                    }
                    Spacer() // pushes the VStack to the left
                }
                .padding(.leading, 16)
                //.padding(.vertical, 16)
                
                Divider().opacity(0.5)
                
                // Table
                ScrollView(.vertical) {
                    VStack() {
                        // header
                        HStack(spacing: 0) { // spacing: 0 removes extra space so it lines up with columns below
                            ForEach(headers, id: \.self) { header in
                                Text(abbrev[header] ?? header)
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundColor(gold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 10)
                            }
                        }
                        .background(Color.white.opacity(0.05))
                        
                        // data rows
                        // rows.enumerated - asigns each row with its index
                        ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                            HStack(spacing: 0) {
                                ForEach(Array(row.enumerated()), id: \.offset) { colIdx, cell in
                                    Text(colIdx == 0 ? prettyDate(cell) : (cell.isEmpty ? "-" : cell))
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(cell.isEmpty ? Color(white: 0.3) : .white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 12)
                                }
                            }
                            .background(idx % 2 == 0 ? Color.clear : Color.white.opacity(0.02)) // creates alternating light and dark rows
                        }
                    }
                }
            }
            .padding(.horizontal, 16) // applies padding to both left and right
        }
        .onAppear { loadCSV() }
    }
    
    private func loadCSV() {
        let url = csvURL()
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard lines.count > 1 else { return }
        headers = lines[0].components(separatedBy: ",")
        rows = lines.dropFirst()
            .map { $0.components(separatedBy: ",") }
            .sorted { a, b in
                let d1 = a.first ?? ""
                let d2 = b.first ?? ""
                return d1 > d2
            }
    }
    
    private func prettyDate(_ raw: String) -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        
        let output = DateFormatter()
        output.dateFormat = "MMM d"
        
        return input.date(from: raw.trimmingCharacters(in: .whitespaces))
            .map { output.string(from: $0 ) } ?? raw
    }
}

