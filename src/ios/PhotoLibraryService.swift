import Photos
import Foundation
import AssetsLibrary // TODO: needed for deprecated functionality
import MobileCoreServices

extension PHAsset {

    // Returns original file name, useful for photos synced with iTunes
    var originalFileName: String? {
        var result: String?

        // This technique is slow
        if #available(iOS 9.0, *) {
            let resources = PHAssetResource.assetResources(for: self)
            if let resource = resources.first {
                result = resource.originalFilename
            }
        }

        return result
    }

    var fileName: String? {
        return self.value(forKey: "filename") as? String
    }

}

// see: https://github.com/terikon/cordova-plugin-photo-library/issues/146
extension UIImage {
    
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        var transform: CGAffineTransform = CGAffineTransform.identity
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(Double.pi ))
            break
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
            break
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat(-Double.pi / 2))
            break
        case .up, .upMirrored:
            break
        }
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case .leftMirrored, .rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        }
        let ctx: CGContext = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0, space: (self.cgImage?.colorSpace)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.concatenate(transform)
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
            break
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        let cgImage: CGImage = ctx.makeImage()!
        return UIImage(cgImage: cgImage)
    }
}

final class PhotoLibraryService {

    let fetchOptions: PHFetchOptions!
    let thumbnailRequestOptions: PHImageRequestOptions!
    let imageRequestOptions: PHImageRequestOptions!
    let dateFormatter: DateFormatter!
    let cachingImageManager: PHCachingImageManager!

    let contentMode = PHImageContentMode.aspectFill // AspectFit: can be smaller, AspectFill - can be larger. TODO: resize to exact size

    var cacheActive = false

    let mimeTypes = [
        "flv":  "video/x-flv",
        "mp4":  "video/mp4",
        "m3u8":	"application/x-mpegURL",
        "ts":   "video/MP2T",
        "3gp":	"video/3gpp",
        "mov":	"video/quicktime",
        "avi":	"video/x-msvideo",
        "wmv":	"video/x-ms-wmv",
        "gif":  "image/gif",
        "jpg":  "image/jpeg",
        "jpeg": "image/jpeg",
        "png":  "image/png",
        "tiff": "image/tiff",
        "tif":  "image/tiff"
    ]

    static let PERMISSION_ERROR = "Permission Denial: This application is not allowed to access Photo data."

    let dataURLPattern = try! NSRegularExpression(pattern: "^data:.+?;base64,", options: NSRegularExpression.Options(rawValue: 0))

    let assetCollectionTypes = [PHAssetCollectionType.album, PHAssetCollectionType.smartAlbum/*, PHAssetCollectionType.moment*/]

    fileprivate init() {
        fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        //fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        if #available(iOS 9.0, *) {
            fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
        }

        thumbnailRequestOptions = PHImageRequestOptions()
        thumbnailRequestOptions.isSynchronous = false
        thumbnailRequestOptions.resizeMode = .exact
        thumbnailRequestOptions.deliveryMode = .highQualityFormat
        thumbnailRequestOptions.version = .current
        thumbnailRequestOptions.isNetworkAccessAllowed = false

        imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isSynchronous = false
        imageRequestOptions.resizeMode = .exact
        imageRequestOptions.deliveryMode = .highQualityFormat
        imageRequestOptions.version = .current
        imageRequestOptions.isNetworkAccessAllowed = false

        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

        cachingImageManager = PHCachingImageManager()
    }

    class var instance: PhotoLibraryService {

        struct SingletonWrapper {
            static let singleton = PhotoLibraryService()
        }

        return SingletonWrapper.singleton

    }

    static func hasPermission() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized

    }

    func getLibrary(_ options: PhotoLibraryGetLibraryOptions, completion: @escaping (_ result: [NSDictionary], _ chunkNum: Int, _ isLastChunk: Bool) -> Void) {

        if(options.includeCloudData == false) {
            if #available(iOS 9.0, *) {
                // remove iCloud source type
                fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced]
            }
        }

        // let fetchResult = PHAsset.fetchAssets(with: .image, options: self.fetchOptions)
        if(options.includeImages == true && options.includeVideos == true) {
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d",
                                                 PHAssetMediaType.image.rawValue,
                                                 PHAssetMediaType.video.rawValue)
        }
        else {
            if(options.includeImages == true) {
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d",
                                                     PHAssetMediaType.image.rawValue)
            }
            else if(options.includeVideos == true) {
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d",
                                                     PHAssetMediaType.video.rawValue)
            }
        }

        if options.maxItems > 0 {
            fetchOptions.fetchLimit = options.maxItems;
        }

        /**
         * TODO: add fetch by dateRange, fetch by most_recent, and skip n records
         */
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)

        /**
         * TODO: add PHAsset.fetchAssetsByIds to get LibraryItems from an Album
         */



	// TODO: do not restart caching on multiple calls
//        if fetchResult.count > 0 {
//
//            var assets = [PHAsset]()
//            fetchResult.enumerateObjects({(asset, index, stop) in
//                assets.append(asset)
//            })
//
//            self.stopCaching()
//            self.cachingImageManager.startCachingImages(for: assets, targetSize: CGSize(width: options.thumbnailWidth, height: options.thumbnailHeight), contentMode: self.contentMode, options: self.imageRequestOptions)
//            self.cacheActive = true
//        }

        var chunk = [NSDictionary]()
        var chunkStartTime = NSDate()
        var chunkNum = 0

        fetchResult.enumerateObjects({ (asset: PHAsset, index, stop) in

            if (options.maxItems > 0 && index + 1 > options.maxItems) {
                completion(chunk, chunkNum, true)
                return
            }

            let libraryItem = self.assetToLibraryItem(asset: asset, useOriginalFileNames: options.useOriginalFileNames, includeAlbumData: options.includeAlbumData)

            chunk.append(libraryItem)

            self.getCompleteInfo(libraryItem, completion: { (fullPath) in

                libraryItem["filePath"] = fullPath

                if index == fetchResult.count - 1 { // Last item
                    completion(chunk, chunkNum, true)
                } else if (options.itemsInChunk > 0 && chunk.count == options.itemsInChunk) ||
                    (options.chunkTimeSec > 0 && abs(chunkStartTime.timeIntervalSinceNow) >= options.chunkTimeSec) {
                    completion(chunk, chunkNum, false)
                    chunkNum += 1
                    chunk = [NSDictionary]()
                    chunkStartTime = NSDate()
                }
            })
        })
    }



    func mimeTypeForPath(path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension

        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
    
    
    func getCompleteInfo(_ libraryItem: NSMutableDictionary, completion: @escaping (_ fullPath: String?) -> Void) {
        
        
        let ident = libraryItem.object(forKey: "id") as! String
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [ident], options: self.fetchOptions)
        if fetchResult.count == 0 {
            completion(nil)
            return
        }

        let mime_type = libraryItem.object(forKey: "mimeType") as! String
        let mediaType = mime_type.components(separatedBy: "/").first


        fetchResult.enumerateObjects({
            (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            let asset = obj as! PHAsset

            if(mediaType == "image") {
                PHImageManager.default().requestImageData(for: asset, options: self.imageRequestOptions) {
                    (imageData: Data?, dataUTI: String?, orientation: UIImage.Orientation, info: [AnyHashable: Any]?) in

                    if(imageData == nil) {
                        completion(nil)
                    }
                    else {
                        // https://stackoverflow.com/questions/45277034/get-exif-metadata-in-of-captured-image-in-swift3
                        let imageNSData: NSData = imageData! as NSData
                        if let imageSource = CGImageSourceCreateWithData(imageNSData, nil) {
                            let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)! as NSDictionary
                            libraryItem["orientation"] = metadata["Orientation"]
                            libraryItem["{Exif}"] = metadata["{Exif}"]
                            libraryItem["{GPS}"] = metadata["{GPS}"]
                            libraryItem["{TIFF}"] = metadata["{TIFF}"]
                            // print("metadata: ", libraryItem)
                        }
                        


                        let file_url:URL = info!["PHImageFileURLKey"] as! URL
//                        let mime_type = self.mimeTypes[file_url.pathExtension.lowercased()]!
                        completion(file_url.relativePath)
                    }
                }
            }
            else if(mediaType == "video") {

                PHImageManager.default().requestAVAsset(forVideo: asset, options: nil, resultHandler: { (avAsset: AVAsset?, avAudioMix: AVAudioMix?, info: [AnyHashable : Any]?) in

                    if( avAsset is AVURLAsset ) {
                        let video_asset = avAsset as! AVURLAsset
                        let url = URL(fileURLWithPath: video_asset.url.relativePath)
                        completion(url.relativePath)
                    }
                    else if(avAsset is AVComposition) {
                        let token = info?["PHImageFileSandboxExtensionTokenKey"] as! String
                        let path = token.components(separatedBy: ";").last
                        completion(path)
                    }
                })
            }
            else if(mediaType == "audio") {
                // TODO:
                completion(nil)
            }
            else {
                completion(nil) // unknown
            }
        })
    }


    private func assetToLibraryItem(asset: PHAsset, useOriginalFileNames: Bool, includeAlbumData: Bool) -> NSMutableDictionary {
        let libraryItem = NSMutableDictionary()

        libraryItem["id"] = asset.localIdentifier
        libraryItem["fileName"] = useOriginalFileNames ? asset.originalFileName : asset.fileName // originalFilename is much slower
        libraryItem["width"] = asset.pixelWidth
        libraryItem["height"] = asset.pixelHeight

        let fname = libraryItem["fileName"] as! String
        libraryItem["mimeType"] = self.mimeTypeForPath(path: fname)

        libraryItem["creationDate"] = self.dateFormatter.string(from: asset.creationDate!)
        if let location = asset.location {
            libraryItem["latitude"] = location.coordinate.latitude
            libraryItem["longitude"] = location.coordinate.longitude
            // extras
            libraryItem["speed"] = location.speed
        }

        // extras
        libraryItem["isFavorite"] = asset.isFavorite
        libraryItem["burstIdentifier"] = asset.burstIdentifier
        libraryItem["representsBurst"] = asset.representsBurst
        libraryItem["duration"] = asset.duration

        
        
        if includeAlbumData {
            // This is pretty slow, use only when needed
            var assetCollectionIds = [String]()
            for assetCollectionType in self.assetCollectionTypes {
                let albumsOfAsset = PHAssetCollection.fetchAssetCollectionsContaining(asset, with: assetCollectionType, options: nil)
                albumsOfAsset.enumerateObjects({ (assetCollection: PHAssetCollection, index, stop) in
                    assetCollectionIds.append(assetCollection.localIdentifier)
                })
            }
            libraryItem["albumIds"] = assetCollectionIds
        }

        return libraryItem
    }

    func getAlbums() -> [NSDictionary] {

        var result = [NSDictionary]()

        for assetCollectionType in assetCollectionTypes {

            let fetchResult = PHAssetCollection.fetchAssetCollections(with: assetCollectionType, subtype: .any, options: nil)

            fetchResult.enumerateObjects({ (assetCollection: PHAssetCollection, index, stop) in

                let albumItem = NSMutableDictionary()

                albumItem["id"] = assetCollection.localIdentifier
                albumItem["title"] = assetCollection.localizedTitle

                result.append(albumItem)

            });

        }

        return result;

    }

    func getMoments(fromDate: Date? = nil, toDate: Date? = nil) -> [NSDictionary] {
        
        var result = [NSDictionary]()
        
        for assetCollectionType in [PHAssetCollectionType.moment] {

            let fetchResult = PHAssetCollection.fetchAssetCollections(with: assetCollectionType, subtype: .any, options: nil)
            
            fetchResult.enumerateObjects({ (assetCollection: PHAssetCollection, index, stop) in
                let albumItem = NSMutableDictionary()
                // filter by date range

                // filter by date range
                if fromDate != nil {
                    guard let startDate = assetCollection.startDate, fromDate!.compare(startDate) != ComparisonResult.orderedDescending
                        else {
                            return
                    }
                }
                if toDate != nil {
                    guard let endDate = assetCollection.endDate, toDate!.compare(endDate) != ComparisonResult.orderedAscending
                        else {
                            return
                    }
                }

                guard assetCollection.localizedLocationNames.count > 0 else {
                    return
                }    
                                
                albumItem["id"] = assetCollection.localIdentifier
                albumItem["title"] = assetCollection.localizedTitle

                // additions
                albumItem["locations"] = assetCollection.localizedLocationNames.joined(separator: ", ")
                albumItem["startDate"] = self.dateFormatter.string(from: assetCollection.startDate!)
                albumItem["endDate"] = self.dateFormatter.string(from: assetCollection.endDate!)


                // get PHAsset ids in moment
                var assetIds = [String]()            
                let assetOptions = PHFetchOptions()
                assetOptions.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
                let assets = PHAsset.fetchAssets(in: assetCollection, options: assetOptions)
                assets.enumerateObjects({ (asset: PHAsset, index, stop) in
                    assetIds.append(asset.localIdentifier)
                })
                albumItem["itemIds"] = assetIds

                result.append(albumItem)
                
            });
            
        }
        
        return result;
        
    }

    // // https://stackoverflow.com/questions/32041420/cropping-image-with-swift-and-put-it-on-center-position
    // // TODO: width/height must be adjusted for Orientation
    // // currently using: contentMode = PHImageContentMode.aspectFill 
    // func centerCropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {

    //     let contextImage: UIImage = UIImage(cgImage: image.cgImage!)

    //     let contextSize: CGSize = contextImage.size

    //     var posX: CGFloat = 0.0
    //     var posY: CGFloat = 0.0
    //     var cgwidth: CGFloat = CGFloat(width)
    //     var cgheight: CGFloat = CGFloat(height)

    //     // See what size is longer and create the center off of that
    //     if contextSize.width > contextSize.height {
    //         posX = ((contextSize.width - contextSize.height) / 2)
    //         posY = 0
    //         cgwidth = contextSize.height
    //         cgheight = contextSize.height
    //     } else {
    //         posX = 0
    //         posY = ((contextSize.height - contextSize.width) / 2)
    //         cgwidth = contextSize.width
    //         cgheight = contextSize.width
    //     }

    //     let rect: CGRect = CGRectMake(posX, posY, cgwidth, cgheight)

    //     // Create bitmap image from context using the rect
    //     let imageRef: CGImageRef = CGImageCreateWithImageInRect(contextImage.CGImage, rect)

    //     // Create a new image based on the imageRef and rotate back to the original orientation
    //     let image: UIImage = UIImage(CGImage: imageRef, scale: image.scale, orientation: image.imageOrientation)!

    //     return image
    // }
    
    func getThumbnail(_ photoId: String, thumbnailWidth: Int, thumbnailHeight: Int, quality: Float, dataURL:Bool, completion: @escaping (_ result: PictureData?) -> Void) {

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photoId], options: self.fetchOptions)

        if fetchResult.count == 0 {
            completion(nil)
            return
        }

        fetchResult.enumerateObjects({
            (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in

            let asset = obj as! PHAsset

            /*
             * targetSize and options.normalizedCropRect, or scale in js and provide exact size.  
             * TODO: check if 80x80 square targetSize crops from middle or topLeft
             *  https://developer.apple.com/documentation/photokit/phimagerequestoptionsresizemode
             *  https://developer.apple.com/documentation/photokit/phimagerequestoptions/1616952-normalizedcroprect
             *  https://stackoverflow.com/questions/32041420/cropping-image-with-swift-and-put-it-on-center-position
            */

            self.cachingImageManager.requestImage(for: asset, targetSize: CGSize(width: thumbnailWidth, height: thumbnailHeight), contentMode: self.contentMode, options: self.thumbnailRequestOptions) {
                (image: UIImage?, imageInfo: [AnyHashable: Any]?) in

                // TODO: confirm auto-rotate is working properly
                guard let image = image else {
                    completion(nil)
                    return
                }

                //TODO: may need to adjust targetSize BEFORE calling fixedOrientation()
                var imageData = PhotoLibraryService.image2PictureData(image.fixedOrientation(), quality: quality)
                // if dataURL {
                //     let base64data = imageData!.data?.base64EncodedString(options: .lineLength64Characters)
                //     imageData = PictureData(data: imageData!.data, dataURL: base64data, mimeType: imageData!.mimeType)
                // }
                completion(imageData)
            }
        })

    }

    func getPhoto(_ photoId: String, completion: @escaping (_ result: PictureData?) -> Void) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photoId], options: self.fetchOptions)
        if fetchResult.count == 0 {
            completion(nil)
            return
        }
        fetchResult.enumerateObjects({
            (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in

            let asset = obj as! PHAsset

            PHImageManager.default().requestImageData(for: asset, options: self.imageRequestOptions) {
                (imageData: Data?, dataUTI: String?, orientation: UIImage.Orientation, info: [AnyHashable: Any]?) in
                
                guard let image = imageData != nil ? UIImage(data: imageData!) : nil else {
                    completion(nil)
                    return
                }
                
                let imageData = PhotoLibraryService.image2PictureData(image.fixedOrientation(), quality: 1.0)
                completion(imageData)
            }
        })
    }


    func getLibraryItem(_ itemId: String, mimeType: String, completion: @escaping (_ base64: String?) -> Void) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [itemId], options: self.fetchOptions)
        if fetchResult.count == 0 {
            completion(nil)
            return
        }

        // TODO: data should be returned as chunks, even for pics.
        // a massive data object might increase RAM usage too much, and iOS will then kill the app.
        fetchResult.enumerateObjects({
            (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            let asset = obj as! PHAsset

            let mediaType = mimeType.components(separatedBy: "/")[0]

            if(mediaType == "image") {
                PHImageManager.default().requestImageData(for: asset, options: self.imageRequestOptions) {
                    (imageData: Data?, dataUTI: String?, orientation: UIImage.Orientation, info: [AnyHashable: Any]?) in

                    if(imageData == nil) {
                        completion(nil)
                    }
                    else {
//                        let file_url:URL = info!["PHImageFileURLKey"] as! URL
//                        let mime_type = self.mimeTypes[file_url.pathExtension.lowercased()]
                        completion(imageData!.base64EncodedString())
                    }
                }
            }
            else if(mediaType == "video") {

                PHImageManager.default().requestAVAsset(forVideo: asset, options: nil, resultHandler: { (avAsset: AVAsset?, avAudioMix: AVAudioMix?, info: [AnyHashable : Any]?) in

                    let video_asset = avAsset as! AVURLAsset
                    let url = URL(fileURLWithPath: video_asset.url.relativePath)

                    do {
                        let video_data = try Data(contentsOf: url)
                        let video_base64 = video_data.base64EncodedString()
//                        let mime_type = self.mimeTypes[url.pathExtension.lowercased()]
                        completion(video_base64)
                    }
                    catch _ {
                        completion(nil)
                    }
                })
            }
            else if(mediaType == "audio") {
                // TODO:
                completion(nil)
            }
            else {
                completion(nil) // unknown
            }

        })
    }


    func getVideo(_ videoId: String, completion: @escaping (_ result: PictureData?) -> Void) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [videoId], options: self.fetchOptions)
        if fetchResult.count == 0 {
            completion(nil)
            return
        }

        fetchResult.enumerateObjects({
            (obj: AnyObject, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in

            let asset = obj as! PHAsset


            PHImageManager.default().requestAVAsset(forVideo: asset, options: nil, resultHandler: { (avAsset: AVAsset?, avAudioMix: AVAudioMix?, info: [AnyHashable : Any]?) in

                let video_asset = avAsset as! AVURLAsset
                let url = URL(fileURLWithPath: video_asset.url.relativePath)

                do {
                    let video_data = try Data(contentsOf: url)
                    let pic_data = PictureData(data: video_data, mimeType: "video/quicktime") // TODO: get mime from info dic ?
                    // let pic_data = PictureData(data: video_data, dataURL:nil, mimeType: "video/quicktime") // TODO: get mime from info dic ?
                    completion(pic_data)
                }
                catch _ {
                    completion(nil)
                }
            })
        })
    }


    func stopCaching() {

        if self.cacheActive {
            self.cachingImageManager.stopCachingImagesForAllAssets()
            self.cacheActive = false
        }

    }

    func requestAuthorization(_ success: @escaping () -> Void, failure: @escaping (_ err: String) -> Void ) {

        let status = PHPhotoLibrary.authorizationStatus()

        if status == .authorized {
            success()
            return
        }

        if status == .notDetermined {
            // Ask for permission
            PHPhotoLibrary.requestAuthorization() { (status) -> Void in
                switch status {
                case .authorized:
                    success()
                default:
                    failure("requestAuthorization denied by user")
                }
            }
            return
        }

        // Permission was manually denied by user, open settings screen
        let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
        if let url = settingsUrl {
            UIApplication.shared.openURL(url)
            // TODO: run callback only when return ?
            // Do not call success, as the app will be restarted when user changes permission
        } else {
            failure("could not open settings url")
        }

    }

    // TODO: implement with PHPhotoLibrary (UIImageWriteToSavedPhotosAlbum) instead of deprecated ALAssetsLibrary,
    // as described here: http://stackoverflow.com/questions/11972185/ios-save-photo-in-an-app-specific-album
    // but first find a way to save animated gif with it.
    // TODO: should return library item
    func saveImage(_ url: String, album: String, completion: @escaping (_ libraryItem: NSDictionary?, _ error: String?)->Void) {

        let sourceData: Data
        do {
            sourceData = try getDataFromURL(url)
        } catch {
            completion(nil, "\(error)")
            return
        }

        let assetsLibrary = ALAssetsLibrary()

        func saveImage(_ photoAlbum: PHAssetCollection) {
            assetsLibrary.writeImageData(toSavedPhotosAlbum: sourceData, metadata: nil) { (assetUrl: URL?, error: Error?) in

                if error != nil {
                    completion(nil, "Could not write image to album: \(error)")
                    return
                }

                guard let assetUrl = assetUrl else {
                    completion(nil, "Writing image to album resulted empty asset")
                    return
                }

                self.putMediaToAlbum(assetsLibrary, url: assetUrl, album: album, completion: { (error) in
                    if error != nil {
                        completion(nil, error)
                    } else {
                        let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [assetUrl], options: nil)
                        var libraryItem: NSDictionary? = nil
                        if fetchResult.count == 1 {
                            let asset = fetchResult.firstObject
                            if let asset = asset {
                                libraryItem = self.assetToLibraryItem(asset: asset, useOriginalFileNames: false, includeAlbumData: true)
                            }
                        }
                        completion(libraryItem, nil)
                    }
                })

            }
        }

        if let photoAlbum = PhotoLibraryService.getPhotoAlbum(album) {
            saveImage(photoAlbum)
            return
        }

        PhotoLibraryService.createPhotoAlbum(album) { (photoAlbum: PHAssetCollection?, error: String?) in

            guard let photoAlbum = photoAlbum else {
                completion(nil, error)
                return
            }

            saveImage(photoAlbum)

        }

    }

    func saveVideo(_ url: String, album: String, completion: @escaping (_ libraryItem: NSDictionary?, _ error: String?)->Void) {

        guard let videoURL = URL(string: url) else {
            completion(nil, "Could not parse DataURL")
            return
        }

        let assetsLibrary = ALAssetsLibrary()

        func saveVideo(_ photoAlbum: PHAssetCollection) {

            // TODO: new way, seems not supports dataURL
            //            if !UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoURL.relativePath!) {
            //                completion(url: nil, error: "Provided video is not compatible with Saved Photo album")
            //                return
            //            }
            //            UISaveVideoAtPathToSavedPhotosAlbum(videoURL.relativePath!, nil, nil, nil)

            if !assetsLibrary.videoAtPathIs(compatibleWithSavedPhotosAlbum: videoURL) {

                // TODO: try to convert to MP4 as described here?: http://stackoverflow.com/a/39329155/1691132

                completion(nil, "Provided video is not compatible with Saved Photo album")
                return
            }

            assetsLibrary.writeVideoAtPath(toSavedPhotosAlbum: videoURL) { (assetUrl: URL?, error: Error?) in

                if error != nil {
                    completion(nil, "Could not write video to album: \(error)")
                    return
                }

                guard let assetUrl = assetUrl else {
                    completion(nil, "Writing video to album resulted empty asset")
                    return
                }

                self.putMediaToAlbum(assetsLibrary, url: assetUrl, album: album, completion: { (error) in
  
                    
                    if error != nil {
                        completion(nil, error)
                    } else {
                        let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [assetUrl], options: nil)
                        var libraryItem: NSDictionary? = nil
                        if fetchResult.count == 1 {
                            let asset = fetchResult.firstObject
                            if let asset = asset {
                                libraryItem = self.assetToLibraryItem(asset: asset, useOriginalFileNames: false, includeAlbumData: true)
                            }
                        }
                        completion(libraryItem, nil)
                    }
                })
            }

        }

        if let photoAlbum = PhotoLibraryService.getPhotoAlbum(album) {
            saveVideo(photoAlbum)
            return
        }

        PhotoLibraryService.createPhotoAlbum(album) { (photoAlbum: PHAssetCollection?, error: String?) in

            guard let photoAlbum = photoAlbum else {
                completion(nil, error)
                return
            }

            saveVideo(photoAlbum)

        }

    }

    struct PictureData {
        var data: Data
        // var data: Data? = nil
        // var dataURL: String? = nil
        var mimeType: String
    }

    // TODO: currently seems useless
    enum PhotoLibraryError: Error, CustomStringConvertible {
        case error(description: String)

        var description: String {
            switch self {
            case .error(let description): return description
            }
        }
    }

    fileprivate func getDataFromURL(_ url: String) throws -> Data {
        if url.hasPrefix("data:") {

            guard let match = self.dataURLPattern.firstMatch(in: url, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, url.characters.count)) else { // TODO: firstMatchInString seems to be slow for unknown reason
                throw PhotoLibraryError.error(description: "The dataURL could not be parsed")
            }
            let dataPos = match.range(at: 0).length
            let base64 = (url as NSString).substring(from: dataPos)
            guard let decoded = Data(base64Encoded: base64, options: NSData.Base64DecodingOptions(rawValue: 0)) else {
                throw PhotoLibraryError.error(description: "The dataURL could not be decoded")
            }

            return decoded

        } else {

            guard let nsURL = URL(string: url) else {
                throw PhotoLibraryError.error(description: "The url could not be decoded: \(url)")
            }
            guard let fileContent = try? Data(contentsOf: nsURL) else {
                throw PhotoLibraryError.error(description: "The url could not be read: \(url)")
            }

            return fileContent

        }
    }

    fileprivate func putMediaToAlbum(_ assetsLibrary: ALAssetsLibrary, url: URL, album: String, completion: @escaping (_ error: String?)->Void) {

        assetsLibrary.asset(for: url, resultBlock: { (asset: ALAsset?) in

            guard let asset = asset else {
                completion("Retrieved asset is nil")
                return
            }

            PhotoLibraryService.getAlPhotoAlbum(assetsLibrary, album: album, completion: { (alPhotoAlbum: ALAssetsGroup?, error: String?) in

                if error != nil {
                    completion("getting photo album caused error: \(error)")
                    return
                }

                alPhotoAlbum!.add(asset)
                completion(nil)

            })

        }, failureBlock: { (error: Error?) in
            completion("Could not retrieve saved asset: \(error)")
        })

    }

    fileprivate static func image2PictureData(_ image: UIImage, quality: Float) -> PictureData? {
        //        This returns raw data, but mime type is unknown. Anyway, crodova performs base64 for messageAsArrayBuffer, so there's no performance gain visible
        //        let provider: CGDataProvider = CGImageGetDataProvider(image.CGImage)!
        //        let data = CGDataProviderCopyData(provider)
        //        return data;

        var data: Data?
        var mimeType: String?

        if (imageHasAlpha(image)){
            data = UIImagePNGRepresentation(image)
            mimeType = data != nil ? "image/png" : nil
        } else {
            data = UIImageJPEGRepresentation(image, CGFloat(quality))
            mimeType = data != nil ? "image/jpeg" : nil        
        }

        if data != nil && mimeType != nil {
            return PictureData(data: data!, mimeType: mimeType!)
            // return PictureData(data: data!, dataURL:nil, mimeType: mimeType!)
        }
        return nil
    }

    fileprivate static func imageHasAlpha(_ image: UIImage) -> Bool {
        let alphaInfo = (image.cgImage)?.alphaInfo
        return alphaInfo == .first || alphaInfo == .last || alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast
    }

    fileprivate static func getPhotoAlbum(_ album: String) -> PHAssetCollection? {

        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", album)
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
        guard let photoAlbum = fetchResult.firstObject else {
            return nil
        }

        return photoAlbum

    }

    fileprivate static func createPhotoAlbum(_ album: String, completion: @escaping (_ photoAlbum: PHAssetCollection?, _ error: String?)->()) {

        var albumPlaceholder: PHObjectPlaceholder?

        PHPhotoLibrary.shared().performChanges({

            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: album)
            albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection

        }) { success, error in

            guard let placeholder = albumPlaceholder else {
                completion(nil, "Album placeholder is nil")
                return
            }

            let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)

            guard let photoAlbum = fetchResult.firstObject else {
                completion(nil, "FetchResult has no PHAssetCollection")
                return
            }

            if success {
                completion(photoAlbum, nil)
            }
            else {
                completion(nil, "\(error)")
            }
        }
    }

    fileprivate static func getAlPhotoAlbum(_ assetsLibrary: ALAssetsLibrary, album: String, completion: @escaping (_ alPhotoAlbum: ALAssetsGroup?, _ error: String?)->Void) {

        var groupPlaceHolder: ALAssetsGroup?

        assetsLibrary.enumerateGroupsWithTypes(ALAssetsGroupAlbum, usingBlock: { (group: ALAssetsGroup?, _ ) in

            guard let group = group else { // done enumerating
                guard let groupPlaceHolder = groupPlaceHolder else {
                    completion(nil, "Could not find album")
                    return
                }
                completion(groupPlaceHolder, nil)
                return
            }

            if group.value(forProperty: ALAssetsGroupPropertyName) as? String == album {
                groupPlaceHolder = group
            }

        }, failureBlock: { (error: Error?) in
            completion(nil, "Could not enumerate assets library")
        })

    }

}
