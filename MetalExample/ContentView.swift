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
    
    var body: some View {
        MetalView()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color.red)
            .edgesIgnoringSafeArea(.all)
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
