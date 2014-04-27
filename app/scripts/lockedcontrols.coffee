module.exports = class LockedControls
    momentum : 0
    velocityFactor : 0.2
    jumpVelocity : 2000
    pitchObject : new THREE.Object3D()
    yawObject : new THREE.Object3D()
    quat : new THREE.Quaternion()
    moveForward : false
    moveBackward : false
    moveLeft : false
    moveRight : false
    canJump : false
    enabled : false
    contactNormal: new CANNON.Vec3()
    upAxis : new CANNON.Vec3(0,1,0)

    PI_2 : Math.PI/2

    constructor: (camera,@cannonBody) ->

        @chirp = new Howl
            urls: ['sounds/dolphins.mp3']

        @pitchObject.add camera
        @yawObject.position.y = 100
        @yawObject.add @pitchObject

        @cannonBody.addEventListener 'collide', (e) =>
            contact = e.contact
            
            if contact.bi.id is @cannonBody.id
                contact.ni.negate @contactNormal
            else
                contact.ni.copy @contactNormal

            if @contactNormal.dot(@upAxis) > 0.5
                @canJump = true
        @velocity = @cannonBody.velocity
        @inputVelocity = new THREE.Vector3(0,0,0)

        document.addEventListener( 'mousemove', @onMouseMove, false )
        document.addEventListener( 'keydown', @onKeyDown, false )
        document.addEventListener( 'keyup', @onKeyUp, false )


    onMouseMove: (event) =>

        if @enabled is false
            return

        movementX = event.movementX || event.mozMovementX || event.webkitMovementX || 0
        movementY = event.movementY || event.mozMovementY || event.webkitMovementY || 0

        @yawObject.rotation.y -= movementX * 0.002
        @pitchObject.rotation.x -= movementY * 0.002

        @pitchObject.rotation.x = Math.max(-@PI_2, Math.min(@PI_2, @pitchObject.rotation.x))


    onKeyDown: (event) =>
        switch event.keyCode
            when 87 then @moveForward = true # w
            when 65 then @moveLeft = true # a
            when 83 then @moveBackward = true # s
            when 68 then @moveRight = true # s
            when 32
                if @canJump
                    @chirp.play()
                    @velocity.y = @jumpVelocity
                @canJump = false


    onKeyUp: (event) =>
        switch event.keyCode
            when 87 then @moveForward = false # w
            when 65 # a
                if not @moveLeft
                    @moveLeft = true
                    @momentum -= 10
            when 83 then @moveBackward = false # s
            when 68
                if @moveLeft
                    @moveLeft = false
                    @momentum -= 10

    getObject: () =>
        return @yawObject

    update: (delta) =>
        if @enabled is false
            return

        delta *= 0.1

        @inputVelocity.set(0,0,0)


        @inputVelocity.z = @momentum * delta
        if @moveLeft
            @inputVelocity.x = -@velocityFactor * delta
        if @moveRight
            @inputVelocity.x = @velocityFactor * delta
        
        if @momentum <= 0
            @momentum += 1
        else
            @momentum = 0
        #console.log @inputVelocity
        #Convert velocity to world coordinates
        #@quat.setFromEuler(new THREE.Euler(@pitchObject.rotation.x, @yawObject.rotation.y, 0,'XYZ')
        #@inputVelocity.applyQuaternion(@quat)
        @inputVelocity.applyEuler(new THREE.Euler(@pitchObject.rotation.x, @yawObject.rotation.y, 0,'ZYX'))

        #Add to the object
        #console.log @quat
        @velocity.x += @inputVelocity.x
        if @canJump
            @velocity.y += @inputVelocity.y
        @velocity.z += @inputVelocity.z
        @cannonBody.position.copy(@yawObject.position)