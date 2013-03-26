package ru.kutu.osmf.advertisement {
	
	public class AdvertisementVO {
		
		public var id:String;
		public var url:String;
		public var hideScrubBarWhilePlayingAd:Boolean;
		public var pauseMainMediaWhilePlayingAd:Boolean;
		public var resumePlaybackAfterAd:Boolean;
		public var preBufferAd:Boolean;
		public var layoutInfo:Object;
		public var clickUrl:String;
		public var pauseMainMediaOnClick:Boolean;
		public var closable:Boolean;
		public var autoCloseAfter:Number;
		
		public var onStart:String;
		public var onComplete:String;
		public var onClose:String;
		public var onClick:String;
		
		public function AdvertisementVO(data:Object = null) {
			if (!data) return;
			for (var k:String in data) {
				try {
					this[k] = data[k];
				} catch(error:Error) {
				}
			}
		}
		
	}
	
}
