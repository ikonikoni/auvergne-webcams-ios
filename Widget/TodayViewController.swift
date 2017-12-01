//
//  TodayViewController.swift
//  Widget
//
//  Created by Drusy on 02/06/2017.
//
//

import UIKit
import NotificationCenter
import Kingfisher
import RealmSwift
import Alamofire
import SwiftyUserDefaults
import NVActivityIndicatorView

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var webcamTitleLabel: UILabel!
    @IBOutlet weak var noFavoriteLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var nvActivityIndicatorView: NVActivityIndicatorView!
    @IBOutlet var shadowViews: [UIView]!
    @IBOutlet weak var errorButton: UIButton! {
        didSet {
            errorButton.titleLabel?.numberOfLines = 0
        }
    }

    var realm: Realm? = nil
    var completionHandler: ((NCUpdateResult) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Realm
        var config = Realm.Configuration()
        let realmPath: URL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.fr.openium.AuvergneWebcams")!
            .appendingPathComponent("db.realm")
        config.fileURL = realmPath
        Realm.Configuration.defaultConfiguration = config
        realm = try? Realm()
        
        // App link
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
        view.addGestureRecognizer(tapGesture)
        
        // Size
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        
        // Initial state
        errorButton.alpha = 0
        contentView.alpha = 0
        noFavoriteLabel.alpha = 0
        nvActivityIndicatorView.alpha = 0
        
        // Shadow
        shadowViews.forEach { view in
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOffset = CGSize(width: 1, height: 1)
            view.layer.shadowOpacity = 0.5
            view.layer.shadowRadius = 4
        }
        
        // Loader
        nvActivityIndicatorView.color = UIColor.white
        nvActivityIndicatorView.type = .ballGridPulse
    }
    
    // MARK: -
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        switch activeDisplayMode {
        case .expanded:
            self.preferredContentSize = CGSize(width: maxSize.width, height: 300)
        case .compact:
            self.preferredContentSize = maxSize
        }
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        self.completionHandler = completionHandler
        guard let realm = realm else {
            onError()
            return
        }
        
        if let favoriteWebcams = favoriteWebcams() {
            if !favoriteWebcams.isEmpty {
                if let currentWebcamUid = Defaults[.currentWidgetWebcamUid], let webcam = realm.object(ofType: Webcam.self, forPrimaryKey: currentWebcamUid) {
                    if favoriteWebcams.contains(webcam) {
                        onShow(webcam)
                    } else {
                        onShow(favoriteWebcams.first)
                    }
                } else {
                    onShow(favoriteWebcams.first)
                }
            } else {
                onNoFavorite()
            }
        } else {
            onError()
        }
    }
    
    // MARK: -
    
    fileprivate func favoriteWebcams() -> [Webcam]? {
        guard let realm = realm else { return nil }
        
        return Array(realm.objects(Webcam.self).filter("%K == true", #keyPath(Webcam.favorite)))
    }
    
    fileprivate func onShow(_ webcam: Webcam?) {
        guard let webcam = webcam else {
            onError()
            return
        }
        
        startLoading()
        webcamTitleLabel.text = webcam.title
        Defaults[.currentWidgetWebcamUid] = webcam.uid
        
        switch webcam.contentType {
        case .image:
            if let image = webcam.preferredImage(), let url = URL(string: image) {
                loadImage(for: url)
            } else {
                onError()
            }
            
        case .viewsurf:
            loadViewsurfPreview(for: webcam)
        }
    }
    
    fileprivate func onNoFavorite() {
        UIView.animate(
            withDuration: 0.3,
            animations: { [weak self] in
                self?.noFavoriteLabel.alpha = 1
                self?.contentView.alpha = 0
                self?.errorButton.alpha = 0
                self?.nvActivityIndicatorView.alpha = 0
        },
            completion: { [weak self] _ in
                self?.nvActivityIndicatorView.stopAnimating()
                self?.completionHandler?(NCUpdateResult.noData)
        })
    }
    
    fileprivate func startLoading() {
        if !nvActivityIndicatorView.isAnimating {
            nvActivityIndicatorView.startAnimating()
        }
        
        UIView.animate(
            withDuration: 0.3,
            animations: { [weak self] in
                self?.nvActivityIndicatorView.alpha = 1
                self?.contentView.alpha = 0
                self?.noFavoriteLabel.alpha = 0
                self?.errorButton.alpha = 0
            },
            completion: nil)
    }
    
    fileprivate func onError() {
        UIView.animate(
            withDuration: 0.3,
            animations: { [weak self] in
                self?.errorButton.alpha = 1
                self?.contentView.alpha = 0
                self?.noFavoriteLabel.alpha = 0
                self?.nvActivityIndicatorView.alpha = 0
            },
            completion: { [weak self] _ in
                self?.nvActivityIndicatorView.stopAnimating()
                self?.completionHandler?(NCUpdateResult.failed)
        })
    }
    
    fileprivate func onSuccess() {
        previousButton.isHidden = true
        nextButton.isHidden = true
        
        if let uid = Defaults[.currentWidgetWebcamUid], let favorites = favoriteWebcams() {
            if let index = favorites.index(where: { $0.uid == uid }) {
                if index > 0 {
                    previousButton.isHidden = false
                }
                if index < favorites.count - 1 {
                    nextButton.isHidden = false
                }
            }
        }
        
        UIView.animate(
            withDuration: 0.3,
            animations: { [weak self] in
                self?.contentView.alpha = 1
                self?.errorButton.alpha = 0
                self?.noFavoriteLabel.alpha = 0
                self?.nvActivityIndicatorView.alpha = 0
            },
            completion: { [weak self] _ in
                self?.nvActivityIndicatorView.stopAnimating()
                self?.completionHandler?(NCUpdateResult.newData)
        })
    }
    
    fileprivate func loadViewsurfPreview(for webcam: Webcam) {
        guard let viewsurf = webcam.preferredViewsurf(), let lastURL = URL(string: "\(viewsurf)/last") else {
            return
        }
        
        let request = Alamofire.request(lastURL,
                                        method: .get,
                                        parameters: nil,
                                        encoding: URLEncoding.default,
                                        headers: ApiRequest.headers)
        request.validate()
        request.debugLog()
        
        request.responseString { [weak self] response in
            guard let strongSelf = self else { return }
            
            if let error = response.error, let statusCode = response.response?.statusCode {
                print("ERROR: \(statusCode) - \(error.localizedDescription)")
                strongSelf.onError()
            } else if let mediaPath = response.result.value?.replacingOccurrences(of: "\n", with: "") {
                if let previewURL = URL(string: "\(viewsurf)/\(mediaPath).jpg") {
                    strongSelf.loadImage(for: previewURL)
                } else {
                    self?.onError()
                }
            }
        }
    }
    
    fileprivate func loadImage(for url: URL) {
        let options: KingfisherOptionsInfo = [.forceRefresh]
        
        imageView?.kf.setImage(
            with: url,
            placeholder: nil,
            options: options,
            progressBlock: nil) { [weak self] image, error, cacheType, url in
                guard let strongSelf = self else { return }
                
                if let error = error {
                    print("ERROR: \(error.code) - \(error.localizedDescription)")
                    strongSelf.onError()
                } else {
                    strongSelf.onSuccess()
                }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onPreviousTouched(_ sender: Any) {
        guard let uid = Defaults[.currentWidgetWebcamUid] else { return }
        guard let favorites = favoriteWebcams() else { return }
        guard let index = favorites.index(where: { $0.uid == uid }) else { return }
        guard index > 0 else { return }
        
        onShow(favorites[index - 1])
    }
    
    @IBAction func onNextTouched(_ sender: Any) {
        guard let uid = Defaults[.currentWidgetWebcamUid] else { return }
        guard let favorites = favoriteWebcams() else { return }
        guard let index = favorites.index(where: { $0.uid == uid }) else { return }
        guard index < favorites.count - 1 else { return }
        
        onShow(favorites[index + 1])
    }
    
    @IBAction func onErrorTouched(_ sender: Any) {
        guard let completionHandler = completionHandler else { return }
        
        widgetPerformUpdate(completionHandler: completionHandler)
    }
    
    @objc func onViewTapped() {
        guard let url = URL(string: "auvergne-webcams://") else { return }
        
        extensionContext?.open(url, completionHandler: nil)
    }
}
