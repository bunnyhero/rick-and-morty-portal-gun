//
//  ImageDownloader.swift
//  RKTest
//
//  Created by bunnyhero on 2021-05-03.
//

import os
import UIKit
import CryptoKit // For hashing


class ImageDownloader {
    static let shared = ImageDownloader()
    
    var imageCacheDir: URL = {
        do {
            let cacheUrl = try FileManager.default.url(
                for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true
            )
            return cacheUrl.appendingPathComponent("images")
        } catch {
            fatalError("Could not find cache directory")
        }
    }()
    var downloads: [URL: DownloadInProgress] = [:]
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ImageDownloader")
    
    init() {
        // Create images dir if missing
        try? FileManager.default.createDirectory(at: imageCacheDir, withIntermediateDirectories: true, attributes: nil)
    }
    
    /// Downloads a remote file to a local cached file
    /// RealityKit can't make textures from UIImage objects, so we need to load it from a file. We want to cache it
    /// anyway so this ends up doing both
    /// - Parameters:
    ///   - remoteUrl: the URL of the remote resource
    ///   - completion: handler which receives the URL of the locally cached version
    func getLocalImageUrl(fromRemoteUrl remoteUrl: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        // Generate a unique local filename in case the last filename component isn't unique
        let filename = MD5(string: remoteUrl.absoluteString) + "." + remoteUrl.pathExtension
        let fileUrl = imageCacheDir.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            completion(.success(fileUrl))
            return
        }
        // Already downloading? If so, just add to the completion handlers to be called
        if let download = downloads[remoteUrl]  {
            download.completions.append(completion)
            return
        }
        let download = DownloadInProgress(remoteUrl: remoteUrl, localUrl: fileUrl)
        download.completions.append(completion)
        downloads[remoteUrl] = download
        logger.debug("___downloading \(remoteUrl, privacy: .public)")
        URLSession.shared.downloadTask(with: remoteUrl) { [self] tempLocation, response, error in
            logger.debug("___download task completed \(download.remoteUrl, privacy: .public), \(download.localUrl)")
            
            // Apple documentation says the file must be read or moved before this handler returns,
            // so do that first.
            
            var finalError = error
            if error == nil, let tempLocation = tempLocation {
                // Move file into place
                do {
                    try FileManager.default.moveItem(at: tempLocation, to: download.localUrl)
                    logger.debug("___moved file")
                }
                catch {
                    finalError = error
                }
            }
            logger.debug("___dispatching to main")
            DispatchQueue.main.async {
                self.logger.debug("___ ((on main)) ___")
                self.downloads.removeValue(forKey: download.remoteUrl)
                if let error = finalError {
                    download.callAllCompletions(result: .failure(error))
                }
                else if tempLocation != nil {
                    download.callAllCompletions(result: .success(download.localUrl))
                }
                else {
                    logger.critical("____ WHOOPS ____")
                }
            }
        }.resume()
    }
    
    /// Object to keep track of what downloads are occurring
    class DownloadInProgress {
        let remoteUrl: URL
        let localUrl: URL
        var completions: [(Result<URL, Error>) -> Void] = []
        
        init(remoteUrl: URL, localUrl: URL) {
            self.remoteUrl = remoteUrl
            self.localUrl = localUrl
        }
        
        func callAllCompletions(result: Result<URL, Error>) {
            for completion in completions {
                completion(result)
            }
        }
    }
}


func MD5(string: String) -> String {
    let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())
    
    return digest.map { String(format: "%02hhx", $0) }.joined()
}
