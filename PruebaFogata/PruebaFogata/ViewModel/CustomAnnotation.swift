//
//  CustomAnnotation.swift
//  PruebaFogata
//
//  Created by Iran Carrillo Guzman on 31/01/24.
//

import Foundation
import MapKit

class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var id: UUID

    init(coordinate: CLLocationCoordinate2D, title: String?, id: UUID) {
        self.coordinate = coordinate
        self.title = title
        self.id = id
    }
}
