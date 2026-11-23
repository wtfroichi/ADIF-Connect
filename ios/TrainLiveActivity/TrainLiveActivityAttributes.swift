import ActivityKit
import Foundation

enum TrainLiveActivityPayloadKey {
    static let trainNumber = "trainNumber"
    static let operatorName = "operatorName"
    static let originCode = "originCode"
    static let destinationCode = "destinationCode"
    static let departureTime = "departureTime"
    static let arrivalTime = "arrivalTime"
    static let platform = "platform"
    static let coach = "coach"
    static let seat = "seat"
    static let progress = "progress"
    static let statusText = "statusText"
}

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState

    public struct ContentState: Codable, Hashable {
        var appGroupId: String
    }

    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        "\(id.uuidString)_\(key)"
    }
}
