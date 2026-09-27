import SwiftUI

struct BalanceCardView: View {
    @ObservedObject var balanceManager: BalanceManager
    @ObservedObject var pricingManager: PricingManager
    @ObservedObject var scheduleManager: ScheduleManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Section label + status/actions
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 10, weight: .bold))
                    Text("ACCOUNT & BUDGET")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(Color.secondary)

                Spacer()

                if balanceManager.hasApiKey && !balanceManager.isEditingKey {
                    HStack(spacing: 6) {
                        // Refresh button
                        Button(action: {
                            balanceManager.fetchBalance()
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 9, weight: .semibold))
                                    .rotationEffect(.degrees(balanceManager.isLoading ? 360 : 0))
                                    .animation(balanceManager.isLoading ? Animation.linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: balanceManager.isLoading)
                                if balanceManager.lastSyncTime != nil {
                                    Text(balanceManager.formattedLastSync)
                                        .font(.system(size: 10, weight: .medium))
                                }
                            }
                            .foregroundColor(Color.primary.opacity(colorScheme == .dark ? 0.70 : 0.60))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.05))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(balanceManager.isLoading)

                        // Key / Settings button
                        Button(action: {
                            balanceManager.isEditingKey = true
                            balanceManager.enteredKey = ""
                        }) {
                            Image(systemName: "key")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color.primary.opacity(colorScheme == .dark ? 0.70 : 0.60))
                                .padding(5)
                                .background(
                                    Circle()
                                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.05))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if balanceManager.isEditingKey {
                // Inline Key Entry
                keyEntryForm
            } else if balanceManager.hasApiKey {
                // Active Account Card
                activeBalanceView
            } else {
                // Callout to add key
                emptyStateView
            }
        }
    }

    // MARK: - Active Balance View

    private var activeBalanceView: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                // Balance amount
                if let balance = balanceManager.totalBalance {
                    HStack(spacing: 4) {
                        Text(String(format: "$%.2f", balance))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color.primary)

                        Text(balanceManager.currency)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.secondary)
                    }
                } else if balanceManager.isLoading {
                    Text("Fetching balance...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.secondary)
                } else if let error = balanceManager.errorMessage {
                    Text(error)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                }

                Spacer()

                // Status Badge
                statusBadge
            }

            // Breakdown (Topped-up vs Granted)
            if let topUp = balanceManager.toppedUpBalance, let grant = balanceManager.grantedBalance {
                HStack(spacing: 8) {
                    Text("Topped-up: $\(String(format: "%.2f", topUp))")
                    Text("•")
                        .foregroundColor(Color.secondary.opacity(0.5))
                    Text("Granted: $\(String(format: "%.2f", grant))")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.secondary)
            }

            // Estimated token capacity pill
            if let balance = balanceManager.totalBalance, balance > 0 {
                tokenCapacityPill
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.05 : 0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.07), lineWidth: 0.8)
        )
    }

    // MARK: - Token Capacity Pill

    private var tokenCapacityPill: some View {
        let isOffPeak = scheduleManager.isOffPeak
        let flashModel = pricingManager.models.first(where: { $0.id == "deepseek-v4-flash" })
        let proModel = pricingManager.models.first(where: { $0.id == "deepseek-v4-pro" })

        return HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 9))
                .foregroundColor(isOffPeak ? Color(red: 0.18, green: 0.52, blue: 1.0) : Color.orange)

            Text("Est. Tokens:")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.secondary)

            if let flash = flashModel {
                HStack(spacing: 2) {
                    Text(balanceManager.estimatedTokens(for: flash, isOffPeak: isOffPeak))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.primary)
                    Text("Flash")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color.secondary)
                }
            }

            Text("•")
                .foregroundColor(Color.secondary.opacity(0.4))

            if let pro = proModel {
                HStack(spacing: 2) {
                    Text(balanceManager.estimatedTokens(for: pro, isOffPeak: isOffPeak))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.primary)
                    Text("Pro")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color.secondary)
                }
            }

            Spacer()

            Text(isOffPeak ? "50% off" : "peak")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(isOffPeak ? Color(red: 0.18, green: 0.52, blue: 1.0) : Color.secondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(isOffPeak ? Color.blue.opacity(0.12) : Color.primary.opacity(0.06))
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.04 : 0.03))
        )
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        Group {
            if let error = balanceManager.errorMessage {
                HStack(spacing: 4) {
                    Circle().fill(Color.red).frame(width: 5, height: 5)
                    Text(error)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.red.opacity(0.12)))
            } else if let balance = balanceManager.totalBalance {
                if balance > 1.0 {
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 5, height: 5)
                        Text("Active")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? Color.green : Color(red: 0.05, green: 0.55, blue: 0.15))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.green.opacity(0.12)))
                } else if balance > 0 {
                    HStack(spacing: 4) {
                        Circle().fill(Color.orange).frame(width: 5, height: 5)
                        Text("Low")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.opacity(0.12)))
                } else {
                    HStack(spacing: 4) {
                        Circle().fill(Color.red).frame(width: 5, height: 5)
                        Text("Zero")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.red.opacity(0.12)))
                }
            }
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        HStack(spacing: 8) {
            Image(systemName: "key.horizontal")
                .font(.system(size: 13))
                .foregroundColor(Color.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Track balance & tokens")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.primary)
                Text("Add your DeepSeek API key for live budget tracking")
                    .font(.system(size: 9.5))
                    .foregroundColor(Color.secondary)
            }

            Spacer()

            Button(action: {
                balanceManager.isEditingKey = true
                balanceManager.enteredKey = ""
            }) {
                Text("+ Add Key")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color(red: 0.18, green: 0.45, blue: 1.0))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.04 : 0.025))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.06), lineWidth: 0.8)
        )
    }

    // MARK: - Key Entry Form

    private var keyEntryForm: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(balanceManager.hasApiKey ? "Update DeepSeek API Key" : "Enter DeepSeek API Key")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.primary)

            SecureField("sk-...", text: $balanceManager.enteredKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11, design: .monospaced))

            HStack {
                Text("Stored locally on your Mac")
                    .font(.system(size: 9))
                    .foregroundColor(Color.secondary)

                Spacer()

                if balanceManager.hasApiKey {
                    Button(action: {
                        balanceManager.removeApiKey()
                        balanceManager.isEditingKey = false
                    }) {
                        Text("Remove")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 4)
                }

                Button(action: {
                    balanceManager.isEditingKey = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)

                Button(action: {
                    if !balanceManager.enteredKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        balanceManager.saveApiKey(balanceManager.enteredKey)
                        balanceManager.isEditingKey = false
                    }
                }) {
                    Text("Save")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color(red: 0.18, green: 0.45, blue: 1.0))
                        )
                }
                .buttonStyle(.plain)
                .disabled(balanceManager.enteredKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.06 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 0.8)
        )
    }
}
