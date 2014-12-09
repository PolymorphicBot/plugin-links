library links;

import 'package:http/http.dart' as http;
import "package:irc/client.dart";

import 'package:html5lib/parser.dart' as html5 show parse;

import 'package:polymorphic_bot/api.dart';

BotConnector bot;
EventManager eventManager;

void main(List<String> args, port) {
  print("[Links] Loading Plugin");
  bot = new BotConnector(port);

  eventManager = bot.createEventManager();
  
  eventManager.on("message").listen(handleMessage);
}

final RegExp LINK_REGEX = new RegExp(r'\(?\b((http|https)://|www[.])[-A-Za-z0-9+&@#/%?=~_()|!:,.;]*[-A-Za-z0-9+&@#/%=~_()|]');
final RegExp NO_SPECIAL_CHARS = new RegExp(r'''[^\w`~!@#$%^&*()\-_=+\[\]:'",<.>/?\\| ]''');
final RegExp NO_MULTI_SPACES = new RegExp(r' {2,}');
final RegExp YT_LINK = new RegExp(r'^.*(youtu.be/|v/|embed/|watch\?|youtube.com/user/[^#]*#([^/]*?/)*)\??v?=?([^#\&\?]*).*');

void handleMessage(data) {
  var msg = data['message'];
  if (LINK_REGEX.hasMatch(msg)) {
    for (var match in LINK_REGEX.allMatches(msg)) {

      var url = match.group(0);

      if (url.contains("github.com/")) {
        return;
      }
      
      if (YT_LINK.hasMatch(url)) return;

      http.get(url).then((http.Response response) {
        if (response.statusCode != 200) {
          return;
        }
        
        try {
          var document = html5.parse(response.body);

          if (document == null) {
            return;
          }

          var title = document.querySelector('title').text;

          if (title == null || title.isEmpty) {
            return;
          }

          title = title.replaceAll(NO_SPECIAL_CHARS, ' ').replaceAll(NO_MULTI_SPACES, ' ');

          bot.message(data['network'], data['target'], "[${Color.BLUE}Link Title${Color.RESET}] ${title}");
        } catch (e) {}
      }).catchError((e) {});
    }
  }
}
