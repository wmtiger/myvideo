package ru.kutu.osmf.advertisement {
	
	import flash.display.Sprite;
	
	import org.osmf.media.PluginInfo;
	
	public class AdvertisementPlugin extends Sprite {

		private var _pluginInfo:PluginInfo;
		
		public function AdvertisementPlugin() {
			_pluginInfo = new AdvertisementPluginInfo();
		}
		
		public function get pluginInfo():PluginInfo {
			return _pluginInfo;
		}
		
	}
	
}
