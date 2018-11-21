//
//  PipelineHelper.swift
//  AR
//
//  Created by Arash Kashi on 2018-11-21.
//  Copyright © 2018 Arash Kashi. All rights reserved.
//

import Foundation
import ARKit

/// Represents a block within a process chain.
/// it has an input queue to process the received items.
class ProcessBlock<InputT, OutputT> {
    
    private var inputQueue: [InputT] = []
    private var inputQueueDispatchQueue: DispatchQueue = DispatchQueue(label: "Input operation Queue")
    private var processDispatchQueue: DispatchQueue = DispatchQueue(label: "Process Queue")
    
    func process(item: InputT) -> OutputT {
        fatalError("pending implementation on subclass")
    }
    
    private var name: String
    
    init(name: String) {
        self.name = name
    }
    
    var onProcessOnsingleInputFinishedBlock: ((OutputT) -> Void)?
    
    final func onProcessOnsingleInputFinished(output: OutputT) {
        
        inputQueueDispatchQueue.async {
            self.inputQueue.removeFirst()
            
            if self.inputQueue.count > 0 {
                self.processFirstQueueItem()
            }
            
            self.onProcessOnsingleInputFinishedBlock?(output)
        }
    }
    
    private var numberOfProcessedItems: UInt64 = 0
    private var currentAverageTime: UInt64?
    
    private final func updateComputationTime(start: DispatchTime, end: DispatchTime) {
        
        let mili = (end.uptimeNanoseconds - start.uptimeNanoseconds) / 1000000
        
        if currentAverageTime == nil {
            currentAverageTime = mili
            numberOfProcessedItems = 1
        } else {
            currentAverageTime = (currentAverageTime! * numberOfProcessedItems + mili)/(numberOfProcessedItems + 1)
            numberOfProcessedItems = numberOfProcessedItems + 1
        }
    }
    
    final func processFirstQueueItem() {
        processDispatchQueue.async {
            guard let first = self.inputQueue.first else {
                fatalError()
            }
            
            let start = DispatchTime.now()
            let result = self.process(item: first)
            let end = DispatchTime.now()
            
            self.updateComputationTime(start: start,
                                       end: end)
            
            print("\(self.name) process: Avg: \(self.currentAverageTime ?? 0), samples: \(self.numberOfProcessedItems)")
            
            self.onProcessOnsingleInputFinished(output: result)
        }
    }
    
    final func enqueueInput(item: InputT) {
        inputQueueDispatchQueue.async {
            self.inputQueue.append(item)
            
            if self.inputQueue.count == 1 {
                self.processFirstQueueItem()
            }
        }
    }
}

class PipelineProcessNode<InputT, IntermediateT, OutputT> {
    var head: ProcessBlock<InputT, IntermediateT>
    var next: ProcessBlock<IntermediateT, OutputT>?
    
    init(head: ProcessBlock<InputT, IntermediateT>,
         next: ProcessBlock<IntermediateT, OutputT>? = nil) {
        self.head = head
        self.next = next
        
        guard let validNext = next else { return }
        
        head.onProcessOnsingleInputFinishedBlock = { intermediateResult in
            validNext.enqueueInput(item: intermediateResult)
        }
    }
}

class PixelBufferToDataProcessBlock: ProcessBlock<CVPixelBuffer, Data> {
    
    let device = MTLCreateSystemDefaultDevice()!
    
    lazy var context: CIContext = {
        
        return CIContext() //(mtlDevice: device)
    }()
    
    override func process(item: CVPixelBuffer) -> Data {
        
        let ciImage = CIImage(cvPixelBuffer: item)
        
        let context = CIContext(mtlDevice: device)
        return context.jpegRepresentation(of: ciImage, colorSpace:  ciImage.colorSpace!, options: [:])!
    }
}


class JpegDataToDiskProcessBlock: ProcessBlock<Data, Int> {
    
     let documentsUrl = FileManager.default.urls(for: .documentDirectory, in:.userDomainMask).first!
    
    override func process(item: Data) -> Int {
        
        let new = URL(string: self.documentsUrl.absoluteString + "/\(UUID().uuidString).jpg")!
        do {
            try item.write(to: new)
        } catch {
            print(error.localizedDescription)
            return -1
        }
        
        return 1
    }
}
