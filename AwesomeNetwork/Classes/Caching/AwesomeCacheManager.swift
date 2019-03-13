//
//  AwesomeCacheManager.swift
//  AwesomeNetwork
//
//  Created by Evandro Harrison Hoffmann on 01/09/2016.
//  Copyright © 2016 Awesome. All rights reserved.
//

import Foundation

public enum AwesomeCacheType {
    case urlCache
    case realm
}

public enum AwesomeCacheRule {
    case fromCacheOnly
    case fromCacheOrUrl
    case fromCacheOrUrlThenUpdate // returns cache or URL data, then fetchs data from URL but doesn't return
    case fromCacheAndUrl
    case fromURL
    
    public var shouldGetFromCache: Bool {
        switch self {
        case .fromCacheOnly, .fromCacheOrUrl, .fromCacheAndUrl, .fromCacheOrUrlThenUpdate:
            return true
        default:
            return false
        }
    }
    
    public func shouldGetFromUrl(didReturnCache: Bool) -> Bool {
        switch self {
        case .fromCacheOrUrl:
            return !didReturnCache
        case .fromURL, .fromCacheAndUrl, .fromCacheOrUrlThenUpdate:
            return true
        default:
            return false
        }
    }
    
    public func shouldReturnUrlData(didReturnCache: Bool) -> Bool {
        switch self {
        case .fromCacheOrUrlThenUpdate, .fromCacheOnly:
            return false
        case .fromCacheAndUrl, .fromURL:
            return true
        default:
            return !didReturnCache
        }
    }
}

public class AwesomeCacheManager: NSObject {
    
    public var cacheType: AwesomeCacheType = .realm
    
    public init(cacheType: AwesomeCacheType = .realm) {
        super.init()
        
        self.cacheType = cacheType
        AwesomeRealmCache.configureRealmDatabase()
    }
    
    public func clearCache() {
        AwesomeRealmCache.clearDatabase()
    }
    
    func cache(_ data: Data, forKey key: String) {
        AwesomeRealmCache(key: key, value: data).save()
    }
    
    func data(forKey key: String) -> Data? {
        return AwesomeRealmCache.data(forKey: key)
    }
    
    // MARK: - Requester methods
    
    public func verifyForCache(withUrl urlString: String, method: String?, body: Data?) -> Data? {
        let url = AwesomeCacheManager.buildURLCacheKey(urlString, method: method, bodyData: body)
        if let data = data(forKey: url) {
            return data
        }
        return nil
    }
    
    public func saveCache(withUrl urlString: String, method: String?, body: Data?, data: Data?) {
        if let data = data {
            let url = AwesomeCacheManager.buildURLCacheKey(urlString, method: method, bodyData: body)
            cache(data, forKey: url)
        }
    }
    
    public static func buildBody(_ jsonBody: [String: AnyObject]?) -> String {
        if let jsonBody = jsonBody {
            for (key, value) in jsonBody {
                if key == "query", let value = value as? String {
                    return value
                }
            }
        }
        return ""
    }
    
    // MARK: - Helpers
    
    static func buildURLCacheKey(_ url: String?,
                                 method: String?,
                                 bodyData: Data?) -> String {
        
        if let bodyData = bodyData,
            let bodyString = String(data: bodyData, encoding: .utf8),
            let urlString = url,
            let method = method {
                let hashValue = bodyString + urlString + method
                return urlString + "?keyHash=\(hashValue)"
        } else if let urlString = url, let method = method {
            let hashValue = urlString + method
            return urlString + "?keyHash=\(hashValue)"
        }
        return url ?? ""
    }
    
}
