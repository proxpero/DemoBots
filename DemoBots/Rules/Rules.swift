/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This file introduces the rules used by the `Robot` rule system to determine an appropriate action for the `Robot`. The rules fall into three distinct sets:
                Percentage of bad `Robot`s in the level (low, medium, high):
                    `BadRobotPercentageLowRule`
                    `BadRobotPercentageMediumRule`
                    `BadRobotPercentageHighRule`
                How close the `Robot` is to the `Player` (near, medium, far):
                    `PlayerNearRule`
                    `PlayerMediumRule`
                    `PlayerFarRule`
                How close the `Robot` is to its nearest "good" `Robot` (near, medium, far):
                    `RobotNearRule`
                    `RobotMediumRule`
                    `RobotFarRule`
*/

import GameplayKit

enum Fact: String {
    // Fuzzy rules pertaining to the proportion of "bad" bots in the level.
    case badRobotPercentageLow = "BadRobotPercentageLow"
    case badRobotPercentageMedium = "BadRobotPercentageMedium"
    case badRobotPercentageHigh = "BadRobotPercentageHigh"

    // Fuzzy rules pertaining to this `Robot`'s proximity to the `Player`.
    case playerBotNear = "PlayerNear"
    case playerBotMedium = "PlayerMedium"
    case playerBotFar = "PlayerFar"

    // Fuzzy rules pertaining to this `Robot`'s proximity to the nearest "good" `Robot`.
    case goodRobotNear = "GoodRobotNear"
    case goodRobotMedium = "GoodRobotMedium"
    case goodRobotFar = "GoodRobotFar"
}

/// Asserts whether the number of "bad" `Robot`s is considered "low".
class BadRobotPercentageLowRule: FuzzyRobotRule {
    // MARK: Properties
    
    override func grade() -> Float {
        return max(0.0, 1.0 - 3.0 * snapshot.badBotPercentage)
    }
    
    // MARK: Initializers
    
    init() { super.init(fact: .badRobotPercentageLow) }
}

/// Asserts whether the number of "bad" `Robot`s is considered "medium".
class BadRobotPercentageMediumRule: FuzzyRobotRule {
    // MARK: Properties
    
    override func grade() -> Float {
        if snapshot.badBotPercentage <= 1.0 / 3.0 {
            return min(1.0, 3.0 * snapshot.badBotPercentage)
        }
        else {
            return max(0.0, 1.0 - (3.0 * snapshot.badBotPercentage - 1.0))
        }
    }
    
    // MARK: Initializers
    
    init() { super.init(fact: .badRobotPercentageMedium) }
}

/// Asserts whether the number of "bad" `Robot`s is considered "high".
class BadRobotPercentageHighRule: FuzzyRobotRule {
    // MARK: Properties
    
    override func grade() -> Float {
        return min(1.0, max(0.0, (3.0 * snapshot.badBotPercentage - 1)))
    }
    
    // MARK: Initializers
    
    init() { super.init(fact: .badRobotPercentageHigh) }
}

/// Asserts whether the `Player` is considered to be "near" to this `Robot`.
class PlayerNearRule: FuzzyRobotRule {
    // MARK: Properties

    override func grade() -> Float {
        guard let distance = snapshot.playerBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (oneThird - distance) / oneThird
    }

    // MARK: Initializers
    
    init() { super.init(fact: .playerBotNear) }
}

/// Asserts whether the `Player` is considered to be at a "medium" distance from this `Robot`.
class PlayerMediumRule: FuzzyRobotRule {
    // MARK: Properties

    override func grade() -> Float {
        guard let distance = snapshot.playerBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return 1 - (fabs(distance - oneThird) / oneThird)
    }
    
    // MARK: Initializers
    
    init() { super.init(fact: .playerBotMedium) }
}

/// Asserts whether the `Player` is considered to be "far" from this `Robot`.
class PlayerFarRule: FuzzyRobotRule {
    // MARK: Properties
    
    override func grade() -> Float {
        guard let distance = snapshot.playerBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (distance - oneThird) / oneThird
    }
    
    // MARK: Initializers
    
    init() { super.init(fact: .playerBotFar) }
}

// MARK: Robot Proximity Rules

/// Asserts whether the nearest "good" `Robot` is considered to be "near" to this `Robot`.
class GoodRobotNearRule: FuzzyRobotRule {
    // MARK: Properties

    override func grade() -> Float {
        guard let distance = snapshot.nearestGoodRobotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (oneThird - distance) / oneThird
    }

    // MARK: Initializers
    
    init() { super.init(fact: .goodRobotNear) }
}

/// Asserts whether the nearest "good" `Robot` is considered to be at a "medium" distance from this `Robot`.
class GoodRobotMediumRule: FuzzyRobotRule {
    // MARK: Properties
    
    override func grade() -> Float {
        guard let distance = snapshot.nearestGoodRobotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return 1 - (fabs(distance - oneThird) / oneThird)
    }

    // MARK: Initializers
    
    init() { super.init(fact: .goodRobotMedium) }
}

/// Asserts whether the nearest "good" `Robot` is considered to be "far" from this `Robot`.
class GoodRobotFarRule: FuzzyRobotRule {
    // MARK: Properties
    
    override func grade() -> Float {
        guard let distance = snapshot.nearestGoodRobotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (distance - oneThird) / oneThird
    }
    
    // MARK: Initializers
    
    init() { super.init(fact: .goodRobotFar) }
}
