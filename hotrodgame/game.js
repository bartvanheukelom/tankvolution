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
global.hslToRgb = function(h, s, l){
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
};



global.basicProg = 0;
global.initGraphicsInner = function() {

	// { GL_VERTEX_SHADER, "../res/primitive_restart.vs.glsl" },
	// { GL_FRAGMENT_SHADER, "../res/primitive_restart.fs.glsl" },
	// { GL_NONE, NULL }

	let c = new Int32Array(1);
	global.basicProg = glCreateProgram();
	for (let f of ["vs", "fs"]) {
		let s = glCreateShader({
			"vs": GL_VERTEX_SHADER,
			"fs": GL_FRAGMENT_SHADER
		}[f]);
		let src = getFileContents("../res/primitive_restart." + f + ".glsl");
		c[0] = src.byteLength;
		glShaderSource(s, 1, src, c.buffer);
		glCompileShader(s);
		glGetShaderiv( s, GL_COMPILE_STATUS, c.buffer);
		if (!c[0]) {
			throw new Error("Shader compile error " + c[0]);
		}
		glAttachShader(basicProg, s);
	}
	glLinkProgram(basicProg);
	glGetProgramiv(basicProg, GL_LINK_STATUS, c.buffer);
	if (!c[0]) {
		throw new Error("Link error");
	}

	let xxx;
	xxx = glGetUniformLocation(basicProg, stringToUtf8("mvp"));
	global.basicProg_mvp = xxx;
	xxx = glGetUniformLocation(basicProg, stringToUtf8("inColor"));
	global.basicProg_inColor = xxx;
	log("LOC", basicProg_mvp, basicProg_inColor);
	if (basicProg_mvp == -1) {
		throw new Error("Random basicProg_mvp fail");
	}

	let v = new Uint32Array(1);
	glGenVertexArrays(1, v.buffer);
    glBindVertexArray(v[0]);
	global.cubeVAO = v;

	let cubeVerts = [
        -1.0,-1.0,-1.0, // triangle 1 : begin
        -1.0,-1.0, 1.0,
        -1.0, 1.0, 1.0, // triangle 1 : end
        1.0, 1.0,-1.0, // triangle 2 : begin
        -1.0,-1.0,-1.0,
        -1.0, 1.0,-1.0, // triangle 2 : end
        1.0,-1.0, 1.0,
        -1.0,-1.0,-1.0,
        1.0,-1.0,-1.0,
        1.0, 1.0,-1.0,
        1.0,-1.0,-1.0,
        -1.0,-1.0,-1.0,
        -1.0,-1.0,-1.0,
        -1.0, 1.0, 1.0,
        -1.0, 1.0,-1.0,
        1.0,-1.0, 1.0,
        -1.0,-1.0, 1.0,
        -1.0,-1.0,-1.0,
        -1.0, 1.0, 1.0,
        -1.0,-1.0, 1.0,
        1.0,-1.0, 1.0,
        1.0, 1.0, 1.0,
        1.0,-1.0,-1.0,
        1.0, 1.0,-1.0,
        1.0,-1.0,-1.0,
        1.0, 1.0, 1.0,
        1.0,-1.0, 1.0,
        1.0, 1.0, 1.0,
        1.0, 1.0,-1.0,
        -1.0, 1.0,-1.0,
        1.0, 1.0, 1.0,
        -1.0, 1.0,-1.0,
        -1.0, 1.0, 1.0,
        1.0, 1.0, 1.0,
        -1.0, 1.0, 1.0,
        1.0,-1.0, 1.0
    ];
	cubeVerts = cubeVerts.map(f => f/2);

	let g_vertex_buffer_data = Float32Array.from(cubeVerts);

	v = new Uint32Array(1);
	glGenBuffers(1, v.buffer);
	glBindBuffer(GL_ARRAY_BUFFER, v[0]);
	glBufferData(GL_ARRAY_BUFFER, g_vertex_buffer_data.byteLength, g_vertex_buffer_data.buffer, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(0);

    glClearColor(0.0, 0.0, 0.0, 1.0);

}


global.runFrame = function() {

	let dt = 1/20;

	global.step++;
	if (global.step % 1000 == 0) log("STEP", global.step);

	global.tw.step(dt);

	glEnable(GL_CULL_FACE);
	glEnable(GL_DEPTH_TEST);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glUseProgram(basicProg);

	updateCam();

	function renderBox(body, rgb) {
		glBindVertexArray(cubeVAO[0]);
		setMvp(basicProg_mvp, body);
		glUniform3f(basicProg_inColor, rgb[0], rgb[1], rgb[2]);
		glDrawArrays(GL_TRIANGLES, 0, 3*12);
	}

	for (let e of global.tw.entities) {
		if (e instanceof tmp.Tank) {
			if (e.disabled()) {
				if (Math.floor(global.step / 30) % 2 == 1) continue;
			}
			let s = (e.relResources() * 0.7 + 0.3);
			let l = 0.2 + 0.4 * (e.health / e.inhpMaxHealth);
			if (isNaN(s)) s = 0.3;
			let rgb = hslToRgb(e.family, s, l);
			// let scale = Math.pow(e.inhpMaxResources / 500, 1/3)
			renderBox(e.btBody, rgb);
		}
		else if (e instanceof tmp.Resource) {
			let rgb = hslToRgb(0.2, 1, Math.min(1, e.value / 200));
			renderBox(e.btBody, rgb);
		}
	}

	return nativeStep();
};

global.run = function() {

	initGraphicsInner();

	global.tw = new tmp.World(300, 0.001);

	log("Entering loop");
	global.step = 0;
	while (true) {
		if (!global.runFrame()) break;
	}
	log("Leaving loop");

}
