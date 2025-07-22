//  albumCameraEtc.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2021/02/28.

import UIKit
import Photos
import AVFoundation

class MyFunctions: NSObject {
    let albumName: String = "iCapNYS"
    var videoDevice: AVCaptureDevice?
    var soundIdx: SystemSoundID = 0
    
    // アルバムの存在確認・作成
    func ensureAlbumExists(completion: ((Bool) -> Void)? = nil) {
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        for i in 0..<albums.count {
            let album = albums.object(at: i)
            if album.localizedTitle == albumName {
                completion?(true)
                return
            }
        }
        
        PHPhotoLibrary.shared().performChanges({ [self] in
            _ = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
        }) { success, error in
#if DEBUG
            if success {
                print("✅ アルバム作成成功：\(self.albumName)")
            } else {
                print("❌ アルバム作成失敗: \(error?.localizedDescription ?? "不明なエラー")")
            }
#endif
            completion?(success)
        }
    }
    func getPHAssetcollection()->PHAssetCollection{
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = false
        requestOptions.deliveryMode = .highQualityFormat //これでもicloud上のvideoを取ってしまう
        //アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: assetFetchOptions)
        return assetCollections.object(at:0)
    }
    func albumExists() -> Bool {
        let fetchOptions = PHFetchOptions()
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
        
        for i in 0..<collections.count {
            let collection = collections.object(at: i)
            if collection.localizedTitle == albumName {
                return true
            }
        }
        return false
    }
 
    // サウンド再生
    func makeSound() {
        AudioServicesPlaySystemSound(1106)
    }
    
    // UI部品の共通設定
    func setLabelProperty(_ label: UILabel, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, _ color: UIColor, _ borderWidth: CGFloat = 1.0, colorType: Int = 0) {
        label.frame = CGRect(x: x, y: y, width: w, height: h)
        label.layer.borderColor = (colorType == 1 ? UIColor.orange : UIColor.black).cgColor
        label.layer.borderWidth = borderWidth
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 5
        label.backgroundColor = color
    }
    
    func setButtonProperty(_ button: UIButton, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, _ color: UIColor, _ borderWidth: CGFloat = 1.0) {
        button.frame = CGRect(x: x, y: y, width: w, height: h)
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = borderWidth
        button.layer.cornerRadius = 5
        button.backgroundColor = color
    }
    
    func setSwitchProperty(_ uiSwitch: UISwitch, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, _ color: UIColor, _ borderWidth: CGFloat) {
        uiSwitch.frame = CGRect(x: x, y: y, width: w, height: h)
        uiSwitch.layer.borderColor = UIColor.black.cgColor
        uiSwitch.layer.borderWidth = borderWidth
        uiSwitch.layer.masksToBounds = true
        uiSwitch.layer.cornerRadius = 5
        uiSwitch.backgroundColor = color
    }
    
    // UserDefaults 取得系
    func getUserDefaultInt(str: String, ret: Int) -> Int {
        if UserDefaults.standard.object(forKey: str) != nil {
            return UserDefaults.standard.integer(forKey: str)
        } else {
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    
    func getUserDefaultDouble(str: String, ret: Double) -> Double {
        if UserDefaults.standard.object(forKey: str) != nil {
            return UserDefaults.standard.double(forKey: str)
        } else {
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    
    func getUserDefaultBool(str: String, ret: Bool) -> Bool {
        if UserDefaults.standard.object(forKey: str) != nil {
            return UserDefaults.standard.bool(forKey: str)
        } else {
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    
    func getUserDefaultString(str: String, ret: String) -> String {
        if let value = UserDefaults.standard.string(forKey: str) {
            return value
        } else {
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    
    func getUserDefaultFloat(str: String, ret: Float) -> Float {
        if UserDefaults.standard.object(forKey: str) != nil {
            return UserDefaults.standard.float(forKey: str)
        } else {
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    
    func getUserDefaultCGFloat(str: String, ret: CGFloat) -> CGFloat {
        if UserDefaults.standard.object(forKey: str) != nil {
            return CGFloat(UserDefaults.standard.float(forKey: str))
        } else {
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    
    // 使用言語取得
    func firstLang() -> String {
        return Locale.preferredLanguages.first ?? "en"
    }
}
