import ActivityKit
import SwiftUI
import WidgetKit

private enum ActivityData {
    static func string(_ key: String, context: ActivityViewContext<TrainActivityAttributes>) -> String {
        UserDefaults(suiteName: context.state.appGroupId)?
            .string(forKey: context.attributes.prefixedKey(key)) ?? "—"
    }

    static func number(_ key: String, context: ActivityViewContext<TrainActivityAttributes>) -> Double {
        UserDefaults(suiteName: context.state.appGroupId)?
            .double(forKey: context.attributes.prefixedKey(key)) ?? 0
    }

    static func color(_ key: String, context: ActivityViewContext<TrainActivityAttributes>) -> Color {
        let token = string(key, context: context)
        guard let value = UInt32(token, radix: 16) else {
            return Color(red: 0.77, green: 0.84, blue: 0)
        }
        return Color(
            red: Double((value >> 16) & 0xff) / 255,
            green: Double((value >> 8) & 0xff) / 255,
            blue: Double(value & 0xff) / 255
        )
    }

    static func operatorLabel(context: ActivityViewContext<TrainActivityAttributes>) -> String {
        string(TrainLiveActivityPayloadKey.operatorName, context: context).uppercased()
    }
}

struct TrainLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrainActivityAttributes.self) { context in
            lockScreenView(context)
                .activityBackgroundTint(Color(red: 0.04, green: 0.12, blue: 0.09))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let origin = ActivityData.string(TrainLiveActivityPayloadKey.originCode, context: context)
            let destination = ActivityData.string(TrainLiveActivityPayloadKey.destinationCode, context: context)
            let platform = ActivityData.string(TrainLiveActivityPayloadKey.platform, context: context)
            let progress = min(max(ActivityData.number(TrainLiveActivityPayloadKey.progress, context: context), 0), 1)
            let accent = ActivityData.color("operatorAccent", context: context)
            let primary = ActivityData.color("operatorPrimary", context: context)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(origin)
                            .font(.headline.weight(.bold))
                            .lineLimit(1)
                        Text(ActivityData.string(TrainLiveActivityPayloadKey.departureTime, context: context))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(destination)
                            .font(.headline.weight(.bold))
                            .lineLimit(1)
                        Text("VÍA \(platform)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accent)
                            .lineLimit(1)
                    Text(ActivityData.operatorLabel(context: context))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                        .padding(.horizontal, 5)
                        .background(primary.opacity(0.55), in: Capsule())
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                routeProgress(progress, accent: accent)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "tram.fill")
                .foregroundStyle(accent)
            } compactTrailing: {
                Text(platform == "Por asignar" ? "—" : platform)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: "tram.fill")
                .foregroundStyle(accent)
            }
            .keylineTint(accent)
        }
    }

    private func lockScreenView(
        _ context: ActivityViewContext<TrainActivityAttributes>
    ) -> some View {
        let progress = min(max(ActivityData.number(TrainLiveActivityPayloadKey.progress, context: context), 0), 1)
        let coach = ActivityData.string(TrainLiveActivityPayloadKey.coach, context: context)
        let accent = ActivityData.color("operatorAccent", context: context)
        let primary = ActivityData.color("operatorPrimary", context: context)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(ActivityData.string(TrainLiveActivityPayloadKey.originCode, context: context))
                        .font(.title2.weight(.heavy))
                    Text(ActivityData.string(TrainLiveActivityPayloadKey.departureTime, context: context))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "tram.fill")
                    .font(.title3)
                    .foregroundStyle(accent)
                    .padding(.top, 8)

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(ActivityData.string(TrainLiveActivityPayloadKey.destinationCode, context: context))
                        .font(.title2.weight(.heavy))
                    Text(ActivityData.string(TrainLiveActivityPayloadKey.arrivalTime, context: context))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                }
            }

            routeProgress(progress, accent: accent)

            HStack(alignment: .center) {
                Label(ActivityData.string(TrainLiveActivityPayloadKey.trainNumber, context: context), systemImage: "train.side.front.car")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 8)

                Label("VÍA \(ActivityData.string(TrainLiveActivityPayloadKey.platform, context: context))", systemImage: "tram.fill")
                    .font(.caption.weight(.bold))
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text("Coche \(coach) · Asento \(ActivityData.string(TrainLiveActivityPayloadKey.seat, context: context))")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)

            HStack {
                Text(ActivityData.string(TrainLiveActivityPayloadKey.statusText, context: context))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text(ActivityData.operatorLabel(context: context))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(primary.opacity(0.55), in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            if #available(iOS 26.0, *) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial)
            }
        }
    }

    private func routeProgress(_ progress: Double, accent: Color) -> some View {
        GeometryReader { geometry in
            let trackWidth = max(geometry.size.width - 14, 0)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(height: 3)
                Capsule()
                    .fill(accent)
                    .frame(width: trackWidth * progress, height: 3)
                Circle()
                    .fill(.white.opacity(0.55))
                    .frame(width: 7, height: 7)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Image(systemName: "tram.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accent)
                    .offset(x: trackWidth * CGFloat(progress))
            }
            .frame(height: 18)
        }
        .frame(height: 18)
    }
}
