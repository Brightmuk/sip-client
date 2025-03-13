import 'package:dart_sip_ua_example/src/theme_provider.dart';
import 'package:dart_sip_ua_example/src/user_state/sip_user_cubit.dart';
import 'package:dart_sip_ua_example/src/widgets/registration_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_ua/sip_ua.dart';

import 'widgets/action_button.dart';

class DialPadWidget extends StatefulWidget {
  final SIPUAHelper? _helper;

  DialPadWidget(this._helper, {Key? key}) : super(key: key);

  @override
  State<DialPadWidget> createState() => _MyDialPadWidget();
}

class _MyDialPadWidget extends State<DialPadWidget>
    implements SipUaHelperListener {
  String? _dest;
  SIPUAHelper? get helper => widget._helper;
  TextEditingController? _textController;
  late SharedPreferences _preferences;
  late SipUserCubit currentUserCubit;

  final Logger _logger = Logger();

  String? receivedMsg;

  @override
  initState() {
    super.initState();
    receivedMsg = "";
    _bindEventListeners();
    _loadSettings();
  }

  void _loadSettings() async {
    _preferences = await SharedPreferences.getInstance();
    _dest = _preferences.getString('dest') ?? '';
    _textController = TextEditingController(text: _dest);
    _textController!.text = _dest!;

    setState(() {});
  }

  void _bindEventListeners() {
    helper!.addSipUaHelperListener(this);
  }

  Future<Widget?> _handleCall(BuildContext context,
      [bool voiceOnly = false]) async {
    final dest = _textController?.text;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await Permission.microphone.request();
      await Permission.camera.request();
    }
    if (dest == null || dest.isEmpty) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Target is empty.'),
            content: Text('Please enter a SIP URI or username!'),
            actions: <Widget>[
              TextButton(
                child: Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return null;
    }

    var mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': {
        'mandatory': <String, dynamic>{
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
      }
    };

    MediaStream mediaStream;

    if (kIsWeb && !voiceOnly) {
      mediaStream =
          await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      mediaConstraints['video'] = false;
      MediaStream userStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      final audioTracks = userStream.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        mediaStream.addTrack(audioTracks.first, addToNative: true);
      }
    } else {
      if (voiceOnly) {
        mediaConstraints['video'] = !voiceOnly;
      }
      mediaStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    }

    helper!.call(dest, voiceOnly: voiceOnly, mediaStream: mediaStream);
    _preferences.setString('dest', dest);
    return null;
  }

  void _handleBackSpace([bool deleteAll = false]) {
    var text = _textController!.text;
    if (text.isNotEmpty) {
      setState(() {
        text = deleteAll ? '' : text.substring(0, text.length - 1);
        _textController!.text = text;
      });
    }
  }

  void _handleNum(String number) {
    setState(() {
      _textController!.text += number;
    });
  }

  List<Widget> _buildNumPad() {
    final labels = [
      [
        {'1': ''},
        {'2': 'abc'},
        {'3': 'def'}
      ],
      [
        {'4': 'ghi'},
        {'5': 'jkl'},
        {'6': 'mno'}
      ],
      [
        {'7': 'pqrs'},
        {'8': 'tuv'},
        {'9': 'wxyz'}
      ],
      [
        {'*': ''},
        {'0': '+'},
        {'#': ''}
      ],
    ];

    return labels
        .map((row) => Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((label) {
                  return GestureDetector(
                    onTap: () => _handleNum(label.keys.first),
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(65),
                          border: Border.all(
                              color: Color.fromRGBO(115, 121, 110, 1),
                              width: 1)),
                      child: Center(
                          child: Text(
                        label.keys.first,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 24),
                      )),
                    ),
                  );
                }).toList())))
        .toList();
  }

  Widget _buildDialPad() {
    Color? textFieldColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);
    Color? textFieldFill =
        Theme.of(context).buttonTheme.colorScheme?.surfaceContainerLowest;
    return 
    Container(
      height: MediaQuery.of(context).size.height*0.7,
      color: Color.fromRGBO(248, 251, 240, 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
             
        children: [
        TextField(
          keyboardType: TextInputType.text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          
          decoration: InputDecoration(
            filled: true,
            fillColor: Color.fromRGBO(248, 251, 240, 1),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent),
             
            ),
            enabledBorder: OutlineInputBorder(
             borderSide: BorderSide(color: Colors.transparent),
             
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent),
             
            ),
          ),
          controller: _textController,
        ),
        SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildNumPad(),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(65),
                      border: Border.all(
                          color: Color.fromRGBO(115, 121, 110, 1), width: 1)),
                  child: Center(
                      child: Icon(
                    Icons.dialpad,
                    size: 25,
                  )),
                ),
              ),
              GestureDetector(
                onTap: () => _handleCall(context, true),
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(65),
                    boxShadow: [BoxShadow(color: Colors.grey,spreadRadius: 1,blurRadius: 5)]
                  ),
                  child: Center(
                      child: Icon(
                    Icons.call,
                    size: 25,
                    color: Colors.white,
                  )),
                ),
              ),
              GestureDetector(
                onTap: () => _handleBackSpace(),
                onLongPress: () => _handleBackSpace(true),
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Color.fromRGBO(115, 121, 110, 1), width: 1),
                    borderRadius: BorderRadius.circular(65),
                  ),
                  child: Center(
                      child: Icon(
                    Icons.backspace,
                    size: 25,
                    color: const Color.fromARGB(255, 198, 198, 198),
                  )),
                ),
              ),
            ],
          ),
        ),
      ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color? textColor = Theme.of(context).textTheme.bodyMedium?.color;
    Color? iconColor = Theme.of(context).iconTheme.color;
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    currentUserCubit = context.watch<SipUserCubit>();
    //  ${helper!.registerState.state?.name ?? ''} $receivedMsg
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: SizedBox(
          width: 100,
          child: Row(
            children: [
              Text("NENACALL" ,style: TextStyle(fontSize: 14),),
              SizedBox(width: 10,),
              RegistrationIndicator(state: helper!.registerState.state?.name??'NONE',)
            ],
          ),
        ),
        actions: <Widget>[
          IconButton(onPressed: ()=>Navigator.pushNamed(context, '/register'), icon: Icon(Icons.person_2_outlined))
        ]
      ),
      body:  ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index){
            return ListTile(
              title: Text('+254 7123456789',style: TextStyle(fontSize: 14),),
              subtitle: Text('Outgoing call, 1 m 12 secs',style: TextStyle(fontSize: 12,color: Colors.grey),),
              trailing: Text('12:30 PM',style: TextStyle(fontSize: 14),),
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
     floatingActionButton: GestureDetector(
                  onTap: (){
                    showMaterialModalBottomSheet(
                      elevation: 0,
                      
                        barrierColor: Colors.transparent,
                        context: context,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        builder: (context) => _buildDialPad(),
                      );
                  },
                  child: Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(65),
                        border: Border.all(
                            color: Color.fromRGBO(115, 121, 110, 1), width: 1)),
                    child: Center(
                        child: Icon(
                      Icons.dialpad,
                      size: 25,
                    )),
                  ),
                ),
    );
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() {
      _logger.i("Registration state: ${state.state?.name}");
    });
  }

  @override
  void transportStateChanged(TransportState state) {}

  @override
  void callStateChanged(Call call, CallState callState) {
    switch (callState.state) {
      case CallStateEnum.CALL_INITIATION:
        Navigator.pushNamed(context, '/callscreen', arguments: call);
        break;
      case CallStateEnum.FAILED:
        reRegisterWithCurrentUser();
        break;
      case CallStateEnum.ENDED:
        reRegisterWithCurrentUser();
        break;
      default:
    }
  }

  void reRegisterWithCurrentUser() async {
    if (currentUserCubit.state == null) return;
    if (helper!.registered) helper!.unregister();
    _logger.i("Re-registering");
    currentUserCubit.register(currentUserCubit.state!);
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    //Save the incoming message to DB
    String? msgBody = msg.request.body as String?;
    setState(() {
      receivedMsg = msgBody;
    });
  }

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {
    // TODO: implement onNewReinvite
  }
}
