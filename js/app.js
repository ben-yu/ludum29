(function(/*! Brunch !*/) {
  'use strict';

  var globals = typeof window !== 'undefined' ? window : global;
  if (typeof globals.require === 'function') return;

  var modules = {};
  var cache = {};

  var has = function(object, name) {
    return ({}).hasOwnProperty.call(object, name);
  };

  var expand = function(root, name) {
    var results = [], parts, part;
    if (/^\.\.?(\/|$)/.test(name)) {
      parts = [root, name].join('/').split('/');
    } else {
      parts = name.split('/');
    }
    for (var i = 0, length = parts.length; i < length; i++) {
      part = parts[i];
      if (part === '..') {
        results.pop();
      } else if (part !== '.' && part !== '') {
        results.push(part);
      }
    }
    return results.join('/');
  };

  var dirname = function(path) {
    return path.split('/').slice(0, -1).join('/');
  };

  var localRequire = function(path) {
    return function(name) {
      var dir = dirname(path);
      var absolute = expand(dir, name);
      return globals.require(absolute);
    };
  };

  var initModule = function(name, definition) {
    var module = {id: name, exports: {}};
    definition(module.exports, localRequire(name), module);
    var exports = cache[name] = module.exports;
    return exports;
  };

  var require = function(name) {
    var path = expand(name, '.');

    if (has(cache, path)) return cache[path];
    if (has(modules, path)) return initModule(path, modules[path]);

    var dirIndex = expand(path, './index');
    if (has(cache, dirIndex)) return cache[dirIndex];
    if (has(modules, dirIndex)) return initModule(dirIndex, modules[dirIndex]);

    throw new Error('Cannot find module "' + name + '"');
  };

  var define = function(bundle, fn) {
    if (typeof bundle === 'object') {
      for (var key in bundle) {
        if (has(bundle, key)) {
          modules[key] = bundle[key];
        }
      }
    } else {
      modules[bundle] = fn;
    }
  };

  globals.require = require;
  globals.require.define = define;
  globals.require.register = define;
  globals.require.brunch = true;
})();

window.require.register("scripts/game", function(exports, require, module) {
  var LockedControls, animate, blueEffect, camera, chirp, composer, controls, dt, effect, inAir, init, initCannon, onWindowResize, playedSplash, render, renderer, scene, score, sound, spawnTarget, sphereBody, splash, time, waterBedHeight, waterHeight, waterLayer, world;

  sphereBody = {};

  waterLayer = [{}, {}];

  LockedControls = require('./lockedcontrols');

  time = Date.now();

  score = 0;

  waterHeight = -90;

  waterBedHeight = -500;

  playedSplash = false;

  sound = new Howl({
    urls: ['sounds/beachwaves.mp3'],
    loop: true
  });

  splash = new Howl({
    urls: ['sounds/splash.mp3']
  });

  chirp = new Howl({
    urls: ['sounds/dolphins.mp3']
  });

  init = function() {
    var aCubeMap, aShader, aSkyBoxMaterial, aSkybox, ambient, createWater, geometry, material, mesh, pointerlock, sun, surface, underwater, waterNormals;
    scene.fog = new THREE.Fog(0x000000, 0, 500);
    renderer.setClearColor(scene.fog.color, 1);
    ambient = new THREE.AmbientLight(0x555555);
    scene.add(ambient);
    sun = new THREE.DirectionalLight(0xffff55, 1);
    sun.position.set(-600, 300, 600);
    sun.lookAt(new THREE.Vector3());
    scene.add(sun);
    pointerlock = require('./pointerlock')(controls);
    geometry = new THREE.PlaneGeometry(50000, 50000, 30, 30);
    geometry.applyMatrix(new THREE.Matrix4().makeRotationX(-Math.PI / 2));
    material = new THREE.MeshLambertMaterial({
      color: 0xdddddd
    });
    mesh = new THREE.Mesh(geometry, material);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    mesh.position.y = waterBedHeight;
    scene.add(mesh);
    waterNormals = new THREE.ImageUtils.loadTexture('img/waternormals.jpg');
    waterNormals.wrapS = waterNormals.wrapT = THREE.RepeatWrapping;
    createWater = function(type, alpha, waterColor, position, xRotation) {
      var aMeshMirror;
      waterLayer[type] = new THREE.Water(renderer, camera, scene, {
        textureWidth: 256,
        textureHeight: 256,
        waterNormals: waterNormals,
        alpha: alpha,
        sunDirection: sun.position.normalize(),
        sunColor: 0xffffff,
        waterColor: waterColor,
        betaVersion: 0
      });
      aMeshMirror = new THREE.Mesh(new THREE.PlaneGeometry(50000, 50000, 100, 100), waterLayer[type].material);
      aMeshMirror.add(waterLayer[type]);
      aMeshMirror.rotation.x = xRotation;
      aMeshMirror.position.y = position;
      return aMeshMirror;
    };
    surface = createWater(0, 1.0, 0x001e0f, waterHeight, -Math.PI * 0.5);
    underwater = createWater(1, 0.85, 0x001e0f, waterHeight + 1, -Math.PI * 1.5);
    scene.add(surface);
    scene.add(underwater);
    aCubeMap = THREE.ImageUtils.loadTextureCube(['img/px.jpg', 'img/nx.jpg', 'img/py.jpg', 'img/ny.jpg', 'img/pz.jpg', 'img/nz.jpg']);
    aCubeMap.format = THREE.RGBFormat;
    aShader = THREE.ShaderLib['cube'];
    aShader.uniforms['tCube'].value = aCubeMap;
    aSkyBoxMaterial = new THREE.ShaderMaterial({
      fragmentShader: aShader.fragmentShader,
      vertexShader: aShader.vertexShader,
      uniforms: aShader.uniforms,
      depthWrite: false,
      side: THREE.BackSide
    });
    aSkybox = new THREE.Mesh(new THREE.CubeGeometry(1000000, 1000000, 1000000), aSkyBoxMaterial);
    scene.add(aSkybox);
    return sound.play();
  };

  initCannon = function() {
    var groundBody, groundBody2, groundShape, groundShape2, mass, physicsContactMaterial, physicsMaterial, radius, solver, sphereShape;
    world.quatNormalizeSkip = 0;
    world.quatNormalizeFast = false;
    solver = new CANNON.GSSolver();
    world.defaultContactMaterial.contactEquationStiffness = 1e9;
    world.defaultContactMaterial.contactEquationRegularizationTime = 4;
    solver.iterations = 7;
    solver.tolerance = 0.1;
    world.solver = new CANNON.SplitSolver(solver);
    world.gravity.set(0, -98.1, 0);
    world.broadphase = new CANNON.NaiveBroadphase();
    physicsMaterial = new CANNON.Material("slipperyMaterial");
    physicsContactMaterial = new CANNON.ContactMaterial(physicsMaterial, physicsMaterial, 0.0, 0.3);
    world.addContactMaterial(physicsContactMaterial);
    mass = 5;
    radius = 1.3;
    sphereShape = new CANNON.Sphere(radius);
    sphereBody = new CANNON.RigidBody(mass, sphereShape, physicsMaterial);
    sphereBody.position.set(0, 0, 0);
    sphereBody.linearDamping = 0.9;
    sphereBody.collisionFilterGroup = 1;
    sphereBody.collisionFilterMask = 1;
    world.add(sphereBody);
    groundShape = new CANNON.Plane();
    groundBody = new CANNON.RigidBody(0, groundShape, physicsMaterial);
    groundBody.quaternion.setFromAxisAngle(new CANNON.Vec3(1, 0, 0), -Math.PI / 2);
    groundBody.position.y = waterBedHeight;
    groundShape2 = new CANNON.Plane();
    groundBody2 = new CANNON.RigidBody(0, groundShape, physicsMaterial);
    groundBody2.quaternion.setFromAxisAngle(new CANNON.Vec3(1, 0, 0), -Math.PI / 2);
    groundBody2.position.y = waterBedHeight - 50;
    return world.add(groundBody);
  };

  spawnTarget = function(pos) {
    var boundBox, physicsMaterial, target, targetBody, targetGeom, targetMat;
    targetGeom = new THREE.TorusGeometry(100, 10, 20, 20);
    targetGeom.computeBoundingBox();
    targetMat = new THREE.MeshNormalMaterial();
    target = new THREE.Mesh(targetGeom, targetMat);
    target.position = pos;
    target.rotation.y = Math.random() * Math.PI;
    scene.add(target);
    physicsMaterial = new CANNON.Material("slipperyMaterial");
    boundBox = new CANNON.Box(new CANNON.Vec3(targetGeom.boundingBox.max.x, targetGeom.boundingBox.max.y, targetGeom.boundingBox.max.z));
    targetBody = new CANNON.RigidBody(-1, boundBox, physicsMaterial);
    targetBody.position.set(target.position.x, target.position.y, target.position.z);
    targetBody.collisionFilterGroup = 1;
    targetBody.collisionFilterMask = 1;
    world.add(targetBody);
    return targetBody.addEventListener('collide', function(e) {
      var contact;
      contact = e.contact;
      console.log('RING COLLISION!');
      console.log(e);
      if (contact.bj.id === sphereBody.id) {
        scene.remove(target);
        targetBody.collisionFilterGroup = 2;
        score += 1;
        document.getElementById('score').innerHTML = score;
        return spawnTarget(new THREE.Vector3(Math.random() * 2000 - 1000, Math.random() * 50, Math.random() * 2000 - 1000));
      }
    });
  };

  onWindowResize = function() {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
    return render();
  };

  inAir = true;

  dt = 1 / 60;

  world = new CANNON.World();

  initCannon();

  scene = new THREE.Scene();

  camera = new THREE.PerspectiveCamera(90, window.innerWidth / window.innerHeight, 0.1, 10000000);

  controls = new LockedControls(camera, sphereBody);

  scene.add(controls.getObject());

  spawnTarget(new THREE.Vector3(-500, 20, -500));

  renderer = new THREE.WebGLRenderer();

  renderer.setSize(window.innerWidth, window.innerHeight);

  document.body.appendChild(renderer.domElement);

  window.addEventListener('resize', onWindowResize, false);

  composer = new THREE.EffectComposer(renderer);

  composer.addPass(new THREE.RenderPass(scene, camera));

  blueEffect = new THREE.ShaderPass(THREE.ColorifyShader);

  blueEffect.uniforms['color'].value = new THREE.Color(0x6699FF);

  blueEffect.enabled = false;

  composer.addPass(blueEffect);

  effect = new THREE.ShaderPass(THREE.CopyShader);

  effect.renderToScreen = true;

  composer.addPass(effect);

  render = function() {
    waterLayer[0].material.uniforms.time.value += 1.0 / 60.0;
    waterLayer[0].render();
    renderer.autoClear = false;
    renderer.render(scene, camera);
    return composer.render();
  };

  animate = function() {
    if (controls.enabled) {
      world.step(dt);
    }
    controls.update(Date.now() - time);
    render();
    time = Date.now();
    requestAnimationFrame(animate);
    if (sphereBody.position.y < waterHeight && inAir) {
      inAir = false;
      controls.canJump = true;
      blueEffect.enabled = true;
      world.gravity.set(0, -98.1, 0);
      splash.play();
    } else if (sphereBody.position.y > waterHeight && !inAir) {
      inAir = true;
      controls.canJump = false;
      blueEffect.enabled = false;
      world.gravity.set(0, -500.1, 0);
      chirp.play();
    }
  };

  init();

  animate();
  
});
window.require.register("scripts/lockedcontrols", function(exports, require, module) {
  var LockedControls,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  module.exports = LockedControls = (function() {
    LockedControls.prototype.momentum = 0;

    LockedControls.prototype.velocityFactor = 0.2;

    LockedControls.prototype.jumpVelocity = 2000;

    LockedControls.prototype.pitchObject = new THREE.Object3D();

    LockedControls.prototype.yawObject = new THREE.Object3D();

    LockedControls.prototype.quat = new THREE.Quaternion();

    LockedControls.prototype.moveForward = false;

    LockedControls.prototype.moveBackward = false;

    LockedControls.prototype.moveLeft = false;

    LockedControls.prototype.moveRight = false;

    LockedControls.prototype.canJump = false;

    LockedControls.prototype.enabled = false;

    LockedControls.prototype.contactNormal = new CANNON.Vec3();

    LockedControls.prototype.upAxis = new CANNON.Vec3(0, 1, 0);

    LockedControls.prototype.PI_2 = Math.PI / 2;

    function LockedControls(camera, cannonBody) {
      this.cannonBody = cannonBody;
      this.update = bind(this.update, this);
      this.getObject = bind(this.getObject, this);
      this.onKeyUp = bind(this.onKeyUp, this);
      this.onKeyDown = bind(this.onKeyDown, this);
      this.onMouseMove = bind(this.onMouseMove, this);
      this.pitchObject.add(camera);
      this.yawObject.position.y = 100;
      this.yawObject.add(this.pitchObject);
      this.cannonBody.addEventListener('collide', (function(_this) {
        return function(e) {
          var contact;
          contact = e.contact;
          if (contact.bi.id === _this.cannonBody.id) {
            contact.ni.negate(_this.contactNormal);
          } else {
            contact.ni.copy(_this.contactNormal);
          }
          if (_this.contactNormal.dot(_this.upAxis) > 0.5) {
            return _this.canJump = true;
          }
        };
      })(this));
      this.velocity = this.cannonBody.velocity;
      this.inputVelocity = new THREE.Vector3(0, 0, 0);
      document.addEventListener('mousemove', this.onMouseMove, false);
      document.addEventListener('keydown', this.onKeyDown, false);
      document.addEventListener('keyup', this.onKeyUp, false);
    }

    LockedControls.prototype.onMouseMove = function(event) {
      var movementX, movementY;
      if (this.enabled === false) {
        return;
      }
      movementX = event.movementX || event.mozMovementX || event.webkitMovementX || 0;
      movementY = event.movementY || event.mozMovementY || event.webkitMovementY || 0;
      this.yawObject.rotation.y -= movementX * 0.002;
      this.pitchObject.rotation.x -= movementY * 0.002;
      return this.pitchObject.rotation.x = Math.max(-this.PI_2, Math.min(this.PI_2, this.pitchObject.rotation.x));
    };

    LockedControls.prototype.onKeyDown = function(event) {
      switch (event.keyCode) {
        case 87:
          return this.moveForward = true;
        case 65:
          return this.moveLeft = true;
        case 83:
          return this.moveBackward = true;
        case 68:
          return this.moveRight = true;
        case 32:
          if (this.canJump) {
            this.chirp.play();
            this.velocity.y = this.jumpVelocity;
          }
          return this.canJump = false;
      }
    };

    LockedControls.prototype.onKeyUp = function(event) {
      switch (event.keyCode) {
        case 87:
          return this.moveForward = false;
        case 65:
          if (!this.moveLeft) {
            this.moveLeft = true;
            return this.momentum -= 10;
          }
          break;
        case 83:
          return this.moveBackward = false;
        case 68:
          if (this.moveLeft) {
            this.moveLeft = false;
            return this.momentum -= 10;
          }
      }
    };

    LockedControls.prototype.getObject = function() {
      return this.yawObject;
    };

    LockedControls.prototype.update = function(delta) {
      if (this.enabled === false) {
        return;
      }
      delta *= 0.1;
      this.inputVelocity.set(0, 0, 0);
      this.inputVelocity.z = this.momentum * delta;
      if (this.moveLeft) {
        this.inputVelocity.x = -this.velocityFactor * delta;
      }
      if (this.moveRight) {
        this.inputVelocity.x = this.velocityFactor * delta;
      }
      if (this.momentum <= 0) {
        this.momentum += 1;
      } else {
        this.momentum = 0;
      }
      this.inputVelocity.applyEuler(new THREE.Euler(this.pitchObject.rotation.x, this.yawObject.rotation.y, 0, 'ZYX'));
      this.velocity.x += this.inputVelocity.x;
      if (this.canJump) {
        this.velocity.y += this.inputVelocity.y;
      }
      this.velocity.z += this.inputVelocity.z;
      return this.cannonBody.position.copy(this.yawObject.position);
    };

    return LockedControls;

  })();
  
});
window.require.register("scripts/pointerlock", function(exports, require, module) {
  var PointerLock;

  module.exports = PointerLock = (function(_this) {
    return function(controls) {
      var HEIGHT, WIDTH, blocker, element, havePointerLock, instructions, pointerlockchange, pointerlockerror, score;
      havePointerLock = 'pointerLockElement' in document || 'mozPointerLockElement' in document || 'webkitPointerLockElement' in document;
      WIDTH = window.innerWidth;
      HEIGHT = window.innerHeight;
      blocker = document.getElementById('blocker');
      instructions = document.getElementById('instructions');
      score = document.getElementById('score');
      if (havePointerLock) {
        element = document.body;
        pointerlockchange = function(event) {
          if (document.pointerLockElement === element || document.mozPointerLockElement === element || document.webkitPointerLockElement === element) {
            controls.enabled = true;
            controls.cursor_x = WIDTH / 2;
            controls.cursor_y = HEIGHT / 2;
            blocker.style.display = 'none';
            return score.style.display = '-webkit-box';
          } else {
            controls.enabled = false;
            blocker.style.display = 'inline';
            blocker.style.display = 'inline';
            blocker.style.display = 'inline';
            instructions.style.display = '';
            return score.style.display = 'none';
          }
        };
        pointerlockerror = function(event) {
          return instructions.style.display = '';
        };
        document.addEventListener('pointerlockchange', pointerlockchange, false);
        document.addEventListener('mozpointerlockchange', pointerlockchange, false);
        document.addEventListener('webkitpointerlockchange', pointerlockchange, false);
        document.addEventListener('pointerlockerror', pointerlockerror, false);
        document.addEventListener('mozpointerlockerror', pointerlockerror, false);
        document.addEventListener('webkitpointerlockerror', pointerlockerror, false);
        return instructions.addEventListener('click', function(event) {
          var fullscreenchange;
          instructions.style.display = 'none';
          element.requestPointerLock = element.requestPointerLock || element.mozRequestPointerLock || element.webkitRequestPointerLock;
          if (/Firefox/i.test(navigator.userAgent)) {
            fullscreenchange = function(event) {
              if (document.fullscreenElement === element || document.mozFullscreenElement === element || document.mozFullScreenElement === element) {
                document.removeEventListener('fullscreenchange', fullscreenchange);
                document.removeEventListener('mozfullscreenchange', fullscreenchange);
              }
              return element.requestPointerLock();
            };
            document.addEventListener('fullscreenchange', fullscreenchange, false);
            document.addEventListener('mozfullscreenchange', fullscreenchange, false);
            element.requestFullscreen = element.requestFullscreen || element.mozRequestFullscreen || element.mozRequestFullScreen || element.webkitRequestFullscreen;
            return element.requestFullscreen();
          } else {
            return element.requestPointerLock();
          }
        }, false);
      } else {
        return instructions.innerHTML = 'Your browser doesn\'t seem to support Pointer Lock API';
      }
    };
  })(this);
  
});
