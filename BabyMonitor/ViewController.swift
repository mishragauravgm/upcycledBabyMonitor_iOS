//
//  ViewController.swift
//  CodingAssignment2021
//
//  Created by Jeff Huang on 1/19/21.
//  Modified by Gaurav Mishra on 2/14/21 for Bose Assignment

import UIKit
import AVKit
import SoundAnalysis

class ViewController: UIViewController {
    
    //Tried using AudioManager but kept encountering some error so used AVAudioEngine
    //private var audiomanager = AudioManager.shared
    private let audioEngine = AVAudioEngine()
    var current_trigger_time = 0.0
    var last_trigger_time = 0.0
    private var soundClassifier = ESC10SoundClassifierModel()
    var streamAnalyzer: SNAudioStreamAnalyzer!
    let queue = DispatchQueue(label: "com.appple.AnalysisQueue")
    var message_to_print = [(message: String, time: String)]()
    var prompts = [(message: String, time: String)]() {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Upcycled Baby Monitor"
    }
        
    
    private func prepareForAnalysis() {
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        streamAnalyzer = SNAudioStreamAnalyzer(format: recordingFormat)
        inputNode.installTap(onBus: 0, bufferSize: 15600, format: recordingFormat){
            [unowned self] (buffer, when) in
            self.queue.async {
                self.streamAnalyzer.analyze(buffer,
                                            atAudioFramePosition: when.sampleTime)
            }
        }
        
        //Start Audio Engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
             }
        catch {
            print("Some error")
        }
        
    }
    
    @IBAction func startAnalysisButtonTapped(_ sender: UIButton) {
        prepareForAnalysis()
        
        //Next Start the Classification Task
        do {
            let request = try SNClassifySoundRequest(mlModel: soundClassifier.model)
            
            try streamAnalyzer.add(request, withObserver: self)
        } catch {
            print("Some Error!!")
        }
    }
}


extension ViewController: SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
              let predicted_label = result.classifications.first else { return }
        //var message_to_print = [(message: String, time: String)]()
        let confidence = predicted_label.confidence*100
        
        if(predicted_label.identifier == "crying_baby" && confidence>=50){
            
            
            current_trigger_time = result.timeRange.start.seconds

            print(current_trigger_time, last_trigger_time)
            if(current_trigger_time-last_trigger_time>=20 || last_trigger_time==0){
                
                print("Condition met and 20 seconds later. Last Trigger is \(last_trigger_time) and current trigger is at \(current_trigger_time)!!")
               
                last_trigger_time = current_trigger_time;
                let time = Date()
                let formatter = DateFormatter()
                formatter.dateStyle = .none
                formatter.timeStyle = .short
                let curr_time = formatter.string(from:time);
                message_to_print.append((message:"Baby is crying", time: curr_time))
            }
            else{
                print("Duplicate! Sent message 20 seconds ago!")
            
        }
        prompts = message_to_print
    }
}
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return prompts.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "ResultCell")
        }
        
        let result = prompts[indexPath.row]
        let label = result.message
        cell!.textLabel!.text = "\(label): \(result.time)"
        return cell!
    }
}
