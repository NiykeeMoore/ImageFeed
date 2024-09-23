
import Foundation

// MARK: - Network Connection
enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError(Error)
    case decodingError(Error, Data?)
}

extension URLSession {
    func objectTask<DecodingType: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<DecodingType, Error>) -> Void
    ) -> URLSessionTask {
        let fulfillCompletionOnTheMainThread: (Result<DecodingType, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        let task = dataTask(with: request) { data, response, error in
            
            if let error = error {
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlSessionError(error)))
            }
            
            if let response = response as? HTTPURLResponse {
                if !(200..<300 ~= response.statusCode) {
                    fulfillCompletionOnTheMainThread(.failure(NetworkError.httpStatusCode(response.statusCode)))
                }
            }
            
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let result = try decoder.decode(DecodingType.self, from: data)
                    fulfillCompletionOnTheMainThread(.success(result))
                    
                } catch {
                    fulfillCompletionOnTheMainThread(.failure(NetworkError.urlSessionError(error)))
                }
            }
        }
        return task
    }
}
