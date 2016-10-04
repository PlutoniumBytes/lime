package lime.audio;


import haxe.io.Bytes;
import lime.audio.openal.AL;
import lime.audio.openal.ALBuffer;
import lime.utils.UInt8Array;

#if howlerjs
import lime.audio.howlerjs.Howl;
#end
#if (js && html5)
import js.html.Audio;
#elseif flash
import flash.media.Sound;
#elseif lime_console
import lime.audio.fmod.FMODMode;
import lime.audio.fmod.FMODSound;
#end

#if !macro
@:build(lime.system.CFFI.build())
#end


class AudioBuffer {
	
	
	public var bitsPerSample:Int;
	public var channels:Int;
	public var data:UInt8Array;
	public var sampleRate:Int;
	public var src (get, set):Dynamic;
	
	@:noCompletion private var __srcAudio:#if (js && html5) Audio #else Dynamic #end;
	@:noCompletion private var __srcBuffer:#if lime_cffi ALBuffer #else Dynamic #end;
	@:noCompletion private var __srcCustom:Dynamic;
	@:noCompletion private var __srcFMODSound:#if lime_console FMODSound #else Dynamic #end;
	@:noCompletion private var __srcHowl:#if howlerjs Howl #else Dynamic #end;
	@:noCompletion private var __srcSound:#if flash Sound #else Dynamic #end;
	
	
	public function new () {
		
		
		
	}
	
	
	public function dispose ():Void {
		
		#if lime_console
		if (channels > 0) {
			
			src.release ();
			channels = 0;
			
		}
		#end
		
	}
	
	
	#if lime_console
	@:void
	private static function finalize (a:AudioBuffer):Void {
		
		a.dispose ();
		
	}
	#end
	
	
	public static function fromBytes (bytes:Bytes):AudioBuffer {
		
		if (bytes == null) return null;
		
		#if lime_console
		
		lime.Lib.notImplemented ("AudioBuffer.fromBytes");
		
		#elseif (lime_cffi && !macro)
		#if !cs
		
		var audioBuffer = new AudioBuffer ();
		audioBuffer.data = new UInt8Array (Bytes.alloc (0));
		
		return lime_audio_load (bytes, audioBuffer);
		
		#else
		
		var data:Dynamic = lime_audio_load (bytes, null);
		
		if (data != null) {
			
			var audioBuffer = new AudioBuffer ();
			audioBuffer.bitsPerSample = data.bitsPerSample;
			audioBuffer.channels = data.channels;
			audioBuffer.data = new UInt8Array (@:privateAccess new Bytes (data.data.length, data.data.b));
			audioBuffer.sampleRate = data.sampleRate;
			return audioBuffer;
			
		}
		
		#end
		#end
		
		return null;
		
	}
	
	
	public static function fromFile (path:String):AudioBuffer {
		
		if (path == null) return null;
		
		#if (js && html5 && howlerjs)
		
		var audioBuffer = new AudioBuffer ();
		audioBuffer.__srcHowl = new Howl ({ src: [ path ] });
		return audioBuffer;
		
		#elseif lime_console
		
		var mode = StringTools.endsWith(path, ".wav") ? FMODMode.LOOP_OFF : FMODMode.LOOP_NORMAL;
		var sound:FMODSound = FMODSound.fromFile (path, mode);
		
		if (sound.valid) {
			
			// TODO(james4k): AudioBuffer needs sound info filled in
			// TODO(james4k): probably move fmod.Sound creation to AudioSource,
			// and keep AudioBuffer as raw data. not as efficient for typical
			// use, but probably less efficient to do complex copy-on-read
			// mechanisms and such. also, what do we do for compressed sounds?
			// usually don't want to decompress large music files. I suppose we
			// can specialize for those and not allow data access.
			var audioBuffer = new AudioBuffer ();
			audioBuffer.bitsPerSample = 0;
			audioBuffer.channels = 1;
			audioBuffer.data = null;
			audioBuffer.sampleRate = 0;
			audioBuffer.__srcFMODSound = sound;
			cpp.vm.Gc.setFinalizer (audioBuffer, cpp.Function.fromStaticFunction (finalize));
			return audioBuffer;
			
		}
		
		#elseif (lime_cffi && !macro)
		#if !cs
		
		var audioBuffer = new AudioBuffer ();
		audioBuffer.data = new UInt8Array (Bytes.alloc (0));
		
		return lime_audio_load (path, audioBuffer);
		
		#else
		
		var data:Dynamic = lime_audio_load (path, null);
		
		if (data != null) {
			
			var audioBuffer = new AudioBuffer ();
			audioBuffer.bitsPerSample = data.bitsPerSample;
			audioBuffer.channels = data.channels;
			audioBuffer.data = new UInt8Array (@:privateAccess new Bytes (data.data.length, data.data.b));
			audioBuffer.sampleRate = data.sampleRate;
			return audioBuffer;
			
		}
		
		#end
		#end
		
		return null;
		
	}
	
	
	public static function fromFiles (paths:Array<String>):AudioBuffer {
		
		#if (js && html5 && howlerjs)
		
		var audioBuffer = new AudioBuffer ();
		audioBuffer.__srcHowl = new Howl ({ src: paths });
		return audioBuffer;
		
		#else
		
		var buffer = null;
		
		for (path in paths) {
			
			buffer = AudioBuffer.fromFile (path);
			if (buffer != null) break;
			
		}
		
		return buffer;
		
		#end
		
	}
	
	
	public static function fromURL (url:String, handler:AudioBuffer->Void):Void {
		
		if (url != null && url.indexOf ("http://") == -1 && url.indexOf ("https://") == -1) {
			
			handler (AudioBuffer.fromFile (url));
			
		} else {
			
			// TODO: Support streaming sound
			
			#if flash
			
			var loader = new flash.net.URLLoader ();
			loader.addEventListener (flash.events.Event.COMPLETE, function (_) {
				handler (AudioBuffer.fromBytes (cast loader.data));
			});
			loader.addEventListener (flash.events.IOErrorEvent.IO_ERROR, function (_) {
				handler (null);
			});
			loader.load (new flash.net.URLRequest (url));
			
			#else
			
			//var loader = new URLLoader ();
			//loader.onComplete.add (function (_) {
				//var bytes = Bytes.ofString (loader.data);
				//handler (AudioBuffer.fromBytes (bytes));
			//});
			//loader.onIOError.add (function (_, msg) {
				//handler (null);
			//});
			//loader.load (new URLRequest (url));
			
			#end
			
		}
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_src ():Dynamic {
		
		#if (js && html5)
		#if howlerjs
		
		return __srcHowl;
		
		#else
		
		return __srcAudio;
		
		#end
		#elseif flash
		
		return __srcSound;
		
		#elseif lime_console
		
		return __srcFMODSound;
		
		#else
		
		return __srcCustom;
		
		#end
		
	}
	
	
	private function set_src (value:Dynamic):Dynamic {
		
		#if (js && html5)
		#if howlerjs
		
		return __srcHowl = value;
		
		#else
		
		return __srcAudio = value;
		
		#end
		#elseif flash
		
		return __srcSound = value;
		
		#elseif lime_console
		
		return __srcFMODSound = value;
		
		#else
		
		return __srcCustom = value;
		
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (lime_cffi && !macro)
	@:cffi private static function lime_audio_load (data:Dynamic, buffer:Dynamic):Dynamic;
	#end
	
	
}