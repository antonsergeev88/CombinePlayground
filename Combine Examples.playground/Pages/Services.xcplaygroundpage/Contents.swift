import Foundation
import Combine

class WebClient {

    class DataTaskSubscription<S: Subscriber>: Subscription where S.Input == Data, S.Failure == Error {

        let url: URL
        let subscriber: S
        let session: URLSession
        init(url: URL, subscriber: S, session: URLSession) {
            self.url = url
            self.subscriber = subscriber
            self.session = session
        }

        var task: URLSessionDataTask?
        func request(_ demand: Subscribers.Demand) {
            task = session.dataTask(with: url) { [weak self] data, _, error in
                guard let self = self else { return }
                if let error = error {
                    self.subscriber.receive(completion: .failure(error))
                } else if let data = data {
                    self.subscriber.receive(data)
                    self.subscriber.receive(completion: .finished)
                } else {
                    fatalError()
                }
            }
            task?.resume()
        }

        func cancel() {
            task?.cancel()
        }

        let combineIdentifier = CombineIdentifier()

    }

    struct DataTaskPublisher: Publisher {
        typealias Output = Data
        typealias Failure = Error

        private let url: URL
        private let session: URLSession
        init(url: URL, session: URLSession) {
            self.url = url
            self.session = session
        }

        func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            let subscription = DataTaskSubscription(url: url, subscriber: subscriber, session: session)
            subscriber.receive(subscription: subscription)
        }
    }

    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func dataTaskPublisher(with url: URL) -> DataTaskPublisher {
        let publisher = DataTaskPublisher(url: url, session: session)
        return publisher
    }

}

struct City: Decodable {
    let name: String
}

let client = WebClient(session: URLSession.shared)

let url = URL(string: "https://demo0892805.mockable.io/cities")!

let cancellable = client.dataTaskPublisher(with: url).tryMap {
    let decoder = JSONDecoder()
    return try decoder.decode([City].self, from: $0)
} .sink(receiveCompletion: { completion in
    print(completion)
}) { data in
    print(data)
}

//cancellable.cancel()
