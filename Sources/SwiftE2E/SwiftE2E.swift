import XCTVapor


public func E2EAssert<Res: Decodable & Equatable>(
    url: String,
    method: String = "GET",
    expectedHTTPStatus: HTTPStatus = .ok,
    expected: Res
) async throws {
    guard let requestURL = URL(string: url) else {
        XCTFail()
        return
    }
    
    var urlRequest = URLRequest(url: requestURL)
    urlRequest.httpMethod = method
    
    let (data, response) = try await nonParamRequest(urlRequest)
    
    guard (response as? HTTPURLResponse)?.statusCode ?? -1 == Int(expectedHTTPStatus.code) else {
        XCTFail()
        return
    }

    if Res.self == String.self {
        stringAssert(data, expected as! String)
    } else {
        try objectAssert(data, expected)
    }
}

public func E2EAssert<Param: Encodable, Res: Decodable & Equatable>(
    url: String,
    method: String = "GET",
    parameter: Param,
    expectedHTTPStatus: HTTPStatus = .ok,
    expected: Res
) async throws {
    guard let requestURL = URL(string: url) else {
        XCTFail()
        return
    }
    
    var urlRequest = URLRequest(url: requestURL)
    urlRequest.httpMethod = method
    
    let (data, response) = try await paramRequest(urlRequest, parameter)
    
    guard (response as? HTTPURLResponse)?.statusCode ?? -1 == Int(expectedHTTPStatus.code) else {
        XCTFail()
        return
    }

    if Res.self == String.self {
        stringAssert(data, expected as! String)
    } else {
        try objectAssert(data, expected)
    }
}

func nonParamRequest(_ req: URLRequest) async throws -> (Data, URLResponse) {
    return try await URLSession.shared.data(for: req)
}

func paramRequest<Param: Encodable>(_ req: URLRequest, _ parameter: Param) async throws -> (Data, URLResponse) {
    var jsonURLRequest = req
    jsonURLRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
    let payload = try JSONEncoder().encode(parameter)
    return try await URLSession.shared.upload(for: jsonURLRequest, from: payload)
}

func stringAssert(_ data: Data, _ expected: String) {
    guard let result = String(data: data, encoding: .utf8) else {
        XCTFail()
        return
    }
    XCTAssertEqual(expected, result)
}

func objectAssert<Res: Decodable & Equatable>(_ data: Data, _ expected: Res) throws {
    let result = try JSONDecoder().decode(Res.self, from: data)
    XCTAssertEqual(result, expected)
}
