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
    let pipelineState: MTLRenderPipelineState
    let vertices = [Vertex(color: [1,0,0,1], pos: [-1,-1]),
                    Vertex(color: [0,1,0,1], pos: [0,1]),
                    Vertex(color: [0,0,1,1], pos: [1,-1])]
    let vertexBuffer: MTLBuffer
    
    init?(mtkView: MTKView) {
        device = mtkView.device!
        commandQueue = device.makeCommandQueue()!
        
        do {
            pipelineState = try Renderer.buildRenderPipelineWith(device: device, metalKitView: mtkView)
        } catch {
            print("Unable to compile render pipeline state: \(error)")
            return nil
        }
        
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])!
    }
    
    class func buildRenderPipelineWith(device: MTLDevice, metalKitView: MTKView) throws -> MTLRenderPipelineState {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        let library = device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        guard let renderPassDescriptor =  view.currentRenderPassDescriptor else {return }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
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
