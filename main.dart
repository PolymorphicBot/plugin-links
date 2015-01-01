library links;

import 'dart:async';

import 'package:http/http.dart' as http;
import "package:irc/client.dart" as IRC;

import 'package:html5lib/parser.dart' as html5 show parse;

import 'package:polymorphic_bot/api.dart';

BotConnector bot;

void main(List<String> args, Plugin plugin) {
  print("[Links] Loading Plugin");
  bot = plugin.getBot();
  
  plugin.addRemoteMethod("getLinkTitle", (call) {
    getLinkTitle(call.getArgument("value")).then((title) {
      call.reply(title);
    }).catchError((e) {
      call.reply(null);
    });
  });

  bot.onMessage((event) => handleMessage(event));
}

final RegExp LINK_REGEX = new RegExp(r'\(?\b((http|https)://|www[.])[-A-Za-z0-9+&@#/%?=~_()|!:,.;]*[-A-Za-z0-9+&@#/%=~_()|]');
final RegExp NO_SPECIAL_CHARS = new RegExp(r'''[^\w`~!@#$%^&*()\-_=+\[\]:'",<.>/?\\| ]''');
final RegExp NO_MULTI_SPACES = new RegExp(r' {2,}');
final RegExp YT_LINK = new RegExp(r'^.*(youtu.be/|v/|embed/|watch\?|youtube.com/user/[^#]*#([^/]*?/)*)\??v?=?([^#\&\?]*).*');

void handleMessage(MessageEvent event) {
  var msg = event.message;
  if (LINK_REGEX.hasMatch(msg)) {
    for (var match in LINK_REGEX.allMatches(msg)) {

      var url = match.group(0);

      if (url.contains("github.com/")) {
        return;
      }

      if (YT_LINK.hasMatch(url)) return;
      
      getLinkTitle(url).then((title) {
        bot.message(event.network, event.target, "[${IRC.Color.BLUE}Link Title${IRC.Color.RESET}] ${title}");
      }).catchError((e) {});
    }
  }
}

Future<String> getLinkTitle(String url) {
  return http.get(url).then((http.Response response) {
    if (response.statusCode != 200) {
      throw new Exception("FAIL");
    }

    try {
      var document = html5.parse(response.body);

      if (document == null) {
        throw new Exception("FAIL");
      }

      var title = document.querySelector('title').text;

      if (title == null || title.isEmpty) {
        throw new Exception("FAIL");
      }

      title = title.replaceAll(NO_SPECIAL_CHARS, ' ').replaceAll(NO_MULTI_SPACES, ' ').trim();
      return title;
    } catch (e) {}
  });
}
