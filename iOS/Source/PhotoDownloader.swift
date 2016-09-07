import Foundation
import UIKit

protocol PhotoDownloaderDelegate: class {
    func photoDownloaderDidFinishDownloadingImage(photoDownloader: PhotoDownloader, error: NSError?)
}

class PhotoDownloader {
    static let iconSize = CGFloat(48)

    weak var delegate: PhotoDownloaderDelegate?

    var photo: Photo
    var indexPath: NSIndexPath
    var sessionTask: NSURLSessionDataTask?

    init(photo: Photo, indexPath: NSIndexPath) {
        self.photo = photo
        self.indexPath = indexPath
    }

    func startDownload() {
        let request = NSURLRequest(URL: NSURL(string: self.photo.thumbnailURL)!)
        self.sessionTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            if let error = error {
                if error.code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
                    // If you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                    // then your Info.plist has not been properly configured to match the target server.
                    fatalError()
                } else {
                    self.delegate?.photoDownloaderDidFinishDownloadingImage(self, error: error)
                }
            } else {
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    guard let data = data else { return }
                    guard let image = UIImage(data: data) else { return }
                    if image.size.width == PhotoDownloader.iconSize && image.size.height == PhotoDownloader.iconSize {
                        let itemSize = CGSize(width: PhotoDownloader.iconSize, height: PhotoDownloader.iconSize)
                        UIGraphicsBeginImageContextWithOptions(itemSize, false, 0)
                        let imageRect = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
                        image.drawInRect(imageRect)
                        self.photo.image = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                    } else {
                        self.photo.image = image
                    }

                    self.delegate?.photoDownloaderDidFinishDownloadingImage(self, error: nil)
                }
            }
        }

        self.sessionTask?.resume()
    }

    func cancelDownload() {
        self.sessionTask?.cancel()
    }
}