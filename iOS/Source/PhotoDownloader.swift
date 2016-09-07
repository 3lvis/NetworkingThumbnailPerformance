import Foundation
import UIKit
import Networking

protocol PhotoDownloaderDelegate: class {
    func photoDownloaderDidFinishDownloadingImage(photoDownloader: PhotoDownloader, error: NSError?)
}

class PhotoDownloader {
    static let iconSize = CGFloat(48)

    weak var delegate: PhotoDownloaderDelegate?
    weak var networking: Networking?

    var photo: Photo
    var indexPath: NSIndexPath
    var sessionTask: NSURLSessionDataTask?

    init(photo: Photo, indexPath: NSIndexPath) {
        self.photo = photo
        self.indexPath = indexPath
    }

    func startDownload() {
        self.networking?.downloadImage(self.photo.thumbnailURL) { image, error in
            if let error = error {
                self.delegate?.photoDownloaderDidFinishDownloadingImage(self, error: error)
            } else {
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    guard let image = image else {
                        self.delegate?.photoDownloaderDidFinishDownloadingImage(self, error: nil)
                        return
                    }

                    self.photo.image = image
                    self.delegate?.photoDownloaderDidFinishDownloadingImage(self, error: nil)
                }
            }
        }
    }

    func cancelDownload() {
        self.networking?.cancelImageDownload(self.photo.thumbnailURL)
    }
}