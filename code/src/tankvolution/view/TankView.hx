package tankvolution.view;

import js.Browser;
import tankvolution.Main;
import tankvolution.model.Tank;
import threejs.core.Object3D;
import threejs.Disposable;
import threejs.extras.geometries.BoxGeometry;
import threejs.extras.geometries.CubeGeometry;
import threejs.materials.MeshBasicMaterial;
import threejs.materials.MeshLambertMaterial;
import threejs.math.Matrix4;
import threejs.math.Vector2;
import threejs.objects.Mesh;
import threejs.scenes.Scene;
import threejs.textures.Texture;
import weber.game.assets.ImageAsset;
import weber.game.assets.ThreeTextureAsset;
import weber.Maths;

class TankView {

	private var main:Main;
	private var tank:Tank;

	private var v:Object3D;
	private var body:Mesh;
	private var turret:Mesh;
	private var nozzle:Mesh;
	private var loadBar:Mesh;
	private var healthBar:Mesh;
	private var resBar:Mesh;
	private var babyBar:Mesh;

	private static var TEX_CAMO = ImageAsset.declare("camo");
	public static var COLORS = ["#33CCFF", "#FF3366", "#1AFF00", "#002EB8"];
	
	private var time:Float = 0;

	private var dispose:Array<Disposable> = [];

	public function new(main:Main, tank:Tank) {

		this.main = main;
		this.tank = tank;

		v = new Object3D();
		v.frustumCulled = true;
		main.scene.add(v);

		var scale = Math.pow(tank.inhpMaxResources / 500, 1/3);
		v.scale.set(scale, scale, scale);


		// --- body

		var color = COLORS[tank.family];

		var canv = Browser.document.createCanvasElement();
		canv.width = 256;
		canv.height = 256;
		var ctx = canv.getContext2d();

		// camo
		ctx.drawImage(TEX_CAMO.image, 0, 0);

		// colour
		ctx.globalAlpha = 0.75;
		ctx.fillStyle = color;
		ctx.fillRect(0, 0, canv.width, canv.height);
		
		// ID
		ctx.translate(canv.width/2, canv.height/2);
		ctx.rotate(Maths.HALFPI);
		ctx.translate(-canv.width/2, -canv.height/2);
		ctx.globalAlpha = 1;
		ctx.fillStyle = "white";
		ctx.strokeStyle = "black";
		ctx.lineWidth = 20;
		ctx.font = "80pt army";
		var tx = (canv.width - ctx.measureText(""+tank.id).width)/2;
		ctx.strokeText(""+tank.id, tx, 180);
		ctx.fillText(""+tank.id, tx, 180);

		var texture = new Texture(canv);
		texture.needsUpdate = true;
		dispose.push(texture);

		var bgm = new BoxGeometry(3, 2, 1.5);
		var bgmtf = new Matrix4();
		bgmtf.makeTranslation(0.5,0,1.5/2);
		bgm.applyMatrix(bgmtf);
		body = new Mesh(bgm, new MeshLambertMaterial({map: texture}));
		dispose.push(bgm);
		dispose.push(body.material);
		body.castShadow = true;
		// body.receiveShadow = true;
		v.add(body);

		// health bar
		var hbm = new BoxGeometry(2.8, 0.2, 0.05);
		var hbmtf = new Matrix4();
		hbmtf.makeTranslation(2.8/2, 0, 0.025);
		hbm.applyMatrix(hbmtf);
		healthBar = new Mesh(hbm, new MeshLambertMaterial({ambient: 0xFFFF00}));
		dispose.push(hbm);
		dispose.push(healthBar.material);
		healthBar.position.z = 1.5;
		healthBar.position.x = 0.1 - 1;
		healthBar.position.y = 1 - 0.2 - 0.1;
		v.add(healthBar);

		// res bar
		var rbm = new BoxGeometry(2.8, 0.2, 0.05);
		var rbmtf = new Matrix4();
		rbmtf.makeTranslation(2.8/2, 0, 0.025);
		rbm.applyMatrix(rbmtf);
		resBar = new Mesh(rbm, new MeshLambertMaterial({ambient: 0x8888FF}));
		dispose.push(rbm);
		dispose.push(resBar.material);
		resBar.position.z = 1.5;
		resBar.position.x = 0.1 - 1;
		resBar.position.y = -(1 - 0.2 - 0.1);
		v.add(resBar);

		// baby bar
		var bybm = new BoxGeometry(2.8, 0.2, 0.05);
		var bybmtf = new Matrix4();
		bybmtf.makeTranslation(2.8/2, 0, 0.025);
		bybm.applyMatrix(bybmtf);
		babyBar = new Mesh(bybm, new MeshLambertMaterial({ambient: 0xFF0088}));
		dispose.push(bybm);
		dispose.push(babyBar.material);
		babyBar.position.z = 1.5;
		babyBar.position.x = 0.1 - 1;
		babyBar.position.y = -(1 - 0.5 - 0.1);
		v.add(babyBar);

		// --- nozzle
		var ngm = new BoxGeometry(1, 0.33, 0.2);
		var ngmtf = new Matrix4();
		ngmtf.makeTranslation(0.5, 0, 0.1);
		ngm.applyMatrix(ngmtf);
		nozzle = new Mesh(ngm, new MeshLambertMaterial({ambient: 0xFFFF00, opacity: 0.25, transparent: true}));
		dispose.push(ngm);
		dispose.push(nozzle.material);
		v.add(nozzle);

		// --- turret
		var tgm = new BoxGeometry(2, 0.5, 0.5);
		var tgmtf = new Matrix4();
		tgmtf.makeTranslation(1, 0, 0.25);
		tgm.applyMatrix(tgmtf);
		turret = new Mesh(tgm, new MeshLambertMaterial({ambient: 0x003333}));
		dispose.push(tgm);
		dispose.push(turret.material);
		turret.position.z = 1.5;
		turret.castShadow = true;
		v.add(turret);

		// load bar
		var lbm = new BoxGeometry(1.8, 0.2, 0.05);
		var lbmtf = new Matrix4();
		lbmtf.makeTranslation(1.8/2, 0, 0.025);
		lbm.applyMatrix(lbmtf);
		loadBar = new Mesh(lbm, new MeshLambertMaterial({ambient: 0xFFFFFF}));
		dispose.push(lbm);
		dispose.push(loadBar.material);
		loadBar.position.z = 0.5;
		loadBar.position.x = 0.1;
		turret.add(loadBar);

	}

	public function update(dt:Float) {

		if (!tank.alive()) {
			v.parent.remove(v);
			main.entityViews.remove(tank);
			for (d in dispose) d.dispose();
			return;
		}

		time += dt;
		
		// pos and orientation
		v.position.x = tank.position.x;
		v.position.y = tank.position.y;
		if (tank.velocity.length() != 0)
			v.rotation.z = angle(tank.velocity);

		// turret
		var turScale = (tank.inhpPowerToLoad / 10) / v.scale.x;
		if (tank.targetEnemy != null) {
			turret.rotation.z = angle(tank.targetEnemy.position.clone().sub(tank.position)) - v.rotation.z;
			turret.scale.set(turScale, 1, 1);
			loadBar.visible = true;
			loadBar.scale.x = tank.powerLoaded / tank.inhpPowerToLoad;
			nozzle.visible = false;
		} else {
			turret.rotation.z = 0;
			turret.scale.set(0.5 * turScale, 0.5, 0.5);
			loadBar.visible = false;

			if (tank.targetResource != null) {
				nozzle.visible = true;
				var resVec = tank.targetResource.position.clone().sub(tank.position);
				nozzle.rotation.z = angle(resVec) - v.rotation.z;
				nozzle.scale.x = resVec.length() / v.scale.x;

				var eating = resVec.length() <= tank.inhpEatDistance;

				nozzle.scale.y = nozzle.scale.z = eating ? 1 : 0.5;

				var oldOp = nozzle.material.opacity;
				nozzle.material.opacity = eating ? 0.75 : 0.25;
				if (nozzle.material.opacity != oldOp) nozzle.material.needsUpdate = true;
			} else {
				nozzle.visible = false;
			}
		}

		// bars
		healthBar.scale.x = Math.max(0.01, tank.health / tank.inhpMaxHealth);
		resBar.scale.x = Math.max(0.01, tank.relResources());
		babyBar.scale.x = Math.max(0.01, tank.baby / (tank.inhpBabyPart * tank.inhpMaxResources));

		// blink res bar
		if (tank.hungry()) {
			resBar.visible = Math.floor(time * (tank.disabled() ? 8 : (tank.veryHungry() ? 4 : 2))) % 2 == 0;
		} else {
			resBar.visible = true;
		}

	}

	private function angle(vec:Vector2):Float {
		return Math.atan2(vec.y, vec.x);
	}

}