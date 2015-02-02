// CMMapLauncher.m
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

#import "CMMapLauncher.h"

@interface CMMapLauncher ()

+ (NSString *)urlPrefixForMapApp:(CMMapApp)mapApp;
+ (NSString *)urlEncode:(NSString *)queryParam;
+ (NSString *)googleMapsStringForMapPoint:(CMMapPoint *)mapPoint;

@end

@implementation CMMapLauncher

+ (NSString *)urlPrefixForMapApp:(CMMapApp)mapApp {
    switch (mapApp) {
        case CMMapAppCitymapper:
            return @"citymapper://";

        case CMMapAppGoogleMaps:
            return @"comgooglemaps://";

        case CMMapAppNavigon:
            return @"navigon://";

        case CMMapAppTheTransitApp:
            return @"transit://";

        case CMMapAppWaze:
            return @"waze://";

        case CMMapAppYandex:
            return @"yandexnavi://";

        case CMMapAppUber:
            return @"uber://";

        default:
            return nil;
    }
}

+ (NSString *)urlEncode:(NSString *)queryParam {
    // Encode all the reserved characters, per RFC 3986
    // (<http://www.ietf.org/rfc/rfc3986.txt>)
    NSString *newString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)queryParam, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);

    if (newString) {
        return newString;
    }

    return @"";
}

+ (NSString *)googleMapsStringForMapPoint:(CMMapPoint *)mapPoint {
    if (!mapPoint) {
        return @"";
    }

    if (mapPoint.isCurrentLocation && mapPoint.coordinate.latitude == 0.0 && mapPoint.coordinate.longitude == 0.0) {
        return @"";
    }

    if (mapPoint.name) {
        return [NSString stringWithFormat:@"%f,%f", mapPoint.coordinate.latitude, mapPoint.coordinate.longitude];
    }

    return [NSString stringWithFormat:@"%f,%f", mapPoint.coordinate.latitude, mapPoint.coordinate.longitude];
}

+ (BOOL)isMapAppInstalled:(CMMapApp)mapApp {
    if (mapApp == CMMapAppAppleMaps) {
        return YES;
    }

    NSString *urlPrefix = [CMMapLauncher urlPrefixForMapApp:mapApp];
    if (!urlPrefix) {
        return NO;
    }

    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlPrefix]];
}

+ (BOOL)launchMapApp:(CMMapApp)mapApp forDirectionsTo:(CMMapPoint *)end {
    return [CMMapLauncher launchMapApp:mapApp forDirectionsFrom:[CMMapPoint currentLocation] to:end];
}

+ (BOOL)launchMapApp:(CMMapApp)mapApp
   forDirectionsFrom:(CMMapPoint *)start
                  to:(CMMapPoint *)end {
    if (![CMMapLauncher isMapAppInstalled:mapApp]) {
        return NO;
    }

    if (mapApp == CMMapAppAppleMaps) {
        // Check for iOS 6
        Class mapItemClass = [MKMapItem class];
        if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]) {
            NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking};
            return [MKMapItem openMapsWithItems:@[start.MKMapItem, end.MKMapItem] launchOptions:launchOptions];
        } else {  // iOS 5
            NSString *url = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%@&daddr=%@",
                             [CMMapLauncher googleMapsStringForMapPoint:start],
                             [CMMapLauncher googleMapsStringForMapPoint:end]
                             ];
            return [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }
    } else if (mapApp == CMMapAppGoogleMaps) {
        NSString *url = [NSString stringWithFormat:@"comgooglemaps://?saddr=%@&daddr=%@",
                         [CMMapLauncher googleMapsStringForMapPoint:start],
                         [CMMapLauncher googleMapsStringForMapPoint:end]
                         ];
        return [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    } else if (mapApp == CMMapAppCitymapper) {
        NSMutableArray *params = [NSMutableArray arrayWithCapacity:10];
        if (start && !start.isCurrentLocation) {
            [params addObject:[NSString stringWithFormat:@"startcoord=%f,%f", start.coordinate.latitude, start.coordinate.longitude]];
            if (start.name) {
                [params addObject:[NSString stringWithFormat:@"startname=%@", [CMMapLauncher urlEncode:start.name]]];
            }
            if (start.address) {
                [params addObject:[NSString stringWithFormat:@"startaddress=%@", [CMMapLauncher urlEncode:start.address]]];
            }
        }
        if (end && !end.isCurrentLocation) {
            [params addObject:[NSString stringWithFormat:@"endcoord=%f,%f", end.coordinate.latitude, end.coordinate.longitude]];
            if (end.name) {
                [params addObject:[NSString stringWithFormat:@"endname=%@", [CMMapLauncher urlEncode:end.name]]];
            }
            if (end.address) {
                [params addObject:[NSString stringWithFormat:@"endaddress=%@", [CMMapLauncher urlEncode:end.address]]];
            }
        }
        NSString *url = [NSString stringWithFormat:@"citymapper://directions?%@", [params componentsJoinedByString:@"&"]];
        return [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    } else if (mapApp == CMMapAppTheTransitApp) {
        // http://thetransitapp.com/developers

        NSMutableArray *params = [NSMutableArray arrayWithCapacity:2];
        if (start && !start.isCurrentLocation) {
            [params addObject:[NSString stringWithFormat:@"from=%f,%f", start.coordinate.latitude, start.coordinate.longitude]];
        }
        if (end && !end.isCurrentLocation) {
            [params addObject:[NSString stringWithFormat:@"to=%f,%f", end.coordinate.latitude, end.coordinate.longitude]];
        }
        NSString *url = [NSString stringWithFormat:@"transit://directions?%@", [params componentsJoinedByString:@"&"]];
        return [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    } else if (mapApp == CMMapAppNavigon) {
        // http://www.navigon.com/portal/common/faq/files/NAVIGON_AppInteract.pdf

        NSString *name = @"Destination";  // Doc doesn't say whether name can be omitted
        if (end.name) {
            name = end.name;
        }
        NSString *url = [NSString stringWithFormat:@"navigon://coordinate/%@/%f/%f", [CMMapLauncher urlEncode:name], end.coordinate.longitude, end.coordinate.latitude];
        return [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    } else if (mapApp == CMMapAppWaze) {
        NSString *url = [NSString stringWithFormat:@"waze://?ll=%f,%f&navigate=yes", end.coordinate.latitude, end.coordinate.longitude];
        return [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    } else if (mapApp == CMMapAppYandex) {
        NSString *url = nil;
        if (start.isCurrentLocation) {
            url = [NSString stringWithFormat:@"yandexnavi://build_route_on_map?lat_to=%f&lon_to=%f", end.coordinate.latitude, end.coordinate.longitude];
        } else {
            url = [NSString stringWithFormat:@"yandexnavi://build_route_on_map?lat_to=%f&lon_to=%f&lat_from=%f&lon_from=%f", end.coordinate.latitude, end.coordinate.longitude, start.coordinate.latitude, start.coordinate.longitude];
        }
        return [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    } else if (mapApp == CMMapAppUber) {
        NSString *url = nil;
        if (start.isCurrentLocation) {
            url = [NSString stringWithFormat:@"uber://?action=setPickup&pickup=my_location&dropoff[latitude]=%f&dropoff[longitude]=%f&dropoff[nickname]=%@", end.coordinate.latitude, end.coordinate.longitude, [end.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        } else {
            url = [NSString stringWithFormat:@"uber://?action=setPickup&pickup[latitude]=%f&pickup[longitude]=%f&dropoff[latitude]=%f&dropoff[longitude]=%f&dropoff[nickname]=%@", start.coordinate.latitude, start.coordinate.longitude, end.coordinate.latitude, end.coordinate.longitude, [end.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        return [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
    return NO;
}

@end


///--------------------------
/// CMMapPoint (helper class)
///--------------------------

@implementation CMMapPoint

+ (CMMapPoint *)currentLocation {
    CMMapPoint *mapPoint = [[CMMapPoint alloc] init];
    mapPoint.isCurrentLocation = YES;
    return mapPoint;
}

+ (CMMapPoint *)mapPointWithCoordinate:(CLLocationCoordinate2D)coordinate {
    CMMapPoint *mapPoint = [[CMMapPoint alloc] init];
    mapPoint.coordinate = coordinate;
    return mapPoint;
}

+ (CMMapPoint *)mapPointWithName:(NSString *)name
                      coordinate:(CLLocationCoordinate2D)coordinate {
    CMMapPoint *mapPoint = [[CMMapPoint alloc] init];
    mapPoint.name = name;
    mapPoint.coordinate = coordinate;
    return mapPoint;
}

+ (CMMapPoint *)mapPointWithName:(NSString *)name
                         address:(NSString *)address
                      coordinate:(CLLocationCoordinate2D)coordinate {
    CMMapPoint *mapPoint = [[CMMapPoint alloc] init];
    mapPoint.name = name;
    mapPoint.address = address;
    mapPoint.coordinate = coordinate;
    return mapPoint;
}

+ (CMMapPoint *)mapPointWithAddress:(NSString *)address coordinate:(CLLocationCoordinate2D)coordinate {
    CMMapPoint *mapPoint = [[CMMapPoint alloc] init];
    mapPoint.address = address;
    mapPoint.coordinate = coordinate;
    return mapPoint;
}

- (NSString *)name {
    if (_isCurrentLocation) {
        return @"Current Location";
    }

    return _name;
}

- (MKMapItem *)MKMapItem {
    if (_isCurrentLocation) {
        return [MKMapItem mapItemForCurrentLocation];
    }

    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:_coordinate addressDictionary:nil];

    MKMapItem *item = [[MKMapItem alloc] initWithPlacemark:placemark];
    item.name = self.name;
    return item;
}

@end

