package tankvolution.model;

import tankvolution.model.World;
import threejs.math.Vector2;

class Resource implements Entity {
	
	public var value:Float;
	private var world:World;
	public var position:Vector2;

	public function new(w:World, pos:Vector2, value:Float) {
		this.world = w;
		this.position = pos;
		this.value = value;

		world.entities.push(this);
	}

	public function step(dt:Float) {
		take(dt * 2);
	}

	public function take(amount:Float) {
		var res = Math.min(amount, value);
		value -= res;
		if (value == 0) {
			world.entities.remove(this);
		}
		return res;
	}

}