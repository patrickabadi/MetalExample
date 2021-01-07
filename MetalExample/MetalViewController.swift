//
//  MetalViewController.swift
//  MetalExample
//
//  Created by Patrick Abadi on 2020-12-23.
//

import UIKit
import Metal
import MetalKit
import ARKit

public final class MetalViewController: UIViewController, ARSessionDelegate
{
    var metalView: MTKView!
    var renderer: Renderer!
    private let session = ARSession()
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        
        print("My GPU is: \(device)")
        
        session.delegate = self
        
        metalView = MTKView()
        self.view = metalView
        
        // Set the view to use the default device
        if let view = view as? MTKView {
            view.device = device
            view.backgroundColor = UIColor.red
            view.depthStencilPixelFormat = .depth32Float
            view.contentScaleFactor = 1
            view.delegate = self
            
            renderer = Renderer(session: session, mtkView: metalView, renderDestination: metalView)
            renderer.drawRecResized(size: view.bounds.size)
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        
        session.run(configuration)
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    public override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    public func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else {return}
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0} ).joined(separator: "\n")
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "The AR Session Failed", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                if let configuration = self.session.configuration {
                    self.session.run(configuration, options: .resetSceneReconstruction)
                }
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension MetalViewController:MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.drawRecResized(size: size)
    }
    
    public func draw(in view:MTKView) {
        renderer.draw()
    }
}
    
protocol RenderDestinationProvider {
    var currentRenderPassDescriptor: MTLRenderPassDescriptor? {get}
    var currentDrawable: CAMetalDrawable? {get}
    var colorPixelFormat: MTLPixelFormat {get set}
    var depthStencilPixelFormat: MTLPixelFormat {get set}
    var sampleCount: Int {get set}
}

extension MTKView: RenderDestinationProvider {
}
