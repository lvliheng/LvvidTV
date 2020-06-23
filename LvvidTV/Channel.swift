//
//  Channel.swift
//  MyTVForIOS
//
//  Created by lvvi on 2020/3/5.
//  Copyright © 2020 lvvi. All rights reserved.
//

import Foundation

class Channel: NSObject, NSCoding {
    
    
    var id: String
    var name: String
    var icon: String
    var url: String
    var isShow: String
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first
    static let ArchivelURL = DocumentsDirectory?.appendingPathComponent("channel")
    
    struct PropertyType {
        static let id = "id"
        static let name = "name"
        static let icon = "icon"
        static let url = "url"
        static let isShow = "isShow"
    }
    
    init?(id: String, name: String, icon: String, url: String, isShow: String) {
        
        if id.isEmpty {
            return nil
        }
        
        self.id = id
        self.name = name
        self.icon = icon
        self.url = url
        self.isShow = isShow
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: PropertyType.id)
        coder.encode(name, forKey: PropertyType.name)
        coder.encode(icon, forKey: PropertyType.icon)
        coder.encode(url, forKey: PropertyType.url)
        coder.encode(isShow, forKey: PropertyType.isShow)
    }
    
    required convenience init?(coder: NSCoder) {
        guard let id = coder.decodeObject(forKey: PropertyType.id) as? String else {
            return nil
        }
        guard let name = coder.decodeObject(forKey: PropertyType.name) as? String else {
            return nil
        }
        guard let icon = coder.decodeObject(forKey: PropertyType.icon) as? String else {
                   return nil
               }
        guard let url = coder.decodeObject(forKey: PropertyType.url) as? String else {
                   return nil
               }
        guard let isShow = coder.decodeObject(forKey: PropertyType.isShow) as? String else {
                   return nil
               }
        
        self.init(id: id, name: name, icon: icon, url: url, isShow: isShow)
    }
    
    static func saveChannels(channels: [Channel]) {
        NSKeyedArchiver.archiveRootObject(channels, toFile: Channel.ArchivelURL!.path)
    }
    
    static func loadChannels() -> [Channel]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Channel.ArchivelURL!.path) as? [Channel]
    }
    
    static func savePlayingURL(playingURL: String) {
        UserDefaults.standard.set(playingURL, forKey: "playing_url")
    }
    
    static func loadPlayingURL() -> String? {
        UserDefaults.standard.value(forKey: "playing_url") as? String
    }

}
