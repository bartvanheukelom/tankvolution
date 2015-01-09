package tankvolution;

import haxe.ds.ObjectMap;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import tankvolution.model.Resource;
import tankvolution.model.Tank;
import tankvolution.model.World;
import tankvolution.view.ResourceView;
import tankvolution.view.TankView;
import threejs.cameras.Camera;
import threejs.cameras.OrthographicCamera;
import threejs.cameras.PerspectiveCamera;
import threejs.core.Geometry;
import threejs.core.Object3D;
import threejs.extras.geometries.CubeGeometry;
import threejs.extras.geometries.PlaneBufferGeometry;
import threejs.extras.geometries.PlaneGeometry;
import threejs.extras.geometries.SphereGeometry;
import threejs.lights.AmbientLight;
import threejs.lights.DirectionalLight;
import threejs.materials.MeshBasicMaterial;
import threejs.materials.MeshLambertMaterial;
import threejs.materials.MeshPhongMaterial;
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

	private var camHeight:Float = 0;

	private var ambient:AmbientLight;
	private var sun:DirectionalLight;
	private var sunTarget:Object3D;

	private var skyScene:Scene;
	private var skyCam:PerspectiveCamera;
	private var sky:Mesh;
	private var stars:Mesh;

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
	private static var SKY = ThreeTextureAsset.declare("sky");
	private static var STARS = ThreeTextureAsset.declare("stars");

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

		renderer = new WebGLRenderer({canvas: Tortilla.canvas, antialias: false, devicePixelRatio: 1});
		scene = new Scene();
		cam = new PerspectiveCamera(75, 1, 1, 400);
		camHeight = 60;
		cam.position.y = 45;
		cam.rotation.x = Math.PI * 0.15;
		cam.rotation.z = Math.PI;
		cam.rotation.order = "ZYX";
		trace("camrot", cam.rotation);

		highGraphics = Tortilla.parameters.get("gfx", "high") == "high";

		renderer.shadowMapEnabled = highGraphics;
    	// renderer.shadowMapSoft = true;

		ambient = new AmbientLight(0x000000);
		scene.add(ambient);
		
		sunTarget = new Object3D();
		scene.add(sunTarget);

		sun = new DirectionalLight(0xffbbbb, 1);
		scene.add(sun);

		sun.castShadow = true;
		// sun.shadowCameraVisible = true;
		sun.shadowMapWidth = sun.shadowMapHeight = 4096;
		sun.target = sunTarget;

		entityViews = new Map<Entity, Dynamic>();


		skyScene = new Scene();
		skyCam = new PerspectiveCamera(75, 1, 1, 400);

		uiCanvas = Tortilla.createBuffer(1,1);
		uiCtx = uiCanvas.getContext2d();

		uiScene = new Scene();
		uiCam = new OrthographicCamera(0,1,0,1,-1000,1000);

		uiTex = new Texture();
		uiTex.image = uiCanvas;
		uiTex.generateMipmaps = false;
		uiTex.magFilter = ThreeJs.NearestFilter;
		uiTex.minFilter = ThreeJs.NearestFilter;

		uiPlane = new Mesh(new PlaneBufferGeometry(1,1), new MeshBasicMaterial({map: uiTex, transparent: true}));
		uiPlane.rotation.x = -Math.PI;
		uiScene.add(uiPlane);

		Tortilla.addEventListener(Tortilla.EV_RESIZED, adaptToSize);
		adaptToSize();

		AssetManager.init();
		AssetManager.loadAll(null, function() {

			sky = new Mesh(new SphereGeometry(100, 36, 4), new MeshBasicMaterial({map: SKY.texture(renderer), transparent: true}));
			sky.rotation.x = Maths.HALFPI;
			sky.scale.x = -1;
			sky.rotation.order = "ZYX";
			skyScene.add(sky);

			stars = new Mesh(new SphereGeometry(105, 36, 4), new MeshBasicMaterial({map: STARS.texture(renderer), transparent: true}));
			stars.rotation.x = Maths.HALFPI;
			stars.scale.x = -1;
			stars.rotation.order = "ZYX";
			skyScene.add(stars);

			world = new World(
				Std.parseFloat(Tortilla.parameters.get("size", "300")),
				Std.parseFloat(Tortilla.parameters.get("density", "0.001"))
			);

			var floor = new Mesh(new PlaneBufferGeometry(10000, 10000), new MeshLambertMaterial({color: 0xFF6633}));
			floor.position.z = -0.1;
			scene.add(floor);

			var wsi = Math.ceil(world.size / 3);

			var gg = new PlaneGeometry(world.size, world.size, wsi, wsi);
			for (v in gg.vertices) {
				v.z = terrainHeight(v.x, v.y);
			}
			for (f in gg.faces) {
				for (fv in 0...3) {
					var vn = f.vertexNormals[fv];
					var fvert:Vector3 = gg.vertices[Reflect.field(f, ["a","b","c"][fv])];
					vn.x = terrainHeight(fvert.x-0.1, fvert.y) - terrainHeight(fvert.x+0.1, fvert.y);
					vn.y = terrainHeight(fvert.x, fvert.y-0.1) - terrainHeight(fvert.x, fvert.y+0.1);
					vn.z = 0.2 * 0.33;
					vn.normalize();
				}
			}

			var ground = new Mesh(gg, new MeshLambertMaterial({map: GRASS.texture(renderer)}));
			ground.receiveShadow = true;
			ground.castShadow = true;
			scene.add(ground);

			cam.far = world.size*2;
			scene.fog = new Fog(0x3366FF, 50, world.size*0.75);

		});


	}

	public function terrainHeight(x:Float, y:Float) {
		var scaleX = 2;
		var scaleY = 4;
		return (
			(Math.sin(x*0.1/scaleX)+1) +
			(Math.cos(y*0.047/scaleX)+1) + 
			(Math.sin(Maths.pythagoras(x, y)*0.02/scaleX)+1) * 4 +
			(Math.cos(y*0.0068/scaleX)+1) * 4
		) * scaleY;
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
						camHeight = 5;
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
				camHeight = 60;
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
				pos.z += terrainHeight(viewingTank.position.x, viewingTank.position.y) + 5;
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
			if (KeyboardInput.isKeyDown(KeyboardInput.KEY_O)) camHeight *= Math.pow(3, dt);
			if (KeyboardInput.isKeyDown(KeyboardInput.KEY_L)) camHeight *= Math.pow(1/3, dt);
			if (viewingTank == null)
				cam.position.z = camHeight + terrainHeight(cam.position.x, cam.position.y);
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

			var repeats = KeyboardInput.isKeyDown(KeyboardInput.KEY_Z) ? 5 : 1;
			for (s in 0...repeats) {
				world.step(dt);
			}

			var vdt = dt * repeats;
			for (v in entityViews) {
				v.update(vdt);
			}

			var sunCurve = (-Math.cos(world.dayProgress() * Maths.TWOPI) + 1) / 2;
			var ambInts = sunCurve * 0.75 + 0.25;
			ambient.color.setRGB(0.7, 0.7, 0.8);
			ambient.color.multiplyScalar(ambInts);

			sky.material.opacity = sunCurve * 0.8 + 0.2;
			stars.material.opacity = Math.max(0, 0.8 - sunCurve * 2);
			sky.material.needsUpdate = true;
			stars.material.needsUpdate = true;

			sky.rotation.z = -world.dayProgress() * Maths.TWOPI;
			stars.rotation.z = world.dayProgress() * Maths.TWOPI;

			scene.fog.color.setHex(0xB3B3B3);
			scene.fog.color.multiplyScalar(ambInts);

			var sunOrigin = new Vector3(1, 1, sunCurve * 2 + 0.1);
			sunOrigin.applyAxisAngle(new Vector3(0,0,1), Maths.TWOPI * world.dayProgress());
			// sun.visible = false;
			sun.color.setHex(0xffbbbb);
			sun.color.multiplyScalar(ambInts);

			var camBase = cam.position.clone();
			camBase.z = 0;
			var camDistance = Math.max(50, cam.position.z);
			
			sunTarget.position.copy(camBase);
			sun.position.copy(sunTarget.position.clone().add(sunOrigin.multiplyScalar(camDistance*2)));

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
						

							// uiCtx.fillStyle = TankView.tankColour(t);// TankView.COLORS[t.family];

							var rad = 12;

							var grad = uiCtx.createRadialGradient(0, 0, 0, 0, 0, rad);
							grad.addColorStop(0, TankView.tankColour(t));
							grad.addColorStop(1, "rgba(0,0,0,0)");
							uiCtx.fillStyle = grad;

							uiCtx.globalAlpha = 0.33;
							uiCtx.beginPath();
							uiCtx.arc(0, 0, rad, 0, Math.PI*2, false);
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

							var rs = Math.pow((r.value * 0.02) / (0.75*Math.PI), 1/3);

							var rad = 10 * rs;

							var grad = uiCtx.createRadialGradient(0, 0, 0, 0, 0, rad);
							grad.addColorStop(0, "yellow");
							grad.addColorStop(1, "rgba(0,0,0,0)");
							uiCtx.fillStyle = grad;

							uiCtx.globalAlpha = 0.1;
							uiCtx.beginPath();
							uiCtx.arc(0, 0, rad, 0, Math.PI*2, false);
							uiCtx.closePath();
							uiCtx.fill();
							uiCtx.globalAlpha = 1;
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

		skyCam.up.copy(cam.up);
		skyCam.rotation.copy(cam.rotation);
		skyCam.aspect = cam.aspect;
		skyCam.updateProjectionMatrix();

		renderer.render(skyScene, skyCam);

		renderer.autoClearColor = false;
		renderer.render(scene, cam);
		renderer.autoClearColor = true;

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
		renderer.autoClear = true;

	}

	private function angle(vec:Vector2):Float {
		return Math.atan2(vec.y, vec.x);
	}

}