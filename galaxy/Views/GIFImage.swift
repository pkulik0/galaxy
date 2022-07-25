//
//  GIF.swift
//  galaxy
//
//  Created by pkulik0 on 25/07/2022.
//

import SwiftUI

public struct GIFImage: UIViewRepresentable {
    let data: Data
    var speed: Double = 1.0

    public func makeUIView(context: Context) -> UIGIFImage {
        return UIGIFImage(data: data, speed: speed)
    }
    
    public func updateUIView(_ uiView: UIGIFImage, context: Context) {
        uiView.updateGIF(data: data, speed: speed)
    }
}

public class UIGIFImage: UIView {
    private let imageView = UIImageView()
    private var speed: Double = 1.0
    private var data: Data?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(data: Data, speed: Double) {
        self.init()
        self.data = data
        self.speed = speed
        initView()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        self.addSubview(imageView)
    }
    
    func updateGIF(data: Data, speed: Double) {
        imageView.image = UIImage.getGIF(data: data, speed: speed)
    }
    
    private func initView() {
        imageView.contentMode = .scaleAspectFit
    }
}
