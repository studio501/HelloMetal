/// Copyright (c) 2021 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import MetalKit


class Renderer: NSObject{
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var library: MTLLibrary!
  
  var uniforms = Uniforms()
  
  let depthStencilState: MTLDepthStencilState
  
  static func buildDepthStencilState() -> MTLDepthStencilState? {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .less
    descriptor.isDepthWriteEnabled = true
    return Renderer.device.makeDepthStencilState(descriptor: descriptor)
  }
  let lighting = Lighting()
  
  // Camera holds view and projection matrices
  lazy var camera: Camera = {
    let camera = ArcballCamera()
    camera.distance = 4.3
    camera.target = [0, 1.2, 0]
    camera.rotation.x = Float(-10).degreesToRadians
    return camera
  }()
  
  lazy var sunlight: Light = {
    var light = buildDefaultLight()
    light.position = [1, 2, -2]
    return light
  }()
  
  lazy var ambientLight: Light = {
    var light = buildDefaultLight()
    light.color = [0.5,1,0]
    light.intensity = 0.15
    light.type = Ambientlight
    return light
  }()
  
  lazy var redLight: Light = {
    var light = buildDefaultLight()
    light.position = [-0,0.5,-0.5]
    light.color = [1,0,0]
    light.attenuation = float3(1,3,4)
    light.type = Pointlight
    return light
  }()
  
  lazy var spotlight: Light = {
    var ligth = buildDefaultLight()
    ligth.position = [0.4,0.8,1]
    ligth.color = [1,0,1]
    ligth.attenuation = float3(1,0.5,0)
    ligth.type = Spotlight
    ligth.coneAngle = Float(40).degreesToRadians
    ligth.coneDirection = [-2, 0, -1.5]
    ligth.coneAttenuation = 12
    return ligth
  }()
  
//  var lights: [Light] = []
  
  var fragmentUniforms = FragmentUniforms()
  
  // Array of modles allows for rendering multiple models
  var models : [Model] = []
  
  // debug drawing of lights
  lazy var lightPipelineState: MTLRenderPipelineState = {
      return buildLightPipelineState()
  }()
  
  
  init(metalView: MTKView) {
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue() else {
        fatalError("GPU not available")
    }
    Renderer.device = device
    Renderer.commandQueue = commandQueue
    Renderer.library = device.makeDefaultLibrary()
    metalView.device = device
    
    // give the rasterizer depth-stencil state
    metalView.depthStencilPixelFormat = .depth32Float
    
    depthStencilState = Renderer.buildDepthStencilState()!
    super.init()
    metalView.clearColor = MTLClearColor(red: 0.7, green: 0.9,
                                         blue: 1.0, alpha: 1)
    metalView.delegate = self
    
    // add the model to the scene
    let house = Model(name: "lowpoly-house.obj")
    house.position = [0,0,0]
    house.rotation = [0, Float(35).degreesToRadians,0]
    models.append(house)
    
//    let train = Model(name: "train.obj")
//    train.position = [0, 0, 0]
//    train.rotation = [0, Float(45).degreesToRadians, 0]
//    models.append(train)
//
//    let fir = Model(name: "treefir.obj")
//    fir.position = [1.4,0,0]
//    models.append(fir)
    
    mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
    
//    lights.append(sunlight)
//    lights.append(ambientLight)
//    lights.append(redLight)
//    lights.append(spotlight)
    
    fragmentUniforms.lightCount = UInt32(lighting.count)
  }
  
  func buildDefaultLight() -> Light{
    var light = Light()
    light.position = [0,0,0]
    light.color = [1,1,1]
    light.specularColor = [0.6,0.6,0.6]
    light.intensity = 1
    light.attenuation = float3(1,0,0)
    light.type = Sunlight
    return light
  }
}

extension Renderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    camera.aspect = Float(view.bounds.width)/Float(view.bounds.height)
  }
  
  func draw(in view: MTKView) {
    guard
      let descriptor = view.currentRenderPassDescriptor,
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
      let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
        return
    }
    renderEncoder.setDepthStencilState(depthStencilState)
    
    uniforms.projectionMatrix = camera.projectionMatrix
    uniforms.viewMatrix = camera.viewMatrix
    fragmentUniforms.cameraPosition = camera.position
    
    var lights = lighting.lights
    renderEncoder.setFragmentBytes(&lights, length: MemoryLayout<Light>.stride * lights.count, index: Int(BufferIndexLight.rawValue))
    renderEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, index: Int(BufferFragUniforms.rawValue))
    // render all the models in the array
    for model in models {
      // model matrix now comes from the Model's superclass: Node
      uniforms.modelMatrix = model.modelMatrix
      uniforms.normalMatrix = model.modelMatrix.upperLeft
      
      renderEncoder.setVertexBytes(&uniforms,
                                   length: MemoryLayout<Uniforms>.stride, index: Int(BufferIndexUniforms.rawValue))
      
      renderEncoder.setRenderPipelineState(model.pipelineState)

      for mesh in model.meshes {
        let vertexBuffer = mesh.mtkMesh.vertexBuffers[0].buffer
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0,
                                      index: 0)

        for submesh in mesh.submeshes {
          let mtkSubmesh = submesh.mtkSubmesh
          // set the fragment tecture here:
          // Buffers, textures and sampler states are held in argument tables and, as you???ve seen, you access them by index numbers
          renderEncoder.setFragmentTexture(submesh.textures.baseColor, index: Int(BaseColorTexture.rawValue))
          
          renderEncoder.drawIndexedPrimitives(type: .triangle,
                                              indexCount: mtkSubmesh.indexCount,
                                              indexType: mtkSubmesh.indexType,
                                              indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                              indexBufferOffset: mtkSubmesh.indexBuffer.offset)
        }
      }
    }
//    debugLights(renderEncoder: renderEncoder, lightType: Sunlight)
//    debugLights(renderEncoder: renderEncoder, lightType: Pointlight)
//    debugLights(renderEncoder: renderEncoder, lightType: Spotlight)
    renderEncoder.endEncoding()
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
