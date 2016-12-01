import UIKit
import Networking

class PhotosController: UICollectionViewController {
    var photoDownloadsInProgress = [IndexPath : PhotoDownloader]()
    var sections = Photo.constructRemoteElements()
    var isScrollingFast = false
    var lastOffsetCapture: TimeInterval = 0
    var lastOffset = CGPoint.zero
    weak var networking: Networking?

    init(networking: Networking, collectionViewLayout: UICollectionViewLayout) {
        self.networking = networking

        super.init(collectionViewLayout: collectionViewLayout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.backgroundColor = UIColor.white
        self.collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.Identifier)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let layout = self.collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
        let columns = CGFloat(4)
        let bounds = UIScreen.main.bounds
        let size = (bounds.width - columns) / columns
        layout.itemSize = CGSize(width: size, height: size)
    }
}

extension PhotosController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let photos = self.sections[section]

        return photos.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.Identifier, for: indexPath) as! PhotoCell
        let photos = self.sections[indexPath.section]
        let photo = photos[indexPath.row]

        if let image = photo.image {
            cell.imageView.image = image
        } else {
            self.startPhotoDownload(photo: photo, forIndexPath: indexPath)
            cell.imageView.image = UIImage(named: "placeholder")
        }

        return cell
    }

    func terminateAllDownloads() {
        let allDownloads = Array(self.photoDownloadsInProgress.values)
        allDownloads.forEach { $0.cancelDownload() }
        self.photoDownloadsInProgress.removeAll()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        self.terminateAllDownloads()
    }

    func startPhotoDownload(photo: Photo, forIndexPath indexPath: IndexPath) {
        guard self.photoDownloadsInProgress[indexPath] == nil else { return }

        let photoDownloader = PhotoDownloader(photo: photo, indexPath: indexPath)
        photoDownloader.networking = self.networking
        photoDownloader.delegate = self
        self.photoDownloadsInProgress[indexPath] = photoDownloader
        photoDownloader.startDownload()
    }

    func loadImagesForOnscreenRows() {
        guard self.sections.count != 0 || self.isScrollingFast == false else { return }

        self.terminateAllDownloads()
        let visibleIndexPaths = self.collectionView?.indexPathsForVisibleItems ?? [IndexPath]()
        for indexPath in visibleIndexPaths {
            let photos = self.sections[indexPath.section]
            let photo = photos[indexPath.row]
            if photo.image == nil {
                self.startPhotoDownload(photo: photo, forIndexPath: indexPath)
            }
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(self.scrollViewDidEndScrollingAnimation), with: nil, afterDelay: 0.3)

        let currentOffset = scrollView.contentOffset
        let currentTime = Date.timeIntervalSinceReferenceDate
        let timeDiff = currentTime - self.lastOffsetCapture
        if timeDiff > 0.1 {
            let distance = Float(currentOffset.y - lastOffset.y)
            let scrollSpeedNotAbs = Float((distance * 10.0) / 1000.0)
            let scrollSpeed = fabsf(scrollSpeedNotAbs)
            if scrollSpeed > 4 {
                self.isScrollingFast = true
                self.terminateAllDownloads()
            } else {
                self.isScrollingFast = false
            }

            self.lastOffset = currentOffset
            self.lastOffsetCapture = currentTime
        }

        if currentOffset.x == 0 && currentOffset.y == 0 {
            self.isScrollingFast = false
            self.loadImagesForOnscreenRows()
        }
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.loadImagesForOnscreenRows()
        }
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.loadImagesForOnscreenRows()
        self.isScrollingFast = false
    }

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.loadImagesForOnscreenRows()
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
}

extension PhotosController: PhotoDownloaderDelegate {
    func photoDownloaderDidFinishDownloadingImage(_ photoDownloader: PhotoDownloader, error: NSError?) {
        guard let cell = self.collectionView?.cellForItem(at: photoDownloader.indexPath as IndexPath) as? PhotoCell else { return }
        if let _ = error {
            cell.imageView.image = UIImage(named: "placeholder")
        } else {
            cell.imageView.image = photoDownloader.photo.image
        }
        self.photoDownloadsInProgress.removeValue(forKey: photoDownloader.indexPath as IndexPath)
    }
}
