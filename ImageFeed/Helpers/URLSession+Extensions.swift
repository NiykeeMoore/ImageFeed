
import Foundation

// MARK: - Network Connection
enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError(Error)
    case decodingError(Error, Data?)
}

extension URLSession {
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        let fulfillCompletionOnMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        let task = dataTask(with: request) { data, response, error in
            if let error = error {
                print("[data]: URLRequestError - \(error.localizedDescription)")
                fulfillCompletionOnMainThread(.failure(NetworkError.urlRequestError(error)))
            } else if let response = response as? HTTPURLResponse,
                      let data = data {
                if 200 ..< 300 ~= response.statusCode {
                    fulfillCompletionOnMainThread(.success(data))
                } else {
                    print("[data]: HTTPStatusCodeError - Code: \(response.statusCode)")
                    fulfillCompletionOnMainThread(.failure(NetworkError.httpStatusCode(response.statusCode)))
                }
            } else {
                let unexpectedError = NSError(domain: "UnexpectedError", code: 0, userInfo: nil)
                print("[data]: UnexpectedError - Неизвестная ошибка")
                fulfillCompletionOnMainThread(.failure(NetworkError.urlSessionError(unexpectedError)))
            }
        }
        task.resume()
        return task
    }
    
    func objectTask<DecodingType: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<DecodingType, Error>) -> Void
    ) -> URLSessionTask {
        let fulfillCompletionOnMainThread: (Result<DecodingType, Error>) -> Void = { result in
              DispatchQueue.main.async {
                  completion(result)
              }
          }
        
        let task = data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    let decodedObject = try JSONDecoder().decode(DecodingType.self, from: data)
                    fulfillCompletionOnMainThread(.success(decodedObject))
                } catch {
                    print("[objectTask]: DecodingError - \(error.localizedDescription), Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
                    fulfillCompletionOnMainThread(.failure(NetworkError.decodingError(error, data)))
                }
            case .failure(let error):
                print("[objectTask]: NetworkError - \(error.localizedDescription)")
                fulfillCompletionOnMainThread(.failure(error))
            }
        }
        return task
    }
}
