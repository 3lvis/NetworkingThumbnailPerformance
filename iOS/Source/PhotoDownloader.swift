import Foundation
import UIKit
import Networking

protocol PhotoDownloaderDelegate: class {
    func photoDownloaderDidFinishDownloadingImage(_ photoDownloader: PhotoDownloader, error: NSError?)
}

class PhotoDownloader {
    static let iconSize = CGFloat(48)

    weak var delegate: PhotoDownloaderDelegate?
    weak var networking: Networking?

    var photo: Photo
    var indexPath: IndexPath
    var sessionTask: URLSessionDataTask?

    init(photo: Photo, indexPath: IndexPath) {
        self.photo = photo
        self.indexPath = indexPath
    }

    func startDownload() {
        self.networking?.downloadImage(self.photo.thumbnailURL) { image, error in
            if let error = error {
                self.delegate?.photoDownloaderDidFinishDownloadingImage(self, error: error)
            } else {
                OperationQueue.main.addOperation {
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
