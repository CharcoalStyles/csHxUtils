package csHxUtils.entities;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText.FlxTextAlign;

typedef InputOptions = {
	keyboard:Bool,
	mouse:Bool,
	gamepad:Bool,
	gamepadId:Int,
}

typedef InputEvent = {
	buttonType:Null<String>,
	mousePos:Null<FlxPoint>,
	mouseClick:Null<Bool>,
}

typedef AnalogStickState = {
	x:Float,
	y:Float,
	active:Bool,
	timeSinceLastUpdate:Float,
}

typedef MouseState = {
	x:Float,
	y:Float,
	mouseClick:Bool,
	timeSinceLastUpdate:Float,
}

class CsMenu extends FlxTypedGroup<CsMenuPage> {
	var x:Float;
	var y:Float;
	var menuAlign:FlxTextAlign;
	var pages:Map<String, CsMenuPage>;
	var activePageTag:String;

	var lastLeftAnalogStickState:AnalogStickState;
	var lastMouseState:MouseState;

	var inputOptions:InputOptions;

	public var rect(get, never):FlxRect;

	function get_rect():FlxRect {
		return FlxRect.get();
	}

	public function new(X:Float, Y:Float, align:FlxTextAlign, io:InputOptions) {
		super();

		x = X;
		y = Y;
		menuAlign = align;

		pages = new Map<String, CsMenuPage>();
		activePageTag = null;
		inputOptions = io;

		if (io.gamepad) {
			lastLeftAnalogStickState = {
				x: 0,
				y: 0,
				active: false,
				timeSinceLastUpdate: 0,
			}
		}

		if (io.mouse) {
			lastMouseState = {
				x: 0,
				y: 0,
				mouseClick: false,
				timeSinceLastUpdate: 0,
			}
		}
	}

	public function createPage(tag:String) {
		var page = new CsMenuPage(x, y, menuAlign);
		add(page);
		pages.set(tag, page);
		if (activePageTag == null) {
			activePageTag = tag;
			page.active = true;
		} else {
			page.active = false;
		}
		return page;
	}

	public function openPage(tag:String) {
		if (activePageTag == tag) {
			return;
		}

		pages[activePageTag].hide(() -> {
			pages[tag].show();
		});

		activePageTag = tag;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		var inputEvent:InputEvent = {
			buttonType: null,
			mousePos: null,
			mouseClick: null,
		};
		var inputchanged = false;

		if (inputOptions.keyboard) {
			if (FlxG.keys.firstJustPressed() != -1) {
				var key = FlxG.keys.justPressed.UP ? "UP" : FlxG.keys.justPressed.DOWN ? "DOWN" : FlxG.keys.justPressed.LEFT ? "LEFT" : FlxG.keys.justPressed.RIGHT ? "RIGHT" : FlxG.keys.justPressed.ENTER ? "ENTER" : null;

				if (key != null) {
					inputEvent.buttonType = key;
					inputchanged = true;
				}
			}
		}

		if (inputOptions.mouse) {
			var mousePos = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
			var nextMouseState:MouseState = {
				x: mousePos.x,
				y: mousePos.y,
				mouseClick: false,
				timeSinceLastUpdate: 0.0,
			}

			if (lastMouseState.x != mousePos.x || lastMouseState.y != mousePos.y) {
				inputEvent.mousePos = mousePos;
				inputchanged = true;
				// mouseClick: FlxG.mouse.justPressed ? true : null,
			}

			if (FlxG.mouse.justPressed && lastMouseState.mouseClick == false) {
				nextMouseState.mouseClick = true;
				inputEvent.mouseClick = true;
				inputchanged = true;
			}

			if (FlxG.mouse.justPressed && lastMouseState.mouseClick == false) {
				nextMouseState.mouseClick = true;
				inputEvent.mouseClick = true;
				inputchanged = true;
			}
			if (!FlxG.mouse.justPressed && lastMouseState.mouseClick == true) {
				nextMouseState.mouseClick = false;
				inputEvent.mouseClick = false;
				inputchanged = true;
			}

			lastMouseState = nextMouseState;
		}

		if (inputOptions.gamepad && FlxG.gamepads.getByID(inputOptions.gamepadId) != null) {
			inputEvent = {
				buttonType: null,
				mousePos: null,
				mouseClick: null,
			};

			var gamePad = FlxG.gamepads.getByID(inputOptions.gamepadId);

			var justPressedButtons = FlxG.gamepads.getByID(inputOptions.gamepadId).justPressed;
			var button = justPressedButtons.A ? "ENTER" : justPressedButtons.DPAD_UP ? "UP" : justPressedButtons.DPAD_DOWN ? "DOWN" : justPressedButtons.DPAD_LEFT ? "LEFT" : justPressedButtons.DPAD_RIGHT ? "RIGHT" : null;

			if (button != null) {
				inputEvent.buttonType = button;
			}

			var leftAnalogStick = FlxPoint.get(gamePad.analog.value.LEFT_STICK_X, gamePad.analog.value.LEFT_STICK_Y);
			var nextLeftAnalogStickState = {
				x: leftAnalogStick.x,
				y: leftAnalogStick.y,
				active: false,
				timeSinceLastUpdate: 0.0,
			}

			// test x is active now
			if (Math.abs(leftAnalogStick.x) > 0.5) {
				nextLeftAnalogStickState.active = true;

				if (lastLeftAnalogStickState.active == false) {
					inputEvent.buttonType = leftAnalogStick.x > 0 ? "RIGHT" : "LEFT";
				}
				// Eventually do some re-trigger after a delay here.
			} else {
				nextLeftAnalogStickState.active = false;
			}

			// test y is active now
			if (Math.abs(leftAnalogStick.y) > 0.5) {
				nextLeftAnalogStickState.active = true;

				if (lastLeftAnalogStickState.active == false) {
					inputEvent.buttonType = leftAnalogStick.y > 0 ? "DOWN" : "UP";
				}
				// Eventually do some re-trigger after a delay here.
			} else {
				nextLeftAnalogStickState.active = false;
			}

			lastLeftAnalogStickState = nextLeftAnalogStickState;

			if (inputEvent.buttonType == null) {
				inputEvent = null;
			}
		}
		if (active && inputEvent != null) {
			pages[activePageTag].onInput(inputEvent);
		}
	}
}
