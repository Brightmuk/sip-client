import 'package:dart_sip_ua_example/src/theme_provider.dart';
import 'package:dart_sip_ua_example/src/user_state/sip_user_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';
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
    _dest = _preferences.getString('dest') ?? 'sip:hello_jssip@tryit.jssip.net';
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
      color: ,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text('Destination URL'),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: textFieldColor),
          maxLines: 2,
          decoration: InputDecoration(
            filled: true,
            fillColor: textFieldFill,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(5),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(5),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(5),
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
                onTap: () => _handleCall(context),
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

    return Scaffold(
      appBar: AppBar(
        title: Text("Dart SIP UA Demo"),
        actions: <Widget>[
          PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'account':
                    Navigator.pushNamed(context, '/register');
                    break;
                  case 'about':
                    Navigator.pushNamed(context, '/about');
                    break;
                  case 'theme':
                    final themeProvider = Provider.of<ThemeProvider>(context,
                        listen:
                            false); // get the provider, listen false is necessary cause is in a function

                    setState(() {
                      isDarkTheme = !isDarkTheme;
                    }); // change the variable

                    isDarkTheme // call the functions
                        ? themeProvider.setDarkmode()
                        : themeProvider.setLightMode();
                    break;
                  default:
                    break;
                }
              },
              icon: Icon(Icons.menu),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem(
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.account_circle,
                            color: iconColor,
                          ),
                          SizedBox(width: 12),
                          Text('Account'),
                        ],
                      ),
                      value: 'account',
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.info,
                            color: iconColor,
                          ),
                          SizedBox(width: 12),
                          Text('About'),
                        ],
                      ),
                      value: 'about',
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.info,
                            color: iconColor,
                          ),
                          SizedBox(width: 12),
                          Text(isDarkTheme ? 'Light Mode' : 'Dark Mode'),
                        ],
                      ),
                      value: 'theme',
                    )
                  ]),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 12),
        children: <Widget>[
          SizedBox(height: 8),
          Center(
            child: Text(
              'Register Status: ${helper!.registerState.state?.name ?? ''}',
              style: TextStyle(fontSize: 18, color: textColor),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Received Message: $receivedMsg',
              style: TextStyle(fontSize: 16, color: textColor),
            ),
          ),
          SizedBox(height: 8),
           _buildDialPad()
        ],
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
