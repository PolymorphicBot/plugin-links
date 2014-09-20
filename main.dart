library links;

import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import "package:irc/irc.dart";

import 'package:html5lib/parser.dart' as html5 show parse;
import 'package:html5lib/dom.dart';

import 'package:polymorphic_bot/api.dart';

BotConnector bot;

void main(List<String> args, port) {
  print("[Links] Loading Plugin");
  bot = new BotConnector(port);

  bot.handleEvent((data) {
    switch (data['event']) {
      case "message":
        handle_message(data);
        break;
    }
  });
}

final RegExp link_regex = new RegExp(r'\(?\b((http|https)://|www[.])[-A-Za-z0-9+&@#/%?=~_()|!:,.;]*[-A-Za-z0-9+&@#/%=~_()|]');

final RegExp NO_SPECIAL_CHARS = new RegExp(r'''[^\w`~!@#$%^&*()\-_=+\[\]:'",<.>/?\\| ]''');

final RegExp NO_MULTI_SPACES = new RegExp(r' {2,}');


final RegExp _yt_link_id = new RegExp(r'^.*(youtu.be/|v/|embed/|watch\?|youtube.com/user/[^#]*#([^/]*?/)*)\??v?=?([^#\&\?]*).*');

void handle_message(data) {
  var msg = data['message'];
  if (link_regex.hasMatch(msg)) {
    for (var match in link_regex.allMatches(msg)) {

      var url = match.group(0);

      if (url.contains("github.com/")) {
        return;
      }
      
      if (_yt_link_id.hasMatch(url)) return;

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
