package ru.kutu.osmf.advertisement {
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.Timer;
	
	import org.osmf.containers.MediaContainer;
	import org.osmf.elements.ImageElement;
	import org.osmf.elements.LightweightVideoElement;
	import org.osmf.elements.ProxyElement;
	import org.osmf.events.BufferEvent;
	import org.osmf.events.ContainerChangeEvent;
	import org.osmf.events.DisplayObjectEvent;
	import org.osmf.events.MediaErrorEvent;
	import org.osmf.events.MediaPlayerStateChangeEvent;
	import org.osmf.events.PlayEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.layout.LayoutMetadata;
	import org.osmf.layout.LayoutTargetSprite;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaFactory;
	import org.osmf.media.MediaPlayer;
	import org.osmf.media.MediaPlayerState;
	import org.osmf.media.URLResource;
	import org.osmf.traits.LoadTrait;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.traits.PlayState;
	
	[Event(name="adv.start", type="ru.kutu.osmf.advertisement.AdvertisementEvent")]
	[Event(name="adv.complete", type="ru.kutu.osmf.advertisement.AdvertisementEvent")]
	[Event(name="adv.close", type="ru.kutu.osmf.advertisement.AdvertisementEvent")]
	[Event(name="adv.click", type="ru.kutu.osmf.advertisement.AdvertisementEvent")]
	
	public class AdvertisementItem extends MediaPlayer {
		
		private var mediaPlayer:MediaPlayer;
		private var mediaContainer:MediaContainer;
		private var mediaFactory:MediaFactory;
		private var _vo:AdvertisementVO;
		
		private var adContainer:MediaContainer;
		private var clickCont:LayoutTargetSprite;
		private var clickBut:Sprite;
		private var closeCont:LayoutTargetSprite;
		private var closeBut:AdvCloseButton;
		
		private var autoCloseTimer:Timer;
		
		private var _isStarted:Boolean;
		
		public function AdvertisementItem(mediaPlayer:MediaPlayer, mediaContainer:MediaContainer, mediaFactory:MediaFactory, vo:AdvertisementVO) {
			this.mediaPlayer = mediaPlayer;
			this.mediaContainer = mediaContainer;
			this.mediaFactory = mediaFactory;
			_vo = vo;
			
			adContainer = new MediaContainer();
			
			// Set up the ad
			var adMediaElement:MediaElement = mediaFactory.createMediaElement(new URLResource(vo.url));
			
			// Set the layout metadata, if present
			if (vo.layoutInfo != null) {
				for (var key:String in vo.layoutInfo) {
					adContainer.layoutMetadata[key] = vo.layoutInfo[key];
				}
//				if (!("index" in vo.layoutInfo)) {
					// Make sure we add the last ad on top of any others
//					adContainer.layoutMetadata.index = mediaContainer.numChildren;
//				}
			} else {
				adContainer.layoutMetadata.percentWidth = 100;
				adContainer.layoutMetadata.percentHeight = 100;
//				adContainer.layoutMetadata.index = mediaContainer.numChildren;
			}
			
			var layoutMetadata:LayoutMetadata = adMediaElement.getMetadata(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata;
			if (!layoutMetadata) {
				layoutMetadata = new LayoutMetadata();
				adMediaElement.addMetadata(LayoutMetadata.LAYOUT_NAMESPACE, layoutMetadata);
			}
			layoutMetadata.percentWidth = 100;
			layoutMetadata.percentHeight = 100;
			adContainer.addMediaElement(adMediaElement);
			
			// click area
			if (vo.clickUrl) {
				clickBut = new Sprite();
				clickBut.buttonMode = true;
				clickBut.graphics.beginFill(0, 0);
				clickBut.graphics.drawRect(0, 0, 10, 10);
				clickBut.addEventListener(MouseEvent.CLICK, onClick);
				clickCont = new LayoutTargetSprite();
				clickCont.layoutMetadata.percentWidth = 100;
				clickCont.layoutMetadata.percentHeight = 100;
				clickCont.addChild(clickBut);
				adContainer.layoutRenderer.addTarget(clickCont);
			}
			
			// close button
			if (vo.closable) {
				closeBut = new AdvCloseButton();
				closeBut.addEventListener(MouseEvent.CLICK, onClose);
				closeCont = new LayoutTargetSprite();
				closeCont.layoutMetadata.top = 4;
				closeCont.layoutMetadata.right = 4;
				closeCont.addChild(closeBut);
				adContainer.layoutRenderer.addTarget(closeCont);
			}
			
			super(adMediaElement);
			
			addEventListener(TimeEvent.COMPLETE, onAdComplete);
			addEventListener(MediaErrorEvent.MEDIA_ERROR, onAdComplete);
			addEventListener(DisplayObjectEvent.MEDIA_SIZE_CHANGE, onMediaSizeChange);
			
			addEventListener(MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE, onAdMediaPlayerStateChange);
			onAdMediaPlayerStateChange();
		}
		
		public function get vo():AdvertisementVO { return _vo }
		public function get isStarted():Boolean { return _isStarted }
		
		public function destroy():void {
			if (_vo.pauseMainMediaWhilePlayingAd) {
				// Add the main video back to the container.
				mediaContainer.addMediaElement(mediaPlayer.media);
				mediaContainer.validateNow();
				
				mediaPlayer.removeEventListener(PlayEvent.PLAY_STATE_CHANGE, onPlayStateChange);
			}
			
			if (_vo.pauseMainMediaWhilePlayingAd && _vo.resumePlaybackAfterAd) {
				// WORKAROUND: http://bugs.adobe.com/jira/browse/ST-397 - GPU Decoding issue on stagevideo: Win7, Flash Player version WIN 10,2,152,26 (debug)
//				if (mediaPlayer.canSeek) {
//					mediaPlayer.seek(mediaPlayer.currentTime);
//				}
				
				// Resume playback
				mediaPlayer.play();
			}
			
			if (mediaPlayer) {
				if (mediaPlayer.media) {
					mediaPlayer.media.removeEventListener(ContainerChangeEvent.CONTAINER_CHANGE, onContainerChange);
				}
				mediaPlayer.removeEventListener(PlayEvent.PLAY_STATE_CHANGE, onPlayStateChange);
			}
			
			removeEventListener(MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE, onAdMediaPlayerStateChange);
			removeEventListener(TimeEvent.COMPLETE, onAdComplete);
			removeEventListener(MediaErrorEvent.MEDIA_ERROR, onAdComplete);
			removeEventListener(BufferEvent.BUFFERING_CHANGE, onAdBufferingChange);
			removeEventListener(DisplayObjectEvent.MEDIA_SIZE_CHANGE, onMediaSizeChange);
			
			if (canPlay) {
				stop();
			}
			
			if (canLoad) {
				(media.getTrait(MediaTraitType.LOAD) as LoadTrait).unload();
			}
			
			if (adContainer.containsMediaElement(media)) {
				adContainer.removeMediaElement(media);
			}
			
			// remove click area
			if (clickCont && adContainer.layoutRenderer.hasTarget(clickCont)) {
				adContainer.layoutRenderer.removeTarget(clickCont);
			}
			if (clickBut) {
				clickBut.removeEventListener(MouseEvent.CLICK, onClick);
			}
			
			// remove close button
			if (closeCont && adContainer.layoutRenderer.hasTarget(closeCont)) {
				adContainer.layoutRenderer.removeTarget(closeCont);
			}
			if (closeBut) {
				closeBut.removeEventListener(MouseEvent.CLICK, onClose);
			}
			
			if (mediaContainer.layoutRenderer.hasTarget(adContainer)) {
				mediaContainer.layoutRenderer.removeTarget(adContainer);
			}
			
			// remove auto close timer
			if (autoCloseTimer) {
				autoCloseTimer.stop();
				autoCloseTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onAutoClose);
				autoCloseTimer = null;
			}
			
			mediaPlayer = null;
			mediaContainer = null;
			mediaFactory = null;
			
			clickBut = null;
			clickCont = null;
			
			closeBut = null; 
			closeCont = null;
			
			adContainer = null;
		}
		
		private function onMediaSizeChange(event:DisplayObjectEvent):void {
			var el:MediaElement = media;
			while (el && el is ProxyElement) {
				el = (el as ProxyElement).proxiedElement;
			}
			if (el is LightweightVideoElement) {
				(el as LightweightVideoElement).smoothing = true;
			}
			if (el is ImageElement) {
				(el as ImageElement).smoothing = true;
			}
		}
		
		private function playAd():void {
			// Copy the player's current volume values
			if (hasAudio) {
				volume = mediaPlayer.volume;
				muted = mediaPlayer.muted;
			}
			
			if (_vo.pauseMainMediaWhilePlayingAd) {
				// TODO: We assume that playback pauses immediately,
				// but this is not the case for all types of content.
				// The linear ads should be inserted only after the player state becomes 'paused'.
				mediaPlayer.pause();
				
				// keep main video stay in pause
				mediaPlayer.addEventListener(PlayEvent.PLAY_STATE_CHANGE, onPlayStateChange);
				
				// If we are playing a linear ad, we need to remove it from the media container.
				if (mediaContainer.containsMediaElement(mediaPlayer.media)) {
					mediaContainer.removeMediaElement(mediaPlayer.media);
				} else {
					// Wait until the media gets added to the container, so that we can remove it
					// immediately afterwards.
					mediaPlayer.media.addEventListener(ContainerChangeEvent.CONTAINER_CHANGE, onContainerChange);
				}
			}
			
			if (!isNaN(_vo.autoCloseAfter) && _vo.autoCloseAfter > 0) {
				autoCloseTimer = new Timer(_vo.autoCloseAfter * 1000, 1);
				autoCloseTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onAutoClose);
				autoCloseTimer.start();
			}
			
			// Add the ad to the container
			mediaContainer.layoutRenderer.addTarget(adContainer);
			
			dispatchEvent(new AdvertisementEvent(AdvertisementEvent.START));
			_isStarted = true;
		}
		
		private function onAdBufferingChange(event:BufferEvent):void {
			var adMediaPlayer:MediaPlayer = event.target as MediaPlayer;
			if (event.buffering == false) {
				adMediaPlayer.removeEventListener(BufferEvent.BUFFERING_CHANGE, onAdBufferingChange);
				playAd();
			}
		}
		
		private function onPlayStateChange(event:PlayEvent):void {
			if (event.playState == PlayState.PLAYING) {
				mediaPlayer.pause();
			}
		}
		
		private function onContainerChange(event:ContainerChangeEvent):void {
			if (mediaContainer.containsMediaElement(mediaPlayer.media)) {
				mediaPlayer.media.removeEventListener(ContainerChangeEvent.CONTAINER_CHANGE, onContainerChange);
				mediaContainer.removeMediaElement(mediaPlayer.media);
			}
		}
		
		private function onAdComplete(event:Event):void {
			dispatchEvent(new AdvertisementEvent(AdvertisementEvent.COMPLETE));
		}
		
		private function onClick(event:MouseEvent):void {
			if (_vo.pauseMainMediaOnClick) {
				mediaPlayer.pause();
			}
			dispatchEvent(new AdvertisementEvent(AdvertisementEvent.CLICK));
			navigateToURL(new URLRequest(_vo.clickUrl));
		}
		
		private function onClose(event:MouseEvent):void {
			dispatchEvent(new AdvertisementEvent(AdvertisementEvent.CLOSE));
		}
		
		private function onAdMediaPlayerStateChange(event:MediaPlayerStateChangeEvent = null):void {
			if (state == MediaPlayerState.READY || state == MediaPlayerState.PLAYING) {
				removeEventListener(MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE, onAdMediaPlayerStateChange);
				if (canBuffer && _vo.preBufferAd) {
					// Wait until the ad fills the buffer and is ready to be played.
					muted = true;
					addEventListener(BufferEvent.BUFFERING_CHANGE, onAdBufferingChange);
				} else {
					playAd();
				}
			}
		}
		
		private function onAutoClose(event:TimerEvent):void {
			dispatchEvent(new AdvertisementEvent(AdvertisementEvent.CLOSE));
		}
		
	}
	
}
