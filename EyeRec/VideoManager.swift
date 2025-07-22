//
//  VideoManager.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2025/04/11.
//

import Foundation
import Photos

class VideoManager {
    let albumName: String = "iCapNYS"

    static let shared = VideoManager()
    private init() {}
    
    // MARK: - 管理用配列
    var videoDate: [String] = []
    var videoPHAsset: [PHAsset] = []
    
    // MARK: - アルバムからビデオを読み込む
    func loadVideosFromAlbum(albumName: String, completion: @escaping () -> Void) {
        videoDate.removeAll()
        videoPHAsset.removeAll()
        
        // "iCapNYS" という名前のアルバムを取得
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        guard let album = collections.firstObject else {
//            print("アルバムが見つかりません: \(albumName)")
            completion()
            return
        }
        
        // アルバム内の動画を取得
        let videoOptions = PHFetchOptions()
        videoOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        videoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let assets = PHAsset.fetchAssets(in: album, options: videoOptions)
        
        assets.enumerateObjects { asset, _, _ in
            self.videoPHAsset.append(asset)
            if let date = asset.creationDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"//formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

                self.videoDate.append(formatter.string(from: date))
            } else {
                self.videoDate.append("Unknown Date")
            }
        }
        
        completion()
    }
    
    // MARK: - ビデオを配列に追加（録画後など）
    func addVideo(asset: PHAsset) {
        videoPHAsset.append(asset)
        if let date = asset.creationDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            videoDate.append(formatter.string(from: date))
        } else {
            videoDate.append("Unknown Date")
        }
    }
    
    // MARK: - 配列から削除（UIだけで内部管理用）
    func removeVideo(at index: Int) {
        guard videoPHAsset.indices.contains(index) else { return }
        videoPHAsset.remove(at: index)
        videoDate.remove(at: index)
    }
//    // VideoManager.swift
//    func removeVideo(at index: Int) {
//        if index >= 0 && index < videoAssets.count {
//            videoAssets.remove(at: index)
//            videoDates.remove(at: index)
//        }
//    }
    // MARK: - フォトライブラリから削除（実データ削除）
    func deleteAssetFromPhotoLibrary(at index: Int, completion: @escaping (Bool) -> Void) {
        guard videoPHAsset.indices.contains(index) else {
            completion(false)
            return
        }
        
        let assetToDelete = videoPHAsset[index]
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([assetToDelete] as NSArray)
        }, completionHandler: { success, error in
            if success {
                DispatchQueue.main.async {
                    self.videoPHAsset.remove(at: index)
                    self.videoDate.remove(at: index)
                    completion(true)
                }
            } else {
//                print("削除失敗: \(error?.localizedDescription ?? "不明なエラー")")
                completion(false)
            }
        })
    }
    func requestAVAssetAsync(asset: PHAsset) async -> AVAsset? {
        await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { asset, _, _ in
                continuation.resume(returning: asset)
            }
        }
    }
    @MainActor
    func loadVideosFromAlbumAsync(albumName: String, includeCloudAssets: Bool = false, latestOnly: Bool = false) async {
        videoDate.removeAll()
        videoPHAsset.removeAll()

        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        guard let album = collections.firstObject else {
            return
        }

        let videoOptions = PHFetchOptions()
        videoOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        videoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let assets = PHAsset.fetchAssets(in: album, options: videoOptions)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        for i in 0..<assets.count {
            let asset = assets[i]
            if !includeCloudAssets {
                let avAsset = await requestAVAssetAsync(asset: asset)
                if avAsset == nil { continue } // iCloud上にしかないものは除外
            }

            videoPHAsset.append(asset)
            if let date = asset.creationDate {
                videoDate.append(formatter.string(from: date))
            } else {
                videoDate.append("Unknown Date")
            }

            if latestOnly { break }
        }
    }
    
    func getPHAssetCollection() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        return collections.firstObject
    }
    
    
}
