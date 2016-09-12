/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKEntity` subclass that represents the player-controlled protagonist of DemoBots. This subclass allows for convenient construction of a new entity with appropriate `GKComponent` instances.
*/

import SpriteKit
import GameplayKit

class Player: GKEntity, ChargeComponentDelegate, ResourceLoadableType {
    // MARK: Static properties
    
    /// The size to use for the `Player`s animation textures.
    static var textureSize = CGSize(width: 120.0, height: 120.0)
    
    /// The size to use for the `Player`'s shadow texture.
    static var shadowSize = CGSize(width: 90.0, height: 40.0)
    
    /// The actual texture to use for the `Player`'s shadow.
    static var shadowTexture: SKTexture = {
        let shadowAtlas = SKTextureAtlas(named: "Shadows")
        return shadowAtlas.textureNamed("PlayerShadow")
    }()
    
    /// The offset of the `Player`'s shadow from its center position.
    static var shadowOffset = CGPoint(x: 0.0, y: -40.0)
    
    /// The animations to use for a `Player`.
    static var animations: [AnimationState: [CompassDirection: Animation]]?

    /// Textures used by `PlayerAppearState` to show a `Player` appearing in the scene.
    static var appearTextures: [CompassDirection: SKTexture]?
    
    /// Provides a "teleport" effect shader for when the `Player` first appears on a level.
    static var teleportShader: SKShader!
    
    // MARK: Properties
    
    var isPoweredDown = false
    
    /// The agent used when pathfinding to the `Player`.
    let agent: GKAgent2D

    /**
        A `Player` is only targetable when it is actively being controlled by a player or is taking damage.
        It is not targetable when appearing or recharging.
    */
    var isTargetable: Bool {
        guard let currentState = component(ofType: IntelligenceComponent.self)?.stateMachine.currentState else { return false }

        switch currentState {
            case is PlayerPlayerControlledState, is PlayerHitState:
                return true
            
            default:
                return false
        }
    }
    
    /// Used to determine the location on the `Player` where the beam starts.
    var antennaOffset = GameplayConfiguration.Player.antennaOffset
    
    /// The `RenderComponent` associated with this `Player`.
    var renderComponent: RenderComponent {
        guard let renderComponent = component(ofType: RenderComponent.self) else { fatalError("A Player must have an RenderComponent.") }
        return renderComponent
    }

    // MARK: Initializers
    
    override init() {
        agent = GKAgent2D()
        agent.radius = GameplayConfiguration.Player.agentRadius
        
        super.init()
        
        /*
            Add the `RenderComponent` before creating the `IntelligenceComponent` states,
            so that they have the render node available to them when first entered
            (e.g. so that `PlayerAppearState` can add a shader to the render node).
        */
        let renderComponent = RenderComponent()
        addComponent(renderComponent)
        
        let orientationComponent = OrientationComponent()
        addComponent(orientationComponent)

        let shadowComponent = ShadowComponent(texture: Player.shadowTexture, size: Player.shadowSize, offset: Player.shadowOffset)
        addComponent(shadowComponent)
        
        let inputComponent = InputComponent()
        addComponent(inputComponent)

        // `PhysicsComponent` provides the `Player`'s physics body and collision masks.
        let physicsComponent = PhysicsComponent(physicsBody: SKPhysicsBody(circleOfRadius: GameplayConfiguration.Player.physicsBodyRadius, center: GameplayConfiguration.Player.physicsBodyOffset), colliderType: .Player)
        addComponent(physicsComponent)

        // Connect the `PhysicsComponent` and the `RenderComponent`.
        renderComponent.node.physicsBody = physicsComponent.physicsBody
        
        // `MovementComponent` manages the movement of a `PhysicalEntity` in 2D space, and chooses appropriate movement animations.
        let movementComponent = MovementComponent()
        addComponent(movementComponent)
        
        // `ChargeComponent` manages the `Player`'s charge (i.e. health).
        let chargeComponent = ChargeComponent(charge: GameplayConfiguration.Player.initialCharge, maximumCharge: GameplayConfiguration.Player.maximumCharge, displaysChargeBar: true)
        chargeComponent.delegate = self
        addComponent(chargeComponent)
        
        // `AnimationComponent` tracks and vends the animations for different entity states and directions.
        guard let animations = Player.animations else {
            fatalError("Attempt to access Player.animations before they have been loaded.")
        }
        let animationComponent = AnimationComponent(textureSize: Player.textureSize, animations: animations)
        addComponent(animationComponent)
        
        // Connect the `RenderComponent` and `ShadowComponent` to the `AnimationComponent`.
        renderComponent.node.addChild(animationComponent.node)
        animationComponent.shadowNode = shadowComponent.node
        
        // `BeamComponent` implements the beam that a `Player` fires at "bad" `Robot`s.
        let beamComponent = BeamComponent()
        addComponent(beamComponent)
        
        let intelligenceComponent = IntelligenceComponent(states: [
            PlayerAppearState(entity: self),
            PlayerPlayerControlledState(entity: self),
            PlayerHitState(entity: self),
            PlayerRechargingState(entity: self)
        ])
        addComponent(intelligenceComponent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Charge component delegate
    
    func chargeComponentDidLoseCharge(chargeComponent: ChargeComponent) {
        if let intelligenceComponent = component(ofType: IntelligenceComponent.self) {
            if !chargeComponent.hasCharge {
                isPoweredDown = true
                intelligenceComponent.stateMachine.enter(PlayerRechargingState.self)
            }
            else {
                intelligenceComponent.stateMachine.enter(PlayerHitState.self)
            }
        }
    }
    
    // MARK: ResourceLoadableType
    
    static var resourcesNeedLoading: Bool {
        return appearTextures == nil || animations == nil
    }
    
    static func loadResources(withCompletionHandler completionHandler: @escaping () -> ()) {
        loadMiscellaneousAssets()
        
        let playerBotAtlasNames = [
            "PlayerIdle",
            "PlayerWalk",
            "PlayerInactive",
            "PlayerHit"
        ]
        
        /*
            Preload all of the texture atlases for `Player`. This improves
            the overall loading speed of the animation cycles for this character.
        */
        SKTextureAtlas.preloadTextureAtlasesNamed(playerBotAtlasNames) { error, playerBotAtlases in
            if let error = error {
                fatalError("One or more texture atlases could not be found: \(error)")
            }

            /*
                This closure sets up all of the `Player` animations
                after the `Player` texture atlases have finished preloading.

                Store the first texture from each direction of the `Player`'s idle animation,
                for use in the `Player`'s "appear"  state.
            */
            appearTextures = [:]
            for orientation in CompassDirection.allDirections {
                appearTextures![orientation] = AnimationComponent.firstTextureForOrientation(compassDirection: orientation, inAtlas: playerBotAtlases[0], withImageIdentifier: "PlayerIdle")
            }
            
            // Set up all of the `Player`s animations.
            animations = [:]
            animations![.idle] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[0], withImageIdentifier: "PlayerIdle", forAnimationState: .idle)
            animations![.walkForward] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[1], withImageIdentifier: "PlayerWalk", forAnimationState: .walkForward)
            animations![.walkBackward] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[1], withImageIdentifier: "PlayerWalk", forAnimationState: .walkBackward, playBackwards: true)
            animations![.inactive] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[2], withImageIdentifier: "PlayerInactive", forAnimationState: .inactive)
            animations![.hit] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[3], withImageIdentifier: "PlayerHit", forAnimationState: .hit, repeatTexturesForever: false)
            
            // Invoke the passed `completionHandler` to indicate that loading has completed.
            completionHandler()
        }
    }
    
    static func purgeResources() {
        appearTextures = nil
        animations = nil
    }
    
    class func loadMiscellaneousAssets() {
        teleportShader = SKShader(fileNamed: "Teleport.fsh")
        teleportShader.addUniform(SKUniform(name: "u_duration", float: Float(GameplayConfiguration.Player.appearDuration)))
        
        ColliderType.definedCollisions[.Player] = [
            .Player,
            .Robot,
            .Obstacle
        ]
    }

    // MARK: Convenience
    
    /// Sets the `Player` `GKAgent` position to match the node position (plus an offset).
    func updateAgentPositionToMatchNodePosition() {
        // `renderComponent` is a computed property. Declare a local version so we don't compute it multiple times.
        let renderComponent = self.renderComponent
        
        let agentOffset = GameplayConfiguration.Player.agentOffset
        agent.position = float2(x: Float(renderComponent.node.position.x + agentOffset.x), y: Float(renderComponent.node.position.y + agentOffset.y))
    }
}
