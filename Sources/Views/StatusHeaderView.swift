import SwiftUI

struct StatusHeaderView: View {
    @ObservedObject var schedule: ScheduleManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Whale Logo circular container
            ZStack {
                Circle()
                    .fill(
                        schedule.isOffPeak
                        ? (colorScheme == .dark ? Color(red: 0.18, green: 0.45, blue: 1.0).opacity(0.20) : Color(red: 0.05, green: 0.40, blue: 0.95).opacity(0.12))
                        : (colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06))
                    )
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                schedule.isOffPeak
                                ? (colorScheme == .dark ? Color(red: 0.35, green: 0.65, blue: 1.0).opacity(0.5) : Color(red: 0.05, green: 0.40, blue: 0.95).opacity(0.25))
                                : (colorScheme == .dark ? Color.white.opacity(0.20) : Color.black.opacity(0.12)),
                                lineWidth: 1.0
                            )
                    )
                
                DeepSeekWhaleLogo(isOffPeak: schedule.isOffPeak, size: 26)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(schedule.isOffPeak ? (colorScheme == .dark ? Color(red: 0.25, green: 0.88, blue: 0.45) : Color(red: 0.12, green: 0.72, blue: 0.32)) : Color.orange)
                        .frame(width: 8, height: 8)
                        .shadow(color: (schedule.isOffPeak ? Color(red: 0.25, green: 0.88, blue: 0.45) : Color.orange).opacity(colorScheme == .dark ? 0.85 : 0.40), radius: colorScheme == .dark ? 4 : 2)
                    
                    Text(schedule.isOffPeak ? "OFF-PEAK HOURS" : "PEAK HOURS")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(
                            schedule.isOffPeak
                            ? (colorScheme == .dark ? Color(red: 0.40, green: 0.72, blue: 1.0) : Color(red: 0.05, green: 0.38, blue: 0.92))
                            : Color.primary
                        )
                }
                
                Text(schedule.nextTransitionText)
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                    .foregroundColor(Color.primary.opacity(colorScheme == .dark ? 0.80 : 0.72))
            }
            
            Spacer()
            
            // Badge showing 50% off or standard
            Text(schedule.isOffPeak ? "50% OFF" : "PEAK RATE")
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(
                            schedule.isOffPeak
                            ? (colorScheme == .dark ? Color(red: 0.18, green: 0.45, blue: 1.0).opacity(0.35) : Color(red: 0.08, green: 0.44, blue: 0.98))
                            : (colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08))
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            schedule.isOffPeak
                            ? (colorScheme == .dark ? Color(red: 0.40, green: 0.70, blue: 1.0).opacity(0.65) : Color.clear)
                            : (colorScheme == .dark ? Color.white.opacity(0.20) : Color.black.opacity(0.12)),
                            lineWidth: 0.8
                        )
                )
                .foregroundColor(colorScheme == .dark || schedule.isOffPeak ? .white : Color.primary)
        }
    }
}
