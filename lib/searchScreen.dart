import 'dart:async';
import 'dart:ffi';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:taxi_booking_app/main.dart';

import 'mapScreen.dart';

void main(List<String> args) {
  runApp(const SearchScreen());
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // String? uid;
  TextEditingController startingpointcontroller = TextEditingController();
  TextEditingController destinationcontroller = TextEditingController();

  DetailsResult? startPosition;
  DetailsResult? endPosition;

  late FocusNode startFocusNode;
  late FocusNode endFocusNode;

  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  Timer? _debounce;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    String apikey = 'AIzaSyBOkMeA9twGGfnr4A-oIRToqLiIhmMSzg0';
    googlePlace = GooglePlace(apikey);

    startFocusNode = FocusNode();
    endFocusNode = FocusNode();
    // uid = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    startFocusNode.dispose();
    endFocusNode.dispose();
  }

//the method to call the api
  void autoCompleteSearch(String value) async {
    var result = await googlePlace.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted) {
      print(result.predictions!.first.description);
      setState(() {
        predictions = result.predictions!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[95],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) {
                    //the api is called after 1sec to avoid
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 1000), () {
                      if (value.isNotEmpty) {
                        //if the textfield is not empty call the places api to make suggestions .
                        autoCompleteSearch(value);
                      } else {
                        //if it is empty then clear out all suggestions.
                        setState(() {
                          predictions = [];
                          startPosition = null;
                        });
                      }
                    });
                  },
                  controller: startingpointcontroller,
                  showCursor: true,
                  autocorrect: false,
                  autofocus: false,
                  focusNode: startFocusNode,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      //the suffix icon only appears when the textfield is not Empty
                      suffixIcon: startingpointcontroller.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  predictions = [];
                                  startingpointcontroller.clear();
                                });
                              },
                              icon: Icon(Icons.clear))
                          : null,
                      prefixIcon: Icon(
                        Icons.search,
                        size: 30,
                        color: Colors.grey[700],
                      ),
                      hintText: 'Starting Point',
                      hintStyle: TextStyle(
                        fontSize: 24,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) {
                    //the api is called after 1sec to avoid
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 1000), () {
                      if (value.isNotEmpty) {
                        //if the textfield is not empty call the places api to make suggestions .
                        autoCompleteSearch(value);
                      } else {
                        //if it is empty then clear out all suggestions.
                        setState(() {
                          predictions = [];
                          endPosition = null;
                        });
                      }
                    });
                  },
                  controller: destinationcontroller,
                  showCursor: true,
                  autocorrect: false,
                  focusNode: endFocusNode,
                  autofocus: false,
                  enabled: startingpointcontroller.text.isNotEmpty &&
                      startPosition != null,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        //the suffix icon only appears when the textfield is not Empty
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      suffixIcon: startingpointcontroller.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  predictions = [];
                                  startingpointcontroller.clear();
                                });
                              },
                              icon: Icon(Icons.clear))
                          : null,
                      hintText: 'Destination',
                      hintStyle: TextStyle(
                        fontSize: 24,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: predictions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                        title: Text(
                          predictions[index].description.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Icon(
                            Icons.pin_drop,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        onTap: () async {
                          final placeId = predictions[index].placeId!;
                          final details =
                              await googlePlace.details.get(placeId);
                          if (details != null &&
                              details.result != null &&
                              mounted) {
                            if (startFocusNode.hasFocus) {
                              setState(() {
                                startPosition = details.result;
                                startingpointcontroller.text =
                                    details.result!.name!;
                                predictions = [];
                              });
                            } else {
                              setState(() {
                                endPosition = details.result;
                                destinationcontroller.text =
                                    details.result!.name!;
                                predictions = [];
                              });
                            }

                            if (startPosition != null && endPosition != null) {
                              print('navigate');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Mapscreen(
                                      startPosition: startPosition,
                                      endPosition: endPosition),
                                ),
                              );
                            }
                          }
                        });
                  }),
              Center(
                child: // In your Flutter code
                    Image.asset(
                  'assets/search.jpg',
                  width: 200,
                  height: 200,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
