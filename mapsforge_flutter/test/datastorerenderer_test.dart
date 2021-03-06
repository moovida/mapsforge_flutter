import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/cache/filesymbolcache.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

import 'testassetbundle.dart';

///
/// flutter test --update-goldens
///
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _initLogging();
  });

  ///
  /// Test one single tile
  testWidgets('MapDataStoreRenderer', (WidgetTester tester) async {
    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );

    double tileSize = displayModel.tileSize;
    int l = 0;
    int z = 16;
    int x = MercatorProjectionImpl(tileSize, z).longitudeToTileX(7.4262); // lat/lon: 43.7399/7.4262;
    int y = MercatorProjectionImpl(tileSize, z).latitudeToTileY(43.7399);

    SymbolCache symbolCache = FileSymbolCache(TestAssetBundle());
    GraphicFactory graphicFactory = FlutterGraphicFactory(symbolCache);
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel);
    String content = await TestAssetBundle().loadString("rendertheme.xml");
    renderThemeBuilder.parseXml(content);
    RenderTheme renderTheme = renderThemeBuilder.build();

    var img = await tester.runAsync(() async {
      MapFile mapDataStore = MapFile(TestAssetBundle().correctFilename("monaco.map"), 0, "en");
      await mapDataStore.init();
      MercatorProjectionImpl mercatorProjection = MercatorProjectionImpl(256, z);
      Tile tile = new Tile(x, y, z, l);
      print("Reading tile ${tile.toString()}");
      Job mapGeneratorJob = new Job(tile, false, displayModel.getUserScaleFactor(), displayModel.tileSize);
      MapDataStoreRenderer _dataStoreRenderer = MapDataStoreRenderer(mapDataStore, renderTheme, graphicFactory, false);

      TileBitmap resultTile = await _dataStoreRenderer.executeJob(mapGeneratorJob);
      assert(resultTile != null);
      var img = (resultTile as FlutterTileBitmap).bitmap;
//      ByteData bytes = await img.toByteData(format: ImageByteFormat.png);
//      assert(bytes != null);
      return img;
    });

    assert(img != null);
//    print("Resulting tile has ${bytes.buffer.lengthInBytes} byte");
//    File resFile = File("store.png");
//    IOSink sink = resFile.openWrite();
//    resFile.writeAsBytes(bytes.buffer.asUint8List());
//    sink.close();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: RawImage(
              image: img,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    //await tester.pump();
    await expectLater(find.byType(RawImage), matchesGoldenFile('datastorerenderer.png'));
  });

  testWidgets('MapDataStoreRendererMultiple', (WidgetTester tester) async {
    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 15,
    );

    String prefix = "../";
    double tileSize = displayModel.tileSize;
    int l = 0;
    int z = 15;
    int x = MercatorProjectionImpl(tileSize, z).longitudeToTileX(7.4262); // lat/lon: 43.7399/7.4262;
    int y = MercatorProjectionImpl(tileSize, z).latitudeToTileY(43.7399);

    tester.binding.window.physicalSizeTestValue = Size(tileSize * 9, tileSize * 9);
// resets the screen to its orinal size after the test end
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    MercatorProjectionImpl mercatorProjection = MercatorProjectionImpl(256, z);

    List<Tile> tilesToLoad = [
      Tile(x - 1, y - 1, z, l),
      Tile(x, y - 1, z, l),
      Tile(x + 1, y - 1, z, l),
      Tile(x - 1, y, z, l),
      Tile(x, y, z, l),
      Tile(x + 1, y, z, l),
      Tile(x - 1, y + 1, z, l),
      Tile(x, y + 1, z, l),
      Tile(x + 1, y + 1, z, l),
    ];

    SymbolCache symbolCache = FileSymbolCache(TestAssetBundle());
    GraphicFactory graphicFactory = FlutterGraphicFactory(symbolCache);
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel);
    //final file = new File(prefix + 'test_resources/rendertheme.xml');
    //String content = file.readAsStringSync();
    String content = await TestAssetBundle().loadString("rendertheme.xml");
    renderThemeBuilder.parseXml(content);
    RenderTheme renderTheme = renderThemeBuilder.build();

    List imgs = await tester.runAsync(() async {
      MapFile mapDataStore = MapFile(prefix + "test_resources/monaco.map", 0, "en");
      await mapDataStore.init();

      MapDataStoreRenderer _dataStoreRenderer = MapDataStoreRenderer(mapDataStore, renderTheme, graphicFactory, false);
      List imgs = List();
      for (Tile tile in tilesToLoad) {
        print("Reading tile ${tile.toString()}");
        Job mapGeneratorJob = new Job(tile, false, displayModel.getUserScaleFactor(), displayModel.tileSize);
        TileBitmap resultTile = await _dataStoreRenderer.executeJob(mapGeneratorJob);
        assert(resultTile != null);
        var img = (resultTile as FlutterTileBitmap).bitmap;
        imgs.add(img);
      }

//      ByteData bytes = await img.toByteData(format: ImageByteFormat.png);
//      assert(bytes != null);
      return imgs;
    });

    assert(imgs != null && imgs.length == tilesToLoad.length);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: SizedBox(
            width: tileSize * 3,
            height: tileSize * 3,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    RawImage(image: imgs[0]),
                    RawImage(image: imgs[1]),
                    RawImage(image: imgs[2]),
                  ],
                ),
                Row(
                  children: <Widget>[
                    RawImage(image: imgs[3]),
                    RawImage(image: imgs[4]),
                    RawImage(image: imgs[5]),
                  ],
                ),
                Row(
                  children: <Widget>[
                    RawImage(image: imgs[6]),
                    RawImage(image: imgs[7]),
                    RawImage(image: imgs[8]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    //await tester.pump();
    await expectLater(find.byType(SizedBox), matchesGoldenFile('datastorerenderermulti.png'));
  });
}

void _initLogging() {
// Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });

// Root logger level.
  Logger.root.level = Level.FINEST;
}
