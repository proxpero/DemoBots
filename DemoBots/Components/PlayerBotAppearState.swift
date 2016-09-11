/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used to represent the player at level start when being 'beamed' into the level.
*/

import SpriteKit
import GameplayKit

class PlayerAppearState: GKState {
    // MARK: Properties
    
    unowned var entity: Player
    
    /// The amount of time the `Player` has been in the "appear" state.
    var elapsedTime: TimeInterval = 0.0
    
    /// The `AnimationComponent` associated with the `entity`.
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A PlayerAppearState's entity must have an AnimationComponent.") }
        return animationComponent
    }
    
    /// The `RenderComponent` associated with the `entity`.
    var renderComponent: RenderComponent {
        guard let renderComponent = entity.component(ofType: RenderComponent.self) else { fatalError("A PlayerAppearState's entity must have an RenderComponent.") }
        return renderComponent
    }
    
    /// The `OrientationComponent` associated with the `entity`.
    var orientationComponent: OrientationComponent {
        guard let orientationComponent = entity.component(ofType: OrientationComponent.self) else { fatalError("A PlayerAppearState's entity must have an OrientationComponent.") }
        return orientationComponent
    }
    
    /// The `InputComponent` associated with the `entity`.
    var inputComponent: InputComponent {
        guard let inputComponent = entity.component(ofType: InputComponent.self) else { fatalError("A PlayerAppearState's entity must have an InputComponent.") }
        return inputComponent
    }
    
    /// The `SKSpriteNode` used to show the player animating into the scene.
    var node = SKSpriteNode()
    
    // MARK: Initializers
    
    required init(entity: Player) {
        self.entity = entity
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        // Reset the elapsed time.
        elapsedTime = 0.0
        
        /*
            The `Player` is about to appear in the level. We use an `SKShader` to
            provide a "teleport" effect to beam in the `Player`.
        */
        
        // Retrieve and use an initial texture for the `Player`, taken from the appropriate idle animation.
        guard let appearTextures = Player.appearTextures else {
            fatalError("Attempt to access Player.appearTextures before they have been loaded.")
        }
        let texture = appearTextures[orientationComponent.compassDirection]!
        node.texture = texture
        node.size = Player.textureSize

        // Add an `SKShader` to the node to render the "teleport" effect.
        node.shader = Player.teleportShader
        
        // Add the node to the `Player`'s render node.
        renderComponent.node.addChild(node)
        
        // Hide the animation component node until the `Player` exits this state.
        animationComponent.node.isHidden = true

        // Disable the input component while the `Player` appears.
        inputComponent.isEnabled = false
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        // Update the amount of time that the `Player` has been teleporting in to the level.
        elapsedTime += seconds

        // Check if we have spent enough time
        if elapsedTime > GameplayConfiguration.Player.appearDuration {
            // Remove the node from the scene
            node.removeFromParent()
            
            // Switch the `Player` over to a "player controlled" state.
            stateMachine?.enter(PlayerPlayerControlledState.self)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is PlayerPlayerControlledState.Type
    }
    
    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
        
        // Un-hide the animation component node.
        animationComponent.node.isHidden = false
        
        // Re-enable the input component
        inputComponent.isEnabled = true
    }
}
