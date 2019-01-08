//
//  AdViewController.swift
//  ContactTransfer
//
//  Created by Mostafizur Rahman on 8/1/19.
//  Copyright © 2019 Mostafizur Rahman. All rights reserved.
//

import UIKit
import GoogleMobileAds
import Firebase

class AdViewController: UINavigationController {

    var admob_banner_id:String = ""
    var admob_interstitial_id:String = "ca-app-pub-3196870140700893/5575879673"//"ca-app-pub-3196870140700893/5736839465"
    var admob_reward:String = ""
    var admob_adid:String = ""
    var fan_interstitial = ""
    var shouldPlaceAd = false
    var interstitial_admob: GADInterstitial?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FirebaseApp.configure()
        if let __app_id = UserDefaults.standard.value(forKey: "admob_id") as? String {
            GADMobileAds.configure(withApplicationID: __app_id)
        } else {
            GADMobileAds.configure(withApplicationID: "ca-app-pub-3196870140700893~4484313377")
        }
        self.changeAdGroup()
        
        // Do any additional setup after loading the view.
    }
    fileprivate func changeAdGroup(){
        self.shouldPlaceAd = UserDefaults.standard.bool(forKey: "UseAd")
        
        if (!self.shouldPlaceAd) {
            let __ref = Database.database().reference()
            __ref.observe(.value) { (fireData) in
                let __firstData = fireData.children
                while true  {
                    if let __nodeObj = __firstData.nextObject() as? DataSnapshot {
                        let __key = __nodeObj.key
                        if __key.elementsEqual("app_config") {
                            
                            if let __data = __nodeObj.value as? [String:AnyObject] {
                                
                                for __value in __data {
                                    if __value.key.elementsEqual("contact_transfer") {
                                        if let __dic = __value.value as? [String:AnyObject]{
                                            if let __placeAD = __dic["place_ad"]  as? Bool {
                                                self.shouldPlaceAd = __placeAD
                                                UserDefaults.standard.set(__placeAD, forKey: "UseAd")
                                                if let __admob_app = __dic["admob_id"] as? String {
                                                    GADMobileAds.configure(withApplicationID: __admob_app)
                                                    UserDefaults.standard.set(__admob_app, forKey: "admob_id")
                                                }
                                                if let __admob_rew = __dic["admob_reward"] as? String {
                                                    UserDefaults.standard.setValue(__admob_rew, forKey: "admob_reward")
                                                    self.admob_reward = __admob_rew
                                                }
                                                if let __admob_banner = __dic["admob_banner"] as? String {
                                                    //                                                        self.bannerView.adUnitID = __admob_banner//"ca-app-pub-3940256099942544/2934735716"
                                                    //                                                        self.bannerView.rootViewController = self
                                                    //                                                        self.bannerView.load(GADRequest())
                                                    //                                                        self.admob_banner = __admob_banner
                                                    self.admob_banner_id = __admob_banner
                                                    UserDefaults.standard.setValue(__admob_banner, forKey: "admob_banner")
                                                }
                                                if let __admob_int = __dic["admob_interstitial"] as? String {
                                                    UserDefaults.standard.setValue(__admob_int, forKey: "admob_interstitial")
                                                    self.admob_interstitial_id = __admob_int
                                                }
                                                //                                                    if let __fan_native = __dic["fan_native"] as? String {
                                                //                                                        UserDefaults.standard.setValue(__fan_native, forKey: "fan_native")
                                                //                                                    }
                                                //                                                    if let __fan_banner = __dic["fan_banner"] as? String {
                                                //                                                        self.fan_banner = __fan_banner
                                                //                                                        UserDefaults.standard.setValue(__fan_banner, forKey: "fan_banner")
                                                //                                                    }
                                                if let __fan_int = __dic["fan_interstitial"] as? String {
                                                    UserDefaults.standard.setValue(__fan_int, forKey: "fan_interstitial")
                                                    self.fan_interstitial = __fan_int
                                                }
                                                
                                                if self.shouldPlaceAd {
                                                    self.requestAD()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        break
                    }
                }
            }
        } else {
            if let __fan_inst = UserDefaults.standard.value(forKey: "fan_interstitial") as? String {
                self.fan_interstitial = __fan_inst
            }
            if let __reward_admob = UserDefaults.standard.value(forKey: "admob_reward") as? String {
                self.admob_reward = __reward_admob
            }
            if let __admob_inst = UserDefaults.standard.value(forKey:"admob_interstitial" ) as? String {
                self.admob_interstitial_id = __admob_inst
            }
            if let __banner = UserDefaults.standard.value(forKey: "admob_banner") as? String {
                self.admob_banner_id = __banner
            }
            self.requestAD()
        }
    }

    func requestAD(){
        
        if self.shouldPlaceAd {
            self.interstitial_admob = GADInterstitial(adUnitID: self.admob_interstitial_id)
            self.interstitial_admob?.delegate = self
            self.interstitial_admob?.load(GADRequest())
        }
    }
    
    func showInterstitial(){
        if self.shouldPlaceAd {
            if let __inst = self.interstitial_admob {
                if __inst.isReady {
                    __inst.present(fromRootViewController: self)
                } else {
                    self.requestAD()
                }
            }
        }
    }
    
    
    func set(BannerAd banner:GADBannerView, withRoot root:UIViewController){
        if self.shouldPlaceAd {
            let __id =  self.admob_banner_id
            banner.adUnitID = __id
            banner.rootViewController = root
            banner.load(GADRequest())
        }
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

extension AdViewController : GADInterstitialDelegate {
    /// Tells the delegate an ad request succeeded.
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("interstitialDidReceiveAd")
    }
    
    /// Tells the delegate an ad request failed.
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print("interstitial:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that an interstitial will be presented.
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        print("interstitialWillPresentScreen")
    }
    
    /// Tells the delegate the interstitial is to be animated off the screen.
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        print("interstitialWillDismissScreen")
        self.requestAD()
    }
    
    /// Tells the delegate the interstitial had been animated off the screen.
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        print("interstitialDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app
    /// (such as the App Store), backgrounding the current app.
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        print("interstitialWillLeaveApplication")
    }
}
