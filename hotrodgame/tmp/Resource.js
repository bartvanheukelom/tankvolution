

defClass(
	"tmp", "Resource",


	function(w, pos, value) {
		this.world = w;
		this.position = pos;
		this.value = value;

		this.world.entities.push(this);
	}, {
		step: function (dt) {
			this.take(dt * 2);
		},

		take: function (amount) {
			var res = Math.min(amount, this.value);
			this.value -= res;
			if (this.value == 0) {
				this.world.entities.splice(this.world.entities.indexOf(this), 1);
			}
			return res;
		}
	}
);
