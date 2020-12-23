//
//  MetalView.swift
//  MetalExample
//
//  Created by Patrick Abadi on 2020-12-23.
//
import MetalKit
import Foundation
import SwiftUI

struct MetalView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MetalViewController {
        let v = MetalViewController()
        return v
    }
    
    func updateUIViewController(_ uiViewController: MetalViewController, context: Context) {
        
    }
    
    typealias UIViewControllerType = MetalViewController
}
