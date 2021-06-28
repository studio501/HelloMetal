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
    let size1 = self.view.frame.size
    
//    do {
//      let len: Float = 0.8
//      //
//      let vertexData: [Float] = [
//         0.0,  len, 0.0,
//        -len, -len, 0.0,
//        len, -len, 0.0,
//
//        0.5,  0.5, 0.0,
//        0.8,  0.5, 0.0,
//        0.8,  0.8, 0.0
//      ]
//
//      let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0]) // 1
//      vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: []) // 2
//    }
    let radius : Float = Float(self.view.frame.size.width) / 2
    let fx = radius / Float(self.view.frame.size.width)
    let fy = radius / Float(self.view.frame.size.height)

      // 1
      let allocator = MTKMeshBufferAllocator(device: device)
    
    
    //
    guard let assetURL = Bundle.main.url(forResource: "train", withExtension: ".obj") else {
      fatalError()
    }
    
    let vertexDescriptor = MTLVertexDescriptor()
    vertexDescriptor.attributes[0].format = .float3
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0
    
    vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
    let meshDescriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
    (meshDescriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
    
    let asset = MDLAsset(url: assetURL, vertexDescriptor: meshDescriptor, bufferAllocator: allocator)
    
      
      // 2
      let mdlMesh =
//        MDLMesh(sphereWithExtent: [fx, fy, 0.75], segments: [100, 100], inwardNormals: false, geometryType: .triangles, allocator: allocator)
//        MDLMesh(coneWithExtent: [1,1,1], segments: [10,10], inwardNormals: false, cap: true, geometryType: .triangles, allocator: allocator)
        asset.childObjects(of: MDLMesh.self).first as! MDLMesh
//        Primitive.makeCube(device: device, size: 0.5, uiview: self.view)
        
    
    
//        MDLMesh(hemisphereWithExtent: [fx,fy,0.5], segments: [100,100], inwardNormals: false, cap: false, geometryType: .triangles, allocator: allocator)
    
//    do{
//      // export the cone
//
//      // begin export code
//      // 1
//      let asset = MDLAsset()
//      asset.add(mdlMesh)
//      // 2
//      let fileExtension = "obj"
//      guard MDLAsset.canExportFileExtension(fileExtension) else {
//        fatalError("Can't export a .\(fileExtension) format")
//      }
//      // 3
//      do {
//
//        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
//        print(path)
//        let url = NSURL(fileURLWithPath: path)
//        if let pathComponent = url.appendingPathComponent("primitive.\(fileExtension)") {
////            let filePath = pathComponent.path
////            let fileManager = FileManager.default
////            if fileManager.fileExists(atPath: filePath) {
////                print("FILE AVAILABLE")
////            } else {
////                print("FILE NOT AVAILABLE")
////            }
//          try asset.export(to: pathComponent)
//        } else {
//            print("FILE PATH NOT AVAILABLE")
//        }
//
////        let url = playgroundSharedDataDirectory.appendingPathComponent(
////          "primitive.\(fileExtension)")
////        try asset.export(to: url)
//      } catch {
//        fatalError("Error \(error.localizedDescription)")
//      }
//      // end export code
//    }
      
      // 3
      mesh = try? MTKMesh(mesh: mdlMesh, device: device)
      vertexBuffer = mesh!.vertexBuffers[0].buffer
    
    // 1
    let defaultLibrary = device.makeDefaultLibrary()!
    let fragmentProgram = defaultLibrary.makeFunction(name: "fragment_main")
    let vertexProgram = defaultLibrary.makeFunction(name: "vertex_main")
        
    // 2
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.vertexFunction = vertexProgram
    pipelineStateDescriptor.fragmentFunction = fragmentProgram
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineStateDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh!.vertexDescriptor)
    
        
    // 3
    pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)

    commandQueue = device.makeCommandQueue()
    
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    let url = NSURL(fileURLWithPath: path)
    if let pathComponent = url.appendingPathComponent("Shaders.metal") {
        let filePath = pathComponent.path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath) {
            print("FILE AVAILABLE")
        } else {
            print("FILE NOT AVAILABLE")
        }
    } else {
        print("FILE PATH NOT AVAILABLE")
    }
    
    
    
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
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    var currentTime = sin(_time)
    renderEncoder.setVertexBytes(&currentTime, length: MemoryLayout<Float>.stride, index: 1)
//    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 2)
    
//    guard let submesh = mesh.submeshes.first else {
//      fatalError()
//    }
//    renderEncoder.setTriangleFillMode(.lines)
//    renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: 0)
    
    renderEncoder.setTriangleFillMode(.lines)
    for submesh in mesh.submeshes{
      renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
    }
    
    
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

