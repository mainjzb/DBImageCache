import 'package:bloc/bloc.dart';

class CounterCubit extends Cubit<String> {
  CounterCubit() : super("");

  void update(String data) {
    data = data.replaceAll("<br>", "\n");
    data = data.replaceAll("&nbsp;", " ");
    var result = "";

    var end = data.indexOf("【种子期限】");
    if (end >= 0) {
      result += data.substring(0, end);
    } else {
      result += data.substring(0, data.indexOf("<ignore_js_op>"));
    }

    result += data.substring(data.indexOf("<ol><li>magnet") + 8, data.indexOf('</li></ol>'));
    result += "\n\n";
    // extract image
    var start = 0;
    end = 0;
    for (;;) {
      start = data.indexOf("<a href=", end);
      if (start == -1) break;
      end = data.indexOf('" target="_blank">下载附件</a>', start);
      result += "![](" + data.substring(start + 9, end) + ")\n\n";
    }

    emit(result);
  }
}
