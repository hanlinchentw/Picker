//
//  SceneDelegate.swift
//  FoodPicker
//
//  Created by 陳翰霖 on 2020/7/5.
//  Copyright © 2020 陳翰霖. All rights reserved.
//

import UIKit
import Firebase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        window?.makeKeyAndVisible()
        window?.rootViewController = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()
        let home = HomeController()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.window?.rootViewController = home
        }
    }
    func resize(image: UIImage, newWidth: CGFloat) -> UIImage {

        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: image.size.height))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: image.size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
}

