
defClass(
	"tmp", "Tank",

	function(w, pos, parent) {

		// ==== inheritable properties ==== //
		// - sight
		// - firing range
		// - rate of fire
		// - speed / mass / thrust

		this.inhpSight = 40;
		this.inhpGunRange = 25;
		this.inhpTargetGunRange = 20;

		this.inhpPowerToLoad = 10;
		this.inhpPowerLoadRate = 5.0;

		this.inhpMaxHealth = 50.0;
		this.inhpHealRate = 2.0;
		this.inhpDecayRate = 0.5;

		this.inhpToEnemySpeed = 8;
		this.inhpFlankSpeed = 5;
		this.inhpIdleSpeed = 3;

		this.inhpChangeDirAfter = 2.0;
		this.inhpChangeDirAmount = Math.PI/8;

		this.inhpMaxResources = 500;

		this.inhpFlankChangeTimeMin = 3.0;
		this.inhpFlankChangeTimeMax = 5.0;

		this.inhpEatRate = 10.0;
		this.inhpEatDistance = 6.0;

		this.inhpFuelRate = 0.02;

		this.inhpBabyGrowRate = 2;
		this.inhpBabyPart = 0.5;
		this.inhpBabyHealthPart = 0.5;

		this.family = 0;

		// === end inh. props ==== //

		this.velocity = new tmp.Vector2();

		if ("tank_idSeq" in global == false) {
			global.tank_idSeq = 0;
		}
		this.id = global.tank_idSeq++;

		// --- state

		this.targetEnemy = null;
		this.targetResource = null;

		this.powerLoaded = 0.0;
		this.health = 0;
		this.resources = 0;
		this.baby = 0;

		this.changeDirIn = 0;
		this.movingToEnemy = false;
		this.flankMode = 0;
		this.timeToChangeFlankMode = 0;

		this.position = pos;
		// log("Tank construct", this.position, this.position.x, this.position.y);
		this.world = w;

		this.world.entities.push(this);
		this.world.tanks.push(this);

		let radius = 1;
		this.btBody = this.world.btWorld.createSphere(
			radius,
			this.position.x, this.position.y, radius/2
		);

		log(this.idStr(), "was born from", parent);

	}, {

		idStr: function() {
			return "Tank#" + this.id;// + "[" + family + "]";
		},

		preStep: function() {
			this.btBody.getPosition(this.position);
		},

		step: function(dt) {

			this.velocity.set(0,0);

			this.damage(dt * this.inhpDecayRate, "decay");

			if (!this.alive()) return;

			if (this.health < this.inhpMaxHealth && !this.disabled()) {
				var heal = Math.min(this.inhpHealRate * dt, this.inhpMaxHealth - this.health);
				this.health += heal;
				this.addResources(-heal, "heal");
			}

			if (this.targetEnemy == null && !this.hungry()) {
				var potentialTarget = null;
				for (let e of this.world.entities) {
					if (e == this || !(e instanceof tmp.Tank)) continue;
					var other = e;

					var distance = other.position.clone().sub(this.position);

					if (distance.length() <= this.inhpSight) {

						if (this.isEnemy(other)) {
							if (this.targetEnemy == null) {
								if (potentialTarget == null) potentialTarget = other;
								else {
									var oDistance = other.position.clone().sub(this.position).length();
									var pDistance = potentialTarget.position.clone().sub(this.position).length();
									if (oDistance < pDistance) potentialTarget = other;
								}
							}
						}

					}

				}
				if (potentialTarget != null) {
					this.targetEnemy = potentialTarget;
					this.movingToEnemy = true;
					// trace(idStr() + " targeting " + targetEnemy.idStr());
				}
			}

			if (!this.veryHungry() && this.powerLoaded < this.inhpPowerToLoad) {
				var toLoad = dt * this.inhpPowerLoadRate;
				this.powerLoaded += toLoad;
				this.addResources(-toLoad, "reload");
			}

			if (this.targetEnemy != null && !this.targetEnemy.alive()) {
				// trace(idStr() + "'s target " + targetEnemy.idStr() + " is no longer alive");
				this.targetEnemy = null;
			}

			if (this.veryHungry()) this.targetEnemy = null;

			if (this.targetEnemy != null) {

				this.changeDirIn = 0;

				var distance = this.targetEnemy.position.clone().sub(this.position);
				var dl = distance.length();
				if (dl > this.inhpSight) {
					// trace(idStr() + " lost " + targetEnemy.idStr());
					this.targetEnemy = null;
				} else {

					// move in range of enemy
					if (dl > this.inhpGunRange) {
						this.movingToEnemy = true;
					}
					if (this.movingToEnemy && dl <= this.inhpTargetGunRange) {
						this.timeToChangeFlankMode = 0;
						this.movingToEnemy = false;
					}

					this.timeToChangeFlankMode -= dt;
					if (this.timeToChangeFlankMode <= 0) {
						this.flankMode = randomInt(3);
						this.timeToChangeFlankMode = randomBetween(this.inhpFlankChangeTimeMin,this.inhpFlankChangeTimeMax);
					}

					if (dl < 4) {
						// keep a minimum distance
						this.velocity.copy(distance.clone().normalize().multiplyScalar(-this.inhpToEnemySpeed));
					} else if (this.movingToEnemy) {
						this.velocity.copy(distance.clone().normalize().multiplyScalar(this.inhpToEnemySpeed));
					} else {
						if (this.flankMode == 0) {
							this.velocity.set(0, 0);
						} else {
							var eAngle = this.angle(distance);
							var flankAngle = eAngle + ((Math.PI/2) * (this.flankMode == 1 ? -1 : 1));
							this.velocity.set(Math.cos(flankAngle) * this.inhpFlankSpeed, Math.sin(flankAngle) * this.inhpFlankSpeed);
						}
					}

					// fire if in range and loaded
					if (dl < this.inhpGunRange && this.powerLoaded >= this.inhpPowerToLoad) {
						// trace(idStr() + " shoots " + targetEnemy.idStr() + " for " + powerLoaded + " damage");
						var dmg = this.powerLoaded * randomBetween(0, 1);
						this.targetEnemy.damage(dmg, "shot by " + this.idStr());
						this.powerLoaded = 0;
						//dispatchEvent("fire", [targetEnemy, powerLoaded, dmg]);
					}

				}
			}
			if (this.targetEnemy == null) {
				if (!this.disabled()) {

					if (this.relResources() < 0.9) {
						var potentialRes = this.targetResource;
						for (let e of this.world.entities) {
							if (e == this || !(e instanceof tmp.Resource)) continue;
							var res = e;
							var distance = res.position.clone().sub(this.position);
							if (distance.length() <= this.inhpSight) {
								if (potentialRes == null)
									potentialRes = res;
								else {
									var potDistance = potentialRes.position.clone().sub(this.position);
									if (potDistance.length() > distance.length()) potentialRes = res;
								}
							}
						}
						if (potentialRes != null) this.targetResource = potentialRes;
					}
					if (this.relResources() >= 1) this.targetResource = null;

					if (this.targetResource != null && this.targetResource.value <= 0)
						this.targetResource = null;

					if (this.targetResource == null) {

						this.changeDirIn -= dt;
						if (this.changeDirIn <= 0) {
							var dir = this.angle(this.velocity);
							if (Math.random() < 0.03) dir += Math.PI;
							dir += randomBetween(-this.inhpChangeDirAmount, this.inhpChangeDirAmount);
							this.velocity.set(Math.cos(dir) * this.inhpIdleSpeed, Math.sin(dir) * this.inhpIdleSpeed);
							this.changeDirIn = this.inhpChangeDirAfter * randomBetween(0.5,1.5);
						}

						var maxDev = (this.world.size/2) - 10;
						if (Math.abs(this.position.x) > maxDev) {
							this.velocity.x = -Math.abs(this.velocity.x) * signum(this.position.x);
						}
						if (Math.abs(this.position.y) > maxDev) {
							this.velocity.y = -Math.abs(this.velocity.y) * signum(this.position.y);
						}

					} else {
						var distance = this.targetResource.position.clone().sub(this.position);
						if (distance.length() > this.inhpEatDistance) {
							this.velocity.copy(distance.clone().normalize().multiplyScalar(this.hungry() ? this.inhpToEnemySpeed : this.inhpIdleSpeed));
						} else {
							this.velocity.set(0,0);
							this.addResources(this.targetResource.take(dt * this.inhpEatRate), "eat");
						}
					}

				}
			}

			var babyRes = this.inhpMaxResources * this.inhpBabyPart;
			if (this.plenty() && this.baby < babyRes) {
				var grow = Math.min(babyRes - this.baby, dt * this.inhpBabyGrowRate);
				this.addResources(-grow, "baby");
				this.baby += grow;
				if (this.baby >= babyRes) {
					var nt = new tmp.Tank(this.world, this.position.clone());//, Math.random() < 0.1 ? randomInt(4) : family);

					log(this.idStr() + " gave birth to " + nt.idStr());// + (nt.family != family ? " (into a different family!)" : ""));
					for (let f in Object.keys(this)) {
						if (f.indexOf("inhp") != 0) continue;
						nt[f] = this[f] * randomBetween(0.5, 2);
						log("- " + f + ": " + nt[f]);
					}
					// apply a few limits
					// - some natural
					nt.inhpBabyPart = Math.min(nt.inhpBabyPart, 1);
					nt.inhpBabyHealthPart = Math.min(nt.inhpBabyHealthPart, 1);
					// - some artificial (find a natural solution later)
					nt.inhpEatDistance = Math.min(nt.inhpEatDistance, 20);

					// some manual inheritance
					nt.family = (this.family + randomBetween(-0.2,0.2)) % 1;

					nt.resources = babyRes;
					this.baby -= babyRes;

					// spend a part of the baby's resources for its health (but don't make it spawn disabled)
					nt.health = Math.min(this.inhpBabyHealthPart * nt.inhpMaxHealth, nt.resources * 0.85);
					nt.resources -= nt.health;
				}
			}

			if (this.disabled()) this.velocity.set(0, 0);
			this.addResources(-this.velocity.length() * this.inhpFuelRate, "move");

			//this.position.add(this.velocity.clone().multiplyScalar(dt));
			let f = 1/200;
			this.btBody.applyImpulse(this.velocity.x*f, this.velocity.y*f, 0);

		},

		isEnemy: function(t) {
			var fDist = Math.min(Math.abs(t.family - this.family), Math.abs((t.family + 1) - this.family));
			return fDist > 0.25;
		},

		alive: function() {
			return this.world.entities.indexOf(this) != -1;
		},

		disabled: function() {
			return this.relResources() <= 0.1;
		},

		veryHungry: function() {
			return this.relResources() <= 0.25;
		},

		hungry: function() {
			return this.relResources() <= 0.33;
		},

		plenty: function() {
			return this.relResources() >= 0.75;
		},

		addResources: function(x, who) {
			let n = this.resources + x;
			if (isNaN(n)) {
				log("addResources", x, "to", this.resources, "of", this.idStr(), "by", who, "would NaN");
				throw new Error();
			}
			this.resources = n;
		},

		relResources: function() {
			let r = this.resources / this.inhpMaxResources;
			if (isNaN(r))
				log(this.idStr(), "relNaN", this.inhpMaxResources, this.resources);
			return r;
		},

		mass: function() {
			return this.resources + this.powerLoaded + this.baby + this.health;
		},

		damage: function(damage, src) {
			this.health -= damage;
			// trace(idStr() + " HP at " + health);
			if (this.health <= 0) {
				log(this.idStr() + " has died (" + src + ")");
				this.world.entities.splice(this.world.entities.indexOf(this), 1);
				this.world.tanks.splice(this.world.tanks.indexOf(this), 1);
				this.btBody.destroy();
				new tmp.Resource(this.world, this.position, this.mass() * 0.3333);
			}
		},

		angle: function(vec) {
			return Math.atan2(vec.y, vec.x);
		}
	}
);
