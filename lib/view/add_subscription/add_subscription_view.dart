import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:trackizer/common/color_extension.dart';
import 'package:trackizer/common_widget/primary_button.dart';
import 'package:trackizer/common_widget/round_textfield.dart';

import '../../common_widget/image_button.dart';
import 'package:trackizer/storage/storage_service.dart';

class AddSubScriptionView extends StatefulWidget {
  const AddSubScriptionView({super.key});

  @override
  State<AddSubScriptionView> createState() => _AddSubScriptionViewState();
}

class _AddSubScriptionViewState extends State<AddSubScriptionView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _iconController = TextEditingController();
  TextEditingController txtDescription = TextEditingController();


  List<Map<String, dynamic>> subArr = [];

  @override
  void initState() {
    super.initState();
    _loadSubs();
  }

  Future<void> _loadSubs() async {
    subArr = await StorageService.loadSubscriptions();
    setState(() {});
  }

  Future<void> _saveSubs() async {
    await StorageService.saveSubscriptions(subArr);
  }

  double amountVal = 0.09;

  @override
  Widget build(BuildContext context) {
  var media = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: TColor.gray,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: TColor.gray70.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25))),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: Image.asset("assets/img/back.png",
                                    width: 25,
                                    height: 25,
                                    color: TColor.gray30))
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "New",
                              style:
                                  TextStyle(color: TColor.gray30, fontSize: 16),
                            )
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "Add new\n subscription",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: TColor.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(
                      width: media.width,
                      height: media.width * 0.6,
                      child: CarouselSlider.builder(
                        options: CarouselOptions(
                          autoPlay: false,
                          aspectRatio: 1,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: true,
                          viewportFraction: 0.65,
                          enlargeFactor: 0.4,
                          enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                        ),
                        itemCount: subArr.length,
                        itemBuilder: (BuildContext context, int itemIndex,
                            int pageViewIndex) {
                          var sObj = subArr[itemIndex] as Map? ?? {};

                          return Container(
                            margin: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  sObj["icon"],
                                  width: media.width * 0.4,
                                  height: media.width * 0.4,
                                  fit: BoxFit.fitHeight,
                                ),
                                const Spacer(),
                                Text(
                                  sObj["name"],
                                  style: TextStyle(
                                      color: TColor.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
              child: RoundTextField(title: "Description", titleAlign: TextAlign.center, controller: txtDescription, )

            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ImageButton(
                    image: "assets/img/minus.png",
                    onPressed: () {

                      amountVal -= 0.1;

                      if(amountVal < 0) {
                        amountVal = 0;
                      }

                      setState(() {
                        
                      });
                    },
                  ),

                  Column(
                    children: [
                        Text(
                        "Monthly price",
                        style: TextStyle(
                            color: TColor.gray40,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),

                     const SizedBox(height: 4,),

                       Text(
                        "₹${amountVal.toStringAsFixed(2)}",
                        style: TextStyle(
                            color: TColor.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(
                        height: 8,
                      ),

                      Container(
                        width: 150,
                        height: 1,
                        color: TColor.gray70,
                      )
                    ],
                  ),

                  ImageButton(
                    image: "assets/img/plus.png",
                    onPressed: () {
                      amountVal += 0.1;

                      setState(() {});
                    },
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Platform Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _iconController,
                    decoration: InputDecoration(
                      labelText: 'Icon Path (e.g. assets/img/netflix_logo.png)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    title: "Add this platform",
                    onPressed: () async {
                      final name = _nameController.text.trim();
                      final icon = _iconController.text.trim();
                      if (name.isNotEmpty && icon.isNotEmpty) {
                        setState(() {
                          subArr.add({"name": name, "icon": icon});
                          _nameController.clear();
                          _iconController.clear();
                        });
                        await _saveSubs();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Platform added!')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter name and icon path.')));
                      }
                    }),
                  const SizedBox(height: 8),
                  Text('Current Platforms:', style: TextStyle(color: TColor.white, fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      itemCount: subArr.length,
                      itemBuilder: (context, idx) {
                        final s = subArr[idx];
                        return ListTile(
                          leading: Image.asset(s["icon"], width: 30, height: 30, errorBuilder: (c, e, s) => Icon(Icons.image_not_supported)),
                          title: Text(s["name"], style: TextStyle(color: TColor.white)),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              setState(() {
                                subArr.removeAt(idx);
                              });
                              await _saveSubs();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Platform deleted!')));
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
