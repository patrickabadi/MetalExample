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
        
        // prepare everything to be sent to the gpu, but don't send yet
        renderEncoder.endEncoding()
        
        // when the gpu is done, send the result to the mtkview drawable so it shows
        // up on the screen
        commandBuffer.present(view.currentDrawable!)
        
        // now send everything to the gpu
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
