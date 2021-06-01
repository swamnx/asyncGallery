//
//  Photo.swift
//  asyncGallery
//
//  Created by swamnx on 31.05.21.
//

import Foundation
import UIKit

class Photo {
    
    var name: String
    var url: URL
    var image: UIImage?
    var status = DownloadingStatus.initial
    
    init(name: String, url: URL) {
      self.name = name
      self.url = url
    }
    
    func loadInitialImage() {
        image = UIImage(systemName: "house")
    }
    
    func loadFailedImage() {
        image = UIImage(systemName: "house")
    }
    
}

enum DownloadingStatus {

    case initial, downloading, downloaded, failed
}
