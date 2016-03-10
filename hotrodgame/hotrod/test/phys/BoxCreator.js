
defClass(
	"hotrod.test.phys", "BoxCreator",
	function(x, world, boxes) {
		log("BoxCreator " + x);
		this.world = world;
		this.steps = 0;
		this.time = 0;
		this.boxes = boxes;
	}, {
		step: function(dt) {
			this.steps++;
			this.time++;
			if (this.steps % 1 == 0) {
				let x = this.time * 0.1;
				let r = x*4;
				let d = 45 + Math.cos(r*8)*3;
				this.boxes.push(this.world.createBox(
					//10+(Math.cos(r)*d),
					//Math.sin(r)*d,
					0, 0,
					400
					//70 + Math.sin(r*0.2378432)*5
				));
			}
		}
	}
);
