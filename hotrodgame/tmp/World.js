
defClass(
	"tmp", "World",
	function(size, density) {

		this.entities = [];
		this.tanks = [];
		this.resourceDumpTime = [0,0,0,0];
		this.dayLength = 300;
		this.size = size;
		this.time = this.dayLength / 2;
		
		this.btWorld = new BulletWorld();
		
		
		// floor
		let hsize = size/2;
		this.btWorld.createStaticBox(
			size, size, 1,
			0, 0, -0.5
		);
		// walls
		this.btWorld.createStaticBox(
			1, size, 20,
			hsize+0.5, 0, 0
		);
		this.btWorld.createStaticBox(
			1, size, 20,
			-(hsize+0.5), 0, 0
		);
		this.btWorld.createStaticBox(
			size, 1, 20,
			0, hsize+0.5, 0
		);
		this.btWorld.createStaticBox(
			size, 1, 20,
			0, -(hsize+0.5), 0
		);

		this.startTanks = Math.floor(size*size * density);
		for (let t = 0; t < this.startTanks; t++) {
			this.createTank();
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
		
		createTank: function() {
			// log(this.randomPos);
			var pos = this.randomPos();
            // log(pos.toString());
			// var fam = (pos.x > 0 ? 1 : 0) + (pos.y > 0 ? 2 : 0);
			var tank = new tmp.Tank(this, pos);
			tank.family = Math.random();
			tank.health = tank.inhpMaxHealth * randomBetween(0.5, 1);
			tank.resources = tank.inhpMaxResources * randomBetween(0.5, 1);
			tank.baby = tank.inhpBabyPart * tank.inhpMaxResources * randomBetween(0, 0.8);
		},

		step: function(dt) {

			if (dt == 0) return;

			this.btWorld.stepSimulation(dt);
			this.time += dt;
			
			if (this.tanks.length < this.startTanks / 4)
				this.createTank();

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
