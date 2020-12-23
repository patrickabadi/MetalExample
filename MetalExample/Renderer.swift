//
//  Renderer.swift
//  MetalExample
//
//  Created by Patrick Abadi on 2020-12-23.
//

import Metal
import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    init(mtkView: MTKView) {
        device = mtkView.device!
        commandQueue = device.makeCommandQueue()!
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        guard let renderPassDescriptor =  view.currentRenderPassDescriptor else {return }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return }
        
        renderEncoder.endEncoding()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
