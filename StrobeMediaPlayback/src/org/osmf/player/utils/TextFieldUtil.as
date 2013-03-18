package org.osmf.player.utils
{
	import flash.text.TextField;
	import flash.text.TextFormat;
	/**
	 * ...
	 * @author wmtiger
	 */
	public class TextFieldUtil 
	{
		
		public function TextFieldUtil() 
		{
			
		}
		
		public static function createTf(txt:String = " ", x:int = 0, y:int = 0, w:int = 100, h:int = 22,
			color:uint = 0, size:int = 14, font:String = null, align:String = null, border:Boolean = false):TextField
		{
			var tf:TextField = new TextField();
			tf.x = x;
			tf.y = y;
			tf.width = w;
			tf.height = h;
			tf.textColor = color;
			tf.text = txt + "";
			tf.border = border;
			setTextFormat(tf, font, size, color, null, null, null, null, null, align);
			return tf;
		}
		
		public static function setTfText(tf:TextField, txt:String, autoWidth:Boolean = false, autoHeight:Boolean = false):void
		{
			if (tf == null) 
			{
				throw new Error("文本不能为空");
				return;
			}
			var fmt:TextFormat = tf.getTextFormat();
			tf.text = "" + txt;
			tf.setTextFormat(fmt);
			if (autoWidth) 
			{
				tf.width = tf.textWidth + 4;
			}
			if (autoHeight) 
			{
				tf.height = tf.textHeight + 4;
			}
		}
		
		/**
		 * 设置文本框的属性，为了性能，只实现了前四个属性
		 * @param	tf
		 * @param	font
		 * @param	size
		 * @param	color
		 * @param	bold
		 * @param	italic
		 * @param	underline
		 * @param	url
		 * @param	target
		 * @param	align
		 * @param	leftMargin
		 * @param	rightMargin
		 * @param	indent
		 * @param	leading
		 */
		public static function setTextFormat(tf:TextField, 
			font:String = null, size:Object = null, color:Object = null, 
			bold:Object = null, italic:Object = null, underline:Object = null, 
			url:String = null, target:String = null, align:String = null, 
			leftMargin:Object = null, rightMargin:Object = null, indent:Object = null, 
			leading:Object=null):void
		{
			if (tf == null) 
			{
				throw new Error("文本不能为空");
				return;
			}
			var fmt:TextFormat = tf.getTextFormat();
			if (fmt.font == font && fmt.size == size && fmt.color == color && fmt.bold == bold && fmt.align == align) 
			{
				return;
			}
			fmt.font = font;
			fmt.size = size;
			fmt.color = color;
			fmt.bold = bold;
			fmt.align = align;
			//fmt.font = fmt.font == null ? font : font == null ? fmt.font : font;
			//fmt.size = fmt.size == null ? size : size == null ? fmt.size : size;
			//fmt.color = fmt.color == null ? color : color == null ? fmt.color : color;
			//fmt.bold = fmt.bold == null ? bold : bold == null ? fmt.bold : bold;
			//fmt.align = fmt.align == null ? align : align == null ? fmt.align : align;
			/*fmt.italic = italic;
			fmt.underline = underline;
			fmt.url = url;
			fmt.target = target;
			fmt.leftMargin = leftMargin;
			fmt.rightMargin = rightMargin;
			fmt.indent = indent;
			fmt.leading = leading;*/
			tf.setTextFormat(fmt);
			//trace(fmt.font,fmt.size,tf.text,tf.getTextFormat());
		}
		
	}

}