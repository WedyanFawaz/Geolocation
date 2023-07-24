
import 'package:flutter/material.dart';
import 'package:flutter_application_glocation/s3.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Set<Marker> markers={};
class CurrentLoc extends StatefulWidget {
  
  const CurrentLoc({super.key});

 
 // final String title;
  

  @override
  State<CurrentLoc> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<CurrentLoc> {
    late GoogleMapController mapController;
    final LatLng _center = const LatLng(20.42796133580664, 80.885749655962);

    void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }





  @override
  Widget build(BuildContext context) {
  
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      
       
      ),
      body:GoogleMap(
        onMapCreated: _onMapCreated,
        markers: markers,
          initialCameraPosition: CameraPosition (
            target: _center,
            zoom: 11.0,
          ),
    
        
      ),
    floatingActionButton:Container(
      alignment: Alignment.bottomLeft,
      padding: EdgeInsets.symmetric(horizontal: 25,vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(onPressed: () async{
            Position position=await _determinePisition();
            
            mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target:LatLng(position.latitude,position.longitude),zoom: 14)));
            
            markers.clear();
    
            markers.add( Marker(markerId: const MarkerId("current loaction"),position:LatLng(position.latitude, position.longitude)));
    
            setState(() {
              
            });
            
    
    
          }
          
          ,label: const Text("Current location"),
          
          icon:const Icon(Icons.location_history),
          ),
          Container(
            margin: EdgeInsets.all(15),
            child: FloatingActionButton(onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (context)=> DistanceMeasure()));}, child: Text('Distance measure')))
        ],
      ),

      
    ),
    
    
    );
  }
  Future<Position>_determinePisition() async{
    bool sereviceEnabled;
    LocationPermission userPermission;

    sereviceEnabled=await Geolocator.isLocationServiceEnabled();
    

    if(!sereviceEnabled){
      return Future.error("Location services are disabled !");
    }
    userPermission=await Geolocator.checkPermission();
    if(userPermission == LocationPermission.denied){
      userPermission=await Geolocator.requestPermission();
      if(userPermission==LocationPermission.denied){
        return Future.error("Location services are disabled !");
      }
    }
    if(userPermission == LocationPermission.deniedForever){
      return Future.error("Location services are permantly denied !");
    }
    Position position=await Geolocator.getCurrentPosition();
    return position;

  }
}
