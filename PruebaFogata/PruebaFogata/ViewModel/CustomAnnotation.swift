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

    init(coordinate: CLLocationCoordinate2D, title: String?) {
        self.coordinate = coordinate
        self.title = title
    }
}
