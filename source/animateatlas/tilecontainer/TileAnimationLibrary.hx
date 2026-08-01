package animateatlas.tilecontainer;

import openfl.display.Tileset;
import haxe.Constraints.Constructible;
import openfl.display.BitmapData;
import animateatlas.JSONData.AnimationData;
import animateatlas.JSONData.ElementData;
import animateatlas.JSONData.LayerFrameData;
import animateatlas.JSONData.LayerData;
import animateatlas.JSONData.SymbolTimelineData;
import animateatlas.JSONData.Matrix3DData;
import animateatlas.JSONData.AtlasData;
import animateatlas.JSONData.SymbolData;
import animateatlas.JSONData.SpriteData;
import animateatlas.HelperEnums.LoopMode;
import animateatlas.HelperEnums.SymbolType;
import openfl.errors.ArgumentError;

/**
 * Since we can extract symbols from the exported timeline and instance them separatedly, this keeps track of all symbols.
 * Also, this is a "more readable" way of understanding the AnimationData
 */
class TileAnimationLibrary {
	public var frameRate:Float;

	private var _atlas:Map<String, SpriteData>;
	private var _symbolData:Map<String, SymbolData>;
	private var _symbolPool:Map<String, Array<TileContainerSymbol>>;
	private var _defaultSymbolName:String;
	private var _texture:Tileset;

	public static inline var BITMAP_SYMBOL_NAME:String = "___atlas_sprite___";

	private static var STD_MATRIX3D_DATA:Matrix3DData = {
		m00: 1,
		m01: 0,
		m02: 0,
		m03: 0,
		m10: 0,
		m11: 1,
		m12: 0,
		m13: 0,
		m20: 0,
		m21: 0,
		m22: 1,
		m23: 0,
		m30: 0,
		m31: 0,
		m32: 0,
		m33: 1
	};

	public function new(data:AnimationData, atlas:AtlasData, texture:BitmapData) {
		parseAnimationData(data);
		parseAtlasData(atlas);
		_texture = new Tileset(texture);
		_symbolPool = new Map();
	}

	public function hasAnimation(name:String):Bool {
		return hasSymbol(name);
	}

	public function createAnimation(symbol:String = null):TileContainerMovieClip {
		symbol = (symbol != null) ? symbol : _defaultSymbolName;
		if (!hasSymbol(symbol)) {
			throw new ArgumentError("Symbol not found: " + symbol);
		}
		return new TileContainerMovieClip(getSymbol(symbol));
	}

	public function getAnimationNames(prefix:String = ""):Array<String> {
		var out = new Array<String>();

		for (name in _symbolData.keys()) {
			if (name != BITMAP_SYMBOL_NAME && name.indexOf(prefix) == 0) {
				out.push(name);
			}
		}

		// but... why?
		out.sort(function(a1, a2):Int {
			a1 = a1.toLowerCase();
			a2 = a2.toLowerCase();
			if (a1 < a2) {
				return -1;
			} else if (a1 > a2) {
				return 1;
			} else {
				return 0;
			}
		});
		return out;
	}

	private function getSpriteData(name:String):SpriteData {
		return _atlas.get(name);
	}

	private function hasSymbol(name:String):Bool {
		return _symbolData.exists(name);
	}

	// # region Pooling
	// todo migrate this to lime pool

	@:access(animateatlas)
	private function getSymbol(name:String):TileContainerSymbol {
		var pool:Array<TileContainerSymbol> = getSymbolPool(name);
		if (pool.length == 0) {
			return new TileContainerSymbol(getSymbolData(name), this, _texture);
		} else {
			return pool.pop();
		}
	}

	private function putSymbol(symbol:TileContainerSymbol):Void {
		symbol.reset();
		var pool:Array<TileContainerSymbol> = getSymbolPool(symbol.symbolName);
		pool.push(symbol);
		symbol.currentFrame = 0;
	}

	private function getSymbolPool(name:String):Array<TileContainerSymbol> {
		var pool:Array<TileContainerSymbol> = _symbolPool.get(name);
		if (pool == null) {
			pool = [];
			_symbolPool.set(name, pool);
		}
		return pool;
	}

	// # end region
	// # region helpers
	private static function convertSymbol2022(symbol2022:animateatlas.JSONData.Animate2022Data):SymbolData {
		var convertedLayers:Array<LayerData> = [];

		for (layer2022 in symbol2022.TL.L) {
			var convertedFrames:Array<LayerFrameData> = [];

			for (frame2022 in layer2022.FR) {
				var convertedElements:Array<ElementData> = [];

				for (element2022 in frame2022.E) {
					if (element2022.ASI != null) {
						var m = element2022.ASI.M3D;
						convertedElements.push({
							ATLAS_SPRITE_instance: {
								name: element2022.ASI.N,
								Position: { x: 0, y: 0 },
								Matrix3D: {
									m00: m[0], m01: m[1], m02: m[2], m03: m[3],
									m10: m[4], m11: m[5], m12: m[6], m13: m[7],
									m20: m[8], m21: m[9], m22: m[10], m23: m[11],
									m30: m[12], m31: m[13], m32: m[14], m33: m[15]
								}
							}
						});
					} else if (element2022.SI != null) {
						var m = element2022.SI.M3D;
						convertedElements.push({
							SYMBOL_Instance: {
								SYMBOL_name: element2022.SI.SN,
								Instance_Name: element2022.SI.IN,
								symbolType: element2022.SI.ST,
								firstFrame: element2022.SI.FF,
								loop: LoopMode.LOOP,
								transformationPoint: { x: 0, y: 0 },
								bitmap: null,
								Matrix3D: {
									m00: m[0], m01: m[1], m02: m[2], m03: m[3],
									m10: m[4], m11: m[5], m12: m[6], m13: m[7],
									m20: m[8], m21: m[9], m22: m[10], m23: m[11],
									m30: m[12], m31: m[13], m32: m[14], m33: m[15]
								}
							}
						});
					}
				}

				convertedFrames.push({
					index: frame2022.I,
					duration: frame2022.DU,
					elements: convertedElements
				});
			}

			convertedLayers.push({
				Layer_name: layer2022.LN,
				Frames: convertedFrames,
				FrameMap: null
			});
		}

		return {
			SYMBOL_name: symbol2022.SN != null && symbol2022.SN != "" ? symbol2022.SN : symbol2022.N,
			TIMELINE: {
				LAYERS: convertedLayers
			}
		};
	}

	private function parseAnimationData(data:AnimationData):Void {
		if (data.MD != null && data.MD.FRT != null && data.MD.FRT > 0) {
			frameRate = data.MD.FRT;
		} else if (data.metadata != null && data.metadata.framerate != null && data.metadata.framerate > 0) {
			frameRate = data.metadata.framerate;
		} else {
			frameRate = 24;
		}

		_symbolData = new Map();
		if (data.AN != null) {
			data.ANIMATION = convertSymbol2022(data.AN);

			if (data.SYMBOL_DICTIONARY == null) {
				data.SYMBOL_DICTIONARY = { Symbols: [] };
			}
			if (data.SD != null && data.SD.S != null) {
				for (subSymbol2022 in data.SD.S) {
					data.SYMBOL_DICTIONARY.Symbols.push(convertSymbol2022(cast subSymbol2022));
				}
			}
		}
		var symbols = data.SYMBOL_DICTIONARY.Symbols;
		for (symbolData in symbols) {
			_symbolData[symbolData.SYMBOL_name] = preprocessSymbolData(symbolData);
		}

		var defaultSymbolData:SymbolData = preprocessSymbolData(data.ANIMATION);
		_defaultSymbolName = defaultSymbolData.SYMBOL_name;
		_symbolData.set(_defaultSymbolName, defaultSymbolData);

		_symbolData.set(BITMAP_SYMBOL_NAME, {
			SYMBOL_name: BITMAP_SYMBOL_NAME,
			TIMELINE: {
				LAYERS: []
			}
		});
	}

	private function preprocessSymbolData(symbolData:SymbolData):SymbolData {
		var timeLineData:SymbolTimelineData = symbolData.TIMELINE;
		var layerDates:Array<LayerData> = timeLineData.LAYERS;

		if (!timeLineData.sortedForRender) {
			timeLineData.sortedForRender = true;
			layerDates.reverse();
		}

		for (layerData in layerDates) {
			var frames:Array<LayerFrameData> = layerData.Frames;

			for (frame in frames) {
				var elements:Array<ElementData> = frame.elements;
				for (e in 0...elements.length) {
					var element:ElementData = elements[e];
					if (element.ATLAS_SPRITE_instance != null) {
						var matrix = element.ATLAS_SPRITE_instance.Matrix3D != null ? element.ATLAS_SPRITE_instance.Matrix3D : STD_MATRIX3D_DATA;
						
						element = elements[e] = {
							SYMBOL_Instance: {
								SYMBOL_name: BITMAP_SYMBOL_NAME,
								Instance_Name: "InstName",
								bitmap: element.ATLAS_SPRITE_instance,
								symbolType: SymbolType.GRAPHIC,
								firstFrame: 0,
								loop: LoopMode.LOOP,
								transformationPoint: { x: 0, y: 0 },
								Matrix3D: matrix
							}
						};
					}
				}
			}
		}

		return symbolData;
	}

	private function parseAtlasData(atlas:AtlasData):Void {
		_atlas = new Map<String, SpriteData>();
		if (atlas.ATLAS != null && atlas.ATLAS.SPRITES != null) {
			for (s in atlas.ATLAS.SPRITES) {
				_atlas.set(s.SPRITE.name, s.SPRITE);
			}
		}
	}

	private function getSymbolData(name:String):SymbolData {
		return _symbolData.get(name);
	}

	// # end region
}
