import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SendRequest extends StatefulWidget{
  @override
  State<SendRequest> createState() => _SendRequestState();
}

class _SendRequestState extends State<SendRequest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        centerTitle: true,
        title: Text("ارسال استفسار"),
      ),
      body:
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
            SizedBox(height: 50,),
           TextField(
             decoration: InputDecoration(
               labelText: "العنوان",
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
               icon: Icon(Icons.text_fields)

             ),
           ),
              SizedBox(height: 30,),
              TextField(
                decoration: InputDecoration(
                    labelText: "المستلم",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    icon: Icon(Icons.location_on)
                ),
              ),
              SizedBox(height: 30,),
              TextField(
                decoration: InputDecoration(
                    labelText: "التفاصيل",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    icon: Icon(Icons.info_outline)

                ),
              ),
              SizedBox(height: 60,),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  'تأكيد الخروج',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        )
    );
  }
}