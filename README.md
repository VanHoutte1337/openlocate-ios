
![OpenLocate](http://imageshack.com/a/img922/4800/Pihgqn.png)

## Purpose

### Why should you collect location data?

A mobile application should only collect a user’s location information if its user experience depends on or is improved by location awareness. An app that delivers retailer-specific coupons or offers based on a user’s location has a valid reason to ask the user for location permissions.

Protecting user privacy and maintaining trust is paramount. The purpose of OpenLocate is to standardize and simplify the collection of location data by mobile applications that have privacy-compliant and user-centric reasons to do so. 

OpenLocate should not be used solely to collect location data for monetization purposes.

Here are a couple of blog posts that discuss best practices and things to keep in mind when asking a mobile app user for permissions:
- https://medium.com/product-breakdown/5-ways-to-ask-users-for-ios-permissions-a8e199cc83ad
- https://uxplanet.org/mobile-ux-design-the-right-ways-to-ask-users-for-permissions-6cdd9ab25c27

### Why is this project useful?

OpenLocate is supported by developers, non-profits, trade groups, and industry for the following reasons:

* Collecting location data in a battery efficient manner that does not adversely affect mobile application performance is non-trivial. OpenLocate enables everyone in the community to benefit from shared knowledge around how to do this well.
* Creates standards and best practices for location collection.
* Developers have full transparency on how OpenLocate location collection works.
* Location data collected via OpenLocate is solely controlled by the developer.

### What can I do with location data?

Mobile application developers can use location data collected via OpenLocate to:

* Enhance their mobile application using context about the user’s location.
* Receive data about the Points of Interest a device has visited by enabling integrations with 3rd party APIs such as Google Places or Foursquare Venues
* Send location data to partners of OpenLocate via integrations listed here.

### Who is supporting OpenLocate?

OpenLocate is supported by mobile app developers, non-profit trade groups, academia, and leading companies across GIS, logistics, marketing, and more.

## Requirements
- XCode 9.0+
- iOS 8.0+

## How OpenLocate Works

OpenLocate utilizes  several services within iOS’s CoreLocation API to provide timely and relevant location updates.
- `Visit Monitoring` API is used to determine locations the user has frequented by logging a location update for the entry and exit of a visit.
- `Significant Location Change` API is used to log significant movement in the user’s location.
- Cached location update when application becomes active. If cached fix is older than 15 minutes, a new location update is fetched when in foreground.
- Lastly, `Background Fetch` is used to periodically fetch the user’s current location.

Given that location updates are sparse, the context in which the location updates occurred in is recorded in location_context.

In order to minimize battery usage and network traffic to your server, the location updates are not transmitted immediately, but rather batched locally for transmission at a defined interval. The default transmission interval is six hours, though this interval can be configured. Once successfully transmitted, the location updates are no longer stored on the device.

## Installation

Cocoapods

If you use cocoapods, add the following line in your podfile and run `pod install`

```ruby
pod 'OpenLocate'
```

## Usage

### Initialize tracking

1. Add appropriate location usage descriptions to the `Info.plist` of your application. **Be sure to fill in your app name where appropriate (or edit the string as you see fit)**

For **Xcode 9:**
```xml
<key>NSLocationAlwaysUsageDescription</key>
<string>[App_name] would like to access location.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>[App_name] would like to access location.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>[App_name] would like to access location.</string>
```

2. Configure where the SDK should send data to by building the configuration with appropriate URL and headers. Supply the configuration to the `initialize` method. Ensure that the initialize method is invoked in the `application:didFinishLaunchingWithOptions:` method in your `UIApplicationDelegate`

#### For example, to send data to SafeGraph:

Assuming you have a UUID and token from SafeGraph:

```swift
import openlocate

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? ) -> Bool {

    let uuid = UUID(uuidString: "<YOUR_UUID>")!
    let token = "YOUR_TOKEN"
    
    let url = URL(string: "https://api.safegraph.com/v1/provider/\(uuid)/devicelocation")!
    let headers = ["Authorization": "Bearer \(token)"]
    
    let configuration = Configuration(url: url, headers: headers, authorizationStatus: .authorizedAlways)
    
    do {
        try OpenLocate.shared.initialize(with: configuration)
    } catch {
        print(error)
    }
}
```

#### Configuring multiple endpoints

If you would like to send the data to multiple endpoints, you can do so by creating multiple `Configuration.Endpoint` objects and passing them in to the `Configuration` object. If data fails to be sent to any given endpoint, data will be saved locally and re-tried in later transmissions. A maximum of 10 days worth of data is kept.

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? ) -> Bool {

    let url1 = URL(string: "https://example-url.com/endpoint1")!
    let headers1 = ["Authorization": "Bearer example_auth_token"]
    let endpoint1 = Configuration.Endpoint(url: url1, headers: headers1)

    let url2 = URL(string: "https://example-url2.com/endpoint2")!
    let headers2 = ["Authorization": "Bearer example_auth_token]
    let endpoint2 = Configuration.Endpoint(url: url2, headers: headers2)

    let configuration = Configuration(endpoints: [endpoint1, endpoint2])
    do {
        try OpenLocate.shared.initialize(with: configuration)
    } catch {
        print(error)
    }
}
```

#### Configuring for "When In Use" location authorization

By default, open locate will use and prompt the `.authorizedAlways` authorization status for `CLLocationManager`. If you prefer to use the `.authroizedWhenInUse` status, you can specify this before calling  `initialize`. Note that you will receive significantly less location updates when compared to the default. Example:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? ) -> Bool {

    let uuid = UUID(uuidString: "<YOUR_UUID>")!
    let token = "YOUR_TOKEN"

    let url = URL(string: "https://api.safegraph.com/v1/provider/\(uuid)/devicelocation")!
    let headers = ["Authorization": "Bearer \(token)"]

    let configuration = Configuration(url: url, headers: headers, authorizationStatus: .authorizedWhenInUse)

    do {
        try OpenLocate.shared.initialize(with: configuration)
    } catch {
        print(error)
    }
}
```

### Start tracking of location

To start the tracking location, call the `startTracking` method on the `OpenLocate`. Get the instance by calling `shared`.

```swift
OpenLocate.shared.startTracking()
```


### Stop tracking of location

To stop the tracking call `stopTracking` method on the `OpenLocate`. Get the instance by calling `shared`.

```swift
OpenLocate.shared.stopTracking()
```

### Check the current state of location tracking

Call `isTrackingEnabled` method on the `OpenLocate`. Get the instance by calling `shared`.

```swift
OpenLocate.shared.isTrackingEnabled()
```

### Configuring the location data transmission interval

By default, the location data transmission interval is six hours. If you would like to change that. Simply pass a different value when constructing your `Configuration` object:

```swift
let configuration = Configuration(endpoints: [endpoint], transmissionInterval: 3 * 60.0 * 60.0) // 3 Hours
```

### Additional location updates via Background Fetch
If you would like more periodic location updates, you can enable background fetch to allow the application to poll for location updates periodically.

Ensure that `Background Fetch` mode is enabled in your project:
<p align="center"><img width="400" src="https://raw.githubusercontent.com/OpenLocate/openlocate-ios/master/Screenshots/BackgroundFetch-Cabability.png" /></p>

Additionally, implement the following method in your `AppDelegate`

```swift
func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
     OpenLocate.shared.performFetchWithCompletionHandler(completionHandler)
}
```

### Using user's location to query 3rd party Places APIs

To use user's current location, obtain the location by calling `fetchCurrentLocation` method on OpenLocate. Get the instance by calling `shared`. Use the fields collected by SDK to send to 3rd party APIs.

#### For example, to obtain user location:

```swift
try OpenLocate.shared.fetchCurrentLocation { location, error in
  if let location = location {
    fetchNearbyPlaces(location: location)
  } else {
    debugPrint(error.localizedDescription)
  }
}
```

#### For example, to query Google Places API using location:

Google Places API: https://developers.google.com/places/web-service/search

```swift

func fetchNearbyPlaces(location: OpenLocateLocation, completion: @escaping GooglePlacesCompletionHandler) {
        guard let coordinates = location.locationFields.coordinates else {
            completion(nil, GooglePlacesError.locationNotFound)
            return
        }

        let queryParams = [
            "location": "\(coordinates.latitude),\(coordinates.longitude)",
            "radius": "500",
            "type": "restaurant",
            "keyword": "south",
            "key": "<YOUR GOOGLE PLACES API KEY>"
            ] as [String : Any]

        Alamofire.request(
            "https://maps.googleapis.com/maps/api/place/nearbysearch/json",
            parameters: queryParams
        )
            .responseJSON { response in
                debugPrint(response)
                guard let json = response.result.value as? [String: Any],
                    let placesJson = json["places"] as? [Any], !placesJson.isEmpty else {
                    completion(nil, GooglePlacesError.placesNotFound)
                    return
                }

                var places = [GooglePlace]()
                for placeJson in placesJson {
                    let place = (placeJson as? [String: Any])!
                    places.append(GooglePlace(json: place))
                }

                completion(places, nil)
        }
    }

```

#### For example, to query Safegraph Places API using location:

SafeGraph Places API: https://partners.safegraph.com/places

```swift

func fetchNearbyPlaces(location: OpenLocateLocation, completion: @escaping SafePlacesCompletionHandler) {
        guard let coordinates = location.locationFields.coordinates else {
            completion(nil, SafeGraphError.locationNotFound)
            return
        }

        let queryParams = [
            "advertising_id": location.advertisingInfo.advertisingId,
            "advertising_id_type": "aaid",
            "latitude": coordinates.latitude,
            "longitude": coordinates.longitude,
            "horizontal_accuracy": location.locationFields.horizontalAccuracy
            ] as [String : Any]

        Alamofire.request(
            "https://api.safegraph.com/places/v1/nearby",
            parameters: queryParams,
            headers: ["Authorization": "Bearer <YOUR_TOKEN>"]
        )
            .responseJSON { response in
                debugPrint(response)
                guard let json = response.result.value as? [String: Any],
                    let placesJson = json["places"] as? [Any], !placesJson.isEmpty else {
                    completion(nil, SafeGraphError.placesNotFound)
                    return
                }

                var places = [SafeGraphPlace]()
                for placeJson in placesJson {
                    let place = (placeJson as? [String: Any])!
                    places.append(SafeGraphPlace(json: place))
                }

                completion(places, nil)
        }
    }

```

Similarly, OpenLocate SDK can be used to query additional APIs such as Facebook Places Graph or any other 3rd party places API.

- Facebook Places API - https://developers.facebook.com/docs/places/

#### Connecting user's location data to Wolfram Cloud for analytics using [Wolfram Data Drop](https://datadrop.wolframcloud.com/)

Data Drop is a service from Wolfram Research that makes it easy to collect data in a manner that proactively sets it up for computation, visualization, analysis, or other data processing operations. **Databins** store and add semantics to data while making it instantly accessible from all Wolfram Language and other systems through the Wolfram Cloud.

Once in a Databin, you can use Wolfram Language to create visualizations like the following, which were generated using UFO sighting location data from the [Wolfram Data Repository](https://datarepository.wolframcloud.com/):

<p align="center"><img src="https://www.wolframcloud.com/objects/q-partnerships/openlocate/geohistogram" alt="UFO Sightings GeoHistogram" align="center"></p>

<p align="center"><img src="https://www.wolframcloud.com/objects/q-partnerships/openlocate/geoplot" alt="UFO Sightings Plot" align="center"></p>

<p align="center"><img src="https://www.wolframcloud.com/objects/q-partnerships/openlocate/vertical-bar" alt="UFO Sightings Vertical Bar Chart" align="center"></p>

<p align="center"><img src="https://www.wolframcloud.com/objects/q-partnerships/openlocate/horizontal-bar" alt="UFO Sightings Horizontal Bar Chart" align="center"></p>

Refer to the [Data Drop Quick Reference](https://www.wolfram.com/datadrop/quick-reference/home/) to learn more.

To send user's location data to a databin via the Data Drop Web API:

```swift
func pushLocationToDataDrop(location: OpenLocateLocation) {
  Alamofire.request(
    "https://datadrop.wolframcloud.com/api/v1.0/Add?bin=<YOUR BIN ID>",
		method: .post,
    parameters: location.locationFields,
		encoding: JSONEncoding.default
  )
  .responseJSON { response in
    debugPrint(response)
  }
}
```

## Fields collected for request

| Fields | Type | Description | Flag to enable |
| ------ | ---- | ----------- | -------------- |
|ad_id|String|An alphanumeric string unique to each device, used only for serving advertisements. More [here](https://developer.apple.com/documentation/adsupport/asidentifiermanager).|CollectingFieldsConfiguration.shouldLogAdId|
|ad_opt_out|Boolean|A Boolean value that indicates whether the user has limited ad tracking. More [here](https://developer.apple.com/documentation/adsupport/asidentifiermanager).|CollectingFieldsConfiguration.shouldLogAdId|
|id_type|String|A string value that indicates which operating systen advertising info belongs to. 'idfa' for iOS devices|CollectingFieldsConfiguration.shouldLogAdId|
|latitude|Decimal|The latitude in degrees.|CollectingFieldsConfiguration.shouldLogLocation|
|longitude|Decimal|The longitude in degrees.|CollectingFieldsConfiguration.shouldLogLocation|
|utc_timestamp|Long|The time at which this location was determined.|CollectingFieldsConfiguration.shouldLogTimestamp|
|utc_timestamp_received|Long|The time at which this location update was delivered to the client. Location updates may come at a much later than time they were determined.||
|horizontal_accuracy|Float|The radius of uncertainty for the location, measured in meters.|CollectingFieldsConfiguration.shouldLogHorizontalAccuracy|
|veritcal_accuracy|Float|The accuracy of the altitude value, measured in meters.|CollectingFieldsConfiguration.shouldLogHorizontalAccuracy|
|altitude|Float|The altitude, measured in meters.|CollectingFieldsConfiguration.shouldLogAltitude|
|carrier_name|String|A string value representing the carrier name|CollectingFieldsConfiguration.shouldLogNetworkInfo|
|wifi_bssid|String|A string value representing the bssid of the wifi to which the device is connected to|CollectingFieldsConfiguration.shouldLogNetworkInfo|
|wifi_ssid|String|A string value representing the ssis of the wifi to which the device is connected to|CollectingFieldsConfiguration.shouldLogNetworkInfo|
|location_context|String|A string value representing the state of the location when it was collected. Possible value - `unknown`, `passive`, `regular`, `visit_entry`, `visit_exit`|CollectingFieldsConfiguration.shouldLogLocation|
|course|Float|The direction in which the device is traveling.|CollectingFieldsConfiguration.shouldLogDeviceCourse|
|speed|Float|The instantaneous speed of the device, measured in meters per second.|CollectingFieldsConfiguration.shouldLogDeviceSpeed|
|is_charging|Boolean|A boolean value to determine if the phone was charging when the location was determined|CollectingFieldsConfiguration.shouldLogDeviceCharging|
|device_model|String|A string value representing the model of the device|CollectingFieldsConfiguration.shouldLogDeviceModel|
|os_version|String|A String value representing the version of the operating system|CollectingFieldsConfiguration.shouldLogDeviceOsVersion|

### Sample Request Body

This is a sample request body sent by the SDK. 
```json
{
"locations":
	[
		{
			"ad_id": "12a451dd-3539-4092-b134-8cb0ef62ab8a",
			"ad_opt_out": true,
			"id_type": "idfa",
			"latitude": "37.773972",
			"longitude": "-122.431297",
			"utc_timestamp": "1508356559",
			"utc_timestamp_received": "1508356559",
			"horizontal_accuracy": 12.323,
			"vertical_accuracy": 5.3,
			"altitude": 0.456,
           		"carrier_name": "T Mobile",
			"wifi_ssid": "OpenLocate_Guest",
			"wifi_bssid": "OpenLocate_Guest",
			"location_context": "regular",
			"course": 175.0,
			"speed": 11.032,
			"is_charging": true,
			"device_model": "iPhone 7",
			"os_version": "iOS 11.0.3"
		},
		{
			"ad_id": "12a451dd-3539-4092-b134-8cb0ef62ab8a",
			"ad_opt_out": true,
			"id_type": "idfa",
			"latitude": "37.773972",
			"longitude": "-122.431297",
			"utc_timestamp": "1508356559",
			"utc_timestamp_received": "1508356581",
			"horizontal_accuracy": 12.323,
			"vertical_accuracy": 5.3,
			"altitude": 0.456,
           		"carrier_name": "T Mobile",
			"wifi_ssid": "OpenLocate_Guest",
			"wifi_bssid": "OpenLocate_Guest",
			"location_context": "regular",
			"course": 175.0,
			"speed": 11.032,
			"is_charging": true,
			"device_model": "iPhone 7",
			"os_version": "iOS 11.0.3"
		}
	]
}
```

If you want to have the SDK send data to your own AWS s3 environment for example, look into setting up an [Kinesis firehose](https://aws.amazon.com/kinesis/firehose/) according to the SDK request above.

## Location Permission Opt-In Best Practices

OpenLocate requires users to accept the iOS's Location Permission in order to work correctly. It is therefore important to understand when and how to prompt for the location permission in order to maximize opt-in rates from users. OpenLocate takes care of prompting the location permission for you when the `startTracking()` method is invoked. OpenLocate also takes care of remembering this started state across app launches, so you only need to invoke `startTracking()` once. You must decide  the optimal time to invoke `startTracking()` within your app however. Below are several articles that explain the different approaches that can be taken. Ensure you choose one that fits your app’s needs:
- https://medium.com/product-breakdown/5-ways-to-ask-users-for-ios-permissions-a8e199cc83ad
- https://uxplanet.org/mobile-ux-design-the-right-ways-to-ask-users-for-permissions-6cdd9ab25c27

## App Submission with OpenLocate
OpenLocate collects the advertising ID by default. If this is kept as-is, during the app submission process, please ensure that you disclose that you are collecting the advertising ID and the reason. This requires checking certain checkboxes under the section “Advertising Identifier” in the app store submission form; we recommend checking at least the following options, but you may want to check others depending on your app’s specific usage of the advertising ID.
* Attribute this app installation to a previously served advertisement
* Attribute an action taken within this app to a previously served advertisement
* Limit Ad Tracking pledge: i.e. that the limit ad tracking setting will be honoured appropriately (see app submission form for more details)

## Communication

- If you **need help**, post a question to the [discussion forum](https://groups.google.com/a/openlocate.org/d/forum/openlocate), or tag a question with 'OpenLocate' on [Stack Overflow](https://stackoverflow.com).
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.
