//
//  CameraService.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2023/02/23.
//


//  CameraService.swift
//  wifiCapNYS
//
//  Created by 黒田賢 on 2022/12/10.
//
import Foundation
import UIKit

protocol CameraServiceDelegateProtocol {
    func frame(image: UIImage) -> Void
}

protocol CameraServiceProtocol {
    var rosServiceDelegate: CameraServiceDelegateProtocol { get set }
}

class CameraService: NSObject, ObservableObject {
    var cameraServiceDelegate: CameraServiceDelegateProtocol
    var dataTask: URLSessionDataTask?
    var receivedData: NSMutableData = NSMutableData()
    var session: URLSession? = nil
    
    init(delegate: CameraServiceDelegateProtocol) {
        cameraServiceDelegate = delegate
    }
    
    func play(url:URL) {
        if session == nil {
            session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
            dataTask = session?.dataTask(with: url)
            dataTask?.resume()
        }
    }
    
    func stop() {
        dataTask?.cancel()
        session = nil
    }
}

extension CameraService: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if self.receivedData.length > 0,
           let receivedImage = UIImage(data: self.receivedData as Data) {
            DispatchQueue.main.async {
                self.cameraServiceDelegate.frame(image: receivedImage)
            }
            self.receivedData = NSMutableData()
        }
        completionHandler(URLSession.ResponseDisposition.allow) //.Cancel,If you want to stop the download
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.receivedData.append(data)
    }
}
/*
 import UIKit
 
 class CameraService: UIViewController {
 
 override func viewDidLoad() {
 super.viewDidLoad()
 
 // Do any additional setup after loading the view.
 }
 
 
 /*
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
  // Get the new view controller using segue.destination.
  // Pass the selected object to the new view controller.
  }
  */
 
 }
 */

