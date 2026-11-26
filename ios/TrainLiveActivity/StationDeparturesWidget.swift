import SwiftUI
import WidgetKit

private struct CachedDeparture: Decodable, Identifiable {
    let payloadID: String?
    let scheduledTime: String
    let trainType: String
    let trainNumber: String
    let destination: String
    let `operator`: String
    let platform: String?

    enum CodingKeys: String, CodingKey {
        case payloadID = "id"
        case scheduledTime
        case trainType
        case trainNumber
        case destination
        case `operator`
        case platform
    }

    var stableID: String { payloadID ?? "\(scheduledTime)-\(trainNumber)" }
    var serviceLabel: String {
        let service = trainType.trimmingCharacters(in: .whitespacesAndNewlines)
        if `operator`.lowercased() == "renfe" {
            let clean = service.range(of: #"^\d+$"#, options: .regularExpression) == nil
            return clean && !service.isEmpty ? "RENFE \(service)" : "RENFE"
        }
        return `operator`.uppercased()
    }

    var platformLabel: String {
        guard let platform else { return "Vía —" }
        let value = platform.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty,
              !["0", "00", "-", "--", "—", "null", "por asignar"]
                .contains(value.lowercased()),
              Double(value).map({ $0 > 0 }) ?? true else {
            return "Vía —"
        }
        return "Vía \(value)"
    }

    var id: String { stableID }
}

private struct StationDeparturesEntry: TimelineEntry {
    let date: Date
    let stationCode: String
    let stationName: String
    let departures: [CachedDeparture]
}

private struct StationDeparturesProvider: TimelineProvider {
    func placeholder(in context: Context) -> StationDeparturesEntry {
        StationDeparturesEntry(
            date: Date(),
            stationCode: "",
            stationName: "Estación",
            departures: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StationDeparturesEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StationDeparturesEntry>) -> Void) {
        let entry = readEntry()
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60))))
    }

    private func readEntry() -> StationDeparturesEntry {
        let defaults = UserDefaults(suiteName: "group.es.andenlibre.app")
        let stationCode = defaults?.string(forKey: "defaultStationCode") ?? ""
        let stationName = defaults?.string(forKey: "defaultStationName") ?? "Estación"
        let json = defaults?.string(forKey: "stationDeparturesJSON.\(stationCode)") ?? "[]"
        let decoded = (try? JSONDecoder().decode([CachedDeparture].self, from: Data(json.utf8))) ?? []
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "HH:mm"
        let currentClock = formatter.string(from: Date())
        let upcoming = decoded
            .filter { $0.scheduledTime.range(of: #"^\d{2}:\d{2}$"#, options: .regularExpression) != nil }
            .filter { $0.scheduledTime >= currentClock }
            .sorted { $0.scheduledTime < $1.scheduledTime }
        return StationDeparturesEntry(
            date: Date(),
            stationCode: stationCode,
            stationName: stationName,
            departures: upcoming
        )
    }
}

struct StationDeparturesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "StationDeparturesWidget",
            provider: StationDeparturesProvider()
        ) { entry in
            StationDeparturesWidgetView(entry: entry)
        }
        .configurationDisplayName("Saídas en tempo real")
        .description("Próximas saídas da estación seleccionada.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct StationDeparturesWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StationDeparturesEntry

    private var visibleDepartures: [CachedDeparture] {
        switch family {
        case .systemLarge:
            return Array(entry.departures.prefix(5))
        case .systemMedium:
            return Array(entry.departures.prefix(2))
        default:
            return Array(entry.departures.prefix(2))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemLarge ? 3 : (family == .systemMedium ? 5 : 8)) {
            HStack(spacing: 6) {
                Image(systemName: "tram.fill")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text("SAÍDAS")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(entry.stationName)
                        .font(.system(size: family == .systemSmall ? 12 : (family == .systemLarge ? 16 : 14), weight: .bold))
                        .lineLimit(family == .systemLarge ? 2 : 1)
                        .minimumScaleFactor(0.82)
                        .foregroundStyle(.primary)
                }
                Spacer(minLength: 0)
            }

            if visibleDepartures.isEmpty {
                Spacer(minLength: 0)
                Text("Sen saídas dispoñibles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
            } else {
                ForEach(visibleDepartures) { departure in
                    departureRow(departure)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
        .background {
            if #available(iOS 26.0, *) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.65), lineWidth: 1)
                    }
            }
        }
    }

    @ViewBuilder
    private func departureRow(_ departure: CachedDeparture) -> some View {
        let isLarge = family == .systemLarge
        let rowSpacing: CGFloat = isLarge ? 5 : 7
        let timeSize: CGFloat = isLarge ? 18 : 15
        let destinationSize: CGFloat = isLarge ? 11 : 9

        HStack(spacing: rowSpacing) {
            Text(departure.scheduledTime)
                .font(.system(size: timeSize, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(.primary)
                .fixedSize()
            VStack(alignment: .leading, spacing: isLarge ? 1 : 2) {
                Text(departure.serviceLabel)
                    .font(.system(size: isLarge ? 9 : 8, weight: .heavy))
                    .lineLimit(family == .systemSmall ? 2 : 1)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.primary)
                    .widgetAccentable()
                if family != .systemSmall {
                    Text(departure.trainNumber)
                        .font(.system(size: isLarge ? 10 : 9, weight: .semibold, design: .rounded).monospacedDigit())
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                    Text(departure.destination)
                        .font(.system(size: destinationSize, weight: .medium))
                        .lineLimit(isLarge ? 2 : 2)
                        .minimumScaleFactor(0.88)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Text(departure.platformLabel)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .foregroundStyle(.primary)
                .overlay {
                    Capsule()
                        .stroke(.primary.opacity(0.25), lineWidth: 0.7)
                }
        }
    }
}
