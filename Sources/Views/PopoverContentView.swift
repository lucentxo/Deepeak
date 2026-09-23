import SwiftUI

struct PopoverContentView: View {
    @ObservedObject var schedule: ScheduleManager
    @ObservedObject var pricing: PricingManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section 1: Header (Whale icon + status pill + discount badge)
            StatusHeaderView(schedule: schedule)
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Section 2: Peak Schedule
            ScheduleCardView(schedule: schedule)
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Section 3: Pricing Table
            PricingCardView(pricing: pricing, schedule: schedule)
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Section 4: Action Footer
            HStack {
                Button(action: {
                    if let url = URL(string: "https://platform.deepseek.com/usage") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11, weight: .medium))
                        Text("DeepSeek Platform")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Color.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 10, weight: .medium))
                        Text("Quit")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Color.white.opacity(0.70))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 1)
        }
        .padding(16)
        .frame(width: 380)
        // Single unified BetterDisplay liquid glass container
        .background(
            ZStack {
                VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                
                // Subtle liquid glass top-to-bottom sheen
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.10), location: 0.0),
                        .init(color: Color.white.opacity(0.02), location: 0.35),
                        .init(color: Color.clear, location: 0.70),
                        .init(color: Color.black.opacity(0.06), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
    }
}

/// Native AppKit visual effect blur integration
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
