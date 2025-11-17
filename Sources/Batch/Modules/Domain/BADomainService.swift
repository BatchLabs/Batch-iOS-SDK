//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

@objc
public enum BADomainService: Int {
    case web, metric

    func url(domain: String) -> String {
        let fullDomain =
            switch self {
            case .web: "ws.\(domain)"
            case .metric: "wsmetrics.\(domain)/api-sdk"
            }

        return "https://\(fullDomain)"
    }
}
