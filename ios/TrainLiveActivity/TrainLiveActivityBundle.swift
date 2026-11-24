//
//  TrainLiveActivityBundle.swift
//  TrainLiveActivity
//
//  Created by Roi Prieto on 23/11/2026.
//

import SwiftUI
import WidgetKit

@main
struct TrainLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        TrainLiveActivityWidget()
        StationDeparturesWidget()
    }
}
