//
//  RARFMaskVideoURLView.swift
//  RARFSlider
//
//  Created by 永田大祐 on 2019/03/11.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import UIKit
import AVFoundation

@available(iOS 13.0, *)
public final class RARFMaskVideoModel: NSObject {

    private var height: CGFloat?
    private var heightY: CGFloat?
    private var numberOfFrames = 1.0
    private var duration: Float64 = 0.0
    private var thumbnailViews = [UIImageView]()
    private var videoURL  = URL(fileURLWithPath: "")
    private var slider: RARFSliderView?


    public func setURL(url: URL,sliderView: RARFSliderView, height: CGFloat, heightY: CGFloat) {
        self.slider = sliderView
        guard let sliderView = slider else { return }

        sliderView.rARFUrl = url
        sliderView.rARFAVPlayerModel.video(url: url)

        self.videoURL = url
        self.heightY = heightY
        self.height = height
        self.duration = videoDuration(videoURL: url)
        self.updateThumbnails(sliderView: sliderView)
        numberOfFrames = framesNumber()
    }

    private func framesNumber() -> Double {
        enum CaseNumber: Double { case zero, one, two, three, four, five }
        switch duration {
        case 0..<5: return CaseNumber.five.rawValue
        case 5..<10: return CaseNumber.four.rawValue
        case 10..<15: return CaseNumber.three.rawValue
        default: return CaseNumber.one.rawValue
        }
    }

    private func videoDuration(videoURL: URL) -> Float64 {
        let source = AVURLAsset(url: videoURL)
        return CMTimeGetSeconds(source.duration)
    }

    private func updateThumbnails(sliderView: UIView) {
        let backgroundQueue = DispatchQueue(label: "com.app.queue", qos: .background, target: nil)
        backgroundQueue.async { _ = self.updateThumbnails(sliderView: sliderView, videoURL: self.videoURL, duration: self.duration) }
    }

    private func updateThumbnails(sliderView: UIView, videoURL: URL, duration: Float64) -> [UIImageView] {
        var thumbnails = [UIImage]()

        for view in self.thumbnailViews {
            DispatchQueue.main.sync { view.removeFromSuperview() }
        }

        for i in 0..<Int(ceil(duration)*numberOfFrames) {
            DispatchQueue.main.sync {
                let thumbnail = thumbnailFromVideo(videoUrl: videoURL,
                                                   time: CMTimeMake(value: Int64(i), timescale: Int32(numberOfFrames)))
                thumbnails.append(thumbnail)
            }
        }
        self.addImagesToView(images: thumbnails)
        return self.thumbnailViews
    }

    private func thumbnailFromVideo(videoUrl: URL, time: CMTime) -> UIImage {
        let asset: AVAsset = AVAsset(url: videoUrl) as AVAsset
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true

        do{
            let cgImage = try imgGenerator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage
        } catch let error { print(error,"error") }

        return UIImage()
    }

    private func addImagesToView(images: [UIImage]) {
        guard let sliderView = slider else { return }

        DispatchQueue.main.async {
            var xPos: CGFloat = 0.0
            self.thumbnailViews.removeAll()
            let width = CGFloat(sliderView.frame.size.width) / CGFloat(Int(ceil(self.duration*self.numberOfFrames)))
            for image in images {
                let imageViews = UIImageView()
                imageViews.image = image
                imageViews.image = image.ResizeUIImage(width: width, height: self.height ?? CGFloat())
                imageViews.clipsToBounds = true
                imageViews.frame = CGRect(x: xPos,
                                          y: 0,
                                          width: width,
                                          height: self.height ?? CGFloat())
                sliderView.rARFPreView?.frame.origin.y = self.heightY ?? CGFloat()
                sliderView.rARFPreView?.addSubview(imageViews); sliderView.rARFPreView?.sendSubviewToBack(imageViews)
                xPos += CGFloat(width)
            }
            sliderView.cALayerView.tori(views: sliderView.lineDashView, sideWhide: sliderView.rARFSideWhide, topDownWhide: sliderView.rARFTopDownWhide, borderWidth: sliderView.rARFBorderWidth, borderColor: sliderView.rARFBorderColor, opacity: sliderView.rARFOpacity)
        }
    }
}

private extension UIImage {
    func ResizeUIImage(width: CGFloat, height: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height),true,0.0)

        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage() }
        UIGraphicsEndImageContext()

        return newImage
    }
}
