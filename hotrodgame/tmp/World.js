
defClass(
	"tmp", "World",
	function(size, density) {

		this.entities = [];
		this.resourceDumpTime = [0,0,0,0];
		this.dayLength = 300;
		this.size = size;
		this.time = this.dayLength / 2;

		for (let t = 0; t < Math.floor(size*size * density); t++) {
            // log(this.randomPos);
			var pos = this.randomPos();
            // log(pos.toString());
			// var fam = (pos.x > 0 ? 1 : 0) + (pos.y > 0 ? 2 : 0);
			var tank = new tmp.Tank(this, pos);
			tank.family = Math.random();
			tank.health = tank.inhpMaxHealth * randomBetween(0.5, 1);
			tank.resources = tank.inhpMaxResources * randomBetween(0.5, 1);
			tank.baby = tank.inhpBabyPart * tank.inhpMaxResources * randomBetween(0, 0.8);
		}

		// for (fam in 0...FAMILIES) {
			// for (t in 0...MEMBERS) {
				// var tank = new Tank(this, randomPos(), fam);
				// tank.health = tank.inhpMaxHealth * randomBetween(0.5, 1);
				// tank.resources = tank.inhpMaxResources * randomBetween(0.5, 1);
				// tank.baby = tank.inhpBabyPart * tank.inhpMaxResources * randomBetween(0, 0.8);
			// }
		// }

	}, {

		step: function(dt) {

			if (dt == 0) return;

			this.time += dt;

			for (let i = 0; i < this.resourceDumpTime.length; i++) {
				this.resourceDumpTime[i] += dt;
			}

			if (this.resourceDumpTime[0] > 0.2) {
				new tmp.Resource(this, new tmp.Vector2(
					randomBetween(-this.size/2, 0),
					randomBetween(-this.size/2, 0)
				), 25);
				this.resourceDumpTime[0] = 0;
			}
			if (this.resourceDumpTime[1] > 1) {
				new tmp.Resource(this, new tmp.Vector2(
					randomBetween(0, this.size/2),
					randomBetween(-this.size/2, 0)
				), 125);
				this.resourceDumpTime[1] = 0;
			}
			if (this.resourceDumpTime[2] > 0.4) {
				new tmp.Resource(this, new tmp.Vector2(
					randomBetween(0, this.size/2),
					randomBetween(0, this.size/2)
				), 50);
				this.resourceDumpTime[2] = 0;
			}
			if (this.resourceDumpTime[2] > 0.2) {
				new tmp.Resource(this, new tmp.Vector2(
					randomBetween(-this.size/2, 0),
					randomBetween(0, this.size/2)
				), 10);
				this.resourceDumpTime[2] = 0;
			}

			for (let e of this.entities) {
				e.step(dt);
			}

		},

		randomPos: function() {
			return new tmp.Vector2(
				randomBetween(-this.size/2, this.size/2),
				randomBetween(-this.size/2, this.size/2)
			);
		},

		dayProgress: function() {
			return (this.time / this.dayLength) % 1;
		}
	}
);
