import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:resizable_widget/resizable_widget.dart';

import 'cubit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resizable Widget Example',
      theme: ThemeData.dark(),
      home: BlocProvider(
        child: const Scaffold(body: MyPage()),
        create: (_) => CounterCubit(),
      ),
    );
  }
}

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final ScrollController _controller = ScrollController();
  static const _extraScrollSpeed = 80;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      ScrollDirection scrollDirection = _controller.position.userScrollDirection;
      if (scrollDirection != ScrollDirection.idle) {
        double scrollEnd =
            _controller.offset + (scrollDirection == ScrollDirection.reverse ? _extraScrollSpeed : -_extraScrollSpeed);
        scrollEnd = min(_controller.position.maxScrollExtent, max(_controller.position.minScrollExtent, scrollEnd));
        _controller.jumpTo(scrollEnd);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterCubit, String>(
      builder: (context, count) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Container(color: Colors.greenAccent, child: const MyListView())),
          Expanded(
            flex: 3,
            child: Markdown(
              selectable: true,
              controller: _controller,
              data: count,
            ),
          )
        ],
      ),
    );
  }
}

class MyListView extends StatefulWidget {
  const MyListView({Key? key}) : super(key: key);

  @override
  State<MyListView> createState() => _MyListViewState();
}

class Item {
  String title;
  Uri url;

  Item(this.title, this.url);
}

class _MyListViewState extends State<MyListView> {
  int fid = 2;
  List<Item> postList = <Item>[];
  int page = 1;
  int length = 0;
  Item? currentButton;

  @override
  void initState() {
    super.initState();
    getList(1).then((value) {
      setState(() {
        postList = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.expand(),
      child: Stack(
        children: [
          Column(
            children: [
              Wrap(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      fid = 2;
                      getList(1).then((value) {
                        setState(() {
                          postList = value;
                        });
                      });
                    },
                    child: const Text("国产原创"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      fid = 36;
                      getList(1).then((value) {
                        setState(() {
                          postList = value;
                        });
                      });
                    },
                    child: const Text("亚洲无码"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      fid = 37;
                      getList(1).then((value) {
                        setState(() {
                          postList = value;
                        });
                      });
                    },
                    child: const Text("亚洲有码"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      fid = 103;
                      getList(1).then((value) {
                        setState(() {
                          postList = value;
                        });
                      });
                    },
                    child: const Text("高清字幕"),
                  )
                ],
              ),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(15.0),
                  children: postList
                      .map(
                        (Item item) => TextButton(
                          onPressed: () async {
                            // read post detail
                            //var postUrl = Uri.parse( 'https://sadfqewqewq.cc/thread-820538-1-1.html');
                            try {
                              Response postResponse = await get(item.url);
                              var postDocument = parse(postResponse.body);
                              var detail = postDocument
                                  .querySelector('div#postlist div table tbody tr')!
                                  .querySelector('td.t_f');
                              //print(detail!.innerHtml);
                              var data = detail!.innerHtml;

                              context.read<CounterCubit>().update(data);
                            } catch (e) {
                              print(e);
                            }
                            setState(() {
                              currentButton = item;
                            });
                          },
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.title,
                              style: currentButton == null
                                  ? null
                                  : (currentButton == item ? const TextStyle(color: Colors.red) : null),
                              softWrap: false,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 10.0,
            child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: pageButtonList(page)),
          ),
        ],
      ),
    );
  }

  // todo: remove  page paramater
  Future<List<Item>> getList(int page) async {
    var domain = 'https://sadfqewqewq.cc/';
    // read post list
    var url = Uri.parse('https://sadfqewqewq.cc/forum-$fid-$page.html');
    Response response = await get(url);
    if (response.statusCode > 299) {
      print('status code err:${response.statusCode}');
    }
    var document = parse(response.body);
    var table = document.querySelector('table#threadlisttableid');

    var result = <Item>[];
    for (var c in table!.children) {
      if (c.id.startsWith("normalthread")) {
        var data = c.querySelector("th a.s.xst");
        result.add(Item(data!.text, Uri.parse(domain + data.attributes["href"]!)));
      }
    }
    return result;
  }

  Widget pageButtonList(int page) {
    var r = <Widget>[];
    int i = (page - 3).clamp(1, 800);
    int max = i + 7;
    for (; i < max; i++) {
      int ii = i;
      r.add(ElevatedButton(
        onPressed: i == page
            ? null
            : () {
                getList(ii).then((value) {
                  setState(() {
                    postList = value;
                    this.page = ii;
                  });
                });
              },
        child: Text(
          i.toString(),
        ),
      ));
    }
    return Row(
      children: r,
    );
  }
}
