LockedControls = require './lockedcontrols'

container = document.getElementById('game')
scene = new THREE.Scene()
camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 1, 10000 )
camera.position.z = 1000

geometry = new THREE.BoxGeometry( 200, 200, 200 )
material = new THREE.MeshBasicMaterial( { color: 0xff0000, wireframe: true } )
mesh = new THREE.Mesh( geometry, material )

scene.add( mesh )

renderer = new THREE.WebGLRenderer { antialias: false }
renderer.setSize( window.innerWidth, window.innerHeight )

document.body.appendChild( renderer.domElement )


controls = new LockedControls mesh

pointerLock = require './pointerlock'
pointerLock(container,renderer,controls)


animate : () ->
    render : ->
        renderer.setViewport(0, 0, window.innerWidth, window.innerHeight)
        renderer.clear()
        renderer.initWebGLObjects( scene )

    requestAnimationFrame( animate )
    render()