package tankvolution.model;

import tankvolution.model.Resource;
import tankvolution.model.Tank;
import tankvolution.model.World;
import threejs.math.Vector2;
import weber.event.EventDispatcher;
import weber.Maths;

class Tank implements Entity extends EventDispatcher {

	public static inline var EV_FIRE = "fire";

	// ==== inheritable properties ==== //
	// - sight
	// - firing range
	// - rate of fire
	// - speed / mass / thrust

	public var inhpSight:Float = 40;
	public var inhpGunRange:Float = 25;
	public var inhpTargetGunRange:Float = 20;

	public var inhpPowerToLoad = 10;
	private var inhpPowerLoadRate = 5.0;

	public var inhpMaxHealth = 50.0;
	public var inhpHealRate = 2.0;
	public var inhpDecayRate = 0.5;

	public var inhpToEnemySpeed:Float = 8;
	public var inhpFlankSpeed:Float = 5;
	public var inhpIdleSpeed:Float = 3;
	
	private var inhpChangeDirAfter = 2.0;
	private var inhpChangeDirAmount = Maths.EIGHTPI;

	public var inhpMaxResources:Float = 500;

	public var inhpFlankChangeTimeMin = 3.0;
	public var inhpFlankChangeTimeMax = 5.0;

	public var inhpEatRate = 10.0;
	public var inhpEatDistance = 6.0;

	public var inhpFuelRate = 0.02;

	public var inhpBabyGrowRate = 2;
	public var inhpBabyPart = 0.5;
	public var inhpBabyHealthPart = 0.5;

	public var family:Float = 0;

	// === end inh. props ==== //
	
	private var world:World;
	public var position:Vector2;
	public var velocity:Vector2 = new Vector2();

	private static var idSeq = 0;
	public var id:Int;

	// --- state

	public var targetEnemy:Tank = null;
	public var targetResource:Resource = null;

	public var powerLoaded = 0.0;
	public var health:Float = 0;
	public var resources:Float = 0;
	public var baby:Float = 0;

	private var changeDirIn:Float = 0;
	public var movingToEnemy:Bool;
	private var flankMode:Int;
	private var timeToChangeFlankMode:Float = 0;

	public function new(w:World, pos:Vector2) {

		super();

		this.position = pos;
		this.world = w;

		this.id = ++idSeq;

		w.entities.push(this);
	}

	private function idStr() {
		return "Tank#" + id;// + "[" + family + "]";
	}

	public function step(dt:Float) {

		damage(dt * inhpDecayRate, "decay");

		if (!alive()) return;

		if (health < inhpMaxHealth && !disabled()) {
			var heal = Math.min(inhpHealRate * dt, inhpMaxHealth - health);
			health += heal;
			resources -= heal;
		}

		if (targetEnemy == null && !hungry()) {
			var potentialTarget = null;
			for (e in world.entities) {
				if (e == this || !Std.is(e, Tank)) continue;
				var other:Tank = cast e;

				var distance = other.position.clone().sub(position);
				
				if (distance.length() <= inhpSight) {

					if (isEnemy(other)) {
						if (targetEnemy == null) {
							if (potentialTarget == null) potentialTarget = other;
							else {
								var oDistance = other.position.clone().sub(position).length();
								var pDistance = potentialTarget.position.clone().sub(position).length();
								if (oDistance < pDistance) potentialTarget = other;
							}
						}
					}

				}

			}
			if (potentialTarget != null) {
				targetEnemy = potentialTarget;
				movingToEnemy = true;
				// trace(idStr() + " targeting " + targetEnemy.idStr());
			}
		}

		if (!veryHungry() && powerLoaded < inhpPowerToLoad) {
			var toLoad = dt * inhpPowerLoadRate;
			powerLoaded += toLoad;
			resources -= toLoad;
		} 

		if (targetEnemy != null && !targetEnemy.alive()) {
			// trace(idStr() + "'s target " + targetEnemy.idStr() + " is no longer alive");
			targetEnemy = null;
		}

		if (veryHungry()) targetEnemy = null;

		if (targetEnemy != null) {
			
			changeDirIn = 0;

			var distance = targetEnemy.position.clone().sub(position);
			var dl = distance.length();
			if (dl > inhpSight) {
				// trace(idStr() + " lost " + targetEnemy.idStr());
				targetEnemy = null;
			} else {

				// move in range of enemy
				if (dl > inhpGunRange) {
					movingToEnemy = true;
				}
				if (movingToEnemy && dl <= inhpTargetGunRange) {
					timeToChangeFlankMode = 0;
					movingToEnemy = false;
				}

				timeToChangeFlankMode -= dt;
				if (timeToChangeFlankMode <= 0) {
					flankMode = Maths.randomInt(3);
					timeToChangeFlankMode = Maths.randomBetween(inhpFlankChangeTimeMin,inhpFlankChangeTimeMax);
				}

				if (dl < 4) {
					// keep a minimum distance
					velocity.copy(distance.clone().normalize().multiplyScalar(-inhpToEnemySpeed));
				} else if (movingToEnemy) {
					velocity.copy(distance.clone().normalize().multiplyScalar(inhpToEnemySpeed));
				} else {
					if (flankMode == 0) {
						velocity.set(0, 0);
					} else {
						var eAngle = angle(distance);
						var flankAngle = eAngle + (Maths.HALFPI * (flankMode == 1 ? -1 : 1));
						velocity.set(Math.cos(flankAngle) * inhpFlankSpeed, Math.sin(flankAngle) * inhpFlankSpeed);
					}
				}

				// fire if in range and loaded
				if (dl < inhpGunRange && powerLoaded >= inhpPowerToLoad) {
					// trace(idStr() + " shoots " + targetEnemy.idStr() + " for " + powerLoaded + " damage");
					var dmg = powerLoaded * Maths.randomBetween(0, 1);
					targetEnemy.damage(dmg, "shot by " + idStr());
					powerLoaded = 0;
					dispatchEvent(EV_FIRE, [targetEnemy, powerLoaded, dmg]);
				}

			}
		}
		if (targetEnemy == null) {
			if (!disabled()) {

				if (relResources() < 0.9) {
					var potentialRes = targetResource;
					for (e in world.entities) {
						if (e == this || !Std.is(e, Resource)) continue;
						var res:Resource = cast e;
						var distance = res.position.clone().sub(position);
						if (distance.length() <= inhpSight) {
							if (potentialRes == null)
								potentialRes = res;
							else {
								var potDistance = potentialRes.position.clone().sub(position);
								if (potDistance.length() > distance.length()) potentialRes = res;
							}
						}
					}
					if (potentialRes != null) targetResource = potentialRes;
				}
				if (relResources() >= 1) targetResource = null;

				if (targetResource != null && targetResource.value <= 0)
					targetResource = null;

				if (targetResource == null) {

					changeDirIn -= dt;
					if (changeDirIn <= 0) {
						var dir = angle(velocity);
						if (Math.random() < 0.03) dir += Math.PI;
						dir += Maths.randomBetween(-inhpChangeDirAmount, inhpChangeDirAmount);
						velocity.set(Math.cos(dir) * inhpIdleSpeed, Math.sin(dir) * inhpIdleSpeed);
						changeDirIn = inhpChangeDirAfter * Maths.randomBetween(0.5,1.5);
					}

					var maxDev = (world.size/2) - 10;
					if (Math.abs(position.x) > maxDev) {
						velocity.x = -Math.abs(velocity.x) * Maths.signum(position.x);
					}
					if (Math.abs(position.y) > maxDev) {
						velocity.y = -Math.abs(velocity.y) * Maths.signum(position.y);
					}

				} else {
					var distance = targetResource.position.clone().sub(position);
					if (distance.length() > inhpEatDistance) {
						velocity.copy(distance.clone().normalize().multiplyScalar(hungry() ? inhpToEnemySpeed : inhpIdleSpeed));
					} else {
						velocity.set(0,0);
						resources += targetResource.take(dt * inhpEatRate);
					}
				}

			}
		}

		var babyRes = inhpMaxResources * inhpBabyPart;
		if (plenty() && baby < babyRes) {
			var grow = Math.min(babyRes - baby, dt * inhpBabyGrowRate);
			resources -= grow;
			baby += grow;
			if (baby >= babyRes) {
				var nt = new Tank(world, position.clone());//, Math.random() < 0.1 ? Maths.randomInt(4) : family);

				trace(idStr() + " gave birth to " + nt.idStr());// + (nt.family != family ? " (into a different family!)" : ""));
				for (f in Reflect.fields(this)) {
					if (f.indexOf("inhp") != 0) continue;
					Reflect.setField(nt, f, Reflect.field(this, f) * Maths.randomBetween(0.5, 2));
					trace("- " + f + ": " + Reflect.field(nt, f));
				}
				// apply a few limits
				// - some natural
				nt.inhpBabyPart = Math.min(nt.inhpBabyPart, 1);
				nt.inhpBabyHealthPart = Math.min(nt.inhpBabyHealthPart, 1);
				// - some artificial (find a natural solution later)
				nt.inhpEatDistance = Math.min(nt.inhpEatDistance, 20);

				// some manual inheritance
				nt.family = (family + Maths.randomBetween(-0.2,0.2)) % 1;

				nt.resources = babyRes;
				baby -= babyRes;

				// spend a part of the baby's resources for its health (but don't make it spawn disabled)
				nt.health = Math.min(inhpBabyHealthPart * nt.inhpMaxHealth, nt.resources * 0.85);
				nt.resources -= nt.health;
			}
		}

		if (disabled()) velocity.set(0, 0);
		resources -= velocity.length() * inhpFuelRate;

		position.add(velocity.clone().multiplyScalar(dt));

	}

	public function isEnemy(t:Tank) {
		var fDist = Math.min(Math.abs(t.family - family), Math.abs((t.family + 1) - family));
		return fDist > 0.25;
	}

	public function alive() {
		return world.entities.indexOf(this) != -1;
	}

	public function disabled() {
		return relResources() <= 0.1;
	}

	public function veryHungry() {
		return relResources() <= 0.25;	
	}

	public function hungry() {
		return relResources() <= 0.33;	
	}

	public function plenty() {
		return relResources() >= 0.75;		
	}

	public function relResources() {
		return resources / inhpMaxResources;
	}

	public function mass() {
		return resources + powerLoaded + baby + health;
	}

	public function damage(damage:Float, src:String = "source n/a") {
		health -= damage;
		// trace(idStr() + " HP at " + health);
		if (health <= 0) {
			trace(idStr() + " has died (" + src + ")");
			world.entities.remove(this);
			new Resource(world, position, mass() * 0.3333);
		}
	}

	private function angle(vec:Vector2):Float {
		return Math.atan2(vec.y, vec.x);
	}

}