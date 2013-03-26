package org.osmf.player.utils
{
	import flash.display.Stage;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.utils.getTimer;
	/**
	 * ...
	 * @author wmTiger
	 */
	public class WmLog 
	{
		public static var console:TextField;
		public static var input:TextField;
		
		private static var _stage:Stage;
		
		public function WmLog() 
		{
			
		}
		
		public static function init(stage:Stage):void
		{
			_stage = stage;
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			
			console = TextFieldUtil.createTf("Log startup now!",0,0,600,400);
			console.background = true;
			console.backgroundColor = 0xcccccc;
			console.visible = false;
			
			input = TextFieldUtil.createTf("Input cmd here:",0,400,600,22,0xffffff);
			input.background = true;
			input.backgroundColor = 0;
			input.type = TextFieldType.INPUT;
			input.visible = false;
			
		}
		
		private static function onKeyUp(event:KeyboardEvent):void
		{
			//27 is ESC , 192 is `
			//if (event.ctrlKey && event.keyCode == 27)
			//info(event.keyCode);
			if (event.keyCode == 192)
			{
				//按下ESC键
				toogle();
			}
		}
		
		/**
		 * 信息
		 */ 
		public static function info(...args):void
		{
//			trace("[Info][" + getTimer() + "]: " + args);
			print("[Info][" + getTimer() + "]: " + args);
		}
		/**
		 * 错误
		 */ 
		public static function error(content:String):void
		{
			print("[Error]: "+content);
		}
		/**
		 * 打印信息
		 */ 
		private static function print(content:String):void
		{
			console.appendText("\n" + content);
			console.scrollV = console.maxScrollV;
		}
		/**
		 * 调试信息
		 * @param	content
		 */
		private static function debug(...args):void
		{
			print("[debug][" + getTimer() + "]: " + args);
		}
		/**
		 * 显示或掩藏控制台
		 */ 
		private static function toogle():void
		{
			if (console && input)
			{
				console.visible = input.visible = !console.visible;
				input.text = "";
				if (input.visible) 
				{
					_stage.focus = input;
				}
				if (console.parent) 
				{
					console.parent.setChildIndex(console, console.parent.numChildren - 1);
					input.parent.setChildIndex(input, input.parent.numChildren - 1);
				}
			}
		}
		
	}

}