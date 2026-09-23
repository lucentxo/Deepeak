import SwiftUI

struct ScheduleCardView: View {
    @ObservedObject var schedule: ScheduleManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PEAK SCHEDULE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.65))
                    .tracking(0.5)
                
                Spacer()
                
                // Active local timezone pill
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(schedule.currentTimeZoneAbbreviation)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(Color.white.opacity(0.85))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(0.10)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8))
            }
            
            VStack(spacing: 5) {
                ForEach(schedule.formattedWindows) { window in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(window.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Text(window.utcRange)
                                .font(.system(size: 10.5, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.60))
                        }
                        
                        Spacer()
                        
                        Text(window.localRange)
                            .font(.system(size: 12, weight: .semibold))
                            .monospacedDigit()
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(window.isCurrentlyActive ? Color.orange.opacity(0.35) : Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(window.isCurrentlyActive ? Color.orange.opacity(0.70) : Color.white.opacity(0.10), lineWidth: 0.8)
                            )
                            .foregroundColor(window.isCurrentlyActive ? Color(red: 1.0, green: 0.72, blue: 0.35) : .white)
                    }
                    .padding(.horizontal, 10)
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
            
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                Text("Applies Mon–Fri. Weekends & Chinese holidays are 100% off-peak.")
                    .font(.system(size: 10))
            }
            .foregroundColor(Color.white.opacity(0.60))
            .padding(.top, 1)
        }
    }
}
