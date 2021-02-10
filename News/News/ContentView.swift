//
//  ContentView.swift
//  News
//
//  Created by Jordan Singer on 2/10/21.
//

import SwiftUI
import SafariServices

// lil news api
let apiURL = "https://api.lil.software/news"

struct News: Codable {
    var articles: [Article]
}

struct Article: Codable, Hashable {
    var title: String
    var url: String
    var image: String?
    var source: String
}

struct ContentView: View {
    @State var articles: [Article] = []
    @State var loading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if self.loading {
                    ProgressView()
                } else {
                    List {
                        ForEach(articles, id: \.self) { article in
                            ArticleView(article: article)
                        }
                    }
                    .navigationBarTitle("News", displayMode: .inline)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: {
            self.loadNews()
        })
    }
    
    func loadNews() {
        // create the API url (ex: https://api.lil.software/news)
        let request = URLRequest(url: URL(string: apiURL)!)
        
        // initiate the API request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                // decode the response into our News struct
                if let decodedResponse = try? JSONDecoder().decode(News.self, from: data) {
                    DispatchQueue.main.async {
                        // set the articles based on the API response
                        self.articles = decodedResponse.articles
                        // we're no longer "loading"
                        self.loading = false
                    }
                    
                    return
                }
            }
        }.resume()
    }
}

struct ArticleView: View {
    @State var article: Article
    @State var showWebView = false
    
    var body: some View {
        Button(action: { self.showWebView = true }) {
            VStack (alignment: .leading, spacing: 24) {
                HStack(alignment: .top, spacing: 16) {
                    ImageView(imageUrl: article.image ?? "")
                        .frame(width: 128, height: 96)
                        .background(Color(UIColor.systemFill))
                        .cornerRadius(4)
                        .clipped()
                    
                    VStack (alignment: .leading, spacing: 6) {
                        Text(article.title)
                            .font(.system(.headline, design: .serif))
                        Text(article.source)
                            .font(.callout)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showWebView) {
            WebView(url: URL(string: self.article.url)!).edgesIgnoringSafeArea(.all)
        }
    }
}

struct WebView: UIViewControllerRepresentable {
    // to display an article's website
    let url: URL
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<WebView>) -> SFSafariViewController {
        let webview = SFSafariViewController(url: url)
        return webview
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<WebView>) {
        // nothing to do
    }
}

struct ImageView: View {
    @ObservedObject var remoteImageURL: RemoteImageURL
    
    init(imageUrl: String) {
        remoteImageURL = RemoteImageURL(imageURL: imageUrl)
    }
    
    var body: some View {
        Image(uiImage: UIImage(data: self.remoteImageURL.data) ?? UIImage())
            .resizable()
            .scaledToFit()
            .aspectRatio(contentMode: .fill)
    }
}

class RemoteImageURL: ObservableObject {
    @Published var data = Data()
    
    // load our image URL
    init(imageURL: String) {
        guard let url = URL(string: imageURL.replacingOccurrences(of: "http://", with: "https://")) else {
            print("Invalid URL")
            return
        }
      
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let response = response {
                DispatchQueue.main.async {
                    self.data = data
                }
            }
        }.resume()
    }
}
