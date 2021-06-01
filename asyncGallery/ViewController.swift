//
//  ViewController.swift
//  asyncGallery
//
//  Created by swamnx on 31.05.21.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var galleryView: UICollectionView!
    
    var photos: [Photo]?
    var asyncPhotoHandler: AsyncPhotoHandler?
    var alertController: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initAlertController()
        galleryView.delegate = self
        galleryView.dataSource = self
        activityIndicator.hidesWhenStopped = true
        photos = [Photo]()
        asyncPhotoHandler = AsyncPhotoHandler()
    }
    
    func initAlertController() {
        alertController = UIAlertController(
            title: "Oops!",
            message: "There was an error fetching photo details.",
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController?.addAction(okAction)
    }
    
    @IBAction func loadDataTouched(_ sender: UIButton) {
        fetchPhotoDetails()
    }
    
}
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCellID", for: indexPath) as? PhotoCellView
        if let photo =  photos?[indexPath.row] {
            switch photo.status {
            case .initial:
                photo.loadInitialImage()
                photo.status = .downloading
                startDownload(photo, indexPath)
                activityIndicator.startAnimating()
                cell?.photo.image = photo.image
            case .downloaded, .failed:
                cell?.photo.image = photo.image
            case .downloading:
                break
            }
        }
        return cell ?? PhotoCellView()
    }

}
extension ViewController {
    
    func fetchPhotoDetails() {
        let request = URLRequest(url: AsyncPhotoUtils.shared.photoDetailsUrl)
        let task = URLSession(configuration: .default).dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            self.cancelPreviousDownloads()
            if let data = data {
              do {
                guard let datasourceDictionary = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: String] else {
                    DispatchQueue.main.async {
                      self.galleryView.reloadData()
                    }
                    return
                }
                for (name, value) in datasourceDictionary {
                    if let url = URL(string: CommonUtils.shared.getHttpsValue(httpValue: value)) {
                        self.photos?.append(Photo(name: name, url: url))
                    }
                }
                DispatchQueue.main.async {
                  self.galleryView.reloadData()
                }
              } catch {
                DispatchQueue.main.async {
                    if let alert = self.alertController {
                        self.present(alert, animated: true, completion: nil)
                    }
                }
              }
            }
            if error != nil {
              DispatchQueue.main.async {
                if let alert = self.alertController {
                    self.present(alert, animated: true, completion: nil)
                }
              }
            }
      }
      task.resume()
    }
    
    func startDownload(_ photo: Photo, _ indexPath: IndexPath) {
        let operation = PhotoOperation(photo)
        operation.completionBlock = { [weak self] in
            guard let self = self else { return }
            if operation.isCancelled { return }
            self.asyncPhotoHandler?.semaphore.wait()
            self.asyncPhotoHandler?.amountOfCompletedTasks+=1
            self.asyncPhotoHandler?.semaphore.signal()
            DispatchQueue.main.async {
                if let photosCount = self.photos?.count,
                   let amountOfCompletedTasks = self.asyncPhotoHandler?.amountOfCompletedTasks,
                   amountOfCompletedTasks == photosCount {
                    self.activityIndicator.stopAnimating()
                }
                self.galleryView.reloadItems(at: [indexPath])
            }
        }
        asyncPhotoHandler?.tasks[indexPath] = operation
        asyncPhotoHandler?.queue.addOperation(operation)
    }
    
    func cancelPreviousDownloads() {
        if let handler = asyncPhotoHandler {
            for (_, task) in handler.tasks {
                task.cancel()
            }
            handler.tasks.removeAll()
            handler.amountOfCompletedTasks = 0
        }
        photos?.removeAll()
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }
}
