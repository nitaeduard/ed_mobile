//
//  EDAdMobManager.swift
//  EDMobile
//
//  Created by Eduard Radu Nita on 02/11/2024.
//

import GoogleMobileAds
import SwiftUI
import UIKit

class EDAdMobManager {
    #if DEBUG
        static let appId = "ca-app-pub-3940256099942544/2435281174"
    #else
        static let appId = ""
    #endif

    static func setup() {
        GADMobileAds.sharedInstance().start()
    }
}

struct EDAdBannerInternalView: UIViewRepresentable {
    let adSize: GADAdSize

    init(_ adSize: GADAdSize) {
        self.adSize = adSize
    }

    func makeUIView(context: Context) -> UIView {
        /// Wrap the GADBannerView in a UIView.
        /// GADBannerView automatically reloads a new ad when its
        /// frame size changes; wrapping in a UIView container insulates the GADBannerView from size
        /// changes that impact the view returned from makeUIView.
        let view = UIView()
        view.addSubview(context.coordinator.bannerView)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        print("size: \(adSize.size.height)")
        context.coordinator.bannerView.adSize = adSize
    }

    func makeCoordinator() -> EDBannerCoordinator {
        return EDBannerCoordinator(self)
    }
}

class EDBannerCoordinator: NSObject, GADBannerViewDelegate {
    private(set) lazy var bannerView: GADBannerView = {
        let banner = GADBannerView(adSize: parent.adSize)
        banner.adUnitID = EDAdMobManager.appId
        banner.load(GADRequest())
        banner.delegate = self
        return banner
    }()

    let parent: EDAdBannerInternalView

    init(_ parent: EDAdBannerInternalView) {
        self.parent = parent
    }
}
