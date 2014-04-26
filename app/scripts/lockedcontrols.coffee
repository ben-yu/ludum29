module.exports = class LockedControls
    velocityFactor : 0.2
    jumpVelocity : 20
    pitchObject : new THREE.Object3D
    yawObject : new THREE.Object3D
    quat : new THREE.Quaternion
    moveForward : false
    moveBackward : false
    moveLeft : false
    moveRight : false
    canJump : false
    contactNormal: new CANNON.Vec3
    upAxis : new CANNON.Vec3(0,1,0)

    PI_2 : Math.PI / 2

    constructor: (camera,cannonBody) ->

        cannonBody.addEventListener 'collide', (e) =>
            contact = e.contact
            #console.log contact
            #cannonBody.position.copy(@targetObject.position)
            #cannonBody.quaternion.copy(@targetObject.quaternion)
            #@targetObject.position.add(new THREE.Vector3(contactNormal.x,contactNormal.y,contactNormal.z))
            if contact.bi.id is cannonBody.id
                contact.ni.negate @contactNormal
            else
                contact.ni.copy @contactNormal
            
            if @contactNormal.dot(upAxis) < 0.5
                @canJump = true
                #cannonBody.position.copy(@targetObject.position)
                #cannonBody.quaternion.copy(@targetObject.quaternion)
                #@targetObject.position.add(new THREE.Vector3(contactNormal.x,contactNormal.y,contactNormal.z))
        @velocity = cannonBody.velocity
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

        @pitchObject.rotation.x = Math.max( - @PI_2, Math.min( @PI_2, @pitchObject.rotation.x ) )


    onKeyDown: (event) =>
        #console.log "Pressed!" + event.keyCode

        switch event.keyCode
            when 87 then @moveForward = true # w
            when 65 then @moveLeft = true # a
            when 83 then @moveBackward = true # s
            when 68 then @moveRight = true # s


    onKeyUp: (event) =>

        switch event.keyCode

            when 87 then @moveForward = false # w
            when 65 then @moveLeft = false # a
            when 83 then @moveBackward = false # s
            when 68 then @moveRight = false # s

    getObject: () =>
        return @yawObject

    update: (delta) =>
        if @enabled is false
            return

        delta *= 0.1

        inputVelocity.set(0,0,0)

        if moveForward
            inputVelocity.z = -@velocityFactor * delta
        if moveBackward
            inputVelocity.z = @velocityFactor * delta
        if moveLeft
            inputVelocity.x = -@velocityFactor * delta
        if moveRight
            inputVelocity.x = @velocityFactor * delta
        
        #Convert velocity to world coordinates
        quat.setFromEuler({x:@pitchObject.rotation.x, y:@yawObject.rotation.y, z:0},"XYZ")
        quat.multiplyVector3(inputVelocity)

        #Add to the object
        velocity.x += inputVelocity.x
        velocity.z += inputVelocity.z

        cannonBody.position.copy(@yawObject.position)
