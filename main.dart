import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(MyApp());
}

enum SearchType {
  StartWith,
  EndWith,
  Contains,
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rhymes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class RhymesData {
  final String tf;
  final String id;
  final String en;

  RhymesData({
    required this.tf,
    required this.id,
    required this.en,
  });
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController searchController = TextEditingController();
  List<RhymesData> data = [];
  List<RhymesData> filteredData = [];
  List<RhymesData> paginatedData = [];
  int currentPage = 1;
  int pageSize = 15;
  bool isLoading = true;
  SearchType searchType = SearchType.StartWith;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      String jsonString = await rootBundle.loadString('assets/rhymes.json');
      List<dynamic> jsonData = jsonDecode(jsonString);

      setState(() {
        data = jsonData.map((item) {
          return RhymesData(
            tf: item['TF'] ?? '',
            id: item['ID'] ?? '',
            en: item['EN'] ?? '',
          );
        }).toList();
      });

      filterData();
      paginateData();
    } catch (error) {
      showToast('Failed to load data');
    }

    setState(() {
      isLoading = false;
    });
  }

  void filterData() {
    String searchTerm = searchController.text.toLowerCase();
    List<String> searchKeywords =
        searchTerm.split(' ').map((keyword) => keyword.trim()).toList();

    setState(() {
      filteredData = data.where((entry) {
        String rhymes = entry.id.toLowerCase();
        bool containsAllKeywords = true;

        for (String keyword in searchKeywords) {
          String processedRhymes = rhymes.replaceAll('·', '');
          if (searchType == SearchType.StartWith) {
            List<String> rhymesWords = processedRhymes.split(' ');
            if (rhymesWords.length > 1) {
              String firstWordAfterSpace = rhymesWords[1];
              if (!firstWordAfterSpace.startsWith(keyword)) {
                containsAllKeywords = false;
                break;
              }
            } else {
              if (!processedRhymes.startsWith(keyword)) {
                containsAllKeywords = false;
                break;
              }
            }
          } else if (searchType == SearchType.EndWith) {
            if (!processedRhymes.endsWith(keyword)) {
              containsAllKeywords = false;
              break;
            }
          } else if (searchType == SearchType.Contains) {
            if (!processedRhymes.contains(keyword)) {
              containsAllKeywords = false;
              break;
            }
          }
        }

        return containsAllKeywords;
      }).toList();
    });

    jumpToPage(1); // Reset halaman ke 1 setiap kali pencarian diubah
  }

  void paginateData() {
    int totalItems = filteredData.length;
    int startIndex = (currentPage - 1) * pageSize;
    int endIndex = startIndex + pageSize;
    setState(() {
      paginatedData = filteredData.sublist(
        startIndex.clamp(0, totalItems),
        endIndex.clamp(0, totalItems),
      );
    });
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
    );
  }

  void jumpToPage(int page) {
    if (page >= 1 && page <= getTotalPages()) {
      setState(() {
        currentPage = page;
      });
      paginateData();
    } else {
      showToast('Invalid page number');
      setState(() {
        currentPage = 1; // Set halaman kembali ke 1 jika nomor halaman tidak valid
      });
    }
  }

  int getTotalPages() {
    return (filteredData.length / pageSize).ceil();
  }

  Future<void> loadMoreData() async {
    if (currentPage < getTotalPages()) {
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        currentPage++;
      });

      paginateData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rhymes'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<SearchType>(
                        value: SearchType.StartWith,
                        groupValue: searchType,
                        onChanged: (SearchType? value) {
                          setState(() {
                            searchType = value!;
                          });
                          filterData();
                        },
                      ),
                      Text('Start With'),
                      Radio<SearchType>(
                        value: SearchType.EndWith,
                        groupValue: searchType,
                        onChanged: (SearchType? value) {
                          setState(() {
                            searchType = value!;
                          });
                          filterData();
                        },
                      ),
                      Text('End With'),
                      Radio<SearchType>(
                        value: SearchType.Contains,
                        groupValue: searchType,
                        onChanged: (SearchType? value) {
                          setState(() {
                            searchType = value!;
                          });
                          filterData();
                        },
                      ),
                      Text('Contains'),
                    ],
                  ),
                  TextField(
                    controller: searchController,
                    onChanged: (value) {
                      filterData();
                    },
                    decoration: InputDecoration(
                      labelText: 'Search',
                    ),
                  ),
                ],
              ),
            ),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('TF')),
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('EN')),
                        ],
                        rows: paginatedData.map((data) {
                          // Mengekstrak karakter pertama dari 'TF'
                          String firstChar = data.tf.isNotEmpty ? data.tf[0] : '';

                          // Mengatur warna latar belakang sel (cell) berdasarkan karakter pertama
                          Color cellColor;
                          if (firstChar == 'T') {
                            cellColor = Colors.red; // Warna latar belakang merah untuk 'T'
                          } else if (firstChar == 'F') {
                            cellColor = Colors.green; // Warna latar belakang hijau untuk 'F'
                          } else {
                            cellColor = Colors.white; // Warna latar belakang default
                          }

                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  color: cellColor, // Atur warna latar belakang sel di sini
                                  child: Text(data.tf),
                                ),
                              ),
                              DataCell(SelectableText(data.id)),
                              DataCell(SelectableText(data.en)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.navigate_before),
              onPressed: currentPage > 1 ? () => jumpToPage(currentPage - 1) : null,
            ),
            Text('Page $currentPage of ${getTotalPages()}'),
            IconButton(
              icon: Icon(Icons.navigate_next),
              onPressed:
                  currentPage < getTotalPages() ? () => jumpToPage(currentPage + 1) : null,
            ),
            TextButton(
              onPressed: () {
                showJumpToPageDialog();
              },
              child: Text('Jump To Page'),
            ),
          ],
        ),
      ),
    );
  }

  void showJumpToPageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController jumpController = TextEditingController();

        return AlertDialog(
          title: Text('Jump To Page'),
          content: TextField(
            controller: jumpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Page Number',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                int page = int.tryParse(jumpController.text) ?? 0;
                jumpToPage(page);
                Navigator.pop(context);
              },
              child: Text('Go'),
            ),
          ],
        );
      },
    );
  }
}
