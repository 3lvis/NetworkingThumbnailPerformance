import UIKit

class PhotosController: UICollectionViewController {
    var photoDownloadsInProgress = [NSIndexPath : PhotoDownloader]()
    var sections = Photo.constructRemoteElements()
    var isScrollingFast = false
    var lastOffsetCapture: NSTimeInterval = 0
    var lastOffset = CGPointZero

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.backgroundColor = UIColor.whiteColor()
        self.collectionView?.registerClass(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.Identifier)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let layout = self.collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
        let columns = CGFloat(4)
        let bounds = UIScreen.mainScreen().bounds
        let size = (bounds.width - columns) / columns
        layout.itemSize = CGSize(width: size, height: size)
    }
}

extension PhotosController {
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.sections.count
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let photos = self.sections[section]

        return photos.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoCell.Identifier, forIndexPath: indexPath) as! PhotoCell
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

    func startPhotoDownload(photo photo: Photo, forIndexPath indexPath: NSIndexPath) {
        guard self.photoDownloadsInProgress[indexPath] == nil else { return }

        let photoDownloader = PhotoDownloader(photo: photo, indexPath: indexPath)
        photoDownloader.delegate = self
        self.photoDownloadsInProgress[indexPath] = photoDownloader
        photoDownloader.startDownload()
    }

    func loadImagesForOnscreenRows() {
        guard self.sections.count != 0 || self.isScrollingFast == false else { return }

        let visibleIndexPaths = self.collectionView?.indexPathsForVisibleItems() ?? [NSIndexPath]()
        for indexPath in visibleIndexPaths {
            let photos = self.sections[indexPath.section]
            let photo = photos[indexPath.row]
            if photo.image == nil {
                self.startPhotoDownload(photo: photo, forIndexPath: indexPath)
            }
        }
    }

    override func scrollViewDidScroll(scrollView: UIScrollView) {
        NSObject.cancelPreviousPerformRequestsWithTarget(self)
        self.performSelector(#selector(self.scrollViewDidEndScrollingAnimation), withObject: nil, afterDelay: 0.3)

        let currentOffset = scrollView.contentOffset
        let currentTime = NSDate.timeIntervalSinceReferenceDate()
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

    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.loadImagesForOnscreenRows()
        }
    }

    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.loadImagesForOnscreenRows()
        self.isScrollingFast = false
    }

    override func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        self.terminateAllDownloads()
        self.loadImagesForOnscreenRows()
        NSObject.cancelPreviousPerformRequestsWithTarget(self)
    }
}

extension PhotosController: PhotoDownloaderDelegate {
    func photoDownloaderDidFinishDownloadingImage(photoDownloader: PhotoDownloader, error: NSError?) {
        guard let cell = self.collectionView?.cellForItemAtIndexPath(photoDownloader.indexPath) as? PhotoCell else { return }
        if let _ = error {
            cell.imageView.image = UIImage(named: "placeholder")
        } else {
            cell.imageView.image = photoDownloader.photo.image
        }
        self.photoDownloadsInProgress.removeValueForKey(photoDownloader.indexPath)
    }
}