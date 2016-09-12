/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used to represent the player when hit by a `Robot` attack.
*/

import SpriteKit
import GameplayKit

class PlayerHitState: GKState {
    // MARK: Properties
    
    unowned var entity: Player
    
    /// The amount of time the `Player` has been in the "hit" state.
    var elapsedTime: TimeInterval = 0.0
    
    /// The `AnimationComponent` associated with the `entity`.
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A PlayerHitState's entity must have an AnimationComponent.") }
        return animationComponent
    }
    
    // MARK: Initializers
    
    required init(entity: Player) {
        self.entity = entity
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        // Reset the elapsed "hit" duration on entering this state.
        elapsedTime = 0.0
        
        // Request the "hit" animation for this `Player`.
        animationComponent.requestedAnimationState = .hit
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        // Update the amount of time the `Player` has been in the "hit" state.
        elapsedTime += seconds
        
        // When the `Player` has been in this state for long enough, transition to the appropriate next state.
        if elapsedTime >= GameplayConfiguration.Player.hitStateDuration {
            if entity.isPoweredDown {
                _ = stateMachine?.enter(PlayerRechargingState.self)
            }
            else {
                _ = stateMachine?.enter(PlayerPlayerControlledState.self)
            }
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
            case is PlayerPlayerControlledState.Type, is PlayerRechargingState.Type:
                return true
            
            default:
                return false
        }
    }
}
