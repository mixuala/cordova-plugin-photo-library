[![Build Status](https://travis-ci.org/terikon/cordova-plugin-photo-library.svg?branch=master)](https://travis-ci.org/terikon/cordova-plugin-photo-library)

Known issues:
- This plugin does not work with WKWebView. Please do not use it if you planning to switch to WKWebView, until someone will resolve this issue.

That's how it looks and performs in real app:

[![](https://img.youtube.com/vi/qHnnRsZ7klE/0.jpg)](https://www.youtube.com/watch?v=qHnnRsZ7klE)

Demo projects (runnable online):

- [For jQuery](https://github.com/terikon/photo-library-demo-jquery)
- [For Ionic 2](https://github.com/terikon/photo-library-demo-ionic2)
- [Vanilla JS with PhotoSwipe](https://github.com/terikon/photo-library-demo-photoswipe)

Displays photo library on cordova's HTML page, by URL. Gets thumbnail of arbitrary sizes, works on multiple platforms, and is fast.

- Displays photo gallery as web page, and not as boring native screen which you cannot modify. This brings back control over your app to you.
For example, you can use [PhotoSwipe](https://github.com/dimsemenov/photoswipe) library to present photos.
- Provides custom schema to access thumbnails: cdvphotolibrary://thumbnail?fileid=xxx&width=128&height=128&quality=0.5 .
- Works on Android, iOS and browser (cordova serve).
- Fast - uses browser cache.
- Can save photos (jpg, png, animated gifs) and videos to specified album on device.
- Handles permissions.
- Handles images [EXIF rotation hell](http://www.daveperrett.com/articles/2012/07/28/exif-orientation-handling-is-a-ghetto/).
- On iOS, written in Swift and not Objective-C.

**Co-maintainer needed**

Currently Android code is pretty stable, iOS has few stability [issues](https://github.com/terikon/cordova-plugin-photo-library/issues).
**Co-maintainer with iOS/Swift knowlege is needed, please [contact](https://github.com/viskin)**.

Contributions are welcome.
Please add only features that can be supported on both Android and iOS.
Please write tests for your contribution.

# Install

    cordova plugin add cordova-plugin-photo-library --variable PHOTO_LIBRARY_USAGE_DESCRIPTION="To choose photos" --save

# Usage

Add cdvphotolibrary protocol to Content-Security-Policy, like this:

```
<meta http-equiv="Content-Security-Policy" content="default-src 'self' 'unsafe-inline' 'unsafe-eval' data: gap: ws: https://ssl.gstatic.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob: cdvphotolibrary:">
```

For remarks about angular/ionic usage, see below.

## Mappi extensions

The following extensions were added, mostly to support extended functionality on `platform=ios`.

### Added extended attributes for `platform=ios`:

```js
export interface IosLibraryItem extends LibraryItem {
    orientation?: number;
    "{Exif}"?: any;
    "{GPS}"?: any;
    "{TIFF}"?: any;
    speed?: number;
    isFavorite?: boolean;
    burstIdentifier?: string;
    representsBurst?: boolean;
    duration?: number;
  }
```

```js
// example output from the ios simulator
const data:LibraryItem = {
  "id": "CC95F08C-88C3-4012-9D6D-64A413D254B3/L0/001",
  "speed": 0.5513811087502415,
  "fileName": "IMG_0006.HEIC",
  "orientation": 3,
  "{Exif}": {
    "DateTimeOriginal": "2018:03:30 12:14:19",
    "MeteringMode": 5,
    "ComponentsConfiguration": [
      1,
      2,
      3,
      0
    ],
    "BrightnessValue": 8.455294117647059,
    "FocalLenIn35mmFilm": 52,
    "LensMake": "Apple",
    "FNumber": 2.4,
    "FocalLength": 6,
    "ShutterSpeedValue": 7.704253214638971,
    "SubjectArea": [
      2007,
      1503,
      2209,
      1327
    ],
    "ApertureValue": 2.5260688216892597,
    "SceneType": 1,
    "SceneCaptureType": 0,
    "ColorSpace": 65535,
    "LensModel": "iPhone X back dual camera 6mm f/2.4",
    "LensSpecification": [
      4,
      6,
      1.7999999523162842,
      2.4000000953674316
    ],
    "PixelYDimension": 3024,
    "WhiteBalance": 0,
    "FlashPixVersion": [
      1,
      0
    ],
    "DateTimeDigitized": "2018:03:30 12:14:19",
    "ISOSpeedRatings": [
      16
    ],
    "ExposureMode": 0,
    "ExifVersion": [
      2,
      2,
      1
    ],
    "PixelXDimension": 4032,
    "CustomRendered": 2,
    "ExposureProgram": 2,
    "ExposureTime": 0.004784688995215311,
    "SubsecTimeDigitized": "365",
    "Flash": 16,
    "SubsecTimeOriginal": "365",
    "SensingMethod": 2,
    "ExposureBiasValue": 0
  },
  "isFavorite": false,
  "mimeType": "image/heic",
  "longitude": -122.50956666666667,
  "width": 4032,
  "latitude": 37.76007833333333,
  "{GPS}": {
    "ImgDirection": 62.766961651917406,
    "LatitudeRef": "N",
    "HPositioningError": 6.00090661831369,
    "DestBearingRef": "M",
    "Latitude": 37.76007833333333,
    "Speed": 0.5513811087502415,
    "TimeStamp": "19:14:18",
    "LongitudeRef": "W",
    "AltitudeRef": 0,
    "Longitude": 122.50956666666667,
    "Altitude": 4.583391486392184,
    "DateStamp": "2018:03:30",
    "DestBearing": 62.766961651917406,
    "ImgDirectionRef": "M",
    "SpeedRef": "K"
  },
  "{TIFF}": {
    "ResolutionUnit": 2,
    "Software": "12.0",
    "TileLength": 512,
    "DateTime": "2018:03:30 12:14:19",
    "XResolution": 72,
    "TileWidth": 512,
    "Orientation": 3,
    "YResolution": 72,
    "Model": "iPhone X",
    "Make": "Apple"
  },
  "representsBurst": false,
  "height": 3024,
  "filePath": "/Users/username/Library/Developer/CoreSimulator/Devices/A5CF5DA3-346A-46B8-B892-D4696F66B276/data/Media/DCIM/100APPLE/IMG_0006.HEIC",
  "duration": 0,
  "creationDate": "2018-03-30T19:14:19.365Z",
  "thumbnailURL": "cdvphotolibrary://thumbnail?photoId=CC95F08C-88C3-4012-9D6D-64A413D254B3%2FL0%2F001&width=80&height=80&quality=0.5",
  "photoURL": "cdvphotolibrary://photo?photoId=CC95F08C-88C3-4012-9D6D-64A413D254B3%2FL0%2F001"
}
```

### Get `PHAssetCollectionType.moment` from library

```js
cordova.plugins.photoLibrary.getMoments(
  success: (result: AlbumItem[]) => void, 
  error: (err:any) => void, 
  options?:GetMomentsOptions
): void;

// example output from the ios simulator
const data:AlbumItem = {
  "id": "ACBADA72-0E97-4AE0-AA81-4CEEEA9191DC/L0/060",
  "title": "San Francisco, CA",
  "startDate": "2018-03-31T03:14:19.365+08:00",
  "endDate": "2018-03-31T03:14:19.365+08:00",
  "locations": "Great Hwy",
  "itemIds": [
    "CC95F08C-88C3-4012-9D6D-64A413D254B3/L0/001"
  ],
  "loc": [
    37.76007833333333,
    122.50956666666661
  ],
  "label": "San Francisco, CA",
  "begins": "Sat Mar 31 2018",
  "days": 0,
  "count": 1
}
```

### Auto-rotate images from library using Orientation patch

auto-rotate images from `getPhoto()` or `getThumbnail()`

> see: https://github.com/terikon/cordova-plugin-photo-library/issues/146#issuecomment-427540942


### Add support for queryparam `dataURL=true`

```js
// example url
const url:string = `cdvphotolibrary://thumbnail?photoId=CC95F08C-88C3-4012-9D6D-64A413D254B3%2FL0%2F001&width=80&height=80&quality=0.5&dataURL=true`
```




## Displaying photos

```js
cordova.plugins.photoLibrary.getLibrary(
  function (result) {
    var library = result.library;
    // Here we have the library as array

    library.forEach(function(libraryItem) {
      console.log(libraryItem.id);          // ID of the photo
      console.log(libraryItem.photoURL);    // Cross-platform access to photo
      console.log(libraryItem.thumbnailURL);// Cross-platform access to thumbnail
      console.log(libraryItem.fileName);
      console.log(libraryItem.width);
      console.log(libraryItem.height);
      console.log(libraryItem.creationDate);
      console.log(libraryItem.latitude);
      console.log(libraryItem.longitude);
      console.log(libraryItem.albumIds);    // array of ids of appropriate AlbumItem, only of includeAlbumsData was used
    });

  },
  function (err) {
    console.log('Error occured');
  },
  { // optional options
    thumbnailWidth: 512,
    thumbnailHeight: 384,
    quality: 0.8,
    includeAlbumData: false // default
  }
);
```

This method is fast, as thumbails will be generated on demand.

## Getting albums

```js
cordova.plugins.photoLibrary.getAlbums(
  function (albums) {
    albums.forEach(function(album) {
      console.log(album.id);
      console.log(album.title);
    });
  }, 
  function (err) { }
);
```

## Saving photos and videos

``` js
var url = 'file:///...'; // file or remote URL. url can also be dataURL, but giving it a file path is much faster
var album = 'MyAppName';
cordova.plugins.photoLibrary.saveImage(url, album, function (libraryItem) {}, function (err) {});
```

```js
// iOS quirks: video provided cannot be .webm . Use .mov or .mp4 .
cordova.plugins.photoLibrary.saveVideo(url, album, function () {}, function (err) {});
```

saveImage and saveVideo both need write permission to be granted by requestAuthorization.

## Permissions

The library handles tricky parts of aquiring permissions to photo library.

If any of methods fail because lack of permissions, error string will be returned that begins with 'Permission'. So, to process on aquiring permissions, do the following:
```js
cordova.plugins.photoLibrary.getLibrary(
  function ({library}) { },
  function (err) {
    if (err.startsWith('Permission')) {
      // call requestAuthorization, and retry
    }
    // Handle error - it's not permission-related
  }
);
```

requestAuthorization is cross-platform method, that works in following way:

- On android, will ask user to allow access to storage
- On ios, on first call will open permission prompt. If user denies it subsequent calls will open setting page of your app, where user should enable access to Photos.

```js
cordova.plugins.photoLibrary.requestAuthorization(
  function () {
    // User gave us permission to his library, retry reading it!
  },
  function (err) {
    // User denied the access
  }, // if options not provided, defaults to {read: true}.
  {
    read: true,
    write: true
  }
);
```

Read permission is added for your app by the plugin automatically. To make writing possible, add following to your config.xml:
```xml
<platform name="android">
  <config-file target="AndroidManifest.xml" parent="/*">
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
  </config-file>
</platform>
```

## Chunked output

```js
cordova.plugins.photoLibrary.getLibrary(
  function (result) {
    var library = result.library;
    var isLastChunk = result.isLastChunk;
  },
  function (err) { },
  {
    itemsInChunk: 100, // Loading large library takes time, so output can be chunked so that result callback will be called on
    chunkTimeSec: 0.5, // each X items, or after Y secons passes. You can start displaying photos immediately.
    useOriginalFileNames: false, // default, true will be much slower on iOS
    maxItems: 200, // limit the number of items to return
  }
);
```

## In addition you can ask thumbnail or full image for each photo separately, as cross-platform url or as blob

```js
// Use this method to get url. It's better to use it and not directly access cdvphotolibrary://, as it will also work on browser.
cordova.plugins.photoLibrary.getThumbnailURL(
  libraryItem, // or libraryItem.id
  function (thumbnailURL) {

    image.src = thumbnailURL;

  },
  function (err) {
    console.log('Error occured');
  },
  { // optional options
    thumbnailWidth: 512,
    thumbnailHeight: 384,
    quality: 0.8
  });
```

```js
cordova.plugins.photoLibrary.getPhotoURL(
  libraryItem, // or libraryItem.id
  function (photoURL) {

    image.src = photoURL;

  },
  function (err) {
    console.log('Error occured');
  });
```

```js
// This method is slower as it does base64
cordova.plugins.photoLibrary.getThumbnail(
  libraryItem, // or libraryItem.id
  function (thumbnailBlob) {

  },
  function (err) {
    console.log('Error occured');
  },
  { // optional options
    thumbnailWidth: 512,
    thumbnailHeight: 384,
    quality: 0.8
  });
```

```js
// This method is slower as it does base64
cordova.plugins.photoLibrary.getPhoto(
  libraryItem, // or libraryItem.id
  function (fullPhotoBlob) {

  },
  function (err) {
    console.log('Error occured');
  });
```

# ionic / angular

It's best to use from [ionic-native](https://ionicframework.com/docs/v2/native/photo-library). The the docs.

As mentioned [here](https://github.com/terikon/cordova-plugin-photo-library/issues/15) by dnmd, cdvphotolibrary urls should bypass sanitization to work.

In angular2, do following:

Define Pipe that will tell to bypass trusted urls. cdvphotolibrary urls should be trusted:

```js
// cdvphotolibrary.pipe.ts
import { Pipe, PipeTransform } from '@angular/core';
import { DomSanitizer } from '@angular/platform-browser';

@Pipe({name: 'cdvphotolibrary'})
export class CDVPhotoLibraryPipe implements PipeTransform {

  constructor(private sanitizer: DomSanitizer) {}

  transform(url: string) {
    return url.startsWith('cdvphotolibrary://') ? this.sanitizer.bypassSecurityTrustUrl(url) : url;
  }
}
```

Register the pipe in your module:

```js
import { CDVPhotoLibraryPipe } from './cdvphotolibrary.pipe.ts';

@NgModule({
  declarations: [
    CDVPhotoLibraryPipe,
    // ...
  ],
})
```

Then in your component, use cdvphotolibrary urls applying the cdvphotolibrary pipe:

```js
@Component({
   selector: 'app',
   template: '<img [src]="url | cdvphotolibrary">'
})

export class AppComponent {
    public url: string = 'placeholder.jpg';
    constructor() {
      // fetch thumbnail URL's
      this.url = libraryItem.thumbnailURL;
    }
}
```

If you use angular1, you need to add cdvphotolibrary to whitelist:

```js
var app = angular
  .module('myApp', [])
  .config([
    '$compileProvider',
    function ($compileProvider) {
		$compileProvider.imgSrcSanitizationWhitelist(/^\s*(https?|cdvphotolibrary):/);
		//Angular 1.2 and above has two sanitization methods, one for links (aHrefSanitizationWhitelist) and 
		//one for images (imgSrcSanitizationWhitelist). Versions prior to 1.2 use $compileProvider.urlSanitizationWhitelist(...)
    }
  ]);
```

# TypeScript

TypeScript definitions are provided in [PhotoLibrary.d.ts](https://github.com/terikon/cordova-plugin-photo-library/blob/master/PhotoLibrary.d.ts)

# Tests

The library includes tests in [tests](https://github.com/terikon/cordova-plugin-photo-library/tree/master/tests) folder. All tests are in
[tests.js](https://github.com/terikon/cordova-plugin-photo-library/blob/master/tests/tests.js) file.

# Running tests

## Travis

tcc.db file is located at $HOME/Library/Developer/CoreSimulator/Devices/$DEVICEID/data/Library/TCC/TCC.db

## Helper app

To run tests, use [special photo-library-tester](https://github.com/terikon/photo-library-tester).
It's always useful to run these tests before submitting changes, for each platform (android, ios, browser).

# TODO

- [#38](https://github.com/terikon/cordova-plugin-photo-library/issues/38) browser platform: saveImage and saveVideo should download file.
- Improve documentation.
- Provide cancellation mechanism for long-running operations, like getLibrary.
- CI.

# Optional enchancements

- iOS: it seems regex causes slowdown with dataURL, and (possibly) uses too much memory - check how to do regex on iOS in better way.
- Browser platform: Separate to multiple files.
- Android: caching mechanism like [this one](https://developer.android.com/training/displaying-bitmaps/cache-bitmap.html) can be helpful.
- Implement save protocol with HTTP POST, so no base64 transformation will be needed for saving.
- EXIF rotation hell is not handled on browser platform.
- Pre-fetching data to file-based cache on app start can improve responsiveness. Just this caching should occur as low-priority thread. Cache can be updated
by system photo libraries events.

# References

Parts are based on

- https://github.com/subitolabs/cordova-gallery-api
- https://github.com/SuryaL/cordova-gallery-api
- https://github.com/ryouaki/Cordova-Plugin-Photos
- https://github.com/devgeeks/Canvas2ImagePlugin
