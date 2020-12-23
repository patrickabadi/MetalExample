//
//  ContentView.swift
//  MetalExample
//
//  Created by Patrick Abadi on 2020-12-23.
//

import SwiftUI
import Metal
import MetalKit

struct ContentView: View {
    var mtkView: MTKView!
    
    var body: some View {
        MetalView()
            .onAppear(){
             
            }
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
