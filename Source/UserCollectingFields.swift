//
//  UserCollectingFields.swift
//  OpenLocate
//
//  Created by Mathias Van Houtte on 13/06/2018.
//  Copyright © 2018 OpenLocate. All rights reserved.
//

import UIKit

public struct UserCollectingFields {
    public let userActivityType: String?
    public let userActivityConfidence: Int?
    
    init(userActivityType: String? = "UNKNOWN", userActivityConfidence: Int? = 0) {
        self.userActivityType = userActivityType
        self.userActivityConfidence = userActivityConfidence
    }
}
