sphereBody = {}
LockedControls = require './lockedcontrols'

scene = new THREE.Scene()
camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 1000 )

renderer = new THREE.WebGLRenderer { antialias: false }
renderer.setSize( window.innerWidth, window.innerHeight )
renderer.setViewport(0, 0, window.innerWidth, window.innerHeight)
#renderer.shadowMapEnabled = true
#renderer.shadowMapSoft = true
document.body.appendChild( renderer.domElement )

init = () ->
    scene.fog = new THREE.Fog(0x000000,0,500)

    ambient = new THREE.AmbientLight(0x111111)
    scene.add ambient

    light = new THREE.SpotLight 0xffffff
    light.position.set( 10, 30, 20 )
    light.target.position.set( 0, 0, 0 )
    light.castShadow = true

    light.shadowCameraNear = 20
    light.shadowCameraFar = 50
    light.shadowCameraFov = 40

    light.shadowMapBias = 0.1
    light.shadowMapDarkness = 0.7
    light.shadowMapWidth = 2*512
    light.shadowMapHeight = 2*512
    scene.add light

    controls = new LockedControls(camera, sphereBody)
    scene.add controls.getObject()

    pointerlock = require('./pointerlock')(controls)

    # floor
    geometry = new THREE.PlaneGeometry( 300, 300, 50, 50 )
    geometry.applyMatrix( new THREE.Matrix4().makeRotationX( - Math.PI / 2 ) )

    #material = new THREE.MeshLambertMaterial( { color: 0xdddddd } )
    #THREE.ColorUtils.adjustHSV( material.color, 0, 0, 0.9 )

    mesh = new THREE.Mesh( geometry, new THREE.MeshNormalMaterial() )
    mesh.castShadow = true
    mesh.receiveShadow = true
    scene.add( mesh )

initCannon = () ->
    world = new CANNON.World()
    world.quatNormalizeSkip = 0
    world.quatNormalizeFast = false

    solver = new CANNON.GSSolver()

    world.defaultContactMaterial.contactEquationStiffness = 1e9
    world.defaultContactMaterial.contactEquationRegularizationTime = 4

    solver.iterations = 7
    solver.tolerance = 0.1
    world.solver = new CANNON.SplitSolver solver

    world.gravity.set(0,-20,0)
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
    sphereBody.position.set(0,5,0)
    sphereBody.linearDamping = 0.9
    world.add(sphereBody)

    # Create a plane
    groundShape = new CANNON.Plane()
    groundBody = new CANNON.RigidBody(0,groundShape,physicsMaterial)
    groundBody.quaternion.setFromAxisAngle(new CANNON.Vec3(1,0,0),-Math.PI/2)
    world.add(groundBody)

onWindowResize = () ->
    camera.aspect = window.innerWidth / window.innerHeight
    camera.updateProjectionMatrix()
    renderer.setSize( window.innerWidth, window.innerHeight )

animate = () ->
    requestAnimationFrame( animate )

    render = () ->
        renderer.render( scene, camera )

    render()
    return

window.addEventListener( 'resize', onWindowResize, false )
initCannon()
init()
animate()