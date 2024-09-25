package csHxUtils.entities;

import csHxUtils.entities.CsMenu;
import csHxUtils.entities.SplitText;
import csHxUtils.entities.SplitText;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxe.Timer;

typedef AnimOptions = {
	unselectedColour:FlxColor,
	?selectedColour:FlxColor,
	?borderColour:FlxColor,
}

var defaultAnimOptions:AnimOptions = {
	unselectedColour: 0xFF202020,
	selectedColour: 0xFF606060,
	borderColour: 0xFFFFFFFF
}

typedef MenuItemOptions = {
	?animOptions:AnimOptions,
	?labelOptions:SplitText.SplitTextOptions,
}

typedef MenuItem = {
	selectable:Bool,
	?callback:Void->Void,
	?options:MenuItemOptions
}

class CsMenuPage extends FlxTypedGroup<SplitText> {
	var menuItems = new Array<MenuItem>();
	var selected:Int = 0;
	var alignment:FlxTextAlign;
	var startX:Float;
	var startY:Float;
	var workingY:Float;
	var minX:Float;
	var maxX:Float;

	public var rect(get, never):FlxRect;

	function get_rect():FlxRect {
		return FlxRect.get(minX, startY, maxX - minX, workingY - startY);
	}

	public function new(X:Float, Y:Float, align:FlxTextAlign) {
		super();
		alignment = align;
		menuItems = [];
		startX = minX = maxX = X;
		startY = workingY = Y;
	}

	public function addLabel(label:String, ?colour:FlxColor) {
		addEntry(label, null, {animOptions: {unselectedColour: colour == null ? 0xFFe0e0e0 : colour}});
	}

	public function addItem(label:String, ?callback:Void->Void, ?options:MenuItemOptions) {
		addEntry(label, callback, options);
	}

	function addEntry(label:String, ?callback:Void->Void, ?options:MenuItemOptions) {
		var opt:MenuItemOptions = options != null ? options : {
			animOptions: {
				unselectedColour: 0xFF202020,
				selectedColour: 0xFF606060,
				borderColour: 0xFFFFFFFF
			},
			labelOptions: SplitText.defaultOptions
		}

		if (opt.animOptions == null) {
			opt.animOptions = defaultAnimOptions;
		}
		if (opt.labelOptions == null) {
			opt.labelOptions = SplitText.defaultOptions;
		}

		if (opt.animOptions.selectedColour == null) {
			opt.animOptions.selectedColour = opt.animOptions.unselectedColour;
		}

		menuItems.push({selectable: callback != null, callback: callback, options: opt});

		var text = new SplitText(startX, workingY, label, opt.labelOptions);
		switch (alignment) {
			case FlxTextAlign.CENTER:
				text.x = startX - text.width / 2;
				minX = Math.min(minX, text.x);
				maxX = Math.max(maxX, text.x + text.width);
			case FlxTextAlign.RIGHT:
				text.x = startX - text.width;
				minX = Math.min(minX, startX - text.width);
				maxX = Math.max(maxX, startX);
			default:
				text.x = startX;
				minX = Math.min(minX, startX);
				maxX = Math.max(maxX, startX + text.width);
		}
		add(text);

		var i = menuItems.filter(function(item) return item.selectable).length;
		if (i == 1) {
			text.color = opt.animOptions.selectedColour;
			selected = menuItems.length - 1;
			selectedAnim(selected);
		} else {
			text.color = opt.animOptions.unselectedColour;
		}

		if (opt.animOptions.borderColour != null) {
			text.borderStyle = FlxTextBorderStyle.OUTLINE;
			text.borderColor = opt.animOptions.borderColour;
			text.borderSize = 2;
		}

		workingY += text.height + 16;
	}

	function onSelectedAnim(index:Int) {
		var selection = members[index];
		selection.stopAnimation();
		var item = menuItems[index];
		selection.animateWave(12, 0.01, 0.2, true, () -> {
			selectedAnim(index);
		});
		selection.animateColour(item.options.animOptions.selectedColour, 0.01, 0.2, item.options.animOptions.unselectedColour, true);
	}

	function selectedAnim(index:Int) {
		var selection = members[index];
		selection.animateWave(6, 0.125, 0.8, false);
	}

	function onDeselectedAnim(index:Int) {
		var selection = members[index];
		selection.stopAnimation();
		var item = menuItems[index];
		selection.animateColour(item.options.animOptions.unselectedColour, 0.01, 0.2, item.options.animOptions.selectedColour, true);
	}

	public function onInput(inputEvent:InputEvent) {
		if (inputEvent.buttonType != null) {
			switch (inputEvent.buttonType) {
				case "UP":
					moveSelected(false);
				case "DOWN":
					moveSelected(true);
				case "LEFT":
				case "RIGHT":
				case "ENTER":
					menuItems[selected].callback();
			}
		}

		if (inputEvent.mousePos != null) {
			for (txtId in 0...members.length) {
				if (members[txtId].rect.containsPoint(inputEvent.mousePos)) {
					if (txtId != selected && menuItems[txtId].selectable) {
						onDeselectedAnim(selected);
						selected = txtId;
						onSelectedAnim(selected);
					}
				}
			}
		}

		if (inputEvent.mouseClick != null && inputEvent.mouseClick) {
			FlxG.log.add("Mouse click");
			menuItems[selected].callback();
		}
	}

	function moveSelected(moveDown:Bool) {
		var direction = moveDown ? 1 : -1;

		var prevSelected = selected;
		var nextSelected = selected;

		var found = false;
		do {
			nextSelected = FlxMath.wrap(nextSelected + direction, 0, menuItems.length - 1);
			if (menuItems[nextSelected].selectable) {
				found = true;
			}
		} while (!found);

		if (nextSelected != prevSelected) {
			selected = nextSelected;
			onDeselectedAnim(prevSelected);
			onSelectedAnim(selected);
		}
	}

	function manuallySetSelectedTop() {
		var s = -1;
		for (i in 0...menuItems.length) {
			if (s == -1 && menuItems[i].selectable) {
				members[i].color = menuItems[i].options.animOptions.selectedColour;
				s = i;
			} else {
				members[i].color = menuItems[i].options.animOptions.unselectedColour;
			}
		}
		selected = s;
	}

	public function show(force:Bool = false, ?callback:Void->Void) {
		if (force) {
			manuallySetSelectedTop();
			active = true;
			for (member in members) {
				member.alpha = 1;
			}
			return;
		}

		for (i in 0...members.length) {
			manuallySetSelectedTop();
			Timer.delay(function() {
				FlxTween.tween(members[i], {alpha: 1}, 0.5, {
					onComplete: (t) -> {
						if (i == members.length - 1) {
							active = true;
							if (callback != null) {
								callback();
							}
						}
					}
				});
			}, 1);
		}
	}

	public function hide(force:Bool = false, ?callback:Void->Void) {
		active = false;

		if (force) {
			for (member in members) {
				member.alpha = 0;
			}
			return;
		}

		for (i in 0...members.length) {
			Timer.delay(function() {
				FlxTween.tween(members[i], {alpha: 0}, 0.5, {
					onComplete: (t) -> {
						if (callback != null && i == members.length - 1)
							callback();
					}
				});
			}, 1);
		}
	}
}
