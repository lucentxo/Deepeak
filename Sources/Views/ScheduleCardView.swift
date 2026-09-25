import SwiftUI

struct ScheduleCardView: View {
    @ObservedObject var schedule: ScheduleManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PEAK SCHEDULE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.secondary)
                    .tracking(0.5)
                
                Spacer()
                
                // Active local timezone pill
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(schedule.currentTimeZoneAbbreviation)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(Color.primary.opacity(colorScheme == .dark ? 0.85 : 0.80))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.06)))
                .overlay(Capsule().strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.10), lineWidth: 0.8))
            }
            
            VStack(spacing: 5) {
                ForEach(schedule.formattedWindows) { window in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(window.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.primary)
                            Text(window.utcRange)
                                .font(.system(size: 10.5, weight: .regular))
                                .foregroundColor(Color.secondary)
                        }
                        
                        Spacer()
                        
                        Text(window.localRange)
                            .font(.system(size: 12, weight: .semibold))
                            .monospacedDigit()
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(
                                        window.isCurrentlyActive
                                        ? Color.orange.opacity(colorScheme == .dark ? 0.35 : 0.15)
                                        : Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.06)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(
                                        window.isCurrentlyActive
                                        ? Color.orange.opacity(colorScheme == .dark ? 0.70 : 0.40)
                                        : Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.08),
                                        lineWidth: 0.8
                                    )
                            )
                            .foregroundColor(
                                window.isCurrentlyActive
                                ? (colorScheme == .dark ? Color(red: 1.0, green: 0.72, blue: 0.35) : Color(red: 0.85, green: 0.35, blue: 0.0))
                                : Color.primary
                            )
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(colorScheme == .dark ? 0.04 : 0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.10), lineWidth: 0.8)
                    )
                }
            }
            
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                Text("Applies Mon–Fri. Weekends & Chinese holidays are 100% off-peak.")
                    .font(.system(size: 10))
            }
            .foregroundColor(Color.secondary)
            .padding(.top, 1)
        }
    }
}
