package tankvolution;

import haxe.ds.ObjectMap;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import tankvolution.model.Resource;
import tankvolution.model.Tank;
import tankvolution.model.World;
import tankvolution.view.ResourceView;
import tankvolution.view.TankView;
import threejs.cameras.OrthographicCamera;
import threejs.cameras.PerspectiveCamera;
import threejs.core.Object3D;
import threejs.extras.geometries.CubeGeometry;
import threejs.extras.geometries.PlaneGeometry;
import threejs.lights.AmbientLight;
import threejs.lights.DirectionalLight;
import threejs.materials.MeshBasicMaterial;
import threejs.materials.MeshLambertMaterial;
import threejs.math.Vector2;
import threejs.math.Vector3;
import threejs.objects.Mesh;
import threejs.renderers.WebGLRenderer;
import threejs.scenes.Fog;
import threejs.scenes.Scene;
import threejs.textures.Texture;
import threejs.ThreeJs;
import tortilla.Tortilla;
import weber.game.assets.AssetManager;
import weber.game.assets.ThreeTextureAsset;
import weber.game.input.KeyboardInput;
import weber.Maths;
import tankvolution.model.Entity;

class Main {

	public var renderer:WebGLRenderer;
	public var scene:Scene;
	private var cam:PerspectiveCamera;
	private var sun:DirectionalLight;
	private var sunTarget:Object3D;


	private var uiCanvas:CanvasElement;
	private var uiCtx:CanvasRenderingContext2D;
	private var uiScene:Scene;
	private var uiCam:OrthographicCamera;
	private var uiPlane:Mesh;
	private var uiTex:Texture;

	private var world:World;

	public var entityViews:Map<Entity, Dynamic>;
	public var highGraphics:Bool;

	private var viewingTank:Tank = null;

	private static var GRASS = ThreeTextureAsset.declare("plains");

	public static function main() {
		Tortilla.game = new Main();
	}

	public function new() {

	}

	public function settings() {
		return {
			showFps: true,
			noContext: true
		};
	}

	public function init() {

		KeyboardInput.init();

		renderer = new WebGLRenderer({canvas: Tortilla.canvas, antialias: true, devicePixelRatio: 1});
		scene = new Scene();
		cam = new PerspectiveCamera(75, 1, 1, 400);
		cam.position.z = 60;
		cam.position.y = 45;
		cam.rotation.x = Math.PI * 0.15;
		cam.rotation.z = Math.PI;
		cam.rotation.order = "ZYX";
		trace("camrot", cam.rotation);

		highGraphics = Tortilla.parameters.get("gfx", "high") == "high";

		renderer.shadowMapEnabled = highGraphics;
    	// renderer.shadowMapSoft = true;

		var ambient = new AmbientLight(0x999999aa);
		scene.add(ambient);
		
		sunTarget = new Object3D();
		scene.add(sunTarget);

		sun = new DirectionalLight(0xffbbbb, 1);
		scene.add(sun);

		sun.castShadow = true;
		// sun.shadowCameraVisible = true;
		sun.shadowMapWidth = sun.shadowMapHeight = 4096;
		sun.target = sunTarget;

		scene.fog = new Fog(0x000000, 50, 400);

		entityViews = new Map<Entity, Dynamic>();

		uiCanvas = Tortilla.createBuffer(1,1);
		uiCtx = uiCanvas.getContext2d();

		uiScene = new Scene();
		uiCam = new OrthographicCamera(0,1,0,1,-1000,1000);

		uiTex = new Texture();
		uiTex.image = uiCanvas;
		uiTex.generateMipmaps = false;
		uiTex.magFilter = ThreeJs.NearestFilter;
		uiTex.minFilter = ThreeJs.NearestFilter;

		uiPlane = new Mesh(new PlaneGeometry(1,1), new MeshBasicMaterial({map: uiTex, transparent: true}));
		uiPlane.rotation.x = -Math.PI;
		uiScene.add(uiPlane);

		Tortilla.addEventListener(Tortilla.EV_RESIZED, adaptToSize);
		adaptToSize();

		AssetManager.init();
		AssetManager.loadAll(null, function() {

			world = new World(
				Std.parseFloat(Tortilla.parameters.get("size", "300")),
				Std.parseFloat(Tortilla.parameters.get("density", "0.001"))
			);

			var ground = new Mesh(new PlaneGeometry(world.size,world.size), new MeshLambertMaterial({map: GRASS.texture(renderer)}));
			ground.receiveShadow = true;
			scene.add(ground);

		});


	}

	private function adaptToSize() {
		var w = Tortilla.canvas.width;
		var h = Tortilla.canvas.height;
		var aspect = w / h;
		trace('adaptToSize ${w}x${h} ($aspect)');
		cam.aspect = aspect;
		renderer.setSize(w,h,false);

		uiCanvas.width = Tortilla.canvas.width;
		uiCanvas.height = Tortilla.canvas.height;

	}

	public function frame(ctx:Dynamic, dt:Float) {

		uiCtx.clearRect(0, 0, uiCanvas.width, uiCanvas.height);

		if (world != null) {

			KeyboardInput.process();

			if (KeyboardInput.isKeyPressed(KeyboardInput.KEY_N)) {

				var tries = 100;
				while (--tries != 0) {
					var e = Maths.arrayRandom(world.entities);
					if (Std.is(e, Tank)) {
						viewingTank = cast e;
						cam.rotation.x = Math.PI * 0.4;
						break;
					}
				}

				// var startingIndex = viewingTank == null ? 0 : (world.entities.indexOf(viewingTank) + 1);
				// for (i in 0...world.entities.length) {
				// 	var io = (i + startingIndex) % world.entities.length;
				// 	var e = world.entities[io];
				// 	if (Std.is(e, Tank)) {
				// 		viewingTank = cast e;
				// 		cam.rotation.x = Math.PI * 0.4;
				// 		// cam.rotation.x = 0;
				// 		break;
				// 	}
				// }
			}
			if (KeyboardInput.isKeyPressed(KeyboardInput.KEY_M)) {
				viewingTank = null;
			}

			if (viewingTank != null && !viewingTank.alive()) {
				viewingTank = null;
			}

			if (KeyboardInput.isKeyPressed(KeyboardInput.KEY_B)) {
				cam.position.x = 0;
				cam.position.z = 60;
				cam.position.y = 45;
				cam.rotation.set(Math.PI * 0.15, 0, Math.PI);
				viewingTank = null;
			}

			if (viewingTank != null) {
				var ta;
				if (viewingTank.targetEnemy == null) {
					if (viewingTank.targetResource == null || viewingTank.velocity.length() != 0)
						ta = angle(viewingTank.velocity);
					else
						ta = angle(viewingTank.targetResource.position.clone().sub(viewingTank.position)) + Maths.HALFPI;
				} else {
					ta = angle(viewingTank.targetEnemy.position.clone().sub(viewingTank.position));
				}
				var pos = new Vector3(viewingTank.position.x, viewingTank.position.y);
				pos.x += Math.cos(ta + Math.PI) * 7;
				pos.y += Math.sin(ta + Math.PI) * 7;
				pos.z += 5;
				// cam.position.copy(pos);
				// cam.rotation.z = -Maths.HALFPI + ta;
				cam.rotation.z = Maths.averageEase(cam.rotation.z, -Maths.HALFPI + ta, 5, dt, 0.01);
				cam.position.x = Maths.averageEase(cam.position.x, pos.x, 5, dt, 0.01);
				cam.position.y = Maths.averageEase(cam.position.y, pos.y, 5, dt, 0.1);
				cam.position.z = Maths.averageEase(cam.position.z, pos.z, 5, dt, 0.1);

			}

			var camMove = dt*250;
			if (KeyboardInput.isKeyDown(KeyboardInput.KEY_U)) cam.position.y += camMove;
			if (KeyboardInput.isKeyDown(KeyboardInput.KEY_J)) cam.position.y -= camMove;
			if (KeyboardInput.isKeyDown(KeyboardInput.KEY_H)) cam.position.x -= camMove;
			if (KeyboardInput.isKeyDown(KeyboardInput.KEY_K)) cam.position.x += camMove;
			if (KeyboardInput.isKeyDown(KeyboardInput.KEY_O)) cam.position.z *= Math.pow(3, dt);
			if (KeyboardInput.isKeyDown(KeyboardInput.KEY_L)) cam.position.z *= Math.pow(1/3, dt);
			var camRot = dt*1.5;
			if (KeyboardInput.isKeyDown(KeyboardInput.KEY_S)) cam.rotation.x += camRot;
			if (KeyboardInput.isKeyDown(KeyboardInput.KEY_W)) cam.rotation.x -= camRot;
			if (KeyboardInput.isKeyDown(KeyboardInput.KEY_A)) cam.rotation.z += camRot;
			if (KeyboardInput.isKeyDown(KeyboardInput.KEY_D)) cam.rotation.z -= camRot;
			cam.updateProjectionMatrix();



			for (e in world.entities) {

				var v = entityViews.get(e);
				if (v == null) {
					if (Std.is(e, Tank)) {
						v = new TankView(this, cast e);
					} else if (Std.is(e, Resource)) {
						v = new ResourceView(this, cast e);
					}
					if (v != null) entityViews.set(e, v);
				}

			}

			var repeats = KeyboardInput.isKeyDown(KeyboardInput.KEY_Z) ? 4 : 1;
			for (s in 0...repeats) {
				world.step(dt);
			}

			for (v in entityViews) {
				v.update(dt);
			}



			var camBase = cam.position.clone();
			camBase.z = 0;
			var camDistance = Math.max(50, cam.position.z);
			
			sunTarget.position.copy(camBase);
			sun.position.copy(sunTarget.position.clone().add(new Vector3(1, 1, 1).multiplyScalar(camDistance*2)));

			sun.shadowCameraLeft = -camDistance;
			sun.shadowCameraRight = -sun.shadowCameraLeft;
			sun.shadowCameraBottom = sun.shadowCameraLeft;
			sun.shadowCameraTop = sun.shadowCameraRight;
			scene.remove(sun.shadowCamera);
			sun.shadowCamera = null;


			uiCtx.save(); {

				uiCtx.translate(50,50);

				var mapSize = 200;

				uiCtx.fillStyle = "black";
				uiCtx.globalAlpha = 0.75;
				uiCtx.fillRect(0,0,mapSize,mapSize);
				uiCtx.globalAlpha = 1;
				uiCtx.strokeStyle = "white";
				uiCtx.lineWidth = 2;
				uiCtx.strokeRect(0,0,mapSize,mapSize);

				uiCtx.translate(mapSize,0);
				uiCtx.scale(-1,1);

				uiCtx.beginPath();
				uiCtx.rect(1,1,mapSize-2,mapSize-2);
				uiCtx.clip();

				for (e in world.entities) {
					var pos;
					if (Std.is(e, Tank)) {
						var t:Tank = cast e;
						pos = t.position;
					}
					else if (Std.is(e, Resource)) {
						var r:Resource = cast e;
						pos = r.position;
					}
					else pos = null;

					var mx = ((pos.x / world.size) + 0.5) * mapSize;
					var my = ((pos.y / world.size) + 0.5) * mapSize;
					uiCtx.save(); {
						uiCtx.translate(mx, my);

						if (Std.is(e, Tank)) {
							var t:Tank = cast e;
						

							uiCtx.fillStyle = TankView.tankColour(t);// TankView.COLORS[t.family];

							uiCtx.globalAlpha = 0.2;
							uiCtx.beginPath();
							uiCtx.arc(0, 0, 7, 0, Math.PI*2, false);
							uiCtx.closePath();
							uiCtx.fill();
							uiCtx.globalAlpha = 1;

							uiCtx.fillRect(-1, -1, 2, 2);

							if (t == viewingTank) {
								uiCtx.lineWidth = 1;
								uiCtx.strokeStyle = "white";
								uiCtx.beginPath();
								uiCtx.arc(0,0,7,0,2*Math.PI,false);
								uiCtx.closePath();
								uiCtx.stroke();
							}
							
						}
						if (Std.is(e, Resource)) {
							var r:Resource = cast e;
							uiCtx.fillStyle = "yellow";
							uiCtx.globalAlpha = r.value / 500;
							uiCtx.fillRect(-3, -3, 6, 6);
						}

					} uiCtx.restore();
				}

				var cx = ((cam.position.x / world.size) + 0.5) * mapSize;
				var cy = ((cam.position.y / world.size) + 0.5) * mapSize;
				uiCtx.save(); {
					uiCtx.translate(cx, cy);
					uiCtx.strokeStyle = "white";
					uiCtx.rotate(cam.rotation.z + Maths.HALFPI);
					var camScale = 4 * cam.position.z / 60;
					var camScaleX = camScale;// * cam.rotation.x;

					uiCtx.beginPath();
					uiCtx.moveTo(0,0);
					uiCtx.lineTo(15 * camScaleX, -15 * camScale);
					uiCtx.lineTo(15 * camScaleX, 15 * camScale);
					
					uiCtx.closePath();
					uiCtx.lineWidth = 1;
					uiCtx.stroke();

				} uiCtx.restore();
				

			} uiCtx.restore();


		}

		renderer.autoClear = true;
		renderer.render(scene, cam);

		uiTex.needsUpdate = true;

		uiPlane.position.x = uiCanvas.width/2;
		uiPlane.position.y = uiCanvas.height/2;
		uiPlane.scale.x = uiCanvas.width;
		uiPlane.scale.y = uiCanvas.height;

		uiCam.right = uiCanvas.width;
		uiCam.bottom = uiCanvas.height;
		uiCam.updateProjectionMatrix();

		renderer.autoClear = false;
		renderer.render(uiScene, uiCam);

	}

	private function angle(vec:Vector2):Float {
		return Math.atan2(vec.y, vec.x);
	}

}