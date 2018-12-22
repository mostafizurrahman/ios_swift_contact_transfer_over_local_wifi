//
//  AppDelegate.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 20/12/18.
//  Copyright © 2018 Mostafizur Rahman. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

public extension UIDevice {
    
    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "PO5"
            case "iPod7,1":                                 return "PO6"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "PH4"
            case "iPhone4,1":                               return "PH4s"
            case "iPhone5,1", "iPhone5,2":                  return "PH5"
            case "iPhone5,3", "iPhone5,4":                  return "PH5c"
            case "iPhone6,1", "iPhone6,2":                  return "PH5s"
            case "iPhone7,2":                               return "PH6"
            case "iPhone7,1":                               return "PH6+"
            case "iPhone8,1":                               return "PH6s"
            case "iPhone8,2":                               return "P6s+"
            case "iPhone9,1", "iPhone9,3":                  return "PH7"
            case "iPhone9,2", "iPhone9,4":                  return "PH7+"
            case "iPhone8,4":                               return "PHSE"
            case "iPhone10,1", "iPhone10,4":                return "PH8"
            case "iPhone10,2", "iPhone10,5":                return "PH8+"
            case "iPhone10,3", "iPhone10,6":                return "PHX"
            case "iPhone11,2":                              return "PHXS"
            case "iPhone11,4", "iPhone11,6":                return "PXSM"
            case "iPhone11,8":                              return "PHXR"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "PA2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "PA3"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "PA4"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "PAA"
            case "iPad5,3", "iPad5,4":                      return "PAA2"
            case "iPad6,11", "iPad6,12":                    return "PA5"
            case "iPad7,5", "iPad7,6":                      return "PA6"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "PAMI"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "PMI2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "MPI3"
            case "iPad5,1", "iPad5,2":                      return "PMI4"
            case "iPad6,3", "iPad6,4":                      return "P97"
            case "iPad6,7", "iPad6,8":                      return "P129"
            case "iPad7,1", "iPad7,2":                      return "2129" //2 for second gen
            case "iPad7,3", "iPad7,4":                      return "P105"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "P11"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "3129" //3 for 3rd gen
            case "AppleTV5,3":                              return "ATV"
            case "AppleTV6,2":                              return "ATV4"//4 for four K
            case "AudioAccessory1,1":                       return "HPOD"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "ATV4"
            case "AppleTV6,2": return "ATVK"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }
        
        return mapToDevice(identifier: identifier)
    }()
    
}
extension UIColor {
    convenience init(rgb: Int) {
        self.init(
            red: CGFloat((rgb >> 24) & 0xFF),
            green: CGFloat((rgb >> 16) & 0xFF),
            blue: CGFloat((rgb >> 8) & 0xFF),
            alpha:1.0
        )
    }
}
