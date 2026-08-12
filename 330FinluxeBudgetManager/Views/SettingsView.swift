import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SectionHeader("Preferences", subtitle: "Legal and data controls")

                    GlassPanel {
                        VStack(spacing: 0) {
                            settingsRow(title: "Rate Us", icon: "star.fill") {
                                AppReviewService.requestReview()
                            }
                            divider
                            settingsRow(title: "Privacy Policy", icon: "hand.raised.fill") {
                                if let url = URL(string: AppLinks.privacy) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            divider
                            settingsRow(title: "Terms of Use", icon: "doc.text.fill") {
                                if let url = URL(string: AppLinks.terms) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            divider
                            settingsRow(title: "Reset All Data", icon: "trash.fill", destructive: true) {
                                showResetConfirm = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .constrainedContentWidth()
            }
            .transparentChrome()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "Reset all data?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Tasks, expenses, budgets, goals, and focus stats will be erased.")
            }
        }
        .background(Color.clear)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color("AppTextSecondary").opacity(0.2))
            .frame(height: 1)
    }

    private func settingsRow(
        title: String,
        icon: String,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(destructive ? Color.red : Color("AppAccent"))
                    .frame(width: 24)
                Text(title)
                    .foregroundStyle(destructive ? Color.red : Color("AppTextPrimary"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}
