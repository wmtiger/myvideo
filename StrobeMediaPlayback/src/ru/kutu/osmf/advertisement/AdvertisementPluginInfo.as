package ru.kutu.osmf.advertisement {
	
	import flash.external.ExternalInterface;
	
	import org.osmf.containers.MediaContainer;
	import org.osmf.events.AudioEvent;
	import org.osmf.events.BufferEvent;
	import org.osmf.events.MediaPlayerStateChangeEvent;
	import org.osmf.events.MetadataEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaFactory;
	import org.osmf.media.MediaPlayer;
	import org.osmf.media.MediaResourceBase;
	import org.osmf.media.PluginInfo;
	
	CONFIG::LOGGING {
		import org.osmf.logging.Log;
		import org.osmf.logging.Logger;
	}

	public class AdvertisementPluginInfo extends PluginInfo {
		
		public static const ADVERTISEMENT:String = "Advertisement";
		
		CONFIG::LOGGING {
			private static const logger:Logger = Log.getLogger("ru.kutu.osmf.advertisement.AdvertisementPluginInfo");
		}
		
		private var media:MediaElement;
		private var mediaPlayer:MediaPlayer;
		private var mediaContainer:MediaContainer;
		private var mediaFactory:MediaFactory;
		
		private var adItems:Vector.<AdvertisementItem> = new Vector.<AdvertisementItem>();
		
		private var prerollURL:String;
		private var midrollURL:String;
		private var midrollTime:int;
		private var postrollURL:String;
		
		public function AdvertisementPluginInfo() {
			if (ExternalInterface.available) {
				ExternalInterface.addCallback("displayAd", displayAd);
				ExternalInterface.addCallback("closeAd", closeAd);
			}
		}

		/**
		 * Initialize the plugin.
		 */
		override public function initializePlugin(resource:MediaResourceBase):void {
			mediaPlayer = resource.getMetadataValue("MediaPlayer") as MediaPlayer;
			mediaContainer = resource.getMetadataValue("MediaContainer") as MediaContainer;
			mediaFactory = resource.getMetadataValue(PluginInfo.PLUGIN_MEDIAFACTORY_NAMESPACE) as MediaFactory;
			
			mediaPlayer.addEventListener(MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE, onMediaPlayerStateChange);
		}
		
		/**
		 * Utility function which plays an ad.
		 */
		public function displayAd(data:Object):void {
			if (!data) return;
			var vo:AdvertisementVO;
			if (data is AdvertisementVO) {
				vo = data as AdvertisementVO;
			} else {
				vo = new AdvertisementVO(data);
			}
			var adItem:AdvertisementItem = new AdvertisementItem(mediaPlayer, mediaContainer, mediaFactory, vo);
			if (adItem.isStarted) {
				startAdItem(adItem);
			} else {
				adItem.addEventListener(AdvertisementEvent.START, onAdItemStart);
			}
			adItem.addEventListener(AdvertisementEvent.COMPLETE, onAdItemComplete);
			adItem.addEventListener(AdvertisementEvent.CLOSE, onAdItemClose);
			adItem.addEventListener(AdvertisementEvent.CLICK, onAdItemClick);
			adItems.push(adItem);
		}
		
		/**
		 * Immediatly close ad by id
		 */
		public function closeAd(id:String):void {
			for each (var adItem:AdvertisementItem in adItems) {
				if (adItem.vo.id == id) {
					closeAdItem(adItem);
				}
			}
		}

		// Internals

		private function onMediaPlayerStateChange(event:MediaPlayerStateChangeEvent):void {
			if (mediaPlayer.media == media) return;
			media = mediaPlayer.media;
			if (!media) return;
			onMediaElement(media);
		}

		private function onMediaElement(element:MediaElement):void {
			var resource:MediaResourceBase = element.resource;

			prerollURL = resource.getMetadataValue("preroll") as String;
			midrollURL = resource.getMetadataValue("midroll") as String;
			midrollTime = int(resource.getMetadataValue("midrollTime"));
			postrollURL = resource.getMetadataValue("postroll") as String;

			clear();
			init();
		}

		private function init():void {
			if (prerollURL) {
				// NOTE: For progressive video the pause will not take effect immediately after playback has started.
				// So we need to pause the main media before it starts playing. To do this, we handle the
				// BufferEvent.BUFFERING_CHANGE event, instead of PlayEvent.PLAY_STATE_CHANGE.
				// mediaPlayer.addEventListener(PlayEvent.PLAY_STATE_CHANGE, onPlayStateChange);

				mediaPlayer.addEventListener(BufferEvent.BUFFERING_CHANGE, onBufferChange);
			}

			if (postrollURL) {
				// TODO: Prebuffer the preroll before the playback completes.
				// The current implementation will likely change in future.
				mediaPlayer.addEventListener(TimeEvent.COMPLETE, onComplete);
			}

			if (midrollURL && midrollTime > 0) {
				mediaPlayer.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, onMidrollCurrentTimeChange);
			}

			// Propagate the muted and volume changes from the video player to the advertisements.
			mediaPlayer.addEventListener(AudioEvent.MUTED_CHANGE, onMutedChange);
			mediaPlayer.addEventListener(AudioEvent.VOLUME_CHANGE, onVolumeChange);
		}

		private function clear():void {
			for each (var adItem:AdvertisementItem in adItems) {
				adItem.removeEventListener(AdvertisementEvent.START, onAdItemStart);
				adItem.removeEventListener(AdvertisementEvent.COMPLETE, onAdItemComplete);
				adItem.removeEventListener(AdvertisementEvent.CLOSE, onAdItemClose);
				adItem.removeEventListener(AdvertisementEvent.CLICK, onAdItemClick);
				adItem.destroy();
			}
			adItems.length = 0;

			// remove previous init listeners
			mediaPlayer.removeEventListener(BufferEvent.BUFFERING_CHANGE, onBufferChange);
			mediaPlayer.removeEventListener(TimeEvent.CURRENT_TIME_CHANGE, onMidrollCurrentTimeChange);
			mediaPlayer.removeEventListener(TimeEvent.COMPLETE, onComplete);
			mediaPlayer.removeEventListener(AudioEvent.MUTED_CHANGE, onMutedChange);
			mediaPlayer.removeEventListener(AudioEvent.VOLUME_CHANGE, onVolumeChange);
		}

		private function onMutedChange(event:AudioEvent):void {
			for each (var adItem:AdvertisementItem in adItems) {
				adItem.muted = mediaPlayer.muted;
			}
		}

		private function onVolumeChange(event:AudioEvent):void {
			for each (var adItem:AdvertisementItem in adItems) {
				adItem.volume = mediaPlayer.volume;
			}
		}

		// Linear ad insertion

		/**
		 * Display the pre-roll advertisement.
		 */
		private function onBufferChange(event:BufferEvent):void {
			if (event.buffering) {
				mediaPlayer.removeEventListener(BufferEvent.BUFFERING_CHANGE, onBufferChange);
				// Do not pre-buffer the ad if playing a pre-roll ad.
				// Let the main content pre-buffer while the ad is playing instead.
				var vo:AdvertisementVO = new AdvertisementVO();
				vo.id = "preroll";
				vo.url = prerollURL;
				vo.hideScrubBarWhilePlayingAd = true;
				vo.pauseMainMediaWhilePlayingAd = true;
				vo.resumePlaybackAfterAd = true;
				displayAd(vo);
			}
		}

		/**
		 * Display the mid-roll ad.
		 */
		private function onMidrollCurrentTimeChange(event:TimeEvent):void {
			if (mediaPlayer.currentTime > midrollTime) {
				mediaPlayer.removeEventListener(TimeEvent.CURRENT_TIME_CHANGE, onMidrollCurrentTimeChange);
				var vo:AdvertisementVO = new AdvertisementVO();
				vo.id = "midroll";
				vo.url = midrollURL;
				vo.hideScrubBarWhilePlayingAd = true;
				vo.pauseMainMediaWhilePlayingAd = true;
				vo.resumePlaybackAfterAd = true;
				vo.preBufferAd = true;
				displayAd(vo);
			}
		}

		/**
		 * Display the post-roll ad.
		 */
		private function onComplete(event:TimeEvent):void {
			mediaPlayer.removeEventListener(TimeEvent.COMPLETE, onComplete);
			// Resume the playback after the ad only if loop is set to true
			var vo:AdvertisementVO = new AdvertisementVO();
			vo.id = "postroll";
			vo.url = postrollURL;
			vo.hideScrubBarWhilePlayingAd = true;
			vo.pauseMainMediaWhilePlayingAd = true;
			vo.resumePlaybackAfterAd = mediaPlayer.loop;
			displayAd(vo);
		}
		
		private function destroyAdItem(adItem:AdvertisementItem):void {
			adItem.destroy();
			
			var index:int = adItems.indexOf(adItem);
			if (index > -1) {
				adItem.removeEventListener(AdvertisementEvent.START, onAdItemStart);
				adItem.removeEventListener(AdvertisementEvent.COMPLETE, onAdItemComplete);
				adItem.removeEventListener(AdvertisementEvent.CLOSE, onAdItemClose);
				adItem.removeEventListener(AdvertisementEvent.CLICK, onAdItemClick);
				adItems.splice(index, 1);
			}
			
			removeAdFromMetadata(adItem);
		}
		
		private function onAdItemStart(event:AdvertisementEvent):void {
			var adItem:AdvertisementItem = event.target as AdvertisementItem;
			if (adItem) {
				startAdItem(adItem);
			}
		}
		private function startAdItem(adItem:AdvertisementItem):void {
			CONFIG::LOGGING {
				logger.info("started id:{0} url:{1}", adItem.vo.id, adItem.vo.url);
			}
			addAdInMetadata(adItem);
			if (ExternalInterface && ExternalInterface.available && adItem.vo.onStart && adItem.vo.onStart.length) {
				ExternalInterface.call(adItem.vo.onStart, adItem.vo.id);
			}
		}
		
		private function onAdItemComplete(event:AdvertisementEvent):void {
			var adItem:AdvertisementItem = event.target as AdvertisementItem;
			if (adItem) {
				CONFIG::LOGGING {
					logger.info("completed id:{0} url:{1}", adItem.vo.id, adItem.vo.url);
				}
				destroyAdItem(adItem);
				if (ExternalInterface && ExternalInterface.available && adItem.vo.onComplete && adItem.vo.onComplete.length) {
					ExternalInterface.call(adItem.vo.onComplete, adItem.vo.id);
				}
			}
		}
		
		private function onAdItemClose(event:AdvertisementEvent):void {
			var adItem:AdvertisementItem = event.target as AdvertisementItem;
			if (adItem) {
				closeAdItem(adItem);
			}
		}
		private function closeAdItem(adItem:AdvertisementItem):void {
			CONFIG::LOGGING {
				logger.info("closed id:{0} url:{1}", adItem.vo.id, adItem.vo.url);
			}
			destroyAdItem(adItem);
			if (ExternalInterface && ExternalInterface.available && adItem.vo.onClose && adItem.vo.onClose.length) {
				ExternalInterface.call(adItem.vo.onClose, adItem.vo.id);
			}
		}
		
		private function onAdItemClick(event:AdvertisementEvent):void {
			var adItem:AdvertisementItem = event.target as AdvertisementItem;
			if (adItem) {
				CONFIG::LOGGING {
					logger.info("clicked id:{0} url:{1}", adItem.vo.id, adItem.vo.url);
				}
				if (ExternalInterface && ExternalInterface.available && adItem.vo.onClick && adItem.vo.onClick.length) {
					ExternalInterface.call(adItem.vo.onClick, adItem.vo.id);
				}
			}
		}
		
		private function addAdInMetadata(adItem:AdvertisementItem):void {
			var adArr:Array = media.metadata.getValue(ADVERTISEMENT) as Array;
			if (adArr) {
				adArr.push(adItem.vo);
				media.metadata.addValue(ADVERTISEMENT, adArr);
				media.metadata.dispatchEvent(new MetadataEvent(MetadataEvent.VALUE_CHANGE, false, false, ADVERTISEMENT, adArr, adArr));
			} else {
				adArr = [adItem.vo];
				media.metadata.addValue(ADVERTISEMENT, adArr);
			}
		}
		
		private function removeAdFromMetadata(adItem:AdvertisementItem):void {
			var adArr:Array = media.metadata.getValue(ADVERTISEMENT) as Array;
			if (adArr) {
				var index:int = adArr.indexOf(adItem.vo);
				if (index > -1) {
					adArr.splice(index, 1);
				}
				if (adArr.length) {
					media.metadata.addValue(ADVERTISEMENT, adArr);
					media.metadata.dispatchEvent(new MetadataEvent(MetadataEvent.VALUE_CHANGE, false, false, ADVERTISEMENT, adArr, adArr));
				} else {
					media.metadata.removeValue(ADVERTISEMENT);
				}
			} else {
				media.metadata.removeValue(ADVERTISEMENT);
			}
		}

	}

}
