//
//  How2ViewController.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/12/07.
//

import UIKit
extension UIImage {
    
    func resize(size _size: CGSize) -> UIImage? {
        let widthRatio = _size.width / size.width
        let heightRatio = _size.height / size.height
        let ratio = widthRatio < heightRatio ? widthRatio : heightRatio
        
        let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0) // 変更
        draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

class How2ViewController: UIViewController {
    let someFunctions = MyFunctions()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var exitButton: UIButton!
//    @IBOutlet weak var gyroButton: UIButton!
//    @IBOutlet weak var rehaButton: UIButton!
    @IBOutlet weak var imageViewOnScrollView: UIImageView!
    
    @IBOutlet weak var imageViewOnScrollView2: UIImageView!
    @IBOutlet weak var labelOnScrollView: UILabel!
    @IBOutlet weak var labelTop: UILabel!
    @IBOutlet weak var labelOnScrollView2: UILabel!
    @IBAction func onExitButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.set(UIScreen.main.brightness, forKey: "brightness")
        
        // パディングと画面サイズ
        let top = CGFloat(UserDefaults.standard.float(forKey: "topPadding"))
        let bottom = CGFloat(UserDefaults.standard.float(forKey: "bottomPadding"))
        let left = CGFloat(UserDefaults.standard.float(forKey: "leftPadding"))
        let right = CGFloat(UserDefaults.standard.float(forKey: "rightPadding"))
        let ww = view.bounds.width - (left + right)
        let wh = view.bounds.height - (top + bottom)
        let sp = ww / 120 // 間隔
        let bw = (ww - sp * 9) / 7 // ボタン幅
        let bh = bw * 170 / 440
        let by = wh - bh - sp
        
        // scrollView サイズ
        scrollView.frame = CGRect(x: left, y: top, width: ww, height: wh)
        
        // ボタン配置
        someFunctions.setButtonProperty(exitButton, x: left + bw * 6 + sp * 8, y: by, w: bw, h: bh, UIColor.darkGray)
        // 最上部ラベル
        
        labelTop.text = someFunctions.firstLang().contains("ja") ? getTextJa() : getTextEn()
        labelTop.numberOfLines = 0
        labelTop.font = UIFont.systemFont(ofSize: 20)
        labelTop.frame = CGRect(x: sp, y: sp, width: ww - 2 * sp, height: 0)
        labelTop.sizeToFit()
        
        // imageViewOnScrollView（1枚目の画像）
        let img = UIImage(named: "boyfix")!
        let imgW = img.size.width
        let imgH = img.size.height
        let imageHeight = ww * imgH / imgW
        let image = img.resize(size: CGSize(width: ww, height: imageHeight))
        let imageY = labelTop.frame.maxY + sp
        imageViewOnScrollView.frame = CGRect(x: sp, y: imageY, width: ww - 2 * sp, height: imageHeight)
        imageViewOnScrollView.image = image
        
        // labelOnScrollView（画像1の説明）
        labelOnScrollView.text = someFunctions.firstLang().contains("ja") ? getTextJa1() : getTextEn1()
        labelOnScrollView.numberOfLines = 0
        labelOnScrollView.font = UIFont.systemFont(ofSize: 20)
        let label1Y = imageViewOnScrollView.frame.maxY + sp
        labelOnScrollView.frame = CGRect(x: sp, y: label1Y, width: ww - 2 * sp, height: 0)
        labelOnScrollView.sizeToFit()
  //以下は2個目の画像を使うときのために、コメントアウトして残しておく
        labelOnScrollView2.text=""
 
        // scrollView 全体の高さを更新
//        scrollView.contentSize = CGSize(width: ww, height: labelOnScrollView2.frame.maxY + 2 * sp)
        scrollView.contentSize = CGSize(width: ww, height: labelOnScrollView.frame.maxY + 2 * sp)
 
        // スクロールの跳ね返り有効（自然な動作）
        scrollView.bounces = true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    @IBAction func unwind2how2(segue: UIStoryboardSegue) {
        UIApplication.shared.isIdleTimerDisabled = false//スリープさせる
    }
   
    func getTextEn()->String{
        let text = "This is an app for recording your own nystagmus using the front-facing camera. Tap the Start button in the center of the screen to begin recording. During recording, the Stop button is very faint and nearly invisible, but it remains in the center of the screen. Tapping that area will stop the recording.\n\nTo capture clear footage of nystagmus, it is important to keep the iPhone fixed in front of your eyes."
        return text
    }
    func getTextEn1()->String{
        var text = "Even just by spreading your palms to hold the iPhone with both hands and pressing both thumbs against your cheeks to stabilize it, you can capture relatively shake-free footage once you get used to it. As shown in the top right photo, using a piece of cut cardboard to support the iPhone and fix it against your left cheek and forehead can also help you record stable footage.\n"
        
        text += "\nThe most recently recorded nystagmus video is displayed as a thumbnail in the upper right corner. Tapping the thumbnail will play the video. The button below the thumbnail shows a list of all recorded videos, which are displayed by recording date and duration. You can tap an item to play it, or swipe it left to delete it. All nystagmus videos are stored in the iCapNYS album, so you can also manage them—playback, deletion, and sharing—using the Photos app.\n\n"
        return text
    }
    func getTextJa()->String{
        let text =  "フロントカメラで自分の眼振を録画するアプリです。中央のスタートボタンを押すと録画開始します。録画中はストップボタンは薄くてほとんど見えませんが、スクリーン中央にあります。そこをタップすると録画終了します。\n\n眼振を綺麗に撮影するために、iPhoneを目の前に固定する必要があります。"
        return text
    }
    func getTextJa1()->String{
        var text = "手の平を広げて両手でiPhoneを支え、両手の親指を両頬に当てて固定するだけでも、慣れればブレの少ない映像が撮れます。上右写真のようにカットした段ボールでiPhoneを支え、左頬と額に固定するとブレの少ない映像が撮れます。\n\n"
        text += "最後に撮影した眼振動画は右上にサムネイルとして表示され、それをタップすると再生出来ます。サムネイルの下のボタンで動画が一覧表示されます。動画は撮影日時（長さ）で一覧表示されます。項目をタップすると再生出来ます。項目を左にスワイプスすると削除できます。眼振動画はiCapNYSアルバムの中に入っていますので、写真アプリでも再生、削除、送信などの管理ができます。\n再生画面から再生中の動画をメールで送信できます。\n\n"
        return text
    }
}
