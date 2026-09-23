import Foundation
import Combine

/// Manages DeepSeek peak/off-peak windows synced to the system's timezone.
///
/// DeepSeek API Schedule (Monday - Friday UTC):
/// - Window 1: 01:00 - 04:00 UTC
/// - Window 2: 06:00 - 10:00 UTC
/// All other times (including all weekends) are 100% Off-Peak (50% discount).
class ScheduleManager: ObservableObject {
    @Published var isOffPeak: Bool = true
    @Published var currentStatusText: String = "Off-Peak Hours"
    @Published var nextTransitionText: String = ""
    @Published var currentTimeZoneIdentifier: String = TimeZone.current.identifier
    @Published var currentTimeZoneAbbreviation: String = TimeZone.current.abbreviation() ?? "Local"
    @Published var formattedWindows: [LocalPeakWindow] = []
    
    // For manual / simulated testing in debug
    @Published var simulatedDate: Date? = nil
    
    private var timer: AnyCancellable?
    private var tzObserver: Any?
    
    struct LocalPeakWindow: Identifiable {
        let id = UUID()
        let title: String
        let utcRange: String
        let localRange: String
        let isCurrentlyActive: Bool
    }
    
    init() {
        updateSchedule()
        setupTimers()
    }
    
    deinit {
        if let observer = tzObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupTimers() {
        // Evaluate every 30 seconds to minimize CPU wakes while keeping countdown fresh
        timer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateSchedule()
            }
        
        // Listen for system timezone changes
        tzObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateSchedule()
        }
    }
    
    func updateSchedule() {
        let now = simulatedDate ?? Date()
        var utcCalendar = Calendar(identifier: .gregorian)
        guard let utcTimeZone = TimeZone(secondsFromGMT: 0) else { return }
        utcCalendar.timeZone = utcTimeZone
        
        let localTimeZone = TimeZone.current
        self.currentTimeZoneIdentifier = localTimeZone.identifier
        self.currentTimeZoneAbbreviation = localTimeZone.abbreviation(for: now) ?? "Local"
        
        // Check day of week in UTC: Sunday is 1, Saturday is 7, Mon-Fri is 2...6
        let weekday = utcCalendar.component(.weekday, from: now)
        let isWeekend = (weekday == 1 || weekday == 7)
        
        let hour = utcCalendar.component(.hour, from: now)
        let minute = utcCalendar.component(.minute, from: now)
        let currentMinutesUTC = hour * 60 + minute
        
        // Peak intervals in minutes UTC:
        // Window 1: 01:00 - 04:00 (60 ... 240)
        // Window 2: 06:00 - 10:00 (360 ... 600)
        let inWindow1 = currentMinutesUTC >= 60 && currentMinutesUTC < 240
        let inWindow2 = currentMinutesUTC >= 360 && currentMinutesUTC < 600
        
        let isPeakNow = !isWeekend && (inWindow1 || inWindow2)
        self.isOffPeak = !isPeakNow
        self.currentStatusText = isOffPeak ? "Off-Peak Hours (50% Off)" : "Peak Hours (Standard)"
        
        // Calculate transition countdown
        self.nextTransitionText = calculateNextTransition(from: now, isPeak: isPeakNow, utcCalendar: utcCalendar)
        
        // Build local representation of peak windows for display
        self.formattedWindows = generateLocalWindows(for: now, inWindow1: !isWeekend && inWindow1, inWindow2: !isWeekend && inWindow2)
    }
    
    private func calculateNextTransition(from now: Date, isPeak: Bool, utcCalendar: Calendar) -> String {
        let weekday = utcCalendar.component(.weekday, from: now)
        let isWeekend = (weekday == 1 || weekday == 7)
        let hour = utcCalendar.component(.hour, from: now)
        let minute = utcCalendar.component(.minute, from: now)
        let currentMinutesUTC = hour * 60 + minute
        
        if isPeak {
            // Currently in peak. When does it end?
            if currentMinutesUTC < 240 {
                let remaining = 240 - currentMinutesUTC
                return "Peak ends in \(formatMinutes(remaining))"
            } else {
                let remaining = 600 - currentMinutesUTC
                return "Peak ends in \(formatMinutes(remaining))"
            }
        } else {
            // Currently off-peak. When does the next peak start?
            if isWeekend {
                // Next peak is Monday 01:00 UTC
                // Find next Monday
                var daysUntilMonday = (2 - weekday + 7) % 7
                if daysUntilMonday == 0 { daysUntilMonday = 7 }
                let minutesToMidnight = (24 * 60) - currentMinutesUTC
                let totalMinutes = minutesToMidnight + ((daysUntilMonday - 1) * 24 * 60) + 60
                return "Next peak starts in \(formatMinutes(totalMinutes))"
            } else {
                // Weekday off-peak
                if currentMinutesUTC < 60 {
                    let remaining = 60 - currentMinutesUTC
                    return "Next peak starts in \(formatMinutes(remaining))"
                } else if currentMinutesUTC >= 240 && currentMinutesUTC < 360 {
                    let remaining = 360 - currentMinutesUTC
                    return "Next peak starts in \(formatMinutes(remaining))"
                } else {
                    // Past 10:00 UTC (600)
                    if weekday == 6 { // Friday evening -> Monday 01:00 UTC
                        let minutesToMidnight = (24 * 60) - currentMinutesUTC
                        let weekendMinutes = 2 * 24 * 60
                        let totalMinutes = minutesToMidnight + weekendMinutes + 60
                        return "Next peak in \(formatMinutes(totalMinutes)) (Mon)"
                    } else {
                        let minutesToMidnight = (24 * 60) - currentMinutesUTC
                        let totalMinutes = minutesToMidnight + 60
                        return "Next peak starts in \(formatMinutes(totalMinutes))"
                    }
                }
            }
        }
    }
    
    private func formatMinutes(_ totalMinutes: Int) -> String {
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours > 24 {
            let days = hours / 24
            let remHours = hours % 24
            return "\(days)d \(remHours)h"
        } else if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
    
    private func generateLocalWindows(for date: Date, inWindow1: Bool, inWindow2: Bool) -> [LocalPeakWindow] {
        var localCalendar = Calendar.current
        localCalendar.timeZone = TimeZone.current
        
        var utcCalendar = Calendar(identifier: .gregorian)
        guard let utcTimeZone = TimeZone(secondsFromGMT: 0) else { return [] }
        utcCalendar.timeZone = utcTimeZone
        
        let startOfDayUTC = utcCalendar.startOfDay(for: date)
        
        // Window 1: 01:00 UTC to 04:00 UTC
        guard let w1Start = utcCalendar.date(byAdding: .hour, value: 1, to: startOfDayUTC),
              let w1End = utcCalendar.date(byAdding: .hour, value: 4, to: startOfDayUTC),
              let w2Start = utcCalendar.date(byAdding: .hour, value: 6, to: startOfDayUTC),
              let w2End = utcCalendar.date(byAdding: .hour, value: 10, to: startOfDayUTC) else {
            return []
        }
        
        let localFormatter = DateFormatter()
        localFormatter.timeZone = TimeZone.current
        localFormatter.dateFormat = "h:mm a"
        
        let w1LocalStr = "\(localFormatter.string(from: w1Start)) – \(localFormatter.string(from: w1End))"
        let w2LocalStr = "\(localFormatter.string(from: w2Start)) – \(localFormatter.string(from: w2End))"
        
        return [
            LocalPeakWindow(
                title: "Window 1 (Morning UTC)",
                utcRange: "01:00 – 04:00 UTC",
                localRange: w1LocalStr,
                isCurrentlyActive: inWindow1
            ),
            LocalPeakWindow(
                title: "Window 2 (Afternoon UTC)",
                utcRange: "06:00 – 10:00 UTC",
                localRange: w2LocalStr,
                isCurrentlyActive: inWindow2
            )
        ]
    }
}
