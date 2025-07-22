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
//        someFunctions.setButtonProperty(gyroButton, x: left + sp * 1, y: by, w: bw, h: bh, UIColor.darkGray)
//        someFunctions.setButtonProperty(rehaButton, x: left + bw + sp * 2, y: by, w: bw, h: bh, UIColor.darkGray)
//        gyroButton.isHidden=true
//        rehaButton.isHidden=true
        // 最上部ラベル
        let topLabelText = someFunctions.firstLang().contains("ja")
            ? "眼振を撮影するためのiPhoneを眼前に固定する装具が必要です。"
            : "A device is necessary to secure the iPhone in front of the eye for capturing nystagmus."
        
        labelTop.text = topLabelText
        labelTop.numberOfLines = 0
        labelTop.font = UIFont.systemFont(ofSize: 20)
        labelTop.frame = CGRect(x: sp, y: sp, width: ww - 2 * sp, height: 0)
        labelTop.sizeToFit()
        
        // imageViewOnScrollView（1枚目の画像）
        let img = UIImage(named: "fix2")!
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
 /*
        // imageViewOnScrollView2（2枚目の画像）
        let img2 = UIImage(named: "fix3")!
        let imgW2 = img2.size.width
        let imgH2 = img2.size.height
        let imageHeight2 = ww * imgH2 / imgW2
        let image2 = img2.resize(size: CGSize(width: ww, height: imageHeight2))
        let image2Y = labelOnScrollView.frame.maxY + sp
        imageViewOnScrollView2.frame = CGRect(x: sp, y: image2Y, width: ww - 2 * sp, height: imageHeight2)
        imageViewOnScrollView2.image = image2
        
        // labelOnScrollView2（画像2の説明）
        labelOnScrollView2.text = someFunctions.firstLang().contains("ja") ? getTextJa() : getTextEn()
        labelOnScrollView2.numberOfLines = 0
        labelOnScrollView2.font = UIFont.systemFont(ofSize: 20)
        let label2Y = imageViewOnScrollView2.frame.maxY + sp
        labelOnScrollView2.frame = CGRect(x: sp, y: label2Y, width: ww - 2 * sp, height: 0)
        labelOnScrollView2.sizeToFit()
 */
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
    func getTextEn1()->String{
        var text = "Using a simple goggle like the one shown in the top-left photo allows you to capture stable, shake-free footage. By fixing the iPhone in place with a cut piece of cardboard against your cheeks and forehead, as shown in the top-right photo, you can also achieve relatively stable video.\n"
        
        text += "Even just holding the iPhone with your palms spread and supporting it from both index to little fingers, while pressing both thumbs against your cheeks, can produce stable footage once you get used to it. \n\nThe most recently recorded nystagmus video is displayed as a thumbnail in the upper right corner. Tapping the thumbnail will play the video. The button below the thumbnail shows a list of all recorded videos, which are displayed by recording date and duration. You can tap an item to play it, or swipe it left to delete it. All nystagmus videos are stored in the iCapNYS album, so you can also manage them—playback, deletion, and sharing—using the Photos app.\n\n"
        return text
    }
    func getTextEn()->String{
        var text = "A custom mount goggle for use with the rear camera was created using a 3D printer (see the photo just above). The iPhone is attached to the goggle using double-sided adhesive gel tape. When using this mount, set the screen cropping to ‘Crop 2’. A 100-yen LED light from Daiso is used for illumination. The 3D data is available at: \"https://kuroda33.com/jibika\".\n\n"
        text += "2: Eye movement recording\n"
        text += "The camera can be switched sequentially using the button at the bottom right. Pressing and holding the button will return to the previous camera. \n\n"
        text += "3: Eye movement playback\n"
        text += "You can play back the most recently recorded eye movement video by tapping the thumbnail in the top right. Use the button below the thumbnail to navigate to the video list screen. The videos are displayed in a list sorted by recording date and duration. Tapping an item will play the video. You can delete an item by swiping left on it. The eye movement videos are stored in the iCapNYS album, so you can manage playback, deletion, and sharing through the Photos app as well. You can send the currently playing video via email from the playback screen.\n\n"
        text += "4: Gyro Button (Left bottom)\n"
        text += "If you set the IP address specified by the Windows application CapNYS, you can send Gyro data to that CapNYS via WiFi. The Windows version of CapNYS can be downloaded from  \"https://kuroda33.com/jibika\".\n\n"
        text += "5: Reha Button (Left bottom)\n"
        text += "The iPhone's pitch, roll, and yaw movements are checked, then trigger alarms, and display the count. This feature is intended for vestibular rehabilitation.\n\n"
 //       text += "iCapNYS Version 5.6 (2025-6-13)\n\n"

        return text
    }
    func getTextJa1()->String{
        var text = "上左写真のような簡単なゴーグルを使うとブレのない映像が撮れます。上右写真のようにカットした段ボールで、頬と額に固定するとブレの少ない映像が撮れます。\n手の平を広げて両手の人差し指から小指まででiPhoneを支え、両手の親指を両頬に当てて固定するだけでも、慣れればブレの少ない映像が撮れます。\n\n"
        text += "最後に撮影した眼振動画は右上にサムネイルとして表示され、それをタップすると再生出来ます。サムネイルの下のボタンで動画が一覧表示されます。動画は撮影日時（長さ）で一覧表示されます。項目をタップすると再生出来ます。項目を左にスワイプスすると削除できます。眼振動画はiCapNYSアルバムの中に入っていますので、写真アプリでも再生、削除、送信などの管理ができます。\n再生画面から再生中の動画をメールで送信できます。\n\n"
        return text
    }
    func getTextJa()->String{
        var text = "バックカメラ利用時のための固定ゴーグルを３Dプリンターで作りました（上写真）。照明にはダイソーの100円LEDライトを利用しています。iPhoneを両面粘着ゲルテープでこのゴーグルに貼り付けます。この固定具を利用するときは、画面切り取りを「切取２」に設定して下さい。３Dデータは \"https://kuroda33.com/jibika\" に載せています。\n\n"
        text += "2: 眼振録画\n"
        text += "右下のボタンで使用するカメラを順次選択できます。ボタンを長押しすると前のカメラに戻れます。\n"
        text += "フロントカメラ使用時、画面中央ボタンは録画ボタンと同等です。フロントカメラの解説付自動90秒では、録画ボタンで解説映像が流れ、それが終わると録画が開始され、90秒で自動的に録画終了します。なお、録画ボタンで解説映像をスキップ、録画の途中終了ができます。\n\n"
        text += "3: 眼振再生\n"
        text += "最後に撮影した眼振動画は右上のサムネイルをタップすると再生出来ます。\nその下のボタンで動画が一覧表示されます。動画は撮影日時（長さ）で一覧表示されます。項目をタップすると再生出来ます。項目を左にスワイプスすると削除できます。眼振動画はiCapNYSアルバムの中に入っていますので、写真アプリでも再生、削除、送信などの管理ができます。\n再生画面から再生中の動画をメールで送信できます。\n\n"
        text += "4: Gyroボタン（左下）\n"
        text += "Gyro画面では、WindowsアプリCapNYSが指定するIP-Addressを設定すると、GyroDataをWiFiでそのCapNYSに送信できます。\nWindows用CapNYSは \"https://kuroda33.com/jibika\" からダウンロードできます。詳細はCapNYSのHelpをご覧ください。\n\n"
        text += "5: リハボタン（左下）\n"
        text += "リハ画面に移動します。iPhoneのpitch, roll, yawの動きをチェックしてアラームを鳴らし、回数を表示します。前庭リハビリのための機能です。\n\n"
   //     text += "iCapNYS Version 5.6 (2025-6-13)\n\n"
        return text
    }
}
