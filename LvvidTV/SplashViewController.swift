//
//  SplashViewController.swift
//  MyTVForIOS
//
//  Created by lvvi on 2020/3/16.
//  Copyright © 2020 lvvi. All rights reserved.
//

import UIKit

import LeanCloud

import Lottie

class SplashViewController: UIViewController {

    @IBOutlet weak var layoutView: UIView!
    @IBOutlet weak var meetDaysLabel: CountingUILabel!
    @IBOutlet weak var bornDaysLabel: CountingUILabel!
    
    let meetDate = "2016-08-19"
    let birthday = "2019-01-09"
    let countingStartNumber: Float = 0
    let countingDuration: TimeInterval = 3
    let delay = 4
    
    var channels = [Channel]()
    
    var viewDidLoadTime: Date!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewDidLoadTime = Date()
        
        layoutView.center.x = view.center.x
        layoutView.center.y = view.center.y
        
        let meetDays = getDays(startDate: meetDate)
        meetDaysLabel.count(fromValue: countingStartNumber, to: Float(meetDays), withDuration: countingDuration, andAnimationType: .EaseOut, andCounterType: .Int)
        
        let bornDays = getDays(startDate: birthday)
        bornDaysLabel.count(fromValue: countingStartNumber, to: Float(bornDays), withDuration: countingDuration, andAnimationType: .EaseOut, andCounterType: .Int)
        
        loadData()
    }
    
    private func getDays(startDate: String) -> Int{
        let calender = Calendar.current
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let start = dateFormatter.date(from: startDate)

        let components = calender.dateComponents([.day], from: start!, to: Date())
        
        return components.day!
    }
    
    private func loadData() {
        let ascendingQuery = LCQuery(className: "video_data")
        ascendingQuery.whereKey("order", .ascending)
        
        let isShowQuery = LCQuery(className: "video_data")
        isShowQuery.whereKey("is_show", .equalTo("1"))
        
        do {
            let query = try ascendingQuery.and(isShowQuery)
            _ = query.find { result in
                switch result {
                case .success(objects: let videos):
                    for video in videos {
                        let id = video.get("id")?.stringValue ?? ""
                        let name = video.get("name")?.stringValue ?? ""
                        let icon = video.get("icon")?.stringValue ?? ""
                        let url = video.get("url1")?.stringValue ?? ""
                        let isShow = video.get("is_show")?.stringValue ?? ""
                        
                        guard let channel = Channel(id: id, name: name, icon: icon, url: url, isShow: isShow) else {
                            fatalError("channel error")
                        }
                        
                        self.channels += [channel]
                    }
                    
                    Channel.saveChannels(channels: self.channels)
                    
                    self.checkViewDidLoadSecond()
                    break
                case .failure(error: let error):
                    print(error)
                }
            }
        } catch {
            fatalError("AscendingQuery and isShowQuery query failed.")
        }
    }
    
    func checkViewDidLoadSecond() {
        let calender = Calendar.current
        
        let viewDidLoadSeconds = calender.dateComponents([.second], from: viewDidLoadTime, to: Date()).second
        
        if viewDidLoadSeconds! < delay {
            perform(#selector(nextViewController), with: nil, afterDelay: TimeInterval(delay - viewDidLoadSeconds!))
        } else {
            nextViewController()
        }
    }

    @objc func nextViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let playerViewController = storyboard.instantiateViewController(withIdentifier: "Player")
        
        self.present(playerViewController, animated: false, completion: nil)
        
    }
}

