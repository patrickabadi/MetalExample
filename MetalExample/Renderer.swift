//
//  Renderer.swift
//  MetalExample
//
//  Created by Patrick Abadi on 2020-12-23.
//

import Metal
import MetalKit
import ARKit

class Renderer: NSObject {
    
    private let device: MTLDevice
    private let library: MTLLibrary
    private let commandQueue: MTLCommandQueue
    private let session: ARSession
    private let renderDestination: RenderDestinationProvider
    private let relaxedStencilState: MTLDepthStencilState
    private let depthStencilState: MTLDepthStencilState
    
    private let maxInFlightBuffers = 3
    private let particleSize: Float = 10
    private let cameraRotationThreshold = cos(2 * .degreesToRadian)
    private let cameraTranslationThreshold: Float = pow(0.02, 2)
    private var viewportSize = CGSize()
    private let orientation = UIInterfaceOrientation.landscapeRight
    
    //private let relaxedStencileState: MTLDepthStencilState
    //private let depthStencileState: MTLDepthStencilState
    
    private lazy var rgbPipelineState = makeRGBPipelineState()!
    
    private lazy var textureCache = makeTextureCache()
    private var capturedImageTextureY: CVMetalTexture?
    private var capturedImageTextureCbCr: CVMetalTexture?
    private var depthTexure: CVMetalTexture?
    private var confidenceTexture: CVMetalTexture?
    
    // multi-buffer rendering pipeline
    private let inFlightSemaphore: DispatchSemaphore
    private var currentBufferIndex = 0
    
    // rgb constants
    private lazy var rgbUniforms: RGBUniforms = {
        var uniforms = RGBUniforms()
        uniforms.radius = rgbRadius
        uniforms.viewToCamera.copy(from: viewToCamera)
        uniforms.viewRatio = Float(viewportSize.width / viewportSize.height)
        return uniforms
    }()
    private var rgbUniformsBuffers = [MetalBuffer<RGBUniforms>]()
    
    let confidenceThreshold = 1
    let rgbRadius: Float = 1
    
    // camera data
    private var sampleFrame: ARFrame { session.currentFrame! }
    private lazy var cameraResolution = Float2(Float(sampleFrame.camera.imageResolution.width), Float(sampleFrame.camera.imageResolution.height))
    private lazy var viewToCamera = sampleFrame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()
    private lazy var lastCameraTransform = sampleFrame.camera.transform
    
    
    // RGB variables
    
    init?(session: ARSession, mtkView: MTKView, renderDestination: RenderDestinationProvider) {

        self.session = session
        self.renderDestination = renderDestination
        device = mtkView.device!
        commandQueue = device.makeCommandQueue()!
        library = device.makeDefaultLibrary()!
        
        // initialize buffers
        for _ in 0 ..< maxInFlightBuffers {
            rgbUniformsBuffers.append(.init(device: device, count: 1, index: 0))
        }
        
        // rgb does not need to read write depth
        let relaxedStateDescriptor = MTLDepthStencilDescriptor()
        relaxedStencilState = device.makeDepthStencilState(descriptor: relaxedStateDescriptor)!

        // setup depth test for point cloud
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = .lessEqual
        depthStateDescriptor.isDepthWriteEnabled = true
        depthStencilState   = device.makeDepthStencilState(descriptor: depthStateDescriptor)!
        
        inFlightSemaphore = DispatchSemaphore(value: maxInFlightBuffers)


    }
    
    func drawRecResized(size: CGSize) {
        viewportSize = size
    }
    
    func draw() {
        guard let currentFrame = session.currentFrame,
              let renderDescriptor = renderDestination.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor) else {
            return
        }
        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        commandBuffer.addCompletedHandler { [weak self] commandBuffer in
            if let self = self {
                self.inFlightSemaphore.signal()
            }
        }
        
        if !updateCapturedImageTextures(frame: currentFrame) {
            return
        }
        
        currentBufferIndex = (currentBufferIndex + 1) % maxInFlightBuffers
        
        if shouldAccumulate(frame: currentFrame), updateDepthTextures(frame: currentFrame) {
            
        }
        
        if rgbUniforms.radius > 0 {
            var retainingTextures = [capturedImageTextureY, capturedImageTextureCbCr]
            commandBuffer.addCompletedHandler { buffer in
                retainingTextures.removeAll()
            }
            rgbUniformsBuffers[currentBufferIndex][0] = rgbUniforms
            renderEncoder.setDepthStencilState(relaxedStencilState)
            renderEncoder.setRenderPipelineState(rgbPipelineState)
            renderEncoder.setVertexBuffer(rgbUniformsBuffers[currentBufferIndex])
            renderEncoder.setFragmentBuffer(rgbUniformsBuffers[currentBufferIndex])
            renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(capturedImageTextureY!), index: Int(kTextureY.rawValue))
            renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(capturedImageTextureCbCr!), index: Int(KTextureCbCr.rawValue))
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(renderDestination.currentDrawable!)
        commandBuffer.commit()
        
    }
    
    private func updateCapturedImageTextures(frame: ARFrame) -> Bool {
        // create two textures (Y and CbCr) from the provided frame's captured image
        let pixelBuffer = frame.capturedImage
        guard CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else {
            return false
        }
        
        capturedImageTextureY = makeTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0)
        capturedImageTextureCbCr = makeTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1)
        
        return true
    }
    
    private func updateDepthTextures(frame: ARFrame) -> Bool {
        guard let depthMap = frame.sceneDepth?.depthMap,
              let confidenceMap = frame.sceneDepth?.confidenceMap else {
            return false
        }
        
        depthTexure = makeTexture(fromPixelBuffer: depthMap, pixelFormat: .r32Float, planeIndex: 0)
        confidenceTexture = makeTexture(fromPixelBuffer: confidenceMap, pixelFormat: .r8Uint, planeIndex: 0)
        
        return true
    }
    
    private func shouldAccumulate(frame: ARFrame) -> Bool {
        let cameraTransform = frame.camera.transform
        return /* bugbug come back to this currentPointCount == 0 ||*/ dot(cameraTransform.columns.2, lastCameraTransform.columns.2) <= cameraRotationThreshold ||
            distance_squared(cameraTransform.columns.3, lastCameraTransform.columns.3) >= cameraTranslationThreshold
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize = size
    }
}
    
private extension Renderer {
    func makeRGBPipelineState() -> MTLRenderPipelineState? {
        guard let vertexFunction = library.makeFunction(name: "rgbVertex"),
              let fragmentFunction = library.makeFunction(name: "rgbFragment") else {
            return nil
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.depthAttachmentPixelFormat = renderDestination.depthStencilPixelFormat
        descriptor.colorAttachments[0].pixelFormat = renderDestination.colorPixelFormat
        
        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    func makeTextureCache() -> CVMetalTextureCache {
        var cache: CVMetalTextureCache!
        CVMetalTextureCacheCreate(nil, nil, device, nil, &cache)
        return cache
    }
    
    func makeTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
        
        if(status != kCVReturnSuccess) {
            texture = nil
        }
        
        return texture
    }
}

