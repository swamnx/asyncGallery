//
//  AsyncUtils.swift
//  asyncGallery
//
//  Created by swamnx on 31.05.21.
//

import Foundation
import UIKit

struct AsyncPhotoUtils {
    
    static var shared = AsyncPhotoUtils()
    
    private init() {
        
    }
    
    var photoDetailsUrl = URL(string: "https://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist")!
    
}
class AsyncPhotoHandler {
    var tasks = [IndexPath: PhotoOperation]()
    var amountOfCompletedTasks = 0
    var semaphore = DispatchSemaphore(value: 1)
    var queue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download queue"
        queue.maxConcurrentOperationCount = 2
        return queue
      }()
}

class PhotoOperation: Operation {
    let photo: Photo
    
    init(_ photo: Photo) {
      self.photo = photo
    }
    override func main() {
        if isCancelled { return }
        guard let imageData = try? Data(contentsOf: photo.url) else { return }
        if isCancelled { return }
        if !imageData.isEmpty {
            photo.image = UIImage(data: imageData)
            photo.status = .downloaded
        } else {
            photo.status = .failed
            photo.loadFailedImage()
        }
    }
}
