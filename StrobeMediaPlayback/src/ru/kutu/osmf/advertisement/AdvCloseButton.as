package ru.kutu.osmf.advertisement {
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.SimpleButton;
	
	public class AdvCloseButton extends SimpleButton {
		
		public function AdvCloseButton() {
			// hit area
			var sh:Shape = new Shape();
			var g:Graphics = sh.graphics;
			var w:Number = 14.0;
			g.beginFill(0, 0);
			g.drawRect(0, 0, w, w);
			
			super(
				getButtonShape(0xCCCCCC),
				getButtonShape(0xFFFFFF),
				null,
				sh
			);
		}
		
		private function getButtonShape(color:uint, alpha:Number=1.0):DisplayObject {
			var sh:Shape = new Shape();
			var g:Graphics = sh.graphics;
			
			var w:Number = 14.0;
			var r:Number = 4.0;
			var t:Number = 2.0;
			
			g.beginFill(0, 0.8);
			g.drawRoundRect(-1, -1, w + 2, w + 2, r + 1);
			g.endFill();
			
			g.beginFill(color, alpha);
			g.drawRoundRect(0, 0, w, w, r);
			g.drawRoundRect(t, t, w - 2*t, w - 2*t, r-t);
			g.endFill();
			
			g.lineStyle(t, color, alpha);
			g.moveTo(r, r);
			g.lineTo(w - r, w - r);
			g.moveTo(w - r, r);
			g.lineTo(r, w - r);
			
			return sh;
		}
		
	}
	
}
