import SwiftUI

struct SupplementTrackerView: View {
    @StateObject private var supplementManager = SupplementManager()
    @State private var showingAddSupplement = false
    @State private var showingTemplates = false
    @State private var selectedSupplement: Supplement?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let summary = supplementManager.todaysSummary {
                        todaysSummaryCard(summary)
                    }
                    
                    supplementsList
                    
                    if !supplementManager.getUpcomingReminders().isEmpty {
                        upcomingRemindersCard
                    }
                    
                    quickAddSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Supplements")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSupplement = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddSupplement) {
                AddSupplementView(supplementManager: supplementManager)
            }
            .sheet(isPresented: $showingTemplates) {
                SupplementTemplatesView(supplementManager: supplementManager)
            }
            .sheet(item: $selectedSupplement) { supplement in
                SupplementDetailView(supplement: supplement, supplementManager: supplementManager)
            }
        }
    }
    
    private func todaysSummaryCard(_ summary: SupplementManager.SupplementSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Progress")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(summary.takenToday)/\(summary.totalSupplements)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(summary.takenToday == summary.totalSupplements ? .green : .primary)
                    Text("Supplements Taken")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: Double(summary.takenToday) / Double(max(summary.totalSupplements, 1)),
                    lineWidth: 8
                )
                .frame(width: 80, height: 80)
            }
            
            if summary.missedToday > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("\(summary.missedToday) supplements still needed today")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            HStack {
                Label("7-Day Compliance", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(summary.complianceRate * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(summary.complianceRate > 0.8 ? .green : .orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var supplementsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Supplements")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(supplementManager.getTodaysIntake(), id: \.supplement.id) { item in
                SupplementRow(
                    supplement: item.supplement,
                    taken: item.taken,
                    timesNeeded: item.timesNeeded,
                    onTap: {
                        selectedSupplement = item.supplement
                    },
                    onToggle: {
                        supplementManager.logIntake(supplementId: item.supplement.id, taken: !item.taken)
                    }
                )
            }
        }
    }
    
    private var upcomingRemindersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Reminders")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(supplementManager.getUpcomingReminders().prefix(3), id: \.0.id) { reminder in
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(reminder.0.name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(formatTime(reminder.1))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(["Prenatal", "Iron", "Vitamin D", "DHA", "Folic Acid"], id: \.self) { name in
                        Button(action: {
                            supplementManager.addFromTemplate(name)
                        }) {
                            Text(name)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(20)
                        }
                        .disabled(supplementManager.supplements.contains(where: { $0.name.contains(name) }))
                    }
                    
                    Button(action: { showingTemplates = true }) {
                        Label("More", systemImage: "ellipsis")
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.gray)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SupplementRow: View {
    let supplement: Supplement
    let taken: Bool
    let timesNeeded: Int
    let onTap: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: taken ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(taken ? .green : .gray)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(supplement.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if supplement.isEssential {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(supplement.dosage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text(supplement.frequency.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if timesNeeded > 1 {
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Text("\(supplement.todaysTaken())/\(timesNeeded) today")
                            .font(.caption)
                            .foregroundColor(supplement.todaysTaken() >= timesNeeded ? .green : .orange)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onTap) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct AddSupplementView: View {
    @ObservedObject var supplementManager: SupplementManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = Supplement.SupplementFrequency.daily
    @State private var reminderEnabled = true
    @State private var reminderTime = Date()
    @State private var notes = ""
    @State private var isEssential = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Supplement Information")) {
                    TextField("Name", text: $name)
                    TextField("Dosage (e.g., 400mg, 1 tablet)", text: $dosage)
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Supplement.SupplementFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    
                    Toggle("Essential Supplement", isOn: $isEssential)
                }
                
                Section(header: Text("Reminders")) {
                    Toggle("Enable Reminders", isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Add Supplement")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") { saveSupplement() }
                    .disabled(name.isEmpty || dosage.isEmpty)
            )
        }
    }
    
    private func saveSupplement() {
        let supplement = Supplement(
            name: name,
            dosage: dosage,
            frequency: frequency,
            reminderTimes: reminderEnabled ? [reminderTime] : [],
            remindersEnabled: reminderEnabled,
            notes: notes.isEmpty ? nil : notes,
            isEssential: isEssential
        )
        
        supplementManager.addSupplement(supplement)
        dismiss()
    }
}

struct SupplementDetailView: View {
    @State var supplement: Supplement
    @ObservedObject var supplementManager: SupplementManager
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var editedDosage: String = ""
    @State private var editedFrequency: Supplement.SupplementFrequency = .daily
    @State private var editedReminderTime: Date = Date()
    @State private var editedNotes: String = ""
    @State private var editedIsEssential: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isEditing {
                        editingCard
                    } else {
                        supplementInfoCard
                    }
                    
                    complianceCard
                    intakeHistoryCard
                    
                    if !supplementManager.checkInteractions(supplement).isEmpty {
                        interactionsCard
                    }
                    
                    deleteButton
                }
                .padding(.vertical)
            }
            .navigationTitle(supplement.name)
            .navigationBarItems(
                leading: isEditing ? Button("Cancel") { 
                    isEditing = false
                    resetEditFields()
                } : nil,
                trailing: Button(isEditing ? "Save" : "Edit") { 
                    if isEditing {
                        saveChanges()
                    } else {
                        startEditing()
                    }
                }
            )
        }
        .onAppear {
            resetEditFields()
        }
    }
    
    private var editingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Edit Details", systemImage: "pencil.circle.fill")
                .font(.headline)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 12) {
                // Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Supplement name", text: $editedName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Dosage
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dosage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g., 500mg", text: $editedDosage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Frequency
                VStack(alignment: .leading, spacing: 4) {
                    Text("Frequency")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Frequency", selection: $editedFrequency) {
                        ForEach(Supplement.SupplementFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Reminder Time
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reminder Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $editedReminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                // Essential Toggle
                Toggle(isOn: $editedIsEssential) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Essential Supplement")
                    }
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes (optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Additional notes", text: $editedNotes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var supplementInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Details", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 8) {
                detailRow(label: "Dosage", value: supplement.dosage)
                detailRow(label: "Frequency", value: supplement.frequency.rawValue)
                
                if supplement.isEssential {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Essential Supplement")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let notes = supplement.notes {
                    detailRow(label: "Notes", value: notes)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var complianceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Compliance", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundColor(.green)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(Int(supplement.complianceRate(days: 7) * 100))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("7-Day Compliance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(supplement.complianceRate(days: 30) * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("30-Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var intakeHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent History", systemImage: "clock.fill")
                .font(.headline)
                .foregroundColor(.purple)
            
            ForEach(supplement.intakeHistory.suffix(7).reversed()) { record in
                HStack {
                    Image(systemName: record.taken ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(record.taken ? .green : .red)
                    
                    Text(formatDate(record.date))
                        .font(.subheadline)
                    
                    Spacer()
                    
                    if let notes = record.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var interactionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Interactions", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.orange)
            
            ForEach(supplementManager.checkInteractions(supplement), id: \.self) { warning in
                Text(warning)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var deleteButton: some View {
        Button(action: {
            supplementManager.deleteSupplement(supplement)
            dismiss()
        }) {
            Label("Delete Supplement", systemImage: "trash")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func startEditing() {
        isEditing = true
        resetEditFields()
    }
    
    private func resetEditFields() {
        editedName = supplement.name
        editedDosage = supplement.dosage
        editedFrequency = supplement.frequency
        editedReminderTime = supplement.reminderTimes.first ?? Date()
        editedNotes = supplement.notes ?? ""
        editedIsEssential = supplement.isEssential
    }
    
    private func saveChanges() {
        // Update the supplement
        supplement.name = editedName
        supplement.dosage = editedDosage
        supplement.frequency = editedFrequency
        supplement.reminderTimes = [editedReminderTime]
        supplement.notes = editedNotes.isEmpty ? nil : editedNotes
        supplement.isEssential = editedIsEssential
        
        // Update in manager
        supplementManager.updateSupplement(supplement)
        
        // Update reminder if time changed
        if !supplement.reminderTimes.isEmpty {
            supplementManager.scheduleReminder(for: supplement)
        }
        
        isEditing = false
    }
}

struct SupplementTemplatesView: View {
    @ObservedObject var supplementManager: SupplementManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(PregnancySupplements.commonSupplements) { template in
                HStack {
                    VStack(alignment: .leading) {
                        Text(template.name)
                            .font(.headline)
                        Text(template.dosage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let notes = template.notes {
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    if template.isEssential {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    supplementManager.addFromTemplate(template.name)
                    dismiss()
                }
            }
            .navigationTitle("Common Supplements")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    progress == 1.0 ? Color.green : Color.blue,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.bold)
        }
    }
}