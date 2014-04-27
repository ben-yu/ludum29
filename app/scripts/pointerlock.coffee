module.exports = PointerLock = (controls) =>
    # Pointer Lock - http://www.html5rocks.com/en/tutorials/pointerlock/intro/
    havePointerLock = 'pointerLockElement' of document or
        'mozPointerLockElement' of document or
        'webkitPointerLockElement' of document

    WIDTH = window.innerWidth
    HEIGHT = window.innerHeight

    blocker = document.getElementById 'blocker'
    instructions = document.getElementById 'instructions'
    score = document.getElementById 'score'

    if havePointerLock

        element = document.body

        pointerlockchange =  (event) =>

            if document.pointerLockElement is element or document.mozPointerLockElement is element or document.webkitPointerLockElement is element
                controls.enabled = true
                controls.cursor_x = WIDTH/2
                controls.cursor_y = HEIGHT/2
                blocker.style.display = 'none'
                score.style.display = '-webkit-box'
            else
                controls.enabled = false
                blocker.style.display = 'inline'
                blocker.style.display = 'inline'
                blocker.style.display = 'inline'
                instructions.style.display = ''
                score.style.display = 'none'
        pointerlockerror =  (event) ->
            instructions.style.display = ''

        # Hook pointer lock state change events
        document.addEventListener 'pointerlockchange', pointerlockchange, false
        document.addEventListener 'mozpointerlockchange', pointerlockchange, false
        document.addEventListener 'webkitpointerlockchange', pointerlockchange, false

        document.addEventListener 'pointerlockerror', pointerlockerror, false
        document.addEventListener 'mozpointerlockerror', pointerlockerror, false
        document.addEventListener 'webkitpointerlockerror', pointerlockerror, false

        instructions.addEventListener( 'click',  (event) ->

            instructions.style.display = 'none'

            # Ask the browser to lock the pointer
            element.requestPointerLock = element.requestPointerLock or element.mozRequestPointerLock or element.webkitRequestPointerLock

            if ( /Firefox/i.test(navigator.userAgent))

                fullscreenchange =  (event) ->

                    if (document.fullscreenElement is element or document.mozFullscreenElement is element or document.mozFullScreenElement is element)
                        document.removeEventListener( 'fullscreenchange', fullscreenchange )
                        document.removeEventListener( 'mozfullscreenchange', fullscreenchange )

                    element.requestPointerLock()

                document.addEventListener( 'fullscreenchange', fullscreenchange, false )
                document.addEventListener( 'mozfullscreenchange', fullscreenchange, false )

                element.requestFullscreen = element.requestFullscreen or element.mozRequestFullscreen or element.mozRequestFullScreen or element.webkitRequestFullscreen
                element.requestFullscreen()

            else
                element.requestPointerLock()

        , false)

    else
        instructions.innerHTML = 'Your browser doesn\'t seem to support Pointer Lock API'
