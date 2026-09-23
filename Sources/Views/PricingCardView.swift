import SwiftUI

struct PricingCardView: View {
    @ObservedObject var pricing: PricingManager
    @ObservedObject var schedule: ScheduleManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PRICING (USD / 1M TOKENS)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.65))
                    .tracking(0.5)
                
                Spacer()
                
                // Refresh trigger & timestamp
                Button(action: {
                    pricing.refreshPricingData()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .semibold))
                            .rotationEffect(.degrees(pricing.isRefreshing ? 360 : 0))
                            .animation(pricing.isRefreshing ? Animation.linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: pricing.isRefreshing)
                        Text(pricing.formattedLastRefreshed)
                            .font(.system(size: 10, weight: .medium))
                            .monospacedDigit()
                    }
                    .foregroundColor(Color.white.opacity(0.85))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help("Refreshes every 12h. Click to refresh now.")
            }
            
            // Header Columns with clear width and alignment
            HStack(spacing: 6) {
                Text("Model")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.50))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Cache Hit")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.50))
                    .frame(width: 58, alignment: .trailing)
                
                Text("Input Miss")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.50))
                    .frame(width: 64, alignment: .trailing)
                
                Text("Output")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.50))
                    .frame(width: 58, alignment: .trailing)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 5) {
                ForEach(pricing.models) { model in
                    HStack(alignment: .center, spacing: 6) {
                        // Full Model Name
                        VStack(alignment: .leading, spacing: 1) {
                            Text(model.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Cache Hit
                        VStack(alignment: .trailing, spacing: 1) {
                            let currentPrice = schedule.isOffPeak ? model.offPeakInputHit : model.peakInputHit
                            Text(formatUSD(currentPrice))
                                .font(.system(size: 12, weight: .semibold))
                                .monospacedDigit()
                                .foregroundColor(schedule.isOffPeak ? Color(red: 0.40, green: 0.75, blue: 1.0) : .white)
                            
                            if schedule.isOffPeak {
                                Text(formatUSD(model.peakInputHit))
                                    .font(.system(size: 9, weight: .regular))
                                    .monospacedDigit()
                                    .strikethrough(color: Color.white.opacity(0.4))
                                    .foregroundColor(Color.white.opacity(0.40))
                            }
                        }
                        .frame(width: 58, alignment: .trailing)
                        
                        // Input Miss
                        VStack(alignment: .trailing, spacing: 1) {
                            let currentPrice = schedule.isOffPeak ? model.offPeakInputMiss : model.peakInputMiss
                            Text(formatUSD(currentPrice))
                                .font(.system(size: 12, weight: .semibold))
                                .monospacedDigit()
                                .foregroundColor(schedule.isOffPeak ? Color(red: 0.40, green: 0.75, blue: 1.0) : .white)
                            
                            if schedule.isOffPeak {
                                Text(formatUSD(model.peakInputMiss))
                                    .font(.system(size: 9, weight: .regular))
                                    .monospacedDigit()
                                    .strikethrough(color: Color.white.opacity(0.4))
                                    .foregroundColor(Color.white.opacity(0.40))
                            }
                        }
                        .frame(width: 64, alignment: .trailing)
                        
                        // Output
                        VStack(alignment: .trailing, spacing: 1) {
                            let currentPrice = schedule.isOffPeak ? model.offPeakOutput : model.peakOutput
                            Text(formatUSD(currentPrice))
                                .font(.system(size: 12, weight: .semibold))
                                .monospacedDigit()
                                .foregroundColor(schedule.isOffPeak ? Color(red: 0.40, green: 0.75, blue: 1.0) : .white)
                            
                            if schedule.isOffPeak {
                                Text(formatUSD(model.peakOutput))
                                    .font(.system(size: 9, weight: .regular))
                                    .monospacedDigit()
                                    .strikethrough(color: Color.white.opacity(0.4))
                                    .foregroundColor(Color.white.opacity(0.40))
                            }
                        }
                        .frame(width: 58, alignment: .trailing)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
                    )
                }
            }
            
            HStack {
                Text("Rates automatically update for 50% off-peak window.")
                    .font(.system(size: 10))
                    .foregroundColor(Color.white.opacity(0.60))
                
                Spacer()
                
                Text("Syncs every 12h")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.50))
            }
            .padding(.top, 1)
        }
    }
    
    private func formatUSD(_ value: Double) -> String {
        if value < 0.01 {
            return String(format: "$%.3f", value)
        } else {
            return String(format: "$%.2f", value)
        }
    }
}
