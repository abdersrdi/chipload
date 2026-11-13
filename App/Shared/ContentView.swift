import SwiftUI
import ChiploadCore

struct ContentView: View {
    @State private var model = CalculatorModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Operation") {
                    Picker("Operation", selection: $model.operationKind) {
                        ForEach(CalculatorModel.OperationKind.allCases) { op in
                            Text(op.rawValue).tag(op)
                        }
                    }
                    Picker("Units", selection: $model.units) {
                        Text("Imperial (in, SFM)").tag(UnitSystem.imperial)
                        Text("Metric (mm, m/min)").tag(UnitSystem.metric)
                    }
                    if model.operationKind == .milling {
                        Stepper("Flutes: \(model.flutes)", value: $model.flutes, in: 1...12)
                    }
                }

                Section("Material (reference, not a spec)") {
                    Picker("Material", selection: $model.selectedMaterial) {
                        ForEach(MaterialReference.library, id: \.name) { m in
                            Text(m.name).tag(m.name)
                        }
                    }
                    Picker("Tool material", selection: $model.toolMaterial) {
                        ForEach(ToolMaterial.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    if let range = model.suggestedSpeedRange {
                        HStack {
                            Text("Typical \(model.speedUnitLabel)")
                            Spacer()
                            Text("\(Int(range.lowerBound))–\(Int(range.upperBound))")
                                .foregroundStyle(.secondary)
                            Button("Use midpoint") { model.applySuggestedSpeed() }
                                .font(.caption)
                        }
                        Text("Starting point only — verify against your tool manufacturer's chart.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Cutting data") {
                    LabeledField(label: "Diameter (\(model.lengthUnitLabel))", value: $model.diameter)
                    LabeledField(label: "Cutting speed (\(model.speedUnitLabel))", value: $model.cuttingSpeed)
                    LabeledField(label: "Chip load (\(model.chipLoadUnitLabel))", value: $model.chipLoad)
                }

                Section("Result") {
                    resultRow("Spindle speed", String(format: "%.0f RPM", model.rpm))
                    resultRow("Feed rate", String(format: "%.2f %@", model.feedRate, model.feedUnitLabel))
                }
            }
            .navigationTitle("Chipload")
        }
    }

    private func resultRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).font(.headline.monospacedDigit())
        }
    }
}

/// A numeric text field bound to a Double, since SwiftUI's own TextField(value:) rounds oddly for
/// small chip-load numbers (0.004) unless the formatter is told how many fraction digits to allow.
private struct LabeledField: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, value: $value, format: .number.precision(.fractionLength(0...4)))
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(maxWidth: 120)
        }
    }
}

#Preview {
    ContentView()
}
