/// Copyright (c) 2018 Razeware LLC
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

import UIKit
import Metal

//import PlaygroundSuport
import MetalKit


class Primitive{
  static func makeCube(device: MTLDevice, size: Float, uiview: UIView) -> MDLMesh{
    let allocator = MTKMeshBufferAllocator(device: device)
    
    let fx = size
    let tx = fx * Float(uiview.frame.size.width)
    let fy = tx / Float(uiview.frame.size.height)
    
    let mesh = MDLMesh(boxWithExtent: [fx, fy, fx], segments: [1,1,1], inwardNormals: false, geometryType: .triangles, allocator: allocator)
    return mesh
  }
}

class ViewController: UIViewController {
  // property
  var device: MTLDevice!
  var metalLayer: CAMetalLayer!
  var vertexBuffer: MTLBuffer!
  var pipelineState: MTLRenderPipelineState!
  var commandQueue: MTLCommandQueue!
  var mesh: MTKMesh!
  
  
  
  var timer: CADisplayLink!
  var _time: Float = 0


  
  // member function
  override func viewDidLoad(){
    super.viewDidLoad()
    
    //
    device = MTLCreateSystemDefaultDevice()
    
    //
    metalLayer = CAMetalLayer()          // 1
    metalLayer.device = device           // 2
    metalLayer.pixelFormat = .bgra8Unorm // 3
    metalLayer.framebufferOnly = true    // 4
    metalLayer.frame = view.layer.frame  // 5
    view.layer.addSublayer(metalLayer)   // 6
    
    // 1
    let defaultLibrary = device.makeDefaultLibrary()!
    let fragmentProgram = defaultLibrary.makeFunction(name: "fragment_main")
    let vertexProgram = defaultLibrary.makeFunction(name: "vertex_main")
        
    // 2
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.vertexFunction = vertexProgram
    pipelineStateDescriptor.fragmentFunction = fragmentProgram
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    
        
    // 3
    pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)

    commandQueue = device.makeCommandQueue()
  
    
    timer = CADisplayLink(target: self, selector: #selector(gameloop))
    timer.add(to: RunLoop.main, forMode: .default)


  }
  
  func render() {
    // TODO
    _time += 0.016
    guard let drawable = metalLayer?.nextDrawable() else { return }
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
      red: 0.5,
      green: 104.0/255.0,
      blue: 55.0/255.0,
      alpha: 1.0)
    
    let commandBuffer = commandQueue.makeCommandBuffer()!
    
    let renderEncoder = commandBuffer
      .makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
    renderEncoder.setRenderPipelineState(pipelineState)
    
    // drawing code here
    var vertices: [float3] = [[0, 0, 0.5]];
    let originalBuffer = device.makeBuffer(bytes: &vertices, length: MemoryLayout<float3>.stride * vertices.count, options: []);
    
    var lightGrayColor: float4 = [0.7,0.7,0.7,0.5];
    
    renderEncoder.setVertexBuffer(originalBuffer, offset: 0, index: 0)
    renderEncoder.setFragmentBytes(&lightGrayColor, length: MemoryLayout<float4>.stride, index: 0);
    
    renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
    
    var martix = matrix_identity_float4x4
    martix.columns.3 = [0.4,-0.4,0,1]
    //vertices[0] += [0.3,-0.4,0]
    vertices = vertices.map {
      let vertex = martix * float4($0,1)
      return [vertex.x,vertex.y,vertex.z]
    }
    var transBuffer = device.makeBuffer(bytes: &vertices, length: MemoryLayout<float3>.stride * vertices.count, options: [])
    
    var redColor: float4 = [1,0,0,1];
    renderEncoder.setVertexBuffer(transBuffer, offset: 0, index: 0)
    renderEncoder.setFragmentBytes(&redColor, length: MemoryLayout<float4>.stride, index: 0)
    renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
    
    
    renderEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()

  }

  @objc func gameloop() {
    autoreleasepool {
      self.render()
    }
  }


}

