import SwiftUI
import Combine

struct FocusView: View {
    @EnvironmentObject private var store: AppDataStore

    @State private var phase: FocusTimerPhase = .idle
    @State private var remainingSec = 0
    @State private var timerActive = false
    @State private var timerCancellable: AnyCancellable?
    @State private var hourlyRateText = ""

    private var focusMinutes: Int { store.focusConfig.focusDurationSec / 60 }
    private var breakMinutes: Int { store.focusConfig.breakDurationSec / 60 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader("Focus Cycle", subtitle: "Configure intervals and run sessions")
                    ClippedBannerImage(name: "imgHourglass", height: 110)

                    GlassPanel {
                        VStack(spacing: 16) {
                            durationControl(
                                title: "Focus length",
                                minutes: focusMinutes,
                                onMinus: { store.setFocusDurationMinutes(focusMinutes - 1) },
                                onPlus: { store.setFocusDurationMinutes(focusMinutes + 1) },
                                onSlider: { store.setFocusDurationMinutes($0) }
                            )
                            durationControl(
                                title: "Break length",
                                minutes: breakMinutes,
                                onMinus: { store.setBreakDurationMinutes(breakMinutes - 1) },
                                onPlus: { store.setBreakDurationMinutes(breakMinutes + 1) },
                                onSlider: { store.setBreakDurationMinutes($0) }
                            )
                            AppTextField(
                                title: "Value per hour",
                                placeholder: "0.00",
                                text: $hourlyRateText,
                                keyboardType: .decimalPad
                            )
                            .onChange(of: hourlyRateText) { newValue in
                                if let value = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                                    store.setHourlyRate(value)
                                } else if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    store.setHourlyRate(0)
                                }
                            }
                        }
                    }

                    GlassPanel {
                        VStack(spacing: 12) {
                            Text(timerLabel)
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text(formattedTime(remainingSec))
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text("Sessions completed: \(store.focusConfig.sessionCount)")
                                .font(.subheadline)
                                .foregroundStyle(Color("AppAccent"))
                            Text("Estimated value: \(AmountFormat.string(store.focusEarnedValue))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            if let last = store.focusConfig.lastSessionDate {
                                Text("Last session: \(last.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            HStack(spacing: 12) {
                                Button(timerActive ? "Pause" : (phase == .idle ? "Start Focus" : "Resume")) {
                                    toggleTimer()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                Button("Reset") {
                                    resetTimer()
                                }
                                .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .constrainedContentWidth()
            }
            .transparentChrome()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                hourlyRateText = store.focusConfig.hourlyRate > 0
                    ? String(format: "%.2f", store.focusConfig.hourlyRate)
                    : ""
            }
            .onDisappear {
                stopTicker()
            }
        }
        .background(Color.clear)
    }

    private var timerLabel: String {
        switch phase {
        case .idle: return "Ready"
        case .focus: return "Focus session"
        case .breakTime: return "Break"
        }
    }

    private func durationControl(
        title: String,
        minutes: Int,
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void,
        onSlider: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .foregroundStyle(Color("AppTextPrimary"))
                Spacer()
                Text("\(minutes) min")
                    .foregroundStyle(Color("AppAccent"))
                    .font(.headline)
            }
            HStack {
                Button(action: onMinus) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                }
                .disabled(minutes <= 1)
                Slider(
                    value: Binding(
                        get: { Double(minutes) },
                        set: { onSlider(Int($0.rounded())) }
                    ),
                    in: 1...60,
                    step: 1
                )
                .tint(Color("AppPrimary"))
                Button(action: onPlus) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(minutes >= 60)
            }
            .foregroundStyle(Color("AppAccent"))
        }
    }

    private func toggleTimer() {
        if timerActive {
            stopTicker()
            return
        }
        if phase == .idle {
            phase = .focus
            remainingSec = store.focusConfig.focusDurationSec
        }
        startTicker()
    }

    private func resetTimer() {
        stopTicker()
        phase = .idle
        remainingSec = 0
    }

    private func startTicker() {
        timerActive = true
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in tick() }
    }

    private func stopTicker() {
        timerActive = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func tick() {
        guard remainingSec > 0 else {
            advancePhase()
            return
        }
        remainingSec -= 1
        if remainingSec == 0 {
            advancePhase()
        }
    }

    private func advancePhase() {
        switch phase {
        case .focus:
            store.recordCompletedFocusSession()
            phase = .breakTime
            remainingSec = store.focusConfig.breakDurationSec
        case .breakTime:
            phase = .focus
            remainingSec = store.focusConfig.focusDurationSec
        case .idle:
            stopTicker()
        }
    }

    private func formattedTime(_ sec: Int) -> String {
        let m = sec / 60
        let s = sec % 60
        return String(format: "%02d:%02d", m, s)
    }
}
