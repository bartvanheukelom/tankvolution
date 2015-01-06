package tankvolution.view;

import tankvolution.model.Resource;
import tankvolution.model.World;
import threejs.extras.geometries.SphereGeometry;
import threejs.materials.MeshBasicMaterial;
import threejs.materials.MeshPhongMaterial;
import threejs.math.Vector2;
import threejs.objects.Mesh;

class ResourceView {
	
	private var main:Main;
	private var res:Resource;

	private var v:Mesh;
	
	public function new(main:Main, res:Resource) {

		this.main = main;
		this.res = res;

		v = new Mesh(new SphereGeometry(1, 30, 30), new MeshPhongMaterial({ambient: 0xFFFF00}));
		v.castShadow = true;
		v.frustumCulled = true;
		main.scene.add(v);

	}

	public function update() {
		
		if (res.value == 0) {
			v.parent.remove(v);
			v.geometry.dispose();
			v.material.dispose();
			main.entityViews.remove(res);
			return;
		}
		
		v.position.x = res.position.x;
		v.position.y = res.position.y;

		var vol = res.value * 0.02;
		var scale = Math.pow(vol / (0.75*Math.PI), 1/3);
		v.scale.set(scale, scale, scale);

	}

}