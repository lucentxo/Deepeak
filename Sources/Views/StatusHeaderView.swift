import SwiftUI

struct StatusHeaderView: View {
    @ObservedObject var schedule: ScheduleManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Whale Logo circular container
            ZStack {
                Circle()
                    .fill(
                        schedule.isOffPeak
                        ? Color(red: 0.18, green: 0.45, blue: 1.0).opacity(0.20)
                        : Color.white.opacity(0.10)
                    )
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                schedule.isOffPeak
                                ? Color(red: 0.35, green: 0.65, blue: 1.0).opacity(0.5)
                                : Color.white.opacity(0.2),
                                lineWidth: 1.0
                            )
                    )
                
                DeepSeekWhaleLogo(isOffPeak: schedule.isOffPeak, size: 26)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(schedule.isOffPeak ? Color(red: 0.25, green: 0.88, blue: 0.45) : Color.orange)
                        .frame(width: 8, height: 8)
                        .shadow(color: (schedule.isOffPeak ? Color(red: 0.25, green: 0.88, blue: 0.45) : Color.orange).opacity(0.85), radius: 4)
                    
                    Text(schedule.isOffPeak ? "OFF-PEAK HOURS" : "PEAK HOURS")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(schedule.isOffPeak ? Color(red: 0.40, green: 0.72, blue: 1.0) : .white)
                }
                
                Text(schedule.nextTransitionText)
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                    .foregroundColor(Color.white.opacity(0.80))
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
                            ? Color(red: 0.18, green: 0.45, blue: 1.0).opacity(0.35)
                            : Color.white.opacity(0.12)
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            schedule.isOffPeak
                            ? Color(red: 0.40, green: 0.70, blue: 1.0).opacity(0.65)
                            : Color.white.opacity(0.20),
                            lineWidth: 0.8
                        )
                )
                .foregroundColor(.white)
        }
    }
}
