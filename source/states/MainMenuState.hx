package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import options.OptionsState;
import states.editors.MasterEditorMenu;

enum MainMenuColumn {
	LEFT;
	CENTER;
	RIGHT;
}

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '1.0.4';
	public static var curSelected:Int = 0;
	public static var curColumn:MainMenuColumn = CENTER;
	var allowMouse:Bool = true;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var magenta:FlxSprite;
	var camFollow:FlxObject;

	var optionShit:Array<String> = [
		"StoryMode",
		"Freeplay",
		"Credits",
		"Settings"
	];

	var optionPositions:Array<{x:Float, y:Float}> = [
		{x: 0,    y: 84},   // StoryMode
		{x: 0,    y: 214},  // Freeplay
		{x: 0,    y: 344},  // Credits
		{x: 1059, y: 488}   // Settings
	];

	static inline var INTRO_TWEEN_DUR:Float   = 1.2; // slide duration for each option
	static inline var INTRO_DELAY_STEP:Float  = 0.25; // stagger between each

	var baseX:Array<Float> = [];
	var baseY:Array<Float> = [];
	var introActive:Bool = true;

	var introTweensTotal:Int = 0;
	var introTweensCompleted:Int = 0;

	inline function isSettings(idx:Int):Bool return optionShit[idx] == "Settings";

	static var showOutdatedWarning:Bool = true;

	override function create()
	{
		super.create();

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = persistentDraw = true;

		var youtube:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('MainMenu/Youtube'));
		youtube.antialiasing = ClientPrefs.data.antialiasing;
		youtube.scrollFactor.set(0, 0);

		var fireBG:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('MainMenu/FireBG'));
		fireBG.antialiasing = ClientPrefs.data.antialiasing;
		fireBG.scrollFactor.set(0, 0);
		add(fireBG);

		var ball:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('MainMenu/8Ball'));
		ball.antialiasing = ClientPrefs.data.antialiasing;
		ball.scrollFactor.set(0, 0);
		add(ball);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		var yScroll:Float = 0.25;
		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var optionName = optionShit[i];
			var pos = optionPositions[i];

			baseX.push(pos.x);
			baseY.push(pos.y);

			var item:FlxSprite = new FlxSprite(pos.x, pos.y).loadGraphic(Paths.image('MainMenu/' + optionName));
			item.antialiasing = ClientPrefs.data.antialiasing;
			item.scrollFactor.set();
			item.updateHitbox();

			item.origin.set(0, 0);
			item.offset.set(0, 0);

			item.alpha = 0.6;
			item.scale.set(1, 1);
			item.angle = 0;
			menuItems.add(item);
		}

		introTweensCompleted = 0;
		introTweensTotal = 0;

		for (i in 0...menuItems.length)
		{
			var it = menuItems.members[i];
			if (!isSettings(i))
			{
				introTweensTotal++; // count only the ones that actually tween in

				var targetX = baseX[i];
				var delay = INTRO_DELAY_STEP * i;

				it.x = -500;
				it.y = baseY[i];

				FlxTween.tween(it, { x: targetX }, INTRO_TWEEN_DUR, {
					ease: FlxEase.quadOut,
					startDelay: delay,
					onComplete: function(_)
					{
						introTweensCompleted++;
						if (introTweensCompleted >= introTweensTotal)
						{
							introActive = false;
							applyHighlight(curSelected); // now safe to apply full highlight behavior
						}
					}
				});
			}
			else
			{
				it.x = baseX[i];
				it.y = baseY[i];
			}
		}

		var border:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('MainMenu/Border'));
		border.antialiasing = ClientPrefs.data.antialiasing;
		border.scrollFactor.set(0, 0);
		add(border); // last = on top

		add(youtube);

		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);

		var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);

		#if ACHIEVEMENTS_ALLOWED
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');
		#end

		FlxG.camera.follow(camFollow, null, 0.15);
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);
			if (controls.UI_DOWN_P)
				changeItem(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				selectedSomethin = true;

				if (ClientPrefs.data.flashing)
					FlxFlicker.flicker(magenta, 1.1, 0.15, false);

				var item:FlxSprite = menuItems.members[curSelected];
				var option:String = optionShit[curSelected];

				FlxFlicker.flicker(item, 1, 0.06, false, false, function(_)
				{
					switch (option)
					{
						case "StoryMode":
							MusicBeatState.switchState(new StoryMenuState());
						case "Freeplay":
							MusicBeatState.switchState(new FreeplayState());
						case "Credits":
							MusicBeatState.switchState(new CreditsState());
						case "Settings":
							MusicBeatState.switchState(new OptionsState());
							OptionsState.onPlayState = false;
							if (PlayState.SONG != null)
							{
								PlayState.SONG.arrowSkin = null;
								PlayState.SONG.splashSkin = null;
								PlayState.stageUI = 'normal';
							}
					}
				});
			}
		}

		super.update(elapsed);
	}

	function changeItem(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		if (introActive)
		{
			applyHighlight(curSelected, true);
			return;
		}

		applyHighlight(curSelected, false);
	}

	function applyHighlight(idx:Int, soft:Bool = false)
	{
		for (i in 0...menuItems.length)
		{
			var it = menuItems.members[i];
			if (!soft)
			{
				FlxTween.cancelTweensOf(it);
				FlxTween.cancelTweensOf(it.scale);
				it.scale.set(1, 1);
				it.angle = 0;
				it.origin.set(0, 0);
				it.x = baseX[i];
				it.y = baseY[i];
			}
			it.alpha = (i == idx) ? 1 : 0.6;
		}

		var selectedItem:FlxSprite = menuItems.members[idx];

		if (!soft)
		{
			if (isSettings(idx))
			{
				var cx = baseX[idx] + selectedItem.width * 0.5;
				var cy = baseY[idx] + selectedItem.height * 0.5;
				selectedItem.origin.set(selectedItem.width * 0.5, selectedItem.height * 0.5);
				selectedItem.x = cx - selectedItem.origin.x;
				selectedItem.y = cy - selectedItem.origin.y;
				FlxTween.tween(selectedItem, { angle: 360 }, 0.75, { ease: FlxEase.quadOut });
			}
			else
			{
				var bx = baseX[idx];
				var by = baseY[idx];
				selectedItem.origin.set(0, 0);
				selectedItem.x = bx;
				selectedItem.y = by;

				FlxTween.tween(selectedItem.scale, { x: 1.1, y: 1.1 }, 0.15, {
					ease: FlxEase.quadOut,
					onUpdate: function(_)
					{
						var offX = (selectedItem.width * (selectedItem.scale.x - 1)) * 0.5;
						var offY = (selectedItem.height * (selectedItem.scale.y - 1)) * 0.5;
						selectedItem.x = bx - offX;
						selectedItem.y = by - offY;
					}
				});
			}
		}

		camFollow.y = selectedItem.getGraphicMidpoint().y;
	}
}
