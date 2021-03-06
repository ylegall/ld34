import effects.GlitchEffect;
import luxe.Input;
import luxe.States;
import luxe.Parcel;
import luxe.ParcelProgress;

import effects.*;

class Main extends luxe.Game {
	private static var fsm:States;
	var effects:Effects = new Effects();
    var bloomEffect :BloomEffect;
	var shockwaveEffect :ShockwaveEffect;
	var sepiaEffect :SepiaEffect;
	var effectsEnabled :Bool = false;

    override function config(config:luxe.AppConfig) {
        config.preload.jsons.push({ id: 'assets/parcel.json' });
        return config;
    }

	override function ready() {
		var parcel = new Parcel();
		parcel.from_json(Luxe.resources.json('assets/parcel.json').asset.json);
		new ParcelProgress({
			parcel: parcel,
			oncomplete: assetsLoaded
		});
		parcel.load();
	}

	function assetsLoaded(_) {
		Luxe.renderer.clear_color = new luxe.Color(0.5, 0.6, 1.0, 1);

		if (Luxe.audio.exists('background')) {
			Luxe.audio.get('background').volume = 0.4;
			Luxe.audio.get('background').loop();
		}

		// set up the VFX
		effects.onload();

        bloomEffect = new BloomEffect();
        effects.addEffect(bloomEffect);

        shockwaveEffect = new ShockwaveEffect();
        effects.addEffect(shockwaveEffect);

		sepiaEffect = new SepiaEffect();
		effects.addEffect(sepiaEffect);
		effects.addEffect(new VignetteEffect());

		var intro_screens = [
			Luxe.resources.texture('assets/backgrounds/title.png'),
			Luxe.resources.texture('assets/backgrounds/instructions.png'),
			Luxe.resources.texture('assets/backgrounds/spring_intro.png'),
			Luxe.resources.texture('assets/backgrounds/summer_intro.png'),
			Luxe.resources.texture('assets/backgrounds/fall_intro.png'),
			Luxe.resources.texture('assets/backgrounds/winter_intro.png'),
			Luxe.resources.texture('assets/backgrounds/spring_intro2.png'),
			Luxe.resources.texture('assets/backgrounds/spring_intro3.png'),
			Luxe.resources.texture('assets/backgrounds/spring_intro4.png')
		];

		Luxe.events.listen('start_intro', function(index :Int) {
			if (index - 1 >= intro_screens.length) return;
			if (index > 1) Luxe.audio.play('ping');
			fsm.enable('Intro', intro_screens[index - 1]);
			effectsEnabled = false;
		});

		Luxe.events.listen('end_intro', function(_) {
			if (fsm.enabled('Intro')) {
				fsm.disable('Intro');
			}
			effectsEnabled = true;
		});

		Luxe.events.listen('got_drop', function(drop :entities.Drop) {
			switch (drop.dropType) {
				case Rain:
					shockwaveEffect.elapsed_effect_time = 0.0;
			        shockwaveEffect.effect_time = 3.0;
			        shockwaveEffect.mouse_pos = Luxe.camera.world_point_to_screen(drop.pos);
					Luxe.audio.play('rain');
					Luxe.camera.shake(3);
					Luxe.events.fire('got_rain');
				case Sun:
					bloomEffect.radius = 3.5;
					Luxe.camera.shake(3);
					Luxe.audio.play('sun');
					Luxe.events.fire('got_sun');
				case Time:
					sepiaEffect.amount = 0.8;
					Luxe.timescale = 0.3;
					luxe.tween.Actuate.tween(Luxe, 3, { timescale: 1 }); //.ease(luxe.tween.easing.Expo.easeInOut);
					Luxe.camera.shake(3);
					Luxe.audio.play('time');
					Luxe.events.fire('got_time');
				case Poison:
					Luxe.audio.play('poison');
					Luxe.camera.shake(10);
					Luxe.events.fire('got_poison');
			}
		});

		// set up the state machine
		fsm = new States();
		fsm.add(new states.Play());
		fsm.add(new states.Intro());
		fsm.set('Play');
	}

	// override function onkeyup( e:KeyEvent ) {
	// 	if(e.keycode == Key.escape) {
	// 		Luxe.shutdown();
	// 	}
	// }

    override function onmousedown(e :MouseEvent) {

    }

	override function update(dt :Float) {
		if (!effectsEnabled) return;
		if (bloomEffect != null && bloomEffect.radius > 2) bloomEffect.radius -= dt;
		if (sepiaEffect != null && sepiaEffect.amount > 0) sepiaEffect.amount -= dt * 0.15;
		effects.update(dt);
	}

	override function onprerender() {
		if (effectsEnabled) effects.onprerender();
	}

	override function onpostrender() {
		if (effectsEnabled) effects.onpostrender();
	}
}
