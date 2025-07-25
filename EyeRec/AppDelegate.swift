//
//  AppDelegate.swift
//  iCapNYS
//
//  Created by 黒田建彰 on 2020/09/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        sleep(UInt32(1.0))
     //   let zero:Float=0
     //   UserDefaults.standard.set(zero,forKey: "contentOffsetY")
        return true
    }
    
//    func getUserDefaultInt(str:String,ret:Int) -> Int{
//        if (UserDefaults.standard.object(forKey: str) != nil){//keyが設定してなければretをセット
//            return UserDefaults.standard.integer(forKey:str)
//        }else{
//            UserDefaults.standard.set(ret, forKey: str)
//            return ret
//        }
//    }
//    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
//
//        let landscapeSide=getUserDefaultInt(str: "landscapeSide", ret: 0)
//        if landscapeSide==0{
//            return UIInterfaceOrientationMask.landscapeRight
//        }else{
//            return UIInterfaceOrientationMask.landscapeLeft
//        }
//    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

