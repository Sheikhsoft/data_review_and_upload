library data_review_and_upload;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as Math;
import 'package:async/async.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as Img;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'map_box.dart';
import 'prograss_indicator.dart';
import 'utils.dart';

class DataReviewAndUpload extends StatefulWidget {
  final Map mapData;
  final Widget container;
  final String apiUrl;

  const DataReviewAndUpload(
      {Key key, this.mapData, this.container, this.apiUrl})
      : super(key: key);

  @override
  _DataReviewAndUploadState createState() => _DataReviewAndUploadState();
}

class _DataReviewAndUploadState extends State<DataReviewAndUpload> {
  ProgressDialog pr;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    pr = new ProgressDialog(context, ProgressDialogType.Normal);
    pr.setMessage('Please wait...');
    return Scaffold(
      body: Container(
        child: Stack(
          children: <Widget>[
            widget.container != null ? widget.container : Container(),
            Container(
              height: double.infinity,
              width: double.infinity,
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: 80.0, left: 25.0, right: 25.0),
              child: Column(
                children: <Widget>[
                  Text(
                    "Incident Summary",
                    style:
                        TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                  ),
                  _bulidRow("What Happend", widget.mapData['incidentType']),
                  _bulidRow("Priority", widget.mapData['priority']),
                  _bulidRow("Date", widget.mapData['date']),
                  _bulidRow("Time", widget.mapData['time']),
                  _bulidColum("Injured Body Part", widget.mapData['bodyPart']),
                  _loadMap()
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(10.0),
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                backgroundColor: Colors.black87,
                child: Icon(Icons.send),
                onPressed: () async {
                  pr.show();
                  await upload(widget.mapData['image'], context);
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home', (Route<dynamic> route) => false);
                },
              ),
            ),
            MyBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _bulidRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(left: 25.0, top: 16.0, right: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _bulidColum(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(left: 25.0, top: 16.0, right: 25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _loadMap() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: MapBox(
        latitude: double.parse(widget.mapData['latitude']),
        longitude: double.parse(widget.mapData['longitude']),
      ),
    );
  }

  Future upload(String imagePath, BuildContext context) async {
    var uri = Uri.parse(widget.apiUrl);

    var request = new http.MultipartRequest("POST", uri);

    if (imagePath != null) {
      File imageFile = new File(imagePath);
      final tempDir = await getTemporaryDirectory();
      final path = tempDir.path;

      int rand = new Math.Random().nextInt(100000);

      Img.Image image = Img.decodeImage(imageFile.readAsBytesSync());
      Img.Image smallerImg = Img.copyResize(image, 500);

      var compressImg = new File("$path/image_$rand.jpg")
        ..writeAsBytesSync(Img.encodeJpg(smallerImg, quality: 85));
      var stream =
          new http.ByteStream(DelegatingStream.typed(compressImg.openRead()));
      var length = await compressImg.length();
      var multipartFile = new http.MultipartFile("image", stream, length,
          filename: basename(compressImg.path));
      request.files.add(multipartFile);
    }

    request.fields['priority'] = widget.mapData['priority'];
    request.fields['incidentType'] = widget.mapData['incidentType'];
    request.fields['bodyPart'] = widget.mapData['bodyPart'];
    request.fields['date'] = widget.mapData['date'];
    request.fields['time'] = widget.mapData['time'];
    request.fields['latitude'] = widget.mapData['latitude'];
    request.fields['longitude'] = widget.mapData['longitude'];

    var response = await request.send();

    if (response.statusCode == 200) {
      print("Insert Into Database");

      //Navigator.pop(context, ModalRoute.withName('/home'));
    } else {
      print("Insert Not Successfull");
    }
    response.stream.transform(utf8.decoder).listen((value) {
      print(value);
    });
  }
}
