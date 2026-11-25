import SwiftUI
import AppKit

@MainActor
enum ScreenshotGenerator {
    static func generateAll(outputDir: String) {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

        // Create deterministic UTC dates for Off-Peak and Peak
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        // Off-Peak: Wednesday 22:15 UTC (2h 45m until 01:00 UTC peak)
        let offPeakDate = cal.date(from: DateComponents(year: 2026, month: 11, day: 25, hour: 22, minute: 15))!
        // Peak: Wednesday 02:45 UTC (1h 15m until 04:00 UTC off-peak)
        let peakDate = cal.date(from: DateComponents(year: 2026, month: 11, day: 25, hour: 2, minute: 45))!

        let pricing = PricingManager()

        let offPeakSchedule = ScheduleManager()
        offPeakSchedule.simulatedDate = offPeakDate
        offPeakSchedule.updateSchedule()

        let peakSchedule = ScheduleManager()
        peakSchedule.simulatedDate = peakDate
        peakSchedule.updateSchedule()

        let activeBalance = BalanceManager(checkKeyOnInit: false, autoFetch: false)
        activeBalance.hasApiKey = true
        activeBalance.isAvailable = true
        activeBalance.totalBalance = 14.82
        activeBalance.toppedUpBalance = 12.50
        activeBalance.grantedBalance = 2.32
        activeBalance.currency = "USD"
        activeBalance.lastSyncTime = offPeakDate

        let emptyBalance = BalanceManager(checkKeyOnInit: false, autoFetch: false)
        emptyBalance.hasApiKey = false

        // 1. Dark Mode Off-Peak (Active Balance)
        let darkCard = renderPopoverCard(
            schedule: offPeakSchedule,
            pricing: pricing,
            balance: activeBalance,
            appearance: NSAppearance(named: .darkAqua)!,
            isDark: true
        )
        if let darkCard {
            saveWithShadow(image: darkCard, to: "\(outputDir)/screenshot-dark.png")
        }

        // 2. Light Mode Off-Peak (Active Balance)
        let lightCard = renderPopoverCard(
            schedule: offPeakSchedule,
            pricing: pricing,
            balance: activeBalance,
            appearance: NSAppearance(named: .aqua)!,
            isDark: false
        )
        if let lightCard {
            saveWithShadow(image: lightCard, to: "\(outputDir)/screenshot-light.png")
        }

        // 3. Dark Mode Peak Hours
        let peakCard = renderPopoverCard(
            schedule: peakSchedule,
            pricing: pricing,
            balance: activeBalance,
            appearance: NSAppearance(named: .darkAqua)!,
            isDark: true
        )
        if let peakCard {
            saveWithShadow(image: peakCard, to: "\(outputDir)/screenshot-peak.png")
        }

        // 4. Dark Mode Setup (+ Add Key)
        let setupCard = renderPopoverCard(
            schedule: offPeakSchedule,
            pricing: pricing,
            balance: emptyBalance,
            appearance: NSAppearance(named: .darkAqua)!,
            isDark: true
        )
        if let setupCard {
            saveWithShadow(image: setupCard, to: "\(outputDir)/screenshot-setup.png")
        }

        // 5. Menu Bar Icon Preview
        let menuBarImg = renderMenuBarPreview()
        if let menuBarImg {
            savePNG(image: menuBarImg, to: "\(outputDir)/menubar-preview.png")
        }

        // 6. Hero Showcase Banner
        if let darkCard, let lightCard {
            let hero = renderHeroBanner(darkCard: darkCard, lightCard: lightCard)
            if let hero {
                savePNG(image: hero, to: "\(outputDir)/hero-banner.png")
            }
        }

        print("✅ Generated all screenshots in: \(outputDir)")
    }

    // MARK: - Popover Card Renderer

    private static func renderPopoverCard(
        schedule: ScheduleManager,
        pricing: PricingManager,
        balance: BalanceManager,
        appearance: NSAppearance,
        isDark: Bool
    ) -> NSImage? {
        let cardView = ZStack {
            // Crisp backing behind VisualEffectBlur for headless capture
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isDark
                      ? Color(red: 0.11, green: 0.12, blue: 0.15)
                      : Color(red: 0.95, green: 0.96, blue: 0.98))

            PopoverContentView(schedule: schedule, pricing: pricing, balance: balance)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isDark ? Color.white.opacity(0.16) : Color.black.opacity(0.10),
                    lineWidth: 1.0
                )
        )
        .environment(\.colorScheme, isDark ? .dark : .light)

        let hosting = NSHostingView(rootView: cardView)
        hosting.appearance = appearance

        // Measure intrinsic height at 380pt width
        hosting.frame = NSRect(x: 0, y: 0, width: 380, height: 800)
        hosting.layoutSubtreeIfNeeded()
        let fitted = hosting.fittingSize
        let size = NSSize(width: 380, height: fitted.height)
        hosting.frame = NSRect(origin: .zero, size: size)

        // Attach to offscreen borderless window so AppKit/SwiftUI renders completely
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.appearance = appearance
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()

        return captureView(hosting, size: size, scale: 2.0)
    }

    // MARK: - Menu Bar Preview Renderer

    private static func renderMenuBarPreview() -> NSImage? {
        let preview = HStack(spacing: 24) {
            menuBarTile(
                title: "Off-Peak (50% Discount)",
                subtitle: "Electric Blue Whale",
                isOffPeak: true,
                isDark: true
            )
            menuBarTile(
                title: "Peak Hours (Standard Rate)",
                subtitle: "Graphite Whale",
                isOffPeak: false,
                isDark: false
            )
        }
        .padding(24)
        .background(Color(red: 0.06, green: 0.08, blue: 0.13))

        let hosting = NSHostingView(rootView: preview)
        hosting.appearance = NSAppearance(named: .darkAqua)
        hosting.frame = NSRect(x: 0, y: 0, width: 800, height: 300)
        hosting.layoutSubtreeIfNeeded()
        let size = hosting.fittingSize
        hosting.frame = NSRect(origin: .zero, size: size)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()

        return captureView(hosting, size: size, scale: 2.0)
    }

    private static func menuBarTile(title: String, subtitle: String, isOffPeak: Bool, isDark: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Simulated macOS menu bar strip
            HStack(spacing: 14) {
                Spacer()
                Image(systemName: "wifi")
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "battery.100")
                    .font(.system(size: 13, weight: .medium))
                HStack(spacing: 4) {
                    DeepSeekWhaleLogo(isOffPeak: isOffPeak, size: 18)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.08))
                )
                Text("Tue 9:41 PM")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isDark ? .white : .black)
            .padding(.horizontal, 14)
            .frame(width: 310, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isDark
                          ? Color(red: 0.14, green: 0.16, blue: 0.21)
                          : Color(red: 0.92, green: 0.93, blue: 0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 0.8)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.60))
            }
            .padding(.leading, 2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    // MARK: - Hero Banner Renderer

    private static func renderHeroBanner(darkCard: NSImage, lightCard: NSImage) -> NSImage? {
        let bannerSize = NSSize(width: 1280, height: 760)

        let bannerView = ZStack {
            // Deep obsidian-navy gradient backdrop
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.06, blue: 0.12),
                    Color(red: 0.02, green: 0.03, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle blue ambient glow behind the popovers
            RadialGradient(
                colors: [
                    Color(red: 0.18, green: 0.45, blue: 1.0).opacity(0.24),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.58),
                startRadius: 40,
                endRadius: 540
            )

            VStack(spacing: 24) {
                // Header Branding
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        DeepSeekWhaleLogo(isOffPeak: true, size: 34)
                        Text("Deepeak")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("v1.2")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(red: 0.18, green: 0.45, blue: 1.0).opacity(0.20)))
                            .overlay(Capsule().strokeBorder(Color(red: 0.35, green: 0.65, blue: 1.0).opacity(0.45), lineWidth: 1))
                    }

                    Text("Native macOS Menu Bar Companion for DeepSeek API")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.72))

                    HStack(spacing: 10) {
                        featurePill(icon: "bolt.fill", text: "50% Off-Peak Tracker", color: Color(red: 0.40, green: 0.72, blue: 1.0))
                        featurePill(icon: "creditcard.fill", text: "Live Balance & Tokens", color: Color(red: 0.30, green: 0.88, blue: 0.50))
                        featurePill(icon: "clock.fill", text: "Local Timezone Sync", color: Color.orange)
                        featurePill(icon: "desktopcomputer", text: "Dark & Light Mode", color: Color.purple.opacity(0.9))
                    }
                    .padding(.top, 4)
                }

                // Side-by-side Popovers
                HStack(alignment: .top, spacing: 44) {
                    VStack(spacing: 10) {
                        Image(nsImage: darkCard)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: darkCard.size.width * 0.92)
                            .shadow(color: Color.black.opacity(0.65), radius: 28, x: 0, y: 18)

                        Text("Dark Mode • Off-Peak Active")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.55))
                    }

                    VStack(spacing: 10) {
                        Image(nsImage: lightCard)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: lightCard.size.width * 0.92)
                            .shadow(color: Color.black.opacity(0.55), radius: 28, x: 0, y: 18)

                        Text("Light Mode • Adaptive Readability")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.55))
                    }
                }
            }
            .padding(.vertical, 34)
        }
        .frame(width: bannerSize.width, height: bannerSize.height)

        let hosting = NSHostingView(rootView: bannerView)
        hosting.appearance = NSAppearance(named: .darkAqua)
        hosting.frame = NSRect(origin: .zero, size: bannerSize)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: bannerSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()

        return captureView(hosting, size: bannerSize, scale: 2.0)
    }

    private static func featurePill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.88))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.white.opacity(0.08)))
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))
    }

    // MARK: - Capture & Save Helpers

    private static func captureView(_ view: NSView, size: NSSize, scale: CGFloat) -> NSImage? {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width * scale),
            pixelsHigh: Int(size.height * scale),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        rep.size = size
        view.cacheDisplay(in: view.bounds, to: rep)

        let image = NSImage(size: size)
        image.addRepresentation(rep)
        return image
    }

    private static func saveWithShadow(image: NSImage, to path: String) {
        let padding: CGFloat = 28
        let canvasSize = NSSize(width: image.size.width + padding * 2, height: image.size.height + padding * 2)

        let shadowed = ZStack {
            Image(nsImage: image)
                .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 8)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)

        let hosting = NSHostingView(rootView: shadowed)
        hosting.frame = NSRect(origin: .zero, size: canvasSize)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: canvasSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()

        if let outImg = captureView(hosting, size: canvasSize, scale: 2.0) {
            savePNG(image: outImg, to: path)
        }
    }

    private static func savePNG(image: NSImage, to path: String) {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let pngData = rep.representation(using: .png, properties: [:]) else {
            return
        }
        try? pngData.write(to: URL(fileURLWithPath: path))
    }
}
