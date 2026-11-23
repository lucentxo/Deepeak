import XCTest
@testable import DeepSeekStatus

@MainActor
final class ScheduleManagerTests: XCTestCase {
    
    private func makeUTCDate(year: Int = 2026, month: Int = 11, day: Int, hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        guard let tz = TimeZone(secondsFromGMT: 0) else {
            fatalError("Could not create UTC timezone")
        }
        calendar.timeZone = tz
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }
    
    func testWeekdayWindow1Peak() {
        // Wednesday, Nov 25, 2026 at 02:30 UTC -> Middle of Window 1 (01:00 - 04:00)
        let schedule = ScheduleManager()
        let date = makeUTCDate(day: 25, hour: 2, minute: 30)
        schedule.simulatedDate = date
        schedule.updateSchedule()
        
        XCTAssertFalse(schedule.isOffPeak, "Wednesday 02:30 UTC must be Peak hours")
        XCTAssertTrue(schedule.currentStatusText.contains("Peak Hours"))
        XCTAssertEqual(schedule.nextTransitionText, "Peak ends in 1h 30m")
        XCTAssertEqual(schedule.formattedWindows.count, 2)
        XCTAssertTrue(schedule.formattedWindows[0].isCurrentlyActive, "Window 1 should be active")
        XCTAssertFalse(schedule.formattedWindows[1].isCurrentlyActive, "Window 2 should not be active")
        
        XCTAssertTrue(ScheduleManager.isPeakTime(date: date))
        XCTAssertFalse(ScheduleManager.isOffPeakTime(date: date))
    }
    
    func testWeekdayWindow2Peak() {
        // Thursday, Nov 26, 2026 at 07:15 UTC -> Middle of Window 2 (06:00 - 10:00)
        let schedule = ScheduleManager()
        let date = makeUTCDate(day: 26, hour: 7, minute: 15)
        schedule.simulatedDate = date
        schedule.updateSchedule()
        
        XCTAssertFalse(schedule.isOffPeak, "Thursday 07:15 UTC must be Peak hours")
        XCTAssertTrue(schedule.currentStatusText.contains("Peak Hours"))
        XCTAssertEqual(schedule.nextTransitionText, "Peak ends in 2h 45m")
        XCTAssertEqual(schedule.formattedWindows.count, 2)
        XCTAssertFalse(schedule.formattedWindows[0].isCurrentlyActive, "Window 1 should not be active")
        XCTAssertTrue(schedule.formattedWindows[1].isCurrentlyActive, "Window 2 should be active")
        
        XCTAssertTrue(ScheduleManager.isPeakTime(date: date))
        XCTAssertFalse(ScheduleManager.isOffPeakTime(date: date))
    }
    
    func testWeekdayBeforeWindow1OffPeak() {
        // Tuesday, Nov 24, 2026 at 00:40 UTC -> Before Window 1 (starts at 01:00 UTC)
        let schedule = ScheduleManager()
        let date = makeUTCDate(day: 24, hour: 0, minute: 40)
        schedule.simulatedDate = date
        schedule.updateSchedule()
        
        XCTAssertTrue(schedule.isOffPeak, "Tuesday 00:40 UTC must be Off-Peak hours")
        XCTAssertTrue(schedule.currentStatusText.contains("Off-Peak"))
        XCTAssertEqual(schedule.nextTransitionText, "Next peak starts in 20m")
        XCTAssertFalse(schedule.formattedWindows[0].isCurrentlyActive)
        XCTAssertFalse(schedule.formattedWindows[1].isCurrentlyActive)
        
        XCTAssertFalse(ScheduleManager.isPeakTime(date: date))
        XCTAssertTrue(ScheduleManager.isOffPeakTime(date: date))
    }
    
    func testWeekdayBetweenWindowsOffPeak() {
        // Wednesday, Nov 25, 2026 at 04:30 UTC -> Between Window 1 (ends 04:00) and Window 2 (starts 06:00)
        let schedule = ScheduleManager()
        let date = makeUTCDate(day: 25, hour: 4, minute: 30)
        schedule.simulatedDate = date
        schedule.updateSchedule()
        
        XCTAssertTrue(schedule.isOffPeak, "Wednesday 04:30 UTC must be Off-Peak hours")
        XCTAssertEqual(schedule.nextTransitionText, "Next peak starts in 1h 30m")
        XCTAssertFalse(schedule.formattedWindows[0].isCurrentlyActive)
        XCTAssertFalse(schedule.formattedWindows[1].isCurrentlyActive)
    }
    
    func testWeekdayEveningOffPeakTransitionToNextDay() {
        // Tuesday, Nov 24, 2026 at 12:00 UTC -> Past Window 2 (ended 10:00 UTC)
        // Next peak is Wednesday 01:00 UTC (12h to midnight + 1h = 13h)
        let schedule = ScheduleManager()
        let date = makeUTCDate(day: 24, hour: 12, minute: 0)
        schedule.simulatedDate = date
        schedule.updateSchedule()
        
        XCTAssertTrue(schedule.isOffPeak, "Tuesday 12:00 UTC must be Off-Peak hours")
        XCTAssertEqual(schedule.nextTransitionText, "Next peak starts in 13h 0m")
    }
    
    func testFridayEveningOffPeakTransitionToMonday() {
        // Friday, Nov 27, 2026 at 11:00 UTC -> Past Window 2
        // Next peak is Monday 01:00 UTC
        let schedule = ScheduleManager()
        let date = makeUTCDate(day: 27, hour: 11, minute: 0)
        schedule.simulatedDate = date
        schedule.updateSchedule()
        
        XCTAssertTrue(schedule.isOffPeak, "Friday 11:00 UTC must be Off-Peak hours")
        XCTAssertTrue(schedule.nextTransitionText.contains("(Mon)"), "Transition text must mention Monday")
    }
    
    func testWeekendIsAlwaysOffPeak() {
        let schedule = ScheduleManager()
        
        // Saturday, Nov 28, 2026 at 02:00 UTC (during weekday Window 1 hour)
        let satDate = makeUTCDate(day: 28, hour: 2, minute: 0)
        schedule.simulatedDate = satDate
        schedule.updateSchedule()
        
        XCTAssertTrue(schedule.isOffPeak, "Saturday must be 100% Off-Peak even during 01:00-04:00 UTC")
        XCTAssertFalse(schedule.formattedWindows[0].isCurrentlyActive, "Window 1 should not be active on weekend")
        XCTAssertFalse(schedule.formattedWindows[1].isCurrentlyActive, "Window 2 should not be active on weekend")
        XCTAssertTrue(schedule.nextTransitionText.contains("Next peak starts in"), "Countdown to Monday peak")
        XCTAssertFalse(ScheduleManager.isPeakTime(date: satDate))
        XCTAssertTrue(ScheduleManager.isOffPeakTime(date: satDate))
        
        // Sunday, Nov 29, 2026 at 07:00 UTC (during weekday Window 2 hour)
        let sunDate = makeUTCDate(day: 29, hour: 7, minute: 0)
        schedule.simulatedDate = sunDate
        schedule.updateSchedule()
        
        XCTAssertTrue(schedule.isOffPeak, "Sunday must be 100% Off-Peak even during 06:00-10:00 UTC")
        XCTAssertFalse(schedule.formattedWindows[0].isCurrentlyActive)
        XCTAssertFalse(schedule.formattedWindows[1].isCurrentlyActive)
        XCTAssertFalse(ScheduleManager.isPeakTime(date: sunDate))
        XCTAssertTrue(ScheduleManager.isOffPeakTime(date: sunDate))
    }
    
    func testTimezoneInformation() {
        let schedule = ScheduleManager()
        schedule.updateSchedule()
        
        XCTAssertFalse(schedule.currentTimeZoneIdentifier.isEmpty)
        XCTAssertFalse(schedule.currentTimeZoneAbbreviation.isEmpty)
        XCTAssertEqual(schedule.formattedWindows.count, 2)
        XCTAssertEqual(schedule.formattedWindows[0].utcRange, "01:00 – 04:00 UTC")
        XCTAssertEqual(schedule.formattedWindows[1].utcRange, "06:00 – 10:00 UTC")
    }
    
    func testTransitionNotificationBroadcasting() {
        let schedule = ScheduleManager()
        let expectation = XCTestExpectation(description: "Transition notification received")
        
        let observer = NotificationCenter.default.addObserver(
            forName: ScheduleManager.transitionNotification,
            object: schedule,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let isOffPeak = userInfo[ScheduleManager.transitionKeyIsOffPeak] as? Bool else {
                XCTFail("Missing userInfo in transition notification")
                return
            }
            XCTAssertTrue(isOffPeak)
            expectation.fulfill()
        }
        
        schedule.sendTransitionNotification(toOffPeak: true)
        wait(for: [expectation], timeout: 2.0)
        NotificationCenter.default.removeObserver(observer)
    }
}
