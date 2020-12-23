//
//  MetalViewController.swift
//  MetalExample
//
//  Created by Patrick Abadi on 2020-12-23.
//

import UIKit
import Metal
import MetalKit

public final class MetalViewController: UIViewController
{
    var metalView: MTKView!
    var renderer: Renderer!
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        
        print("My GPU is: \(device)")
        
        metalView = MTKView()
        self.view = metalView
        
        // Set the view to use the default device
        if let view = view as? MTKView {
            view.device = device
            view.backgroundColor = UIColor.clear
            // we need this to enable depth test
            view.depthStencilPixelFormat = .depth32Float
            view.contentScaleFactor = 1
            
            renderer = Renderer(mtkView: metalView)
            
            view.delegate = renderer

        }
    }
}
