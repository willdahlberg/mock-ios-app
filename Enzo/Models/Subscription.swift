//
//  Subscription.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-03-24.
//

import Foundation

enum SubscriptionType: String, Codable {
    case STARTER = "STARTER"
    case BASIC = "BASIC"
    case PRO = "PRO"
}

struct SubscriptionIntent: Codable {
    let subscriptionType: SubscriptionType
    let executeAt: Date
}

struct Subscription: Codable {
    let subscriptionType: SubscriptionType
    let intent: SubscriptionIntent?
    let active: Bool
    let expiresAt: Date
}