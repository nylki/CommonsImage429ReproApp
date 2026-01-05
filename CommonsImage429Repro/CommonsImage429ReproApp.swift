//
//  CommonsImage429ReproApp.swift
//  CommonsImage429Repro
//
//  Created by Tom Brewe on 05.01.26.
//

import SwiftUI
import os.log

/// This sample was created to reproduce an image loading issue, resulting in 429 errors when requesting original (non-resized) images from wiki commons.
/// see: https://phabricator.wikimedia.org/T413570

@main
struct CommonsImage429ReproApp: App {
    let imageURL = URL(
        string: "https://upload.wikimedia.org/wikipedia/commons/1/18/Berlin_Mitte_June_2023_01.jpg"
    )!
    let bigThumbURL = URL(
        string: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/Berlin_Mitte_June_2023_01.jpg/2560px-Berlin_Mitte_June_2023_01.jpg"
    )!
    
    @State private var imageData: Data?
    @State private var errorBody: String?
    
    private func loadImage() async {
        do {
            let sessionConfig = URLSessionConfiguration.default

            sessionConfig.httpAdditionalHeaders = [
                "User-Agent": "CommonsImage429ReproApp/1 (https://github.com/nylki/CommonsImage429ReproApp) iOS 26.1.0"
            ]
            
            /// for debugging purposes, a common **firefox header** that **results in a succesful original image load**:
//                sessionConfig.httpAdditionalHeaders = [
//                    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0"
//                ]
            
            let session = URLSession(configuration: sessionConfig)

            let req = URLRequest(url: imageURL, cachePolicy: .reloadIgnoringCacheData)
            
            /// for debugging, **the thumb/resize URLs work**:
//                let req = URLRequest(url: bigThumbURL, cachePolicy: .reloadIgnoringCacheData)
            
            Logger().info("Loading \(req.url?.absoluteString ?? "?")")
            
            let (data, res) = try await session.data(for: req)
            
            guard let httpResponse = res as? HTTPURLResponse else {
                Logger().error("Non-HTTP response")
                return
            }

            if (200...299).contains(httpResponse.statusCode) {
                print("2xx response, ok.")
                imageData = data
            } else if let body = String(data: data, encoding: .utf8) {
                errorBody = body
                print("error response. body: \(body)")
            } else {
                print("no data response")
            }
        } catch {
            Logger().error("failed to load image: \(error)")
        }

    }
    
    var body: some Scene {
        WindowGroup {
            ScrollView(.vertical) {
                VStack {
                    if let errorBody {
                        Text("Error response")
                            .foregroundStyle(.red)
                        TextField(
                            "response body",
                            text: .constant(errorBody),
                            axis: .vertical
                        )
                    } else if let imageData, let uiImage = UIImage(data: imageData) {
                        VStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 512, height: 512)
                        }
                    } else {
                        Color.gray
                            .frame(width: 512, height: 512)
                            .overlay {
                                ProgressView()
                            }
                    }
                }
            }
            .padding()
            .task {
                await loadImage()
            }
        }
    }
}
