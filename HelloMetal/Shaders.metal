/// Copyright (c) 2020 Razeware LLC
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

#include <metal_stdlib>
using namespace metal;

#import "Common.h"

struct VertexIn {
  float4 position [[ attribute(0) ]];
  float3 normal [[ attribute(1) ]];
};

struct VertexOut{
  float4 position [[position]];
  float3 worldPosition;
  float3 worldNormal;
};

vertex VertexOut vertex_main(const VertexIn vertex_in [[ stage_in ]], constant Uniforms &uniforms [[ buffer(BufferIndexUniforms) ]]) {
  VertexOut out{
    .position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * vertex_in.position,
//    .normal = vertex_in.normal
    .worldPosition = (uniforms.modelMatrix * vertex_in.position).xyz,
    .worldNormal = uniforms.normalMatrix * vertex_in.normal
    
  };
  return out;
}

fragment float4 fragment_main(VertexOut in [[ stage_in ]],
                              constant Light * lights [[buffer(BufferIndexLight)]],
                              constant FragmentUniforms &fragmentUniforms [[buffer(BufferFragUniforms)]]) {
//  return float4(0, 0, 1, 1);
  float3 baseColor = float3(1,1,1);
  float3 diffuseColor = 0;
  float3 ambientColor = 0;
  
  float3 specularColor = 0;
  float materialShiness = 32;
  float3 materialSpecularColor = float3(1,1,1);
  
  //
  float3 normalDirection = normalize(in.worldNormal);
  for(uint i=0; i< fragmentUniforms.lightCount; i++){
    Light light = lights[i];
    if(light.type == Sunlight){
      float3 lightDirection = normalize(-light.position);
      //
      float diffuseIntensity = saturate(-dot(lightDirection, normalDirection));
      //
      diffuseColor += light.color * baseColor * diffuseIntensity;
      //
      if(diffuseIntensity > 0){
        float3 reflection = reflect(lightDirection, normalDirection);
        float3 cameraDirection = normalize(in.worldPosition - fragmentUniforms.cameraPosition);
        float specularIntensity = pow(saturate(-dot(reflection, cameraDirection)), materialShiness);
        specularColor += light.specularColor * materialSpecularColor * specularIntensity;
      }
    }
    else if(light.type == Ambientlight){
      ambientColor += light.color * light.intensity;
    }
    else if(light.type == Pointlight){
      float d = distance(light.position, in.worldPosition);
      float3 lightDirection = normalize(in.worldPosition - light.position);
      float attenuation = 1.0 / (light.attenuation.x + light.attenuation.y * d + light.attenuation.z * d * d);
      float diffuseIntensity = saturate(-dot(lightDirection, normalDirection));
      float3 color = light.color * baseColor * diffuseIntensity;
      color *= attenuation;
      diffuseColor += color;
    }
    else if(light.type == Spotlight){
      //1
      float d = distance(light.position, in.worldPosition);
      float3 lightDirection = normalize(in.worldPosition - light.position);
      
      // 2
      float3 coneDirection = normalize(light.coneDirection);
      float spotResult = dot(lightDirection, coneDirection);
      
      // 3
      if(spotResult > cos(light.coneAngle)){
        float attenuation = 1.0 / (light.attenuation.x + light.attenuation.y * d + light.attenuation.z * d * d);
        //4
        attenuation *= pow(spotResult, light.coneAttenuation);
        float diffuseIntensiy = saturate(dot(-lightDirection, normalDirection));
        float3 color = light.color * baseColor * diffuseIntensiy;
        color *= attenuation;
        diffuseColor += color;
      }
    }
  }
  float3 color = diffuseColor + ambientColor + specularColor;
  return float4(color, 1);
}

