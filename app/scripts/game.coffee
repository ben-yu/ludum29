sphereBody = {}
LockedControls = require './lockedcontrols'
time = Date.now()
init = () ->
    scene.fog = new THREE.Fog(0x000000,0,500)
    renderer.setClearColor(scene.fog.color, 1)
    ambient = new THREE.AmbientLight(0x555555)
    scene.add ambient

    sun = new THREE.DirectionalLight( 0xffffff, 1.5, 30000 )
    sun.position.set( -4000, 1200, 1800 )
    sun.lookAt new THREE.Vector3()
    scene.add sun

    pointerlock = require('./pointerlock')(controls)

    # floor
    geometry = new THREE.PlaneGeometry( 1000, 1000, 30, 30 )
    geometry.applyMatrix( new THREE.Matrix4().makeRotationX( - Math.PI / 2 ) )
    #material = new THREE.MeshLambertMaterial( { color: 0xdddddd } )
    #THREE.ColorUtils.adjustHSV( material.color, 0, 0, 0.9 )

    mesh = new THREE.Mesh( geometry, new THREE.MeshNormalMaterial() )
    mesh.castShadow = true
    mesh.receiveShadow = true
    mesh.position.y = -10
    scene.add( mesh )

    cubegeometry = new THREE.CubeGeometry( 10, 10, 10 )
    cubematerial = new THREE.MeshNormalMaterial()
    cube = new THREE.Mesh( cubegeometry, cubematerial )
    scene.add(cube)

initCannon = () ->
    world.quatNormalizeSkip = 0
    world.quatNormalizeFast = false

    solver = new CANNON.GSSolver()

    world.defaultContactMaterial.contactEquationStiffness = 1e9
    world.defaultContactMaterial.contactEquationRegularizationTime = 4

    solver.iterations = 7
    solver.tolerance = 0.1
    world.solver = new CANNON.SplitSolver solver

    world.gravity.set(0,-200.8,0)
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
    groundBody.position.y = -10
    world.add(groundBody)

onWindowResize = () ->
    camera.aspect = window.innerWidth / window.innerHeight
    camera.updateProjectionMatrix()
    renderer.setSize( window.innerWidth, window.innerHeight )

render = () ->
    renderer.render( scene, camera )

animate = () ->
    requestAnimationFrame animate
    if controls.enabled
        world.step(dt)
    controls.update( Date.now() - time )
    render()
    time = Date.now()
    return

dt = 1/60
world = new CANNON.World()
initCannon()
scene = new THREE.Scene()
camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 10000 )
#camera.lookAt(new THREE.Vector3(0,0,0))
controls = new LockedControls(camera, sphereBody)
scene.add controls.getObject()

renderer = new THREE.WebGLRenderer()
renderer.setSize( window.innerWidth, window.innerHeight )
document.body.appendChild( renderer.domElement )
window.addEventListener( 'resize', onWindowResize, false )

init()
animate()