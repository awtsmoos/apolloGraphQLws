//B"H
import 'dart:convert';
import 'dart:math';
import 'package:graphql/client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
class Etsem {
  //B"H
  String randomID() {
    return "BH_"+DateTime.now()
    .millisecondsSinceEpoch
    .toString()+"_"
    +Random().nextInt(7700)
    .toString();
  }

  Function? onData = (me,d){};
  Function? onString = (me,str){};
  Function? onConnect = (me){};
  Function? onClosed = (){};
  Function? onError = (er){};
  Function? onSubError = (er){};

  WebSocketChannel? con;
  GraphQLWebSocketChannel? graphQLws;

  WebSocketSink? sink;

  void endSubscription(String id) {
    if(graphQLws!.closeCode == null) {
      sink!.add(jsonEncode({
        "type":"complete",
        "id":id
      }));

      if(subscriptions[id] != null) {
        subscriptions.remove(id);
      }
    }
  }

  void close() {
    
    graphQLws!.sink.close();
    
    
  }
  var subscriptions = {};
  var subscriptionID = "";
  var payload = {};

  void Subscribe({
    String jwt="", 
    String query="", 
    String operationName="",
    Map vars=const {}
  }) {
    
    var id = randomID();
      payload = {
          "operationName":operationName,
          "query": query,
          "variables": vars
        };
      graphQLws!.sink.add(jsonEncode({
        "id": id,
        "type":"subscribe",
        "payload":payload
      }));

      subscriptions[id] = payload;
      subscriptionID = id;
  }
  Etsem({
    String url="", 
    String jwt="", 
    this.onData,
    this.onString,
    this.onConnect,
    this.onError,
    this.onSubError,
    this.onClosed,
    
  }) {
    
    con = WebSocketChannel.connect(Uri.parse(url),
        protocols: ["graphql-ws"]);

    graphQLws = con!.forGraphQL();
    sink = graphQLws!.sink;

    graphQLws!.sink.add(jsonEncode({
      "type":"connection_init",
      "payload":{
        "Authorization":
        "Bearer $jwt"
      }
    }));
    
    graphQLws!.stream.listen((msg) {
      
      
      Map? js;
      try {
        js = jsonDecode(msg);
      } catch(e) {
        onString!(this,msg);
      }

      if(js == null) {
        return;
      }

      //print(js);

      switch(js["type"]) {
        case "connection_ack":
          onConnect!(this,js);
          
        break;
        case "next":
          var id = js["id"];
          if(id != null) {
            
            onData!(this,js);
          }
          
      }
    },
      onDone: () => {
        onClosed!()
      },
      onError: (er) {
        onError!(er);
      }
    );

    
  }
}
