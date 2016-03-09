CMMapLauncher
=============

CMMapLauncher is a mini-library for iOS that makes it quick and easy to show directions in various mapping applications.  To use it, just add `CMMapLauncher.h` and `CMMapLauncher.m` to your project. If you are using Swift, just add `CMMapLauncher.swift` to your project.

##Objective C

To check whether one of the supported mapping apps is present on the user's device:

    BOOL installed = [CMMapLauncher isMapAppInstalled:CMMapAppCitymapper];
    
Then, to launch into directions in that app:

    CLLocationCoordinate2D bigBen = CLLocationCoordinate2DMake(51.500755, -0.124626);
    [CMMapLauncher launchMapApp:CMMapAppCitymapper
                forDirectionsTo:[CMMapPoint mapPointWithName:@"Big Ben"
                                                  coordinate:bigBen]];

CMMapLauncher currently knows how to show directions in the following mapping apps:

* Apple Maps &mdash; `CMMapAppAppleMaps`
* Citymapper &mdash; `CMMapAppCitymapper`
* Google Maps &mdash; `CMMapAppGoogleMaps`
* Navigon &mdash; `CMMapAppNavigon`
* The Transit App &mdash; `CMMapAppTheTransitApp`
* Moovit &mdash; `CMMapAppMoovit`
* Waze &mdash; `CMMapAppWaze`
* Yandex Navigator &mdash; `CMMapAppYandex`

##Swift

To check whether one of the supported mapping apps is present on the user's device:

    let installed = CMMapLauncher.isMapAppInstalled(.Citymapper)
    
Then, to launch into directions in that app:

    let bigBen = CLLocationCoordinate2DMake(51.500755, -0.124626)
    CMMapLauncher.launchMapApp(.Citymapper, forDirectionsTo: CMMapPoint(name:@"Big Ben", address: nil, coordinate:bigBen))

CMMapLauncher currently knows how to show directions in the following mapping apps:

* Apple Maps &mdash; `CMMapApp.AppleMaps`
* Citymapper &mdash; `CMMapApp.Citymapper`
* Google Maps &mdash; `CMMapApp.GoogleMaps`
* Navigon &mdash; `CMMapApp.Navigon`
* The Transit App &mdash; `CMMapApp.TheTransitApp`
* Moovit &mdash; `CMMapApp.Moovit`
* Waze &mdash; `CMMapApp.Waze`
* Yandex Navigator &mdash; `CMMapApp.Yandex`

If you know of other direction-providing apps that expose a URL scheme for launching from other apps, this project wants to incorporate them!  Pull requests and issues providing URL schemes are encouraged.

CMMapLauncher was originally created by [Citymapper](http://citymapper.com), but is released under the MIT License for the benefit of the iOS developer community.
