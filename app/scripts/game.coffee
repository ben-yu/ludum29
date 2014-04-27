sphereBody = {}
waterLayer = [{},{}]
LockedControls = require './lockedcontrols'
time = Date.now()


init = () ->
    scene.fog = new THREE.Fog(0x000000,0,500)
    renderer.setClearColor(scene.fog.color, 1)
    ambient = new THREE.AmbientLight(0x555555)
    scene.add ambient

    sun = new THREE.DirectionalLight( 0xffff55, 1)
    sun.position.set( -600, 300, 600 )
    sun.lookAt new THREE.Vector3()
    scene.add sun

    pointerlock = require('./pointerlock')(controls)

    # floor
    geometry = new THREE.PlaneGeometry( 50000, 50000, 30, 30 )
    geometry.applyMatrix( new THREE.Matrix4().makeRotationX( - Math.PI / 2 ) )
    material = new THREE.MeshLambertMaterial( { color: 0xdddddd } )
    #THREE.ColorUtils.adjustHSV( material.color, 0, 0, 0.9 )

    mesh = new THREE.Mesh( geometry, material )
    mesh.castShadow = true
    mesh.receiveShadow = true
    mesh.position.y = -500
    scene.add( mesh )

    waterNormals = new THREE.ImageUtils.loadTexture('img/waternormals.jpg')
    waterNormals.wrapS = waterNormals.wrapT = THREE.RepeatWrapping

    createWater = (type,alpha,waterColor,xRotation) ->
        # Create the water effect
        waterLayer[type] = new THREE.Water renderer, camera, scene,
            textureWidth: 256
            textureHeight: 256
            waterNormals: waterNormals
            alpha:  alpha
            sunDirection: sun.position.normalize()
            sunColor: 0xffffff
            waterColor: waterColor
            betaVersion: 0
        
        aMeshMirror = new THREE.Mesh(new THREE.PlaneGeometry(50000, 50000, 100, 100),waterLayer[type].material)
        aMeshMirror.add(waterLayer[type])
        aMeshMirror.rotation.x = xRotation
        aMeshMirror.position.y = -105
        return aMeshMirror

    surface = createWater(0,1.0,0x001e0f,- Math.PI * 0.5)
    underwater = createWater(1,0.85,0x001e0f,- Math.PI * 1.5)
    scene.add(surface)
    scene.add(underwater)

    aCubeMap = THREE.ImageUtils.loadTextureCube([
        'img/px.jpg',
        'img/nx.jpg',
        'img/py.jpg',
        'img/ny.jpg',
        'img/pz.jpg',
        'img/nz.jpg'
    ])
    aCubeMap.format = THREE.RGBFormat

    aShader = THREE.ShaderLib['cube']
    aShader.uniforms['tCube'].value = aCubeMap

    aSkyBoxMaterial = new THREE.ShaderMaterial
        fragmentShader: aShader.fragmentShader
        vertexShader: aShader.vertexShader
        uniforms: aShader.uniforms
        depthWrite: false
        side: THREE.BackSide

    aSkybox = new THREE.Mesh( new THREE.CubeGeometry(1000000, 1000000, 1000000),aSkyBoxMaterial)

    scene.add(aSkybox)

    targetGeom = new THREE.SphereGeometry(10)
    targetMat = new THREE.MeshNormalMaterial()
    target = new THREE.Mesh(targetGeom, targetMat)
    target.position.y = 100
    scene.add(target)

initCannon = () ->
    world.quatNormalizeSkip = 0
    world.quatNormalizeFast = false

    solver = new CANNON.GSSolver()

    world.defaultContactMaterial.contactEquationStiffness = 1e9
    world.defaultContactMaterial.contactEquationRegularizationTime = 4

    solver.iterations = 7
    solver.tolerance = 0.1
    world.solver = new CANNON.SplitSolver solver

    world.gravity.set(0,-98.1,0)
    world.broadphase = new CANNON.NaiveBroadphase()

    #Create a slippery material (friction coefficient = 0.0)
    physicsMaterial = new CANNON.Material("slipperyMaterial")
    physicsContactMaterial = new CANNON.ContactMaterial physicsMaterial,
                                                        physicsMaterial,
                                                        0.0, # friction coefficient
                                                        0.3  # restitution
    world.addContactMaterial(physicsContactMaterial)

    # Create a sphere
    mass = 5
    radius = 1.3
    sphereShape = new CANNON.Sphere(radius)
    sphereBody = new CANNON.RigidBody(mass,sphereShape,physicsMaterial)
    sphereBody.position.set(0,0,0)
    sphereBody.linearDamping = 0.9
    world.add(sphereBody)

    # Create a plane
    groundShape = new CANNON.Plane()
    groundBody = new CANNON.RigidBody(0,groundShape,physicsMaterial)
    groundBody.quaternion.setFromAxisAngle(new CANNON.Vec3(1,0,0),-Math.PI/2)
    groundBody.position.y = -500
    world.add(groundBody)


onWindowResize = () ->
    camera.aspect = window.innerWidth / window.innerHeight
    camera.updateProjectionMatrix()
    renderer.setSize( window.innerWidth, window.innerHeight )
    render()
inAir = true
dt = 1/60
world = new CANNON.World()
initCannon()
scene = new THREE.Scene()
camera = new THREE.PerspectiveCamera( 90, window.innerWidth / window.innerHeight, 0.1, 10000000 )
#camera.lookAt(new THREE.Vector3(0,0,0))
controls = new LockedControls(camera, sphereBody)
scene.add controls.getObject()

_.extend(sphereBody, Backbone.Events)
console.log sphereBody

renderer = new THREE.WebGLRenderer()
renderer.setSize( window.innerWidth, window.innerHeight )
document.body.appendChild( renderer.domElement )
window.addEventListener( 'resize', onWindowResize, false )

render = () ->
    waterLayer[0].material.uniforms.time.value += 1.0/60.0
    waterLayer[0].render()
    #waterLayer[1].material.uniforms.time.value += 1.0/60.0
    #waterLayer[1].render()
    renderer.render(scene,camera)

animate = () ->
    if controls.enabled
        world.step(dt)
    controls.update( Date.now() - time )
    render()
    time = Date.now()
    requestAnimationFrame animate
    if inAir and sphereBody.position.y < 0
        controls.canJump = true
        world.gravity.set(0,-98.1,0)
    else
        controls.canJump = false
        world.gravity.set(0,-980.1,0)
    return

init()
animate()