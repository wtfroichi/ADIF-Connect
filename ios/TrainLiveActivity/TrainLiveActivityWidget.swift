import ActivityKit
import SwiftUI
import WidgetKit

private enum ActivityData {
    static func string(_ key: String, context: ActivityViewContext<LiveActivitiesAppAttributes>) -> String {
        UserDefaults(suiteName: context.state.appGroupId)?
            .string(forKey: context.attributes.prefixedKey(key)) ?? "—"
    }

    static func number(_ key: String, context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Double {
        UserDefaults(suiteName: context.state.appGroupId)?
            .double(forKey: context.attributes.prefixedKey(key)) ?? 0
    }

    static func operatorLabel(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> String {
        string(TrainLiveActivityPayloadKey.operatorName, context: context).uppercased()
    }
}

struct TrainLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            lockScreenView(context)
                .activityBackgroundTint(Color(red: 0.04, green: 0.12, blue: 0.09))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let origin = ActivityData.string(TrainLiveActivityPayloadKey.originCode, context: context)
            let destination = ActivityData.string(TrainLiveActivityPayloadKey.destinationCode, context: context)
            let platform = ActivityData.string(TrainLiveActivityPayloadKey.platform, context: context)
            let progress = min(max(ActivityData.number(TrainLiveActivityPayloadKey.progress, context: context), 0), 1)

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
                            .foregroundStyle(Color(red: 0.77, green: 0.84, blue: 0))
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    routeProgress(progress)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "tram.fill")
                    .foregroundStyle(Color(red: 0.77, green: 0.84, blue: 0))
            } compactTrailing: {
                Text(platform == "Por asignar" ? "—" : platform)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: "tram.fill")
                    .foregroundStyle(Color(red: 0.77, green: 0.84, blue: 0))
            }
            .keylineTint(Color(red: 0, green: 0.39, blue: 0.22))
        }
    }

    private func lockScreenView(
        _ context: ActivityViewContext<LiveActivitiesAppAttributes>
    ) -> some View {
        let progress = min(max(ActivityData.number(TrainLiveActivityPayloadKey.progress, context: context), 0), 1)
        let coach = ActivityData.string(TrainLiveActivityPayloadKey.coach, context: context)

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
                    .foregroundStyle(Color(red: 0.77, green: 0.84, blue: 0))
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

            routeProgress(progress)

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
                    .foregroundStyle(Color(red: 0.77, green: 0.84, blue: 0))
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

    private func routeProgress(_ progress: Double) -> some View {
        GeometryReader { geometry in
            let trackWidth = max(geometry.size.width - 14, 0)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(height: 3)
                Capsule()
                    .fill(Color(red: 0.77, green: 0.84, blue: 0))
                    .frame(width: trackWidth * progress, height: 3)
                Circle()
                    .fill(.white.opacity(0.55))
                    .frame(width: 7, height: 7)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Image(systemName: "tram.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 0.77, green: 0.84, blue: 0))
                    .offset(x: trackWidth * CGFloat(progress))
            }
            .frame(height: 18)
        }
        .frame(height: 18)
    }
}
