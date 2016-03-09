//
// CMMapLauncher.swift
//
// Copyright (c) 2013 Citymapper Ltd. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

//
// README
//
// This class simplifies the process of launching various mapping
// applications to display directions.  Here's the simplest use case:
//
// let bigBen =  CLCLLocationCoordinate2DMake(51.500755, -0.124626)
// CMMapLauncher.launchMapApp(CMMapAppAppleMaps, forDirectionsTo: CMMapPoint(name:"Big Ben", address: nil, coordinate:bigBen)
//

import Foundation
import MapKit
import MobileCoreServices

enum CMMapApp {
    
    /**
     Preinstalled Apple Maps
     */
    case AppleMaps  // Preinstalled Apple Maps
    /**
     Citymapper
     */
    case Citymapper
    /**
     Standalone Google Maps App
     */
    case GoogleMaps
    /**
     Navigon
     */
    case Navigon
    /**
     The Transit App
     */
    case TheTransitApp
    /**
     Moovit
     */
    case Moovit
    /**
     Waze
     */
    case Waze
    /**
     Yandex Navigator
     */
    case Yandex
    
}

class CMMapLauncher: NSObject {
    
    //MARK: - Public Library Methods
    
    /**
     Determines whether the given mapping app is installed.
     
     @param mapApp An enumeration value identifying a mapping application.
     @return true if the specified app is installed, false otherwise.
     */
    
    static func isMapAppInstalled(mapApp: CMMapApp) -> Bool {
        
        if mapApp == .AppleMaps {
            return true
        }
        
        let urlPrefix = CMMapLauncher.urlPrefixForMapApp(mapApp)
        guard let prefix = urlPrefix else {
            return false
        }
        
        return UIApplication.sharedApplication().canOpenURL(NSURL(string:prefix)!)
        
    }
    
    /**
     Launches the specified mapping application with directions
     from the user's current location to the specified endpoint.
     
     @param mapApp An enumeration value identifying a mapping application.
     @param end The destination of the desired directions.
     
     @return true if the mapping app could be launched, false otherwise.
     */
    
    static func launchMapApp(mapApp: CMMapApp, forDirectionsTo end: CMMapPoint) -> Bool {
        return CMMapLauncher.launchMapApp(mapApp, forDirectionsFrom: CMMapPoint(currentLocation: true), to:end)
    }
    
    /**
     Launches the specified mapping application with directions
     between the two specified endpoints.
     
     @param mapApp An enumeration value identifying a mapping application.
     @param start The starting point of the desired directions.
     @param end The destination of the desired directions.
     
     @return true if the mapping app could be launched, false otherwise.
     */
    
    static func launchMapApp(mapApp: CMMapApp, forDirectionsFrom start: CMMapPoint, to end: CMMapPoint) -> Bool {
        
        var url = String()
        
        func launchCitymapper() {
            
            var params = [String]()
            
            if !start.isCurrentLocation {
                params.append("startcoord=\(start.coordinate.latitude),\(start.coordinate.longitude)")
                if let startName = start.name {
                    params.append("startname=\(CMMapLauncher.urlEncode(startName))")
                }
                if let startAddress = start.address {
                    params.append("startaddress=\(CMMapLauncher.urlEncode(startAddress))")
                }
            }
            
            if !end.isCurrentLocation {
                
                params.append("endcoord=\(end.coordinate.latitude),\(end.coordinate.longitude)")
                
                if let endName = end.name {
                    params.append("endname=\(CMMapLauncher.urlEncode(endName))")
                }
                if let endAddress = end.address {
                    params.append("endaddress=\(CMMapLauncher.urlEncode(endAddress))")
                }
            }
            
            url = "citymapper://directions?\(params.stringFromComponentsJoinedBy("&"))"
            
        }
        
        func launchTransitApp() {
            var params = [String]()
            
            if !start.isCurrentLocation {
                params.append("from=\(start.coordinate.latitude),\(start.coordinate.longitude)")
            }
            
            if !end.isCurrentLocation {
                params.append("to=\(end.coordinate.latitude),\(end.coordinate.longitude)")
            }
            
            url = "transit://directions?\(params.stringFromComponentsJoinedBy("&"))"
            
        }
        
        func launchMoovit() {
            
            var params = [String]()
            
            if !start.isCurrentLocation {
                params.append("origin_lat=\(start.coordinate.latitude)&origin_lon=\(start.coordinate.longitude)")
                if let startName = start.name {
                    params.append("orig_name=\(CMMapLauncher.urlEncode(startName))")
                }
            }
            
            if !end.isCurrentLocation {
                params.append("dest_lat=\(end.coordinate.latitude)&dest_lon=\(end.coordinate.longitude)")
                if let endName = end.name {
                    params.append("dest_name=\(CMMapLauncher.urlEncode(endName))")
                }
            }
            
            url = "moovit://directions?\(params.stringFromComponentsJoinedBy("&"))"
            
        }
        
        func launchNavigon() {
            let name = end.name != nil ? end.name : "Destination"
            url = "navigon://coordinate/\(name)/\(end.coordinate.latitude)/\(end.coordinate.longitude)"
        }
        
        func launchYandex() {
            var tempUrl = "yandexnavi://build_route_on_map?lat_to=\(end.coordinate.latitude)&lon_to=\(end.coordinate.longitude)"
            if !start.isCurrentLocation {
                tempUrl += "&lat_from=\(start.coordinate.latitude)&lon_from=%\(start.coordinate.longitude)"
            }
            url = tempUrl
        }
        
        guard CMMapLauncher.isMapAppInstalled(mapApp) == true else {
            return false
        }
        
        if mapApp == .AppleMaps {
            
            if #available(iOS 6.0, *) {
                let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                return MKMapItem.openMapsWithItems([start.mapItem, end.mapItem], launchOptions: launchOptions)
            } else {
                url = "http://maps.google.com/maps?saddr=\(CMMapLauncher.googleMapsStringForMapPoint(start))&daddr=\(CMMapLauncher.googleMapsStringForMapPoint(end))"
            }
            
        } else if mapApp == .GoogleMaps {
            url = "comgooglemaps://?saddr=\(CMMapLauncher.googleMapsStringForMapPoint(start))&daddr=\(CMMapLauncher.googleMapsStringForMapPoint(end))"
            
        } else if mapApp == .Citymapper {
            launchCitymapper()
            
        } else if mapApp == .TheTransitApp {
            // http://thetransitapp.com/developers
            launchTransitApp()
            
        } else if (mapApp == .Moovit) {
            // http://developers.moovitapp.com
            launchMoovit()
            
        } else if (mapApp == .Navigon) {
            // http://www.navigon.com/portal/common/faq/files/NAVIGON_AppInteract.pdf
            launchNavigon()
            
        } else if (mapApp == .Waze) {
            url = "waze://?ll\(end.coordinate.latitude),\(end.coordinate.longitude)&navigate=yes"
            
        } else if (mapApp == .Yandex) {
            launchYandex()
            
        }
        
        return UIApplication.sharedApplication().openURL(NSURL(string: url)!)
    }
    
    //MARK: - Utility
    
    private static func urlPrefixForMapApp(mapApp: CMMapApp) -> String? {
        
        switch mapApp {
        case .Citymapper:
            return "citymapper://"
            
        case .GoogleMaps:
            return "comgooglemaps://"
            
        case .Navigon:
            return "navigon://"
            
        case .TheTransitApp:
            return "transit://"
            
        case .Moovit:
            return "moovit://"
            
        case .Waze:
            return "waze://"
            
        case .Yandex:
            return "yandexnavi://"
            
        default:
            return nil;
        }
        
        
    }
    
    private static func urlEncode(queryParam: String) -> String {
        // Encode all the reserved characters, per RFC 3986
        // (<http://www.ietf.org/rfc/rfc3986.txt>)
        
        let encodedString = (queryParam as NSString).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) ?? ""
        return encodedString as String ?? ""
        
    }
    
    private static func googleMapsStringForMapPoint(mapPoint: CMMapPoint) -> String {
        
        if mapPoint.isCurrentLocation && mapPoint.coordinate.latitude == 0.0 && mapPoint.coordinate.longitude == 0.0 {
            return String()
        }
        
        if let mapPointName = mapPoint.name {
            let mapPointString = "\(mapPoint.coordinate.latitude),\(mapPoint.coordinate.longitude)+\(CMMapLauncher.urlEncode(mapPointName))"
            return mapPointString
        }
        
        return "\(mapPoint.coordinate.latitude), \(mapPoint.coordinate.longitude)"
    }
    
}

///--------------------------
/// CMMapPoint (helper class)
///--------------------------

class CMMapPoint : NSObject {
    
    /**
     Determines whether this map point represents the user's current location.
     */
    var isCurrentLocation = false
    
    /**
     The geographical coordinate of the map point.
     */
    var coordinate: CLLocationCoordinate2D!
    
    /**
     The user-visible name of the given map point (optional, may be nil).
     */
    var name: String? {
        get {
            let returnValue = self.isCurrentLocation ? "Current Location" : _name
            return returnValue
        } set(newValue) {
            self._name = newValue
        }
    }
    
    private var _name: String?
    
    /**
     The address of the given map point (optional, may be nil).
     */
    var address: String!
    
    /**
     Gives an MKMapItem corresponding to this map point object.
     */
    var mapItem: MKMapItem {
        get {
            if self.isCurrentLocation {
                return MKMapItem.mapItemForCurrentLocation()
            } else {
                let placemark = MKPlacemark(coordinate: self.coordinate, addressDictionary: nil)
                let item = MKMapItem(placemark: placemark)
                item.name = self.name
                return item
            }
        }
    }
    
    /**
     Creates a new CMMapPoint with the given name, address, and coordinate.
     
     @param name The optional user-visible name of the new map point.
     @param address The optional address string of the new map point.
     @param coordinate The geographical coordinate of the new map point.
     */
    
    init(name: String?, address: String?, coordinate: CLLocationCoordinate2D) {
        self._name = name
        self.address = address
        self.coordinate = coordinate
    }
    
    /**
     Convenience initializer that reflects user's current location
     */
    init(currentLocation: Bool) {
        self.isCurrentLocation = true
    }
    
}

extension Array {
    
    func stringFromComponentsJoinedBy(unionString: String) -> String {
        
        var string = ""
        for element in self where String(element) != nil {
            
            let converted = String(element)
            
            if (converted == String(self.last!)) == false {
                string += "\(element)\(unionString)"
            } else if converted == String(self.last!) {
                string += "\(element)"
            }
        }
        return string
    }
}

