import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/datastore/mapreadresult.dart';
import 'package:mapsforge_flutter/src/mapfile/mapfile.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

import 'testassetbundle.dart';

main() async {
  //create a mapfile from .map
  MapFile mapFile =
      MapFile(TestAssetBundle().correctFilename("campus_level.map"), null, null); //Map that contains part of the Canpus Reichehainer Straße
  await mapFile.init();

  ////Maps that contain single rooms in the NHG
  MapFile N115 = MapFile(TestAssetBundle().correctFilename("N115.map"), null, null);
  await N115.init();

  MapFile N112 = MapFile(TestAssetBundle().correctFilename("N112.map"), null, null);
  await N112.init();

  MapFile NHG_WC = MapFile(TestAssetBundle().correctFilename("NHG_WC.map"), null, null);
  await NHG_WC.init();

  //x- and y-Coordinates from upperLeft- and lowerRight-Tile that define the map-area,
  //here we are using the coordinates of 4 Tiles around the NHG in Reichenhainer Straße 70, 09126
  //Coordinates and zoomlevel were taken from http://tools.geofabrik.de/map/#18/50.8137/12.9301&type=Geofabrik_Standard&grid=1&mlat=50.81374&mlon=12.92947
  int ul_x = 140486; //x of upperLeft
  int ul_y = 87974; //y of upperLeft
  int lr_x = 140487; //x of lowerRight
  int lr_y = 87975; //y of lowerRight
  int z = 18; //zoomlevel
  int iz = 18; // indoor zoomlevel
  double tileSize = 256.0; //standard tilesize
  MercatorProjectionImpl mercatorProjection = MercatorProjectionImpl(tileSize, z);

  //initialize 2 Tiles with the coordinates, zoomlevel and tilesize
  Tile upperLeft = new Tile(ul_x, ul_y, z, iz);
  Tile lowerRight = new Tile(lr_x, lr_y, z, iz);
  Tile Single = new Tile(140486, 87975, z, iz);

  //initialize MapReadResult as Container for the data of the area defined by upperLeft and lowerRight in the mapfile
  //Campus
  MapReadResult mapReadResult; //area
  mapReadResult = await mapFile.readMapData(upperLeft, lowerRight);

  //Single rooms on Campus
  MapReadResult mapReadResult_N115; //area
  mapReadResult_N115 = await mapFile.readMapData(upperLeft, lowerRight);
  MapReadResult mapReadResult_N112; //area
  mapReadResult_N112 = await mapFile.readMapData(upperLeft, lowerRight);
  MapReadResult mapReadResult_NHG_WC; //area
  mapReadResult_NHG_WC = await mapFile.readMapData(upperLeft, lowerRight);

  int j = 0; //Iterator for ways
  //print each way with its key and value in the area defined by upperLeft and lowerRight
  mapReadResult.ways.forEach((way) {
    j++;
    print("Way " + j.toString());
    //just print tags of a way
    way.tags.forEach((tag) {
      print("Key: " + tag.key);
      print("Value: " + tag.value);
    });
  });

///////////////////////////////////////////////////////////////////////////////////////////////

  //help function, that returns true, if Indoor-Data in general is found
  bool indoorPois = false;
  bool indoorWays = false;

  bool indoorDetector() {
    bool indoorDataDetector = false;
    //POI's
    mapReadResult.pointOfInterests.forEach((poi) {
      poi.tags.forEach((tag) {
        if (tag.key == "indoor") indoorPois = true;
      });
    });

    //Ways
    mapReadResult.ways.forEach((way) {
      way.tags.forEach((tag) {
        if (tag.key == "indoor") indoorWays = true;
      });
    });
    if (indoorPois && indoorWays) indoorDataDetector = true;

    return indoorDataDetector;
  }

  //help function, that returns true, if the level-tag is found
  bool levelDetector() {
    bool levelDetector = false;
    //POI's
    mapReadResult.pointOfInterests.forEach((poi) {
      poi.tags.forEach((tag) {
        if (tag.key == "level") levelDetector = true;
      });
    });
    //Ways
    mapReadResult.ways.forEach((way) {
      way.tags.forEach((tag) {
        if (tag.key == "level") levelDetector = true;
      });
    });
    return levelDetector;
  }

  //General tag detecting function
  bool objectDetected(String tagname) {
    bool objectDetector = false;
    //POI's
    mapReadResult.pointOfInterests.forEach((poi) {
      poi.tags.forEach((tag) {
        if (tag.key == tagname || tag.value == tagname) objectDetector = true; //stop search, if tag was found
        return objectDetector;
      });
    });
    //Ways
    mapReadResult.ways.forEach((way) {
      way.tags.forEach((tag) {
        if (tag.key == tagname || tag.value == tagname) objectDetector = true;
        return objectDetector; //stop search, if tag was found
      });
    });
    return objectDetector;
  }

  //Test, if Indoor-data in general is found
  test("Indoor-Data", () {
    //Arrange
    bool indoorDataDetector;

    //Act
    indoorDataDetector = indoorDetector();

    //Assert
    expect(indoorDataDetector, true);
  });

  //Test if specific tag e.g. "room" is found
  test("tagTest", () {
    bool tagdetected;

    tagdetected = objectDetected("room");

    expect(tagdetected, true);
  });

  test("doorTest", () {
    bool tagdetected;

    tagdetected = objectDetected("door");

    expect(tagdetected, true);
  });

  //Test if tag "steps" is found
  test("stepsTest", () {
    bool tagdetected;

    tagdetected = objectDetected("steps");

    expect(tagdetected, true);
  });

  //Test if tag "room" is found
  test("roomTest", () {
    bool tagdetected;

    tagdetected = objectDetected("room");

    expect(tagdetected, true);
  });

// currently not working, because tags are not yet in the .map-file

  //Test if level-tag is found
  /*test("Level-Test", () {
    //Arrange
    bool levelDetected;

    //Act
    levelDetected = levelDetector();

    //Assert
    expect(levelDetected, true);
  });

    //Test if tag "surface" is found
   test ("surfaceTest", (){
    bool tagdetected;

    tagdetected= objectDetected("surface");

    expect(tagdetected, true);
  });

   //Test if tag "tactile_paving" is found
   test ("Test", (){
    bool tagdetected;

    tagdetected= objectDetected("tactile_paving");

    expect(tagdetected, true);
  });

   //Test if tag "wheelchair" is found
   test ("wheelchairTest", (){
    bool tagdetected;

    tagdetected= objectDetected("wheelchair");

    expect(tagdetected, true);
  });

   //Test if tag "incline" is found
   test ("inclineTest", (){
    bool tagdetected;

    tagdetected= objectDetected("incline");

    expect(tagdetected, true);
  });

  //Test if tag "handrail" is found
   test ("handrailTest", (){
    bool tagdetected;

    tagdetected= objectDetected("handrail");

    expect(tagdetected, true);
  });

  //Test if tag "access" is found
   test ("accessTest", (){
    bool tagdetected;

    tagdetected= objectDetected("access");

    expect(tagdetected, true);
  });

  //Test if tag "elevator" is found
   test ("elevatorTest", (){
    bool tagdetected;

    tagdetected= objectDetected("elevator");

    expect(tagdetected, true);
  });

  //Test if tag "corridor" is found
   test ("corridorTest", (){
    bool tagdetected;

    tagdetected= objectDetected("corridor");

    expect(tagdetected, true);
  });

  //Test if tag "step_count" is found
   test ("step_countTest", (){
    bool tagdetected;

    tagdetected= objectDetected("step_count");

    expect(tagdetected, true);
  });

  //Test if tag "doorhandle" is found
   test ("doorhandleTest", (){
    bool tagdetected;

    tagdetected= objectDetected("doorhandle");

    expect(tagdetected, true);
  });

   //Test if tag "staircase" is found
   test ("staircaseTest", (){
    bool tagdetected;

    tagdetected= objectDetected("staircase");

    expect(tagdetected, true);
  });

   //Test if tag "contact" is found
   test ("contactTest", (){
    bool tagdetected;

    tagdetected= objectDetected("contact");

    expect(tagdetected, true);
  });
  */
}
