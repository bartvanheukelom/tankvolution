

defClass(
	"tmp", "Resource",


	function(w, pos, value) {
		this.world = w;
		this.position = pos;
		this.value = value;

		this.world.entities.push(this);

		let radius = 0.5;
		this.btBody = this.world.btWorld.createBox(
			radius*2,
			this.position.x, this.position.y, radius/2
		);

	}, {

		preStep: function() {
			this.btBody.getPosition(this.position);
		},

		step: function (dt) {
			this.take(dt * 2);
		},

		take: function (amount) {
			var res = Math.min(amount, this.value);
			this.value -= res;
			if (this.value == 0) {
				this.world.entities.splice(this.world.entities.indexOf(this), 1);
				// TODO remove body
			}
			return res;
		}
	}
);
