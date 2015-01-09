package tankvolution.view;

import tankvolution.model.Resource;
import tankvolution.model.World;
import threejs.extras.geometries.SphereGeometry;
import threejs.lights.PointLight;
import threejs.materials.MeshBasicMaterial;
import threejs.materials.MeshPhongMaterial;
import threejs.math.Vector2;
import threejs.objects.Mesh;

class ResourceView {
	
	private var main:Main;
	private var res:Resource;

	private var v:Mesh;
	private var light:PointLight;
	
	public function new(main:Main, res:Resource) {

		this.main = main;
		this.res = res;

		v = new Mesh(new SphereGeometry(1, 30, 30), new MeshPhongMaterial({color: 0xFFFF00}));
		v.castShadow = true;
		v.frustumCulled = true;
		main.scene.add(v);

		// light = new PointLight(0xFFFFFF, 1, 1);
		// main.scene.add(light);

	}

	public function update() {
		
		if (res.value == 0) {
			
			v.parent.remove(v);
			v.geometry.dispose();
			v.material.dispose();

			// light.parent.remove(light);

			main.entityViews.remove(res);
			return;
		}
		
		v.position.x = res.position.x;
		v.position.y = res.position.y;
		v.position.z = main.terrainHeight(v.position.x, v.position.y);

		// light.position.x = res.position.x;
		// light.position.y = res.position.y;
		// light.position.z = 5;

		var vol = res.value * 0.02;
		var scale = Math.pow(vol / (0.75*Math.PI), 1/3);
		v.scale.set(scale, scale, scale);

		// light.distance = scale * 30;

	}

}