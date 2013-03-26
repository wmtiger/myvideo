package ru.kutu.osmf.advertisement {

	import flash.events.Event;

	public class AdvertisementEvent extends Event {

		public static const START:String = "adv.start";
		public static const COMPLETE:String = "adv.complete";
		public static const CLOSE:String = "adv.close";
		public static const CLICK:String = "adv.click";

		public function AdvertisementEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
		}

		override public function clone():Event {
			return new AdvertisementEvent(type, bubbles, cancelable);
		}

		override public function toString():String {
			return formatToString("AdvertisementEvent", "type", "bubbles", "cancelable", "eventPhase");
		}

	}

}
