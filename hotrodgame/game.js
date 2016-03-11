"use strict";

global.loadClass = function(f) {
	runScript(global.gameBase + "/" + f.replace(/\./g, "/") + ".js");
}

for (let c of [
	"tmp.Resource",
	"tmp.Tank",
	"tmp.Vector2",
	"tmp.World",
	"hotrod.test.phys.BoxCreator"
]) loadClass(c);

global.randomBetween = function(min, max) {
	return Math.random() * (max-min) + min;
};
global.randomInt = function(r) {
	return Math.floor(Math.random()*r);
};
global.signum = function(x) {
	if (x == 0) return 0;
	return x > 0 ? 1 : -1;
};

global.runFrame = function() {

	let dt = 1/20;
	
	global.step++;
	if (global.step % 1000 == 0) log("STEP", global.step);

	global.tw.step(dt);
/*
	global.world.stepSimulation(dt);
	for (let e of global.entities) e.step(dt);

	prepareBoxRender();
	for (let b of global.boxes) {
		renderBox(b);
	}
*/
	function hslToRgb(h, s, l){
	    var r, g, b;

	    if(s == 0){
	        r = g = b = l; // achromatic
	    }else{
	        var hue2rgb = function hue2rgb(p, q, t){
	            if(t < 0) t += 1;
	            if(t > 1) t -= 1;
	            if(t < 1/6) return p + (q - p) * 6 * t;
	            if(t < 1/2) return q;
	            if(t < 2/3) return p + (q - p) * (2/3 - t) * 6;
	            return p;
	        }

	        var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
	        var p = 2 * l - q;
	        r = hue2rgb(p, q, h + 1/3);
	        g = hue2rgb(p, q, h);
	        b = hue2rgb(p, q, h - 1/3);
	    }

	    return [r,g,b];
	}

	prepareBoxRender();
	for (let e of global.tw.entities) {
		if (e instanceof tmp.Tank) {
			if (e.disabled()) {
				if (Math.floor(global.step / 30) % 2 == 1) continue;
			}
			//e.family;
			//log(e.resources);
			let s = (e.relResources() * 0.7 + 0.3);
			if (isNaN(s)) s = 0.3;
			var rgb = hslToRgb(e.family, s, 0.4);
			var scale = Math.pow(e.inhpMaxResources / 500, 1/3)
			renderBox(e.btBody, rgb[0], rgb[1], rgb[2]);
		}
	}

	return nativeStep();
};

global.run = function() {
/*
	log("Hi World, " + typeof(hotrod.test.phys.BoxCreator));

	log("btCreateWorld");
	global.world = new BulletWorld();
	global.world.createStaticBox(
		150, 150, 2,
		0, 0, -1
	);

	log("entities & boxes");
	global.entities = [];
	global.boxes = [];


	log("new BoxCreator");
	var bc = new hotrod.test.phys.BoxCreator(12, world, global.boxes);
	log(typeof(bc));
	log(typeof(bc.step));
	log(bc.constructor.name);
	entities.push(bc);


*/
	
	global.tw = new tmp.World(300, 0.001);

	log("Entering loop");
	global.step = 0;
	while (true) {
		if (!global.runFrame()) break;
	}
	log("Leaving loop");

}
