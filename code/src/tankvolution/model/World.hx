package tankvolution.model;

import tankvolution.model.Resource;
import threejs.math.Vector2;
import weber.Maths;

class World {

	// private static inline var FAMILIES = 4;
	// private static inline var MEMBERS = 10;

	public var entities:Array<Entity>;

	private var resourceDumpTime:Array<Float> = [0,0,0,0];

	public var size:Float;

	public function new(size:Float = 300, density:Float = 0.001) {

		entities = [];
		this.size = size;

		for (t in 0...Math.floor(size*size * density)) {
			var pos = randomPos();
			// var fam = (pos.x > 0 ? 1 : 0) + (pos.y > 0 ? 2 : 0);
			var tank = new Tank(this, pos);
			tank.family = Math.random();
			tank.health = tank.inhpMaxHealth * Maths.randomBetween(0.5, 1);
			tank.resources = tank.inhpMaxResources * Maths.randomBetween(0.5, 1);
			tank.baby = tank.inhpBabyPart * tank.inhpMaxResources * Maths.randomBetween(0, 0.8);
		}

		// for (fam in 0...FAMILIES) {
			// for (t in 0...MEMBERS) {
				// var tank = new Tank(this, randomPos(), fam);
				// tank.health = tank.inhpMaxHealth * Maths.randomBetween(0.5, 1);
				// tank.resources = tank.inhpMaxResources * Maths.randomBetween(0.5, 1);
				// tank.baby = tank.inhpBabyPart * tank.inhpMaxResources * Maths.randomBetween(0, 0.8);
			// }
		// }

	}

	public function step(dt:Float):Void {

		if (dt == 0) return;

		for (i in 0...resourceDumpTime.length) resourceDumpTime[i] += dt;

		if (resourceDumpTime[0] > 0.2) {
			new Resource(this, new Vector2(
				Maths.randomBetween(-size/2, 0), 
				Maths.randomBetween(-size/2, 0)
			), 25);
			resourceDumpTime[0] = 0;
		}
		if (resourceDumpTime[1] > 1) {
			new Resource(this, new Vector2(
				Maths.randomBetween(0, size/2), 
				Maths.randomBetween(-size/2, 0)
			), 125);
			resourceDumpTime[1] = 0;
		}
		if (resourceDumpTime[2] > 0.4) {
			new Resource(this, new Vector2(
				Maths.randomBetween(0, size/2), 
				Maths.randomBetween(0, size/2)
			), 50);
			resourceDumpTime[2] = 0;
		}
		if (resourceDumpTime[2] > 0.2) {
			new Resource(this, new Vector2(
				Maths.randomBetween(-size/2, 0), 
				Maths.randomBetween(0, size/2)
			), 10);
			resourceDumpTime[2] = 0;
		}
	
		for (e in entities) {
			e.step(dt);
		}

	}

	private function randomPos() {
		return new Vector2(
			Maths.randomBetween(-size/2, size/2), 
			Maths.randomBetween(-size/2, size/2)
		);
	}

}