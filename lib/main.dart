import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:async_preferences/async_preferences.dart';
import 'package:flutter/services.dart';
import 'package:restart_app/restart_app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
//import 'package:flutter_native_splash/flutter_native_splash.dart';


void main() async {
  final time = Stopwatch()..start();  //計測１
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.getDatabaseInstance();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_){
    runApp(MyApp(
    navigatorObservers: [MyNavigatorObserver()],
  ));
  });

  Future.wait([
  dotenv.load(fileName: ".env"),
  AppTrackingTransparency.requestTrackingAuthorization(),
  MobileAds.instance.initialize(),
  ]);
  time.stop();  //計測１終了
  debugPrint('main time:${time.elapsedMilliseconds} ms');

}

class MyApp extends StatefulWidget {
  final List<NavigatorObserver> navigatorObservers;
  const MyApp({Key? key,required this.navigatorObservers}):super(key:key);

  @override
  _MyAppState createState() => _MyAppState();
  
}

class _MyAppState extends State<MyApp> {

  final MyNavigatorObserver _navigatorObserver = MyNavigatorObserver();
  
  String _selectedFont = "Gothic";
  String _selectedTheme = 'default';
  String _selectedLanguage = 'en';
  Locale _locale =  WidgetsBinding.instance.platformDispatcher.locale;
  TimeOfDay _onTimeIn = const TimeOfDay(hour:0,minute:0);
  TimeOfDay _onTimeOut = const TimeOfDay(hour:0,minute:0);

  Future<void> _loadFont() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState((){
      _selectedFont = prefs.getString('font') ?? 'Gothic';
      _selectedTheme = prefs.getString('theme') ?? 'default';
      if (prefs.getString('language')==null && _locale.languageCode == 'ja'){
        _selectedLanguage = 'ja';
      }else{
        _selectedLanguage = prefs.getString('language') ?? 'en';}
      _locale = Locale(_selectedLanguage);
      String? timeString = prefs.getString('onTimeIn');
      if (timeString != null){
        List<String> parts = timeString.split(':');
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        _onTimeIn = TimeOfDay(hour: hour,minute:minute);
      } else {_onTimeIn = const TimeOfDay(hour:0,minute:0);}
      timeString = prefs.getString('onTimeOut');
      if (timeString != null){
        List<String> parts = timeString.split(':');
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        _onTimeOut = TimeOfDay(hour: hour,minute:minute);
      } else {_onTimeOut = const TimeOfDay(hour:0,minute:0);}
      
    });
  }
  
  void initConsent() async {
    final params = ConsentRequestParameters(
      //consentDebugSettings: ConsentDebugSettings(
      //  debugGeography: DebugGeography.debugGeographyEea,
      //  testIdentifiers:["",],),  
    );

    ConsentInformation.instance.requestConsentInfoUpdate(params,()async{
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
      ConsentForm.loadAndShowConsentFormIfRequired((loadAndShowError){
        if(loadAndShowError != null){
          debugPrint("Consent gathering failed: ${loadAndShowError.message}");
        }else{
          debugPrint("consent has been gathered");
        }
      },);
      }else{debugPrint("同意フォームは利用できません");}
        //Called when consent information is successfully updated.
    },
      (FormError error){
        // Called when theres an error updating consent information
        debugPrint("Failed to update consent information: ${error.message}");
          
      },
    );
  }
  

    
  

  void _changeFont(String font) async{
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('font',font);
    setState((){
        _selectedFont = font;
    });
  }
  void _changeTheme(String theme) async{
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('theme',theme);
    setState((){
        _selectedTheme = theme;
    });
  }
  void _changeLanguage(String language) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language',language);
    setState((){
      _selectedLanguage = language;
      intl.Intl.defaultLocale = language == 'ja' ? 'ja_JP' : 'en_US';
      initializeDateFormatting(intl.Intl.defaultLocale!, null);
      _loadFont();
    });
  }
  void _changeOnTimeIn(TimeOfDay? onTimeIn)async{
    final prefs = await SharedPreferences.getInstance();
    if(onTimeIn != null){
      String timeString = '${onTimeIn.hour}:${onTimeIn.minute}';
      await prefs.setString('onTimeIn',timeString);
    }
    setState((){});
    //print("onTimeIn.pref:$timeString");
  }
  void _changeOnTimeOut(TimeOfDay? onTimeOut)async{
    final prefs = await SharedPreferences.getInstance();
    if(onTimeOut != null){
      String timeString = '${onTimeOut.hour}:${onTimeOut.minute}';
      await prefs.setString('onTimeOut',timeString);
    }
    setState((){});
    //print("onTimeOut.pref:$timeString");
  }

  ThemeData _getTheme(){
    switch (_selectedTheme) {
      case 'blue':
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: _selectedFont,
          appBarTheme: AppBarTheme(
            backgroundColor: ColorScheme.fromSeed(seedColor: Colors.blue).inversePrimary,  
          ),
        );
      case 'red':
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red,primary:const Color.fromARGB(255,50,20,20)),
          useMaterial3: true,
          fontFamily: _selectedFont,
          appBarTheme: AppBarTheme(
            backgroundColor: ColorScheme.fromSeed(seedColor: Colors.red).inversePrimary,  
          ),
        );
      case 'green':
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green,primary:const Color.fromARGB(255,20,50,20)),
          useMaterial3: true,
          fontFamily: _selectedFont,
          appBarTheme: AppBarTheme(
            backgroundColor: ColorScheme.fromSeed(seedColor: Colors.green).inversePrimary,  
          ),
        );
      case 'yellow':
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow,primary:const Color.fromARGB(255,20,50,50)),
          useMaterial3: true,
          fontFamily: _selectedFont,
          appBarTheme: AppBarTheme(
            backgroundColor: ColorScheme.fromSeed(seedColor: Colors.yellow).inversePrimary,  
          ),
        );
      case 'mono':
        return ThemeData(
          colorScheme: const ColorScheme.light(primary:Colors.black,secondary:Colors.white),
          useMaterial3: true,
          fontFamily: _selectedFont,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
          )
        );
      case 'dark':
        return ThemeData(
          colorScheme: ColorScheme.fromSwatch(
            brightness:Brightness.dark,
            primarySwatch:Colors.grey,
          ),
          useMaterial3: true,
          fontFamily: _selectedFont,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color.fromARGB(255,50,50,50),
            foregroundColor: Colors.white,
          
          ),
        );
      case 'default':
      default:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 179, 195, 247)),
          useMaterial3: true,
          fontFamily: _selectedFont,
          appBarTheme: AppBarTheme(
            backgroundColor: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 179, 195, 247)).inversePrimary,  
          ),
        );
    }
  }
  Future<void> checkAppVersion() async {
    final prefs = await SharedPreferences.getInstance();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;
    String? storedVersion = prefs.getString('app_version');
    
    if (storedVersion == null || storedVersion != currentVersion){
        //新しいバージョンの処理
      prefs.setString('app_version', currentVersion);
        //必要な処理
    }
  }


  @override
  void initState(){
    super.initState();
    initConsent();
    checkAppVersion();
    _loadFont();

  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AttendTap',
      theme: _getTheme(),
      home: HomeScreen(
        selectedFont: _selectedFont,
        onFontChange: _changeFont,
        selectedTheme: _selectedTheme,
        onThemeChange:_changeTheme,
        selectedLanguage: _selectedLanguage,
        onLanguageChange:_changeLanguage,
        onTimeIn: _onTimeIn,
        onTimeOut: _onTimeOut,
        onTimeChangeIn:_changeOnTimeIn,
        onTimeChangeOut:_changeOnTimeOut
        ),
      navigatorObservers:[_navigatorObserver],
      locale: _locale,
      supportedLocales:const[
        Locale('en'),
        Locale('ja'),
      ],
      localeResolutionCallback: (Locale? locale, Iterable<Locale> supportedLocales){
        if (locale != null && locale.languageCode == 'ja'){
          initializeDateFormatting('ja_JP',null);
          intl.Intl.defaultLocale = 'ja_JP';
          return const Locale('ja');
        }
        initializeDateFormatting('en_US',null);
        intl.Intl.defaultLocale = 'en_US';
        return const Locale('en');
      },
      localizationsDelegates:const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes:{
        '/AttendanceList':(context) => const AttendanceListScreen(),
        '/ConfigScreen':(context) => ConfigScreen(
          onFontChange: _changeFont,
          currentFont: _selectedFont,
          onThemeChange:_changeTheme,
          currentTheme: _selectedTheme,
          onLanguageChange: _changeLanguage,
          currentLanguage: _selectedLanguage,
          onTimeChangeIn: _changeOnTimeIn,
          onTimeChangeOut: _changeOnTimeOut,
          onTimeIn: _onTimeIn,
          onTimeOut: _onTimeOut
          ),
        '/AttendanceListCalendar':(context) =>  AttendanceListScreenCalendar(initialDate:DateTime.now()),
      },
    );
  }
}

//カスタムオブザーバークラス
class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route,Route? previousRoute){
    super.didPop(route,previousRoute);
    if (previousRoute?.settings.name == '/AttendanceList'){
    }
  }
  @override
  void didPush(Route route,Route? previousRoute){
    super.didPush(route,previousRoute);
    if(route.settings.name == '/AttendanceList'){
    }
  }
}
//functionクラス-インフォメーションモーダル
class Functions {
  void informationModal(String title,String caption,BuildContext context,){ 
    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title:  Text(title),
          content: Text(caption),
          actions: <Widget>[
            TextButton(
              onPressed:() {
                Navigator.of(context).pop();                   
              },
              child:const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  Future<Map<String,dynamic>> getSharedPref()async{
    final prefs = await SharedPreferences.getInstance();
    return {'onTimeIn':prefs.getString('onTimeIn'),'onTimeOut':prefs.getString('onTimeOut')};
  }


}

//ユーティリティ関数:出勤関連
class AttendanceUtils {
  //出勤記録追加addAttendance
  static Future<void> addAttendance({
    required BuildContext context,
    TimeOfDay? checkInTime,
    TimeOfDay? checkOutTime,
    overtimeReason,
    String? free ,
    flagInOut,
    DateTime? date,
  }) async {
    final record = AttendanceLogic.createAttendanceRecord(
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      free:free,
      flagInOut:flagInOut,
      overtimeReason:overtimeReason,
      date:date,
      context:context,
    );
    //重複確認
  final l10n = L10n.of(context)! ;
  String? freeRecord;
  bool isDuplicate = await _checkDuplicate(record["date"]);
  freeRecord = await duplicateFree(record["date"]);
  if (isDuplicate) {
    if(flagInOut=="inOut"){
      var functions=Functions();
      functions.informationModal(l10n.registered,l10n.registered_caption,context);//登録済み
      return;
    }
    final duplicateCheck =  await duplicateInOutByDate(record["date"]);
    if ((flagInOut == 'in' && duplicateCheck?['check_in'] !=L10n.of(context)!.unregistered ) || (flagInOut == 'out' && duplicateCheck?['check_out'] !=L10n.of(context)!.unregistered )){
      String flagInOutString = "";
      if(flagInOut == 'in'){
        flagInOutString = l10n.attendance_time;
      } else if (flagInOut == 'out'){
        flagInOutString = l10n.leavework_time;
      }
      showDialog(
        context:context,
        barrierDismissible: false,
        builder:(_) => AlertDialog(
          title:Text(l10n.duplicate),//重複確認
          content: Text(
            duplicateCheck != null
            ? "${l10n.registered_caption} \n${L10n.of(context)!.attendance_time}:${duplicateCheck['check_in']}　${L10n.of(context)!.leavework_time}:${duplicateCheck['check_out']}\n\n'$flagInOutString' ${l10n.overwrite_check}"//上書きしますか。
            : l10n.notfound //データが見つかりません。
            ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              } ,
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () async {
                var functions = Functions();
                if ((freeRecord?.isNotEmpty ?? false) && (free?.isNotEmpty ?? false) ){
                  bool? freeCheck = await _freeReplaceDialog(context,freeRecord);
                  if (freeCheck == false){
                    record['free'] = null;                    
                  }
                }
                _updateRecord(context,record);
                Navigator.of(context).pop();
                
                if (flagInOut=="in"){
                  functions.informationModal(l10n.attendance,l10n.attendance_registration,context);  //出勤記録、出勤登録しました。     
                } else if (flagInOut == "out"){
                  functions.informationModal(l10n.clockout,l10n.clockout_registration,context);  //退勤記録、退勤登録しました。
                }
              }, 
            )         
          ],
        )
      );
    } else if (flagInOut == "edit"){
      _updateRecord(context,record);
      var functions = Functions();
      functions.informationModal(l10n.edit_complete,l10n.edited,context); //編集完了、編集しました。

    } else{ //check in もしくはoutがN/Aで上書きする時は確認なし。
        if ( (freeRecord?.isNotEmpty ?? false) && (free?.isNotEmpty ?? false) ){
          bool? freeCheck = await _freeReplaceDialog(context,freeRecord);
          if (freeCheck == false){
            record['free'] = null;                    
          }
        }
      _updateRecord(context,record);
        var functions = Functions();
        if (flagInOut=="in"){
          functions.informationModal(l10n.attendance,l10n.attendance_registration,context); //出勤記録、出勤登録しました。
        } else if (flagInOut == "out"){
          functions.informationModal(l10n.clockout,l10n.clockout_registration,context);  //退勤記録、退勤登録しました。
        }
    }
  } else{
    record.remove('flagInOut');
    List<int> recordOutOTR =[];
    if (record['overtime_reason'].isNotEmpty){
      String rOtR = record['overtime_reason'];
        recordOutOTR = rOtR.split(',')
          .map((e) => int.parse(e.trim()))
          .cast<int>()
          .toList();
    }
    record.remove('overtime_reason');
    int lastId = await DatabaseHelper.insertRecord('attendance_table',record);
    
    const action = "Insert";
    var newHistory = {"attendance_id":lastId,"action":action,};
    await DatabaseHelper.insertRecord('history_table',newHistory);
    Map<String, dynamic> map = {'attendance_id':lastId};
    
    final db = await DatabaseHelper.getDatabaseInstance();
    await DatabaseHelper.addOvertimeReasons(db,map,recordOutOTR);
    var functions = Functions();
    if (flagInOut=="in"){
      functions.informationModal(l10n.attendance,l10n.attendance_registration,context); //出勤記録、出勤登録しました。
    } else if (flagInOut == "out"){
      functions.informationModal(l10n.clockout,l10n.clockout_registration,context); //退勤記録、退勤登録しました。
    } else if (flagInOut =="inOut"){
      functions.informationModal(l10n.record,l10n.signedup,context);  //記録、登録しました。
    }
  }
  }
  static Future<void> _updateRecord(BuildContext context, Map<String, dynamic> record)async{
      await DatabaseHelper.updateRecord(record,context);
  }
  //重複チェックよう関数
  static Future<bool> _checkDuplicate(String date) async {
    final db = await DatabaseHelper.getDatabaseInstance();
    final result = await db.query(
      'attendance_table',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.isNotEmpty;
  }
  static Future<Map<String,String>?> duplicateInOutByDate(String date) async {
    final db = await DatabaseHelper.getDatabaseInstance();
    final duplicateInOut = await db.query(
      'attendance_table',
      columns:['check_in', 'check_out'],
      where: 'date = ?',
      whereArgs: [date],
    );
    if (duplicateInOut.isNotEmpty){
      return{
        'check_in':duplicateInOut[0]['check_in'] as String,
        'check_out':duplicateInOut[0]['check_out'] as String,
      };
    }
    return null;
  }
  static Future<String?> duplicateFree(String date) async {
    final db = await DatabaseHelper.getDatabaseInstance();
    final freeRecord = await db.query(
      'attendance_table',
      columns:['free'],
      where: 'date = ?',
      whereArgs: [date],
    );
    if (freeRecord.isNotEmpty){
      
      return freeRecord.first['free'] as String?;
    }
    return null;
  }
  static Future<bool?> _freeReplaceDialog(BuildContext context,String? free)async {
    
    return await showDialog<bool?>(
      context:context,
      barrierDismissible: false,
      builder:(_){
        return AlertDialog(
          title: Text(L10n.of(context)!.duplicate),  //重複確認
          content: Text("${L10n.of(context)!.free_overwrite}\n${L10n.of(context)!.free}$free"), //自由記述も上書きしてよろしいですか？、自由記述
          actions: [
            TextButton(
              child: Text(L10n.of(context)!.notoverwrite),  //上書きしない
              onPressed:() {
                Navigator.pop(context,false);
              },
            ),
            TextButton(
              child: Text(L10n.of(context)!.overwrite),  //上書きする
              onPressed:(){
                Navigator.pop(context,true);
                
              },
            ),

          ],
        );
      },

    );
  }
  static Future<List<Map<String, dynamic>>> fetchAttendanceRecords() async {
    return await DatabaseHelper.getRecords('attendance_table');
  }

  static Future<void> deleteAttendance(String date) async {
    await DatabaseHelper.deleteRecord('attendance_table','date = ?', [date]);
  }

}

//データベース操作
class DatabaseHelper {
  static Database? _database;

  static Future<Database> getDatabaseInstance() async {
    if (_database != null) return _database!;
    final watch = Stopwatch()..start();
    _database = await initDatabase();
    watch.stop();
    debugPrint('Database initial time:${watch.elapsedMilliseconds} ms');
    return _database!;
  }

  static Future<Database> initDatabase() async {
    Locale locale = WidgetsBinding.instance.platformDispatcher.locale;

    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'attendance.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE attendance_table(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            check_in TEXT, 
            check_out TEXT,
            free TEXT,
            last_update DATETIME DEFAULT CURRENT_TIMESTAMP
          );
          '''); 
        await db.execute('''
          CREATE TABLE history_table(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            attendance_id INTEGER NOT NULL,
            action TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (attendance_id) REFERENCES attendance_table(id)
              ON DELETE CASCADE
              ON UPDATE NO ACTION
          );
          ''');
          await db.execute('''
          CREATE TABLE overtime_reason_table(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            overtime_reason TEXT NOT NULL,
            remarks TEXT,
            order_index INTEGER UNIQUE,
            available BOOLEAN
          );
          ALTER TABLE overtime_reason_table ADD COLUMN available BOOLEAN DEFAULT 1;
          ''');
          final sequenceResult = await db.rawQuery(
            "SELECT seq FROM sqlite_sequence WHERE name = 'overtime_reason_table'"
          ); 
          if (sequenceResult.isEmpty){
            await db.insert('overtime_reason_table',{'overtime_reason':locale.languageCode == 'ja' ? '始業準備' : 'preparation' ,'order_index':'1','available':1});  //始業準備
            await db.insert('overtime_reason_table',{'overtime_reason':locale.languageCode == 'ja' ? '会議' : 'meeting' ,'order_index':'2','available':1});  //会議
            await db.insert('overtime_reason_table',{'overtime_reason':'QC','order_index':'3','available':1});
          }
          await db.execute('''
          CREATE TABLE attendance_overtime(
            attendance_id INTEGER NOT NULL,
            overtime_reason_id INTEGER NOT NULL,
            PRIMARY KEY (attendance_id,overtime_reason_id),
            FOREIGN KEY (attendance_id) REFERENCES attendance_table(id)
              ON DELETE CASCADE
            FOREIGN KEY (overtime_reason_id) REFERENCES overtime_reason_table(id)
              ON DELETE CASCADE 
          );
          ''');
        await db.execute("PRAGMA foreign_keys = ON;");
      },
      version: 2,
    );
  }  
  static Future<int> insertRecord(String tableName, Map<String,dynamic> record) async {
    final db = await DatabaseHelper.getDatabaseInstance();
    int lastId = await db.insert(tableName,record,conflictAlgorithm: ConflictAlgorithm.ignore);

    return lastId;
  }

  static Future<List<Map<String, dynamic>>> getRecords(String tableName) async {
    final db = await DatabaseHelper.getDatabaseInstance();
    return await db.query(tableName);    
  }

  static Future<void> addOvertimeReasons(Database db, Map<String, dynamic> attendanceId, List<int> overtimeReasonIds) async {
    if(overtimeReasonIds.isNotEmpty){
      final int attendance_id = attendanceId['attendance_id'];
      await db.transaction((txn) async{
        for (var reasonId in overtimeReasonIds){
          await txn.insert(
            'attendance_overtime',
            {'attendance_id': attendance_id, 'overtime_reason_id': reasonId},
            conflictAlgorithm : ConflictAlgorithm.ignore,
        );
      }
    });
    }
  }

  static Future<void> updateRecord(Map<String, dynamic> record,context) async{
    final db = await DatabaseHelper.getDatabaseInstance();
    Map<String, dynamic> updateValues= {};
    const action = "update";

    if (record['check_in'] != L10n.of(context)!.unregistered && record['flagInOut']=="in"){
      updateValues['check_in'] = record['check_in'];
    }
    if (record['check_out'] != L10n.of(context)!.unregistered && record['flagInOut']=="out"){
      updateValues['check_out'] = record['check_out'];
    }
    if ((record['free'] ?? "").isNotEmpty){
      updateValues['free'] = record['free'];
    }
    if (record['flagInOut'] =='edit'){
      updateValues['check_in'] = record['check_in'];
      updateValues['check_out'] = record['check_out'];
    }

    await db.update(
      'attendance_table',
      updateValues,
      where: 'date = ?',
      whereArgs: [record['date']],
    );
    
    final result = await db.query('attendance_table',columns:['id'],where:'date =?',whereArgs:[record['date']],limit:1,);
    final Map<String, dynamic> attendId = result.first;
    final attendance_id = attendId['id'];
    final historyData = {"attendance_id":attendance_id,"action":action,};
    await DatabaseHelper.insertRecord("history_table",historyData);
    if (record['flagInOut'] == "edit"){
      await deleteRecord('attendance_overtime','attendance_id = ?',[attendance_id]);
    }
    if (record['overtime_reason'] != ""){
      
      String rOtR = record['overtime_reason'];
      List<int> recordOvertimeReason = rOtR.split(',')
        .map((e) => int.parse(e.trim()))
        .cast<int>()
        .toList();
      final Map<String,dynamic> otattendanceId = {'attendance_id':attendId['id']};
      await DatabaseHelper.addOvertimeReasons(db,otattendanceId,recordOvertimeReason);
    }
  }

  static Future<void> deleteRecord(String tableName, String whereClause, List<dynamic> whereArgs) async {
    final db = await DatabaseHelper.getDatabaseInstance();
    if (tableName == 'overtime_reason_table'){
      await db.update(
        tableName,
        {'available':0,'order_index': null},
        where: whereClause,
        whereArgs: whereArgs,
      );
      final availableItems = await db.query(
        tableName,
        where: 'available = ?',
        whereArgs: [1],
        orderBy: 'order_index',
      );
      for (int i = 0; i < availableItems.length; i++){
        await db.update(
          tableName,
          {'order_index':i+1},
          where: 'id = ?',
          whereArgs: [availableItems[i]['id']],
        );
      }
    } else {
      await db.delete(tableName, where: whereClause, whereArgs: whereArgs);
    }
  }
}
//ロジック
class AttendanceLogic {
  static String _timeOfDayToString(TimeOfDay? time,context){
    if (time == null) {
      return L10n.of(context)!.unregistered;//未登録
    }
    return '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  static Map<String, dynamic> createAttendanceRecord( {
    TimeOfDay? checkInTime,
    TimeOfDay? checkOutTime,
    String? free,
    flagInOut,
    overtimeReason,
    DateTime? date,
    context
  }) 
   
  { date ??= DateTime.now();
  
    return {
      "date": intl.DateFormat('y-MM-dd').format(date),
      "check_in":_timeOfDayToString(checkInTime,context),
      "check_out":_timeOfDayToString(checkOutTime,context),
      "flagInOut":flagInOut,
      "free":free,
      "overtime_reason":overtimeReason,
    };
  }
  static Future<List<Map<String, dynamic>>> fetchMonthlyRecords(String month) async {
    final db = await DatabaseHelper.getDatabaseInstance();

    return await db.rawQuery(
       '''
      SELECT 
        attendance_table.*,
        GROUP_CONCAT(overtime_reason_table.overtime_reason) AS overtime_reasons
      FROM attendance_table
      LEFT JOIN attendance_overtime ON attendance_table.id = attendance_overtime.attendance_id
      LEFT JOIN overtime_reason_table ON overtime_reason_table.id = attendance_overtime.overtime_reason_id
      WHERE strftime('%Y-%m', attendance_table.date) = ?
      GROUP BY attendance_table.id
      ORDER BY attendance_table.date ASC;
      ''',
      [month],
    );
  }
  static Future<List<Map<String, dynamic>>> allRecords() async {
    final db = await DatabaseHelper.getDatabaseInstance();
    return await db.rawQuery(
       '''
      SELECT 
        attendance_table.*,
        GROUP_CONCAT(overtime_reason_table.overtime_reason) AS overtime_reasons
      FROM attendance_table
      LEFT JOIN attendance_overtime ON attendance_table.id = attendance_overtime.attendance_id
      LEFT JOIN overtime_reason_table ON overtime_reason_table.id = attendance_overtime.overtime_reason_id
      GROUP BY attendance_table.id
      ORDER BY attendance_table.date ASC;
      ''',
    );
  }
  static Future<List<Map<String, dynamic>>> overtimeReasonRecords() async {
    final db = await DatabaseHelper.getDatabaseInstance();
    return await db.query(
      'overtime_reason_table',
      where:'available = ?',
      whereArgs: [1],
      orderBy: 'order_index ASC',
    );
  }
  static Future<Map<String, dynamic>?> todayRecords() async {
    final db = await DatabaseHelper.getDatabaseInstance();
    final today = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
    final List<Map<String,dynamic>> result =  await db.query(
      'attendance_table',
      where:'date = ?',
      whereArgs: [today],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
  static Future<bool> checkOvertimeReason(String inputtxt) async {
    final db = await DatabaseHelper.getDatabaseInstance();
    final reason = await db.query('overtime_reason_table',columns:['overtime_reason'],where:'overtime_reason=? AND available = ?',whereArgs:[inputtxt,1],limit:1,);
  
    if (reason.isNotEmpty){
      return false;
    } else {
      int maxOrderIndex = await db.rawQuery(
        'SELECT IFNULL(MAX(order_index), 0) + 1 AS max_order FROM overtime_reason_table'
      ).then((value) => value.first['max_order'] as int);
      
      final addreason = {'overtime_reason':inputtxt,'order_index':maxOrderIndex,'available':1};
      DatabaseHelper.insertRecord('overtime_reason_table',addreason);
    
      return true;
    }
  } 

  static Future<bool> updateOvertimeReason(context,String inputTxt,int itemId) async{
    final db = await DatabaseHelper.getDatabaseInstance();
    final reason = await db.query('overtime_reason_table',columns:['overtime_reason'],where:'overtime_reason=? AND available = ?',whereArgs:[inputTxt,1],limit:1,);
    
    if (reason.isNotEmpty){
      var functions = Functions();
      functions.informationModal(L10n.of(context)!.error,"${inputTxt}${L10n.of(context)!.yetregist}",context,);  //エラー、はすでに登録済みです。
      return false;
    } else {
      await db.update(
      'overtime_reason_table',
      {'overtime_reason':inputTxt},
      where: 'id = ?',
      whereArgs: [itemId],
    );
      return true;
    }
  }

  static Future<void> swapItems(Database db, int orderId1,int orderId2) async {
    List<Map<String,dynamic>> items = await db.rawQuery(
      'SELECT id, order_index FROM overtime_reason_table WHERE order_index IN (?,?)',
      [orderId1,orderId2],
    );
    
    int id1 = items.first['id'];
    int id2 = items.last['id'];

    await db.transaction((txn) async {
      await txn.rawUpdate('UPDATE overtime_reason_table SET order_index = -1 WHERE id = ?' ,[id1]);
      await txn.rawUpdate('UPDATE overtime_reason_table SET order_index = ? WHERE id = ?' ,[orderId1,id2]);
      await txn.rawUpdate('UPDATE overtime_reason_table SET order_index = ? WHERE id = ?' ,[orderId2,id1]);
    });

  }
  

}



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key,
    required this.selectedFont, 
    required this.onFontChange,
    required this.selectedTheme,
    required this.onThemeChange,
    required this.selectedLanguage,
    required this.onLanguageChange,
    required this.onTimeIn,
    required this.onTimeOut,
    required this.onTimeChangeIn,
    required this.onTimeChangeOut
    });

  final String selectedFont;
  final String selectedTheme;
  final String selectedLanguage;
  final TimeOfDay onTimeIn;
  final TimeOfDay onTimeOut;
  final Function(String) onFontChange;
  final Function(String) onThemeChange;
  final Function(String) onLanguageChange;
  final Function(TimeOfDay?) onTimeChangeIn;
  final Function(TimeOfDay?) onTimeChangeOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String currentDate = "";
  String currentTime = "";
  String currentSec = "";
  DateTime now = DateTime.now();
  TimeOfDay? selectedTime;
  TimeOfDay? checkInTime ;
  TimeOfDay? checkOutTime ;
  Set<int> selectedIndices = <int>{};
  String? free ;

  @override
  void initState() { 
    super.initState();
      _updateDateTime();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {

    });
    
  }

  Timer? _timer;
  final ValueNotifier<DateTime> currentYmdhms = ValueNotifier(DateTime.now());
  void _updateDateTime(){
    if (_timer != null && _timer!.isActive){
      return;
    }
    DateTime now = DateTime.now();
    setState((){
      currentTime = intl.DateFormat('H:mm:').format(now);
      currentSec = intl.DateFormat('ss').format(now);
    });
    _timer = Timer.periodic(const Duration(seconds:1),(timer) {
        currentYmdhms.value = DateTime.now();
       
    });
  }
  void _stopTimer(){
    _timer?.cancel();
    _timer = null;
  }
  @override
  void dispose(){
    _timer?.cancel();
    super.dispose();
  }

  Future<TimeOfDay?> _showTimePicker(BuildContext context) async {
    TimeOfDay? pickedDate = await showTimePicker(
      context:context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale:const Locale('en','US'),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
      );      
    if (pickedDate != null){
      return pickedDate;
    }
      return null;
  }
  Future<String?> _showInputFreeDialog(BuildContext context,String? free) async {
    final TextEditingController _controller = TextEditingController(text:free);

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children:[
            Text(L10n.of(context)!.content_input,style:const TextStyle(fontSize:15,)), //内容を入力してください。
            const SizedBox(height:2),
            Text(L10n.of(context)!.twentychar,style:const TextStyle(fontSize:12,),), //(20文字以内)
            ],),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: L10n.of(context)!.here),  //ここに入力
            maxLength:20,
            
          ),
          actions: [
            TextButton(
              onPressed: (){
                  Navigator.of(context).pop(free);                 
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: ()async {
                Navigator.of(context).pop((_controller.text).trim());
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
      );
  }
  

  @override
  Widget build(BuildContext context){
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final navigationBarHeight = MediaQuery.of(context).padding.bottom;
    final appBarHeight = AppBar().preferredSize.height;

    final usableHeight = screenHeight - statusBarHeight - navigationBarHeight - appBarHeight;
    
    double? containerHeight = usableHeight -450 >= 250 ? 250 : usableHeight -450;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title:  Row(children:[
          const Icon(Icons.cases_outlined),
          const SizedBox(width:8),
          Text(L10n.of(context)!.attendance_management,  //勤怠管理
        style: TextStyle(fontSize: Localizations.localeOf(context).languageCode == 'ja' ? 25 : 20 ),
        ),
        ],),
         
      ),

      body: Stack(
        children: [
          //左上
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height:5),
                  Padding(padding: const EdgeInsets.symmetric(horizontal:5),
                    child:Row(
                    mainAxisAlignment: selectedTime != null
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.end,
                    children:[
                if (selectedTime != null)
                  ElevatedButton(
                    onPressed: () async {
                        selectedTime = null;
                        _updateDateTime();
                    } ,
                    style: ElevatedButton.styleFrom(
                      side: const BorderSide(
                        width:1,
                        color: Colors.grey,
                      ),
                      backgroundColor:  null,
                    ),
                    child: Text(
                       L10n.of(context)!.now,  //今
                        style: TextStyle(fontSize: 18,color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null )
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      
                      final time = await _showTimePicker(context);
                      if (time != null){
                        _stopTimer();
                        setState((){
                          selectedTime = time;
                        });
                      }
                    } ,
                    style: ElevatedButton.styleFrom(
                      side: BorderSide(
                        width:1,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey :const Color.fromARGB(255,150,150,200) 
                        
                      ),
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black :const Color.fromARGB(255,235,235,255),
                      
                    ),
                    child:Text(L10n.of(context)!.time_adjusment,  //時刻調整
                      style: TextStyle(fontSize:18,color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null ,),
                    ),
                  ),
                  ],
                  ),
                  ),
                  
                  ValueListenableBuilder<DateTime>(
                    valueListenable: currentYmdhms,
                    builder:(context,time,child){
                      String dateFormatString = L10n.of(context)!.date_format;
                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text( intl.DateFormat(dateFormatString).format(currentYmdhms.value) ,  //y年M月d日
                      style: const TextStyle(fontSize: 25, fontWeight:FontWeight.bold),
                    ),
                  );
                  },
                  ),
                ],      
          ),
          
          //中央
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            height: usableHeight - 450 >= 250 ? usableHeight - 250 - 250 - 100 : 100,
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [ 
              //Align(
              //  child:
                ValueListenableBuilder<DateTime>(
                  valueListenable: currentYmdhms,
                  builder: (context,time,child){

                  return Column(                  
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children:[
                        const SizedBox(width:60),
                        Text(
                        selectedTime != null
                          ? L10n.of(context)!.settime //設定時刻
                          : L10n.of(context)!.currenttime, //現在時刻
                        style: TextStyle(fontSize:Localizations.localeOf(context).languageCode == 'ja' ? 28 : 23),
                        ),
                      ],),
                      Row(  mainAxisAlignment:MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                        children:[
                      Text(
                        selectedTime != null
                          ? MaterialLocalizations.of(context).formatTimeOfDay(selectedTime!, alwaysUse24HourFormat: true) //設定時刻
                          : intl.DateFormat('H:mm:').format(currentYmdhms.value), //現在時刻
                        style: TextStyle(fontSize:Localizations.localeOf(context).languageCode == 'ja' ? 28 : 28),
                      
                      ) ,
                      Text(
                        selectedTime != null
                          ? ''
                          : intl.DateFormat('ss').format(currentYmdhms.value),
                        style: const TextStyle(fontSize:23),
                      )
                      ],),
                    ],
                  );
                },), 
              //),
                       
          ],//columnchild
          ),
          ),
          

          //真ん中下
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10,0,10,32.0),
              child:  
              Column(
                mainAxisSize:MainAxisSize.min,
                children:[
            Padding(padding: const EdgeInsets.symmetric(horizontal:20),
              child:
              Row (
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  
                  ElevatedButton(
                    onPressed: ()async {
                      free = await _showInputFreeDialog(context,free); 
                      setState((){});   
                    },
                    style: ElevatedButton.styleFrom(
                      side: BorderSide(
                        width:(free?.isEmpty ?? true)
                        ? 1
                        : 2.5,
                        color:(free?.isEmpty ?? true)
                        ? Colors.grey
                        : Theme.of(context).brightness == Brightness.dark ? Colors.grey :const Color.fromARGB(255,150,150,200) ,
                        ),
                      backgroundColor: (free?.isEmpty ?? true)
                      ? null
                      : Theme.of(context).brightness == Brightness.dark ? Colors.black :const Color.fromARGB(255,235,235,255),
                    ),
                    child: 
                      Text(L10n.of(context)!.free, //自由記述
                      style: TextStyle(fontSize:25,color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null ,),
                      ),                                   
                  ),
                  const SizedBox(width:10),
                  SizedBox(width:MediaQuery.of(context).size.width * 0.5,
                  child:
                  Text(free ?? ""),
                  ),
                ],
              ),
              ),
            
            const SizedBox(height:10),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: AttendanceLogic.overtimeReasonRecords(),// データ取得
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No records found.'));
                }

                final records = snapshot.data!;


            return Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: containerHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 3.4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: records.length,
                  itemBuilder: (context,index){
                    final record = records[index];
                    final recordId = record['id'] as int;
                    final isSelected = selectedIndices.contains(recordId);

                    return GestureDetector(
                      onTap: (){
                        setState((){
                          if (isSelected) {
                            selectedIndices.remove(recordId);
                          } else {
                            selectedIndices.add(recordId);
                          }
                        });
                      },
                      child: Container(
                        margin:  const EdgeInsets.symmetric(vertical:2,horizontal:10),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,50,50,50) :const Color(0x156E79CF) 
                            : Colors.transparent,
                          border: Border.all(
                            color: isSelected 
                              ? Theme.of(context).brightness == Brightness.dark ? Colors.grey :const Color(0x8F6E79CF) 
                              : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding:  const EdgeInsets.all(5),
                        
                        child: Column(
                          //crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record['overtime_reason'] ?? '',
                              style:  const TextStyle(fontSize: 18),
                              overflow: TextOverflow.ellipsis, // 長い文字列を省略
                              maxLines: 1, // 最大1行
                            ),
                          ],
                        ),
                                              
                      ),
                    );
                  },//itembuilder
                ),//gridviewbuilder
              ),//singlechildscrollview
            );//container
            },  //},builder?
            ),//),futurebuilder
            const SizedBox(height:15),

            FutureBuilder<Map<String, dynamic>?>(
              future: AttendanceLogic.todayRecords(),// データ取得
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final records = snapshot.data ?? {};
                final record = records;
                  return Row (
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      
                      OutlinedButton(
                        onPressed:()async{                          
                          if (selectedTime != null){
                            checkInTime = selectedTime;
                          } else{
                            checkInTime = TimeOfDay(hour: DateTime.now().hour,minute:DateTime.now().minute);
                          }
                          var flagInOut = "in";
                          final overReason = selectedIndices.toList();
                          final overtimeReason= overReason.join(',');
                          await AttendanceUtils.addAttendance(
                            context:context,
                            checkInTime:checkInTime,
                            overtimeReason:overtimeReason,
                            flagInOut:flagInOut,
                            free:free,
                          );
                          flagInOut = "";
                          if (!mounted) return;
                          setState(() {});
                          
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,185,188,195) : const Color.fromARGB(255, 225, 238, 255),),
                        child: Row(children:[
                          Icon(Icons.login,color:Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,80,80,100) :const Color.fromARGB(255,80,80,100)),
                          const SizedBox(width:10),
                          Column(children:[
                          if (record['check_in'] != null && record['check_in'] != L10n.of(context)!.unregistered && record['check_in'] != "N/A")
                            Text(record['check_in']),
                          Text(L10n.of(context)!.atwork,  //出勤
                            style:TextStyle(
                              fontSize:Localizations.localeOf(context).languageCode == 'ja' 
                                ? record['check_in'] != null && record['check_in'] != L10n.of(context)!.unregistered && record['check_in'] != "N/A" ? 20 : 35 
                                : 20,color:const Color.fromARGB(255,80,80,100)),
                          ),
                          

                          ],),
                        ],),
                      ),
              
                      OutlinedButton(
                        onPressed:()async{
                          if (selectedTime != null){
                            checkOutTime = selectedTime;
                          } else {
                            checkOutTime = TimeOfDay(hour:DateTime.now().hour,minute:DateTime.now().minute);
                          }
                          var flagInOut = "out";
                          final overReason = selectedIndices.toList();
                          final overtimeReason= overReason.join(',');
                          await AttendanceUtils.addAttendance(
                            context:context,
                            checkOutTime: checkOutTime,
                            flagInOut:flagInOut,
                            free:free,
                            overtimeReason:overtimeReason,
                            );
                          flagInOut = "";
                          if (!mounted) return;
                          setState((){});
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,35,30,30) :const Color.fromARGB(255, 255, 242, 232),),
                        child: Row(children:[
                          Column(children:[
                          if (record['check_out'] != null && record['check_out'] != L10n.of(context)!.unregistered && record['check_out'] != "N/A")
                            Text(record['check_out']),
                          Text(L10n.of(context)!.leavingwork,  //退勤
                            style:TextStyle(
                              fontSize:Localizations.localeOf(context).languageCode == 'ja' 
                                ? record['check_out'] != null && record['check_out'] != L10n.of(context)!.unregistered && record['check_out'] != "N/A" ? 20 : 35  
                                : 20,color:Theme.of(context).brightness == Brightness.dark ? Colors.white :const Color.fromARGB(255,80,80,100)),
                        ),
                        ],),
                          const SizedBox(width:10),
                          Icon(Icons.logout,color:Theme.of(context).brightness == Brightness.dark ? Colors.white :const Color.fromARGB(255,80,80,100)),
                        ],),
                      ),
                      
                    ],
                  );
              },),
                const SizedBox(height:30),
              Row(
                mainAxisAlignment:MainAxisAlignment.center,
                children: [
                ElevatedButton(
                style: ElevatedButton.styleFrom(
                  side: const BorderSide(
                    color: Colors.grey                  
                  ),
                ),
                onPressed:(){
                  _stopTimer();
                  Navigator.pushNamed(
                    context,
                    '/AttendanceList',
                  ).then((_){
                      selectedTime = null;
                      _updateDateTime();                   
                  });
                },
              child:  Row(children:[
                Icon(Icons.list,color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null ),
                const SizedBox(width:5),
                Text(L10n.of(context)!.list,  //一覧
                style: TextStyle(fontSize:Localizations.localeOf(context).languageCode == 'ja' ? 30 : 25,color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null ,),),
              ],),
              ),
              const SizedBox(width:40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  side: const BorderSide(
                    color: Colors.grey                  
                  ),
                ),
                onPressed:(){
                  _stopTimer();
                  Navigator.pushNamed(
                    context,
                    '/ConfigScreen',
                  ).then((_){
                      selectedTime = null;
                      _updateDateTime();                   
                  });
                },
              child: Row(children:[
                Icon(Icons.settings,color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null ),
                const SizedBox(width:5),
                Text(L10n.of(context)!.config,
                style: TextStyle(fontSize:Localizations.localeOf(context).languageCode == 'ja' ? 30 :25,color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null ,),),
              ],),
              ),
                ],
              ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  

}

//設定画面
class ConfigScreen extends StatefulWidget{
  const ConfigScreen({super.key,
    required this.onFontChange,
    required this.currentFont,
    required this.onThemeChange,
    required this.currentTheme,
    required this.onLanguageChange,
    required this.currentLanguage,
    required this.onTimeIn,
    required this.onTimeOut,
    required this.onTimeChangeIn,
    required this.onTimeChangeOut
    });
  final Function(String) onFontChange;
  final Function(String) onThemeChange;
  final Function(String) onLanguageChange;
  final Function(TimeOfDay?) onTimeChangeIn;
  final Function(TimeOfDay?) onTimeChangeOut;
  final String currentFont;
  final String currentTheme;
  final String currentLanguage;
  final TimeOfDay onTimeIn;
  final TimeOfDay onTimeOut;

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen>{
  int? selectedIndex;
  List<Map<String,dynamic>> records =[];
  late String _selectedFont;
  String? _selectedTheme = 'default';
  String? _selectedLanguage  ;
  final String jpTermsUrl = 'https://butternut-beetle-638.notion.site/152ff023717a80d88504e94cfb12e2b9?pvs=4';
  final String jpPrivacyPolicyUrl ='https://butternut-beetle-638.notion.site/153ff023717a806a9907db22350efede?pvs=4';
  final String enTermsUrl = 'http://butternut-beetle-638.notion.site';
  final String enPrivacyPolicyUrl ='https://butternut-beetle-638.notion.site/Privacy-Policy-152ff023717a80d1a24bf4a59cefd221?pvs=4';
  final String jpQAndAUrl = 'https://butternut-beetle-638.notion.site/Q-A-157ff023717a8033a9fcfcb7da55d8de?pvs=4';
  final String enQAndAUrl = 'https://butternut-beetle-638.notion.site/FAQ-157ff023717a8074924cd52b4d5a1add?pvs=4';
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  final String androidAdId = dotenv.env['ANDROID_ADMOB_ID'] ?? 'ca-app-pub-3940256099942544/9214589741';
  final String iOsAdId = dotenv.env['IOS_ADMOB_ID'] ?? 'ca-app-pub-3940256099942544/2435281174';
  TimeOfDay? _onTimeIn ;
  TimeOfDay? _onTimeOut ;
  

  @override
  void initState(){
    super.initState();
    _selectedFont = widget.currentFont;
    _selectedTheme = widget.currentTheme;
    _selectedLanguage = widget.currentLanguage;
    _onTimeIn = widget.onTimeIn;
    _onTimeOut = widget.onTimeOut;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      
    loadAd();
    });
  }

  Future<void> loadAd()async{
    final adUnitId = Platform.isAndroid
      ? androidAdId
      : iOsAdId;
    bool canRequestAds = await ConsentInformation.instance.canRequestAds();
      if (canRequestAds){
      BuildContext context = this.context;
      AdSize? adaptiveSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
        Orientation.portrait,
        MediaQuery.of(context).size.width.truncate(),
      );
      adaptiveSize ??=  AdSize.banner;
      

      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: adaptiveSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad){
            debugPrint('$ad loaded.');
            setState((){
              _isLoaded = true;
            });
          },
          onAdFailedToLoad:(ad,error){
            debugPrint('BannerAd failed to load: $error');
            ad.dispose();
          },
        ),
      )..load();
    } else {
      debugPrint('not Consent');
    }
  }

  void openUrl(BuildContext context, String url) async{
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)){
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context)!.url_notopen)), //URLを開くことができませんでした。
      );
    }
  }
  void _withdrawalModal(BuildContext context){
    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: const Text('Withdrawal of consent'),
          content: const Text("Do you wish to withdraw your consent to the use of your personal data?"),
          actions:[
            TextButton(
              child:const Text("Hold Consent"),
              onPressed:(){
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child:const Text("Withdrawal of Consent"),
              onPressed:()async{
                Navigator.of(context).pop();
                ConsentInformation.instance.reset();
                setState((){ _bannerAd = null;});
               
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Restart the app."),duration:Duration(milliseconds: 2000),)
                );
                await Future.delayed(const Duration(milliseconds:2000));
                Restart.restartApp(
                  notificationTitle: 'Restarting App',
		              notificationBody: 'Please tap here to open the app again.',
                );
                
                                 
              },
            ),
          ]
        );
      }
    );
  }

  Future<void> changePrivacyPreferences()async{
    final status = ConsentRequestParameters(
      //consentDebugSettings: ConsentDebugSettings(
      //  debugGeography: DebugGeography.debugGeographyEea,
      //  testIdentifiers:["",],),
    );
      ConsentInformation.instance.requestConsentInfoUpdate(status,()async{
        ConsentForm.showPrivacyOptionsForm((formError){
          if (formError != null){
            debugPrint("${formError.errorCode}: ${formError.message}");
          }
        });
      },(FormError error){
        debugPrint("error updating consent information");
      });
  }
  Future<bool> isPrivacyOptionsRequired()async{
    final preferences = AsyncPreferences();
    return await preferences.getInt('IABTCF_gdprApplies') == 1;
  }

  Future<void> _showEditItemNameDialog(BuildContext context,int itemId)async{
    final records = await AttendanceLogic.overtimeReasonRecords();
    String? reason;
    try {
      reason = records.firstWhere((record)
      => record['id'] == itemId,
      orElse: () => const{},
    )['overtime_reason'] as String?;
    } catch (e) {
      reason = null;  // 例外発生時の処理
    }
    final TextEditingController _controller = TextEditingController(text:reason);
    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Column (children:[
            Text(L10n.of(context)!.edit),
            Text(L10n.of(context)!.itemnameEdit ,style:const TextStyle(fontSize:15)),
            ],),
          content: 
            TextField(
              controller: _controller,
              maxLength:15,
            ),
          actions: [
            TextButton(
              onPressed: (){
                  Navigator.of(context).pop();                 
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: ()async {
                var functions = Functions();
                if ((_controller.text).trim().isEmpty){
                  functions.informationModal(L10n.of(context)!.error,L10n.of(context)!.itemname,context,); //"エラー","項目名を入力してください。"
                  return;
                }
                bool updateBool = await AttendanceLogic.updateOvertimeReason(context,_controller.text,itemId);
                
                if (updateBool){ 
                  Navigator.of(context).pop();
                  functions.informationModal(L10n.of(context)!.edit_complete,"${_controller.text}${L10n.of(context)!.edited}",context,);  //編集完了、編集しました。
                  setState((){});
                }
              },
              child: const Text('OK'),
            ),
          ],);
      }
    );
  }
  Future<Map<String,dynamic>> fetchOnTimeInOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? onTimeInString = prefs.getString('onTimeIn') ;
    //List<String> parts = timeString.split(':');
    //int hour = int.parse(parts[0]);
    //int minute = int.parse(parts[1]);
    //TimeOfDay onTimeIn = TimeOfDay(hour: hour,minute:minute);
      
    String? onTimeOutString = prefs.getString('onTimeOut') ;
    //parts = timeString.split(':');
    //hour = int.parse(parts[0]);
    //minute = int.parse(parts[1]);
    //TimeOfDay onTimeOut = TimeOfDay(hour: hour,minute:minute);

    return {"onTimeIn":onTimeInString,"onTimeOut":onTimeOutString};
  }
  //定時設定のダイアログ
  void showOnTimeInOutDialog(BuildContext context,Map<String,dynamic> data) async{
    String? onTimeInString = data['onTimeIn'] ;
    String? onTimeOutString = data['onTimeOut'] ;
    TimeOfDay? onTimeIn; 
    TimeOfDay? onTimeOut;
    TimeOfDay? inTimeTemp;
    TimeOfDay? outTimeTemp;
    
    if(onTimeInString != null){
      onTimeIn =  stringToTimeOfDay(onTimeInString);
    }
    if(onTimeOutString != null){
      onTimeOut = stringToTimeOfDay(onTimeOutString);
    }
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:(context,setState){
            return AlertDialog(
              title: Text(L10n.of(context)!.ontime), //定時設定
              content:SizedBox(height:130,child:
              Column(children:[
                const SizedBox(height:10),
                TextButton(
                  onPressed:()async{
                    inTimeTemp = await _showTimePicker(context);
                    if (inTimeTemp != null){
                    setState((){ onTimeIn = inTimeTemp; });          
                    }
                  },
                  child: Text( onTimeIn != null ? "${L10n.of(context)!.attendance_time}   ${MaterialLocalizations.of(context).formatTimeOfDay(onTimeIn!, alwaysUse24HourFormat: true)}": "${L10n.of(context)!.attendance_time} : ${L10n.of(context)!.notset}",
                    style:const TextStyle(fontSize:18,decoration: TextDecoration.underline),),
                ),
                const SizedBox(height:15),
                TextButton(
                  onPressed: ()async{
                    outTimeTemp = await _showTimePicker(context);
                    if (outTimeTemp != null){
                    setState((){ onTimeOut = outTimeTemp; });          
                    }
                  },
                  child: Text( onTimeOut != null ? "${L10n.of(context)!.leavework_time}   ${MaterialLocalizations.of(context).formatTimeOfDay(onTimeOut!, alwaysUse24HourFormat: true)}": "${L10n.of(context)!.leavework_time} : ${L10n.of(context)!.notset}",
                  style:const TextStyle(fontSize:18,decoration: TextDecoration.underline),), 
                ),

              ]),),
              actions:[
                Row( mainAxisAlignment:MainAxisAlignment.spaceAround,
                  children:[
                  TextButton(
                    style: TextButton.styleFrom(
                        backgroundColor:const Color.fromARGB(255,200,200,200),
                        foregroundColor:const Color.fromARGB(255,0,0,0),
                      padding: const EdgeInsets.symmetric(horizontal:20,vertical:10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),),
                      ),
                    child: Text(L10n.of(context)!.cancel),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,30,30,30) :const Color.fromARGB(255, 95, 130, 234),
                        foregroundColor:const Color.fromARGB(255,255,255,255),
                        padding: const EdgeInsets.symmetric(horizontal:30,vertical:10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),),
                      ),
                    child: Text(L10n.of(context)!.ok),
                    onPressed: () async{
                      if (inTimeTemp != null){
                      widget.onTimeChangeIn(inTimeTemp);
                      setState((){ _onTimeIn = inTimeTemp; });          
                      }
                      if (outTimeTemp != null){
                      widget.onTimeChangeOut(outTimeTemp);
                      setState((){ _onTimeIn = outTimeTemp; });          
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ]),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final navigationBarHeight = MediaQuery.of(context).padding.bottom;
    final appBarHeight = AppBar().preferredSize.height;

    final usableHeight = screenHeight - statusBarHeight - navigationBarHeight - appBarHeight;
    double itemListHeight = usableHeight -450 >= 250 ? 250 : usableHeight -450;
    double configHeight = usableHeight - 260 - itemListHeight;

    ScrollController _scrollController = ScrollController();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          children:[
            const Icon(Icons.settings),
            const SizedBox(width:10),
            Text(L10n.of(context)!.config),
          ],
        ),
      ),
      body:

      Stack(
        
        children:[
        FutureBuilder<bool>(
          future: isPrivacyOptionsRequired(),
          builder: (context,snapshot){
            if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();  // ローディング表示
            } else if (snapshot.hasData && snapshot.data == true) {
              return Positioned(
                top: _bannerAd == null ? 0 : _bannerAd!.size.height.toDouble(),
                right:5,
                child:TextButton(
                onPressed:() => _withdrawalModal(context),
                child:const Text("Privacy option"),
              ),);
            } 
            return const SizedBox.shrink();
        },),

        

        if (_bannerAd != null && _isLoaded)
          Container( 
            child: SafeArea(
            child:SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
            ),
        ),
        
        

        Positioned(
          top: _bannerAd != null ? _bannerAd!.size.height.toDouble()+10 : 60,
          child:
        Container(
          //color:Colors.grey,
          height:configHeight,
          width:screenWidth,
          child:Scrollbar(
            thickness: 5,
            thumbVisibility:true,
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: ClampingScrollPhysics(),
              child:NotificationListener(
              onNotification:(notification){if(notification is ScrollUpdateNotification){}return true;},
              child:
          
        Column(children:[
        
        Row( 
          children: [
            const SizedBox(width:20),
            Container(
              
              width:105,
              child:
            Column( crossAxisAlignment:CrossAxisAlignment.center,
              children:[
              const SizedBox(height:2),
              Text(L10n.of(context)!.theme), //テーマカラー
              const SizedBox(height:28),
              Text(L10n.of(context)!.font), //フォント
              const SizedBox(height:28),
              Text(L10n.of(context)!.language), //言語
              const SizedBox(height:28),
              Text(L10n.of(context)!.ontime),//定時設定
             

              
            ]),),
            const Column( 
              children:[
              SizedBox(height:5),
              Text("：  "),
              SizedBox(height:28),
              Text("：  "),
              SizedBox(height:28),
              Text("：  "),
              SizedBox(height:28),
              Text("："),
              

            ]),
            Column(crossAxisAlignment:CrossAxisAlignment.start,
              children:[
              DropdownButton<String>(
                value: _selectedTheme,
                onChanged: (String? newValue){
                  if(newValue != null){
                    widget.onThemeChange(newValue);
                    setState((){ _selectedTheme = newValue; });
                  }
                },
                items: <Map<String,String>>[
                  {'display':L10n.of(context)!.blue,'value':'blue'},
                  {'display':L10n.of(context)!.red,'value':'red'},
                  {'display':L10n.of(context)!.green,'value':'green'},
                  {'display':L10n.of(context)!.yellow,'value':'yellow'},
                  {'display':L10n.of(context)!.simple,'value':'mono'},
                  {'display':L10n.of(context)!.dark,'value':'dark'},
                  {'display':L10n.of(context)!.tdefault,'value':'default'},
                ].map<DropdownMenuItem<String>>((Map<String,String> theme){
                  return DropdownMenuItem<String>(
                    value: theme['value'],
                    child: Text(theme['display']!),
                  );
                }).toList(),
              ),

              DropdownButton<String>(
                value: _selectedFont,
                onChanged: (String? newValue){
                  if (newValue != null){
                    widget.onFontChange(newValue);
                    setState((){ _selectedFont = newValue ;});
                  }
                },
                items: <Map<String,String>>[
                  {'display':L10n.of(context)!.gothic,'value':'Gothic'},  //ゴシック
                  {'display':L10n.of(context)!.mincho,'value':'Mincho'},  //明朝体
                  {'display':L10n.of(context)!.anzu,'value':'Anzu'},  //あんずもじ
                  {'display':'Annai MN','value':'Annai'},] 
                  .map<DropdownMenuItem<String>>((Map<String,String> font){
                    return DropdownMenuItem<String>(
                      value: font['value'],
                      child: Text(font['display']!),
                    );
                  }).toList(),
              ),
              DropdownButton<String>(
                value: _selectedLanguage,
                onChanged: (String? newValue){
                  if (newValue != null){
                    widget.onLanguageChange(newValue);
                    setState((){ _selectedLanguage = newValue ;});
                  }
                },
                items: <Map<String,String>>[
                  {'display':L10n.of(context)!.japanese,'value':'ja'},
                  {'display':'English','value':'en'},
                  ]
                  .map<DropdownMenuItem<String>>((Map<String,String> language){
                    return DropdownMenuItem<String>(
                      value: language['value'],
                      child: Text(language['display']!),
                    );
                  }).toList(),
              ),
              const SizedBox(height:2),

              FutureBuilder<Map<String,dynamic>>(future:fetchOnTimeInOut(),builder:(context,snapshot){
                    if(snapshot.connectionState == ConnectionState.waiting){
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasData && snapshot.data != null){
                      final data = snapshot.data!;
                      print("fetch data:$data");
                      TimeOfDay? onTimeIn;
                      TimeOfDay? onTimeOut;
                      if(data['onTimeIn'] != null){
                        onTimeIn = stringToTimeOfDay(data['onTimeIn']);
                      }
                      if(data['onTimeOut'] != null){
                        onTimeOut = stringToTimeOfDay(data['onTimeOut']);
                      }
                      return Row( 
                        children:[
                TextButton(
                onPressed:()async{
                  showOnTimeInOutDialog(context,data);
                  setState((){});
                },
                child: 
                  Row(children:[
                   Text( onTimeIn != null  
                    ? "${L10n.of(context)!.inwork}  ${MaterialLocalizations.of(context).formatTimeOfDay(onTimeIn, alwaysUse24HourFormat: true)} "
                    : "${L10n.of(context)!.inwork}  ${L10n.of(context)!.notset}",
                   style: const TextStyle(decoration:TextDecoration.underline,decorationColor:Colors.grey,decorationThickness:2,)), 
                   const SizedBox(width:5),
                   Text( onTimeOut != null  
                    ? "${L10n.of(context)!.outwork}  ${MaterialLocalizations.of(context).formatTimeOfDay(onTimeOut, alwaysUse24HourFormat: true)}"
                    : "${L10n.of(context)!.outwork}  ${L10n.of(context)!.notset}",
                   style: const TextStyle(decoration:TextDecoration.underline,decorationColor:Colors.grey,decorationThickness:2,)),            
                ]),
                ),
                
              ],);
              } else{ return TextButton(
                onPressed:()async{
                  TimeOfDay onTimeIn = const TimeOfDay(hour:0,minute:0);
                  TimeOfDay onTimeOut = const TimeOfDay(hour:0,minute:0);
                  final dummyData = {'onTimeIn':onTimeIn,'onTimeOut':onTimeOut}; 
                  showOnTimeInOutDialog(context,dummyData);
                  setState((){});
                },
                child: 
                   Text( L10n.of(context)!.notset,
                   style: const TextStyle(decoration:TextDecoration.underline,decorationColor:Colors.grey,decorationThickness:2,),             
                ),);
                
                }},),
          
            ]),
          ]),
           
       
        ]),
        ),
        ),),
        ),

        ),
        

        Column(mainAxisAlignment:MainAxisAlignment.end,
          children:[
            
            Text(L10n.of(context)!.itemlist,  //項目リスト
                      style: const TextStyle(fontSize:20),
                      ),
            Row(children:[  
              const SizedBox(width:20),
              Container(
                
                width: MediaQuery.of(context).size.width *0.8,
                height: itemListHeight ,
                decoration: BoxDecoration(
                  border: Border.all(color:Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                
                child:FutureBuilder<List<Map<String, dynamic>>>(
                  future: AttendanceLogic.overtimeReasonRecords(),
                  builder: (context,snapshot){
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No records found.'));
                    }
                    records = snapshot.data!;

                    return  GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 1,
                        childAspectRatio:3.4,
                      ),
                      itemCount:records.length ,
                      itemBuilder: (context,index){
                        final record = records[index];    

                        String text = record['overtime_reason'];
                       //表示を長さで変えるようにテキストの長さ取得したけど、今のところ不使用
                        double measure_size = 20;//計測するときの文字の大きさと実際の表示を統一
                        TextStyle style = TextStyle(fontSize: measure_size);   
                        TextPainter textPainter = TextPainter(
                          text: TextSpan(text: text, style: style),
                          textDirection: TextDirection.ltr,
                        );
                        textPainter.layout();
                        //double textWidth = textPainter.width;                     
                        
                      return GestureDetector(
                          onTap:(){
                            setState((){
                            selectedIndex = index ;
                            });
                          },
                          onLongPress:()async{
                            await _showEditItemNameDialog(context,record['id']);
                            
                            setState((){selectedIndex = index;});
                          },
                          
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical:2,horizontal:5),
                        decoration: BoxDecoration(
                          color: selectedIndex == index 
                            ? Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,50,50,50) :const Color(0x156E79CF)
                          : Colors.transparent,
                        border: Border.all(
                          color: selectedIndex == index 
                            ? Theme.of(context).brightness == Brightness.dark ? Colors.grey :const Color(0x8F6E79CF)
                            : Colors.transparent,
                          width:2,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical:2,horizontal:8),
                          child: Column(
                            crossAxisAlignment:CrossAxisAlignment.start,
                            children: [
                              Text(record['overtime_reason'] ?? '',
                                style: TextStyle(fontSize:measure_size),
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                //maxLines:2,
                              ),
                            ],
                          ),
                      ),
                      );
                      },
                    
                    ); 
                  },       
                ),
              
            ),
            Column(     
              children:[
              SizedBox(height:usableHeight -450 >= 250 ? 125 : (usableHeight - 450)/2),
              IconButton(
                icon:const Icon(Icons.expand_less),
                onPressed:()async{
                  final db = await DatabaseHelper.getDatabaseInstance();
                  if (selectedIndex  != null ){
                    final record = records[selectedIndex!];
                    if (record['order_index'] != 1 ){
                      await AttendanceLogic.swapItems(db,record['order_index']-1,record['order_index']);
                      setState((){selectedIndex = selectedIndex!-1;});
                    }
                  }
                }
              ),
              IconButton(
                icon:const Icon(Icons.expand_more),
                onPressed:()async{
                  final db = await DatabaseHelper.getDatabaseInstance();
                  if (selectedIndex  != null ){
                    final record = records[selectedIndex!];
                    if (record['order_index'] != records.length ){
                      await AttendanceLogic.swapItems(db,record['order_index'],record['order_index']+1);
                      setState((){selectedIndex = selectedIndex!+1;});
                    }
                  }
                },
              ),

           

          ],),

          ],
        ),
        const SizedBox(height:8),

        Row( mainAxisAlignment:MainAxisAlignment.center,
          children:[
        TextButton(
          onPressed: () =>  openUrl(context, Localizations.localeOf(context).languageCode == 'ja' ? jpTermsUrl : enTermsUrl),
          child:Text(L10n.of(context)!.terms),
        ),
        TextButton(
          onPressed: () =>  openUrl(context, Localizations.localeOf(context).languageCode == 'ja' ? jpPrivacyPolicyUrl : enPrivacyPolicyUrl),
          child:Text(L10n.of(context)!.privacy),
        ),
        TextButton(
          onPressed: () =>  openUrl(context, Localizations.localeOf(context).languageCode == 'ja' ? jpQAndAUrl : enQAndAUrl),
          child:const Text("FAQ"),
        ),
        //const SizedBox(width:40)

        ]),
        
        Align(
          alignment: Alignment.bottomRight,
          child:Padding(
            padding: const EdgeInsets.fromLTRB(0,0,30,10),
            child: 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                side: const BorderSide(color:Colors.grey),
              ),
              onPressed: (){
                _showInputDialog(context);//定型文作成
              },
              child:Text(L10n.of(context)!.phrase,   //'定型文作成'
                style: TextStyle(fontSize:Localizations.localeOf(context).languageCode == 'ja' ? 28 :23,color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null),
              ),
            ),
          ),
        ),
        const Align(alignment: Alignment.bottomRight,
          child: Padding(padding: EdgeInsets.fromLTRB(0,0,15,8),
            child:
          Text("©2024 Mig's Factory",style:TextStyle(fontSize:10)),
          ),
        ),
      ],),
      ],),

        floatingActionButton: FloatingActionButton(
          onPressed:() async {
            if (selectedIndex == null){
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content:Text(L10n.of(context)!.tobedelete)), //'削除対象を選択してください。'
              );
            } else {
              showDialog(
                context:context,
                builder:(_) => AlertDialog(
                  title:Text(L10n.of(context)!.confirm_delete),  //'削除確認'
                  content: Text(
                    L10n.of(context)!.reallydelete //"本当に削除してもよろしいですか？"
                  ),
                  actions: [
                    TextButton(
                      child:const Text("Cancel"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child:const Text("OK"),
                      onPressed: () async{
                        Navigator.of(context).pop();
                          final selectRecord = records[selectedIndex!];
                          final selectId = selectRecord['id'];
                          await DatabaseHelper.deleteRecord("overtime_reason_table",'id = ?',[selectId]);
                          setState((){selectedIndex = null;});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(L10n.of(context)!.deleted)),);  //削除しました。
                      }
                      
                    ),
                  ],
                )
              );
            }
          },
          child:const Icon(Icons.delete),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,

    );
  }
  void _showInputDialog(BuildContext context){
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children:[
            Text(L10n.of(context)!.itemname,style:const TextStyle(fontSize:15,)), //'項目名を入力してください。'
            const SizedBox(height:2),
            Text(L10n.of(context)!.omission,style:const TextStyle(fontSize:12,),),  //'(15文字以内:長文は一覧では省略されます。)'
            ],),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: L10n.of(context)!.here),  //'ここに入力'
            maxLength:15,
            
          ),
          actions: [
            TextButton(
              onPressed: (){
                Navigator.of(context).pop();
              },
              child: Text('Cancel',style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
            ),
            TextButton(
              onPressed: ()async {
                //登録処理 _controller.text
                var functions = Functions();
                if ((_controller.text).trim().isEmpty){
                  functions.informationModal(L10n.of(context)!.error,L10n.of(context)!.itemname,context,); //エラー、項目名を入力してください。
                  return;
                }
                Navigator.of(context).pop();
                
                bool reason = await AttendanceLogic.checkOvertimeReason(_controller.text);
                if(reason){
                  functions.informationModal(L10n.of(context)!.regist_complete,"${_controller.text}${L10n.of(context)!.isregistered}",context,);  //登録完了、を登録しました。
                  setState((){});
                }  else {
                  functions.informationModal(L10n.of(context)!.error,"${_controller.text}${L10n.of(context)!.yetregist}",context,);  //エラー、はすでに登録済みです。
                }
                
              },
              child: Text('OK',style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
            ),
          ],
        );
      },
      );

  }
  
}

//一覧画面
class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> with AutomaticKeepAliveClientMixin{
  int? selectedIndex;
  ScrollController _scrollController = ScrollController();
  double? _currentScrollPosition;
  DateTime monthList = DateTime.now();
  DateTime fetchMonth = DateTime.now();
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState(){
    super.initState();  
    _scrollController = ScrollController();  
  }


  void _navigateToCalendar(BuildContext context){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:(context) => AttendanceListScreenCalendar(
          initialDate: monthList,
        ),
      ),
    ).then((_){setState((){ });});
  }
  Future<void> _pickMonth(BuildContext context) async{
    DateTime? picked = await showMonthPicker(
      context:context,
      initialDate: monthList,
      firstDate:DateTime(2020),
      lastDate: DateTime(2150),
    );
    if (picked != null && picked != monthList){
      setState((){ 
        monthList = DateTime(picked.year,picked.month);
        fetchMonth = DateTime(picked.year,picked.month); 
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String dateFormatYm = L10n.of(context)!.date_format_ym ;
    //DateTime now = DateTime.now();
    List<Map<String,dynamic>> records = [];
    String _stateValue = 'state';
    String formatDateString(String? date){
      if (date== null) return L10n.of(context)!.unregistered;
      final DateTime parsedDate = DateTime.parse(date);
      return intl.DateFormat('y-M-dd(EEE)').format(parsedDate);
    }
    TimeOfDay? onTimeIn;
    TimeOfDay? onTimeOut;
    TimeOfDay? checkIn;
    TimeOfDay? checkOut;
    
    return Scaffold(
      appBar: AppBar(
        
        //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children:[
            Text(L10n.of(context)!.monthlist), //月別一覧
        ],),
        actions: [
          Builder(
            builder:(BuildContext context){
              return IconButton(icon: const Icon(Icons.calendar_month),
          onPressed: (){ 
            _navigateToCalendar(context);
          },
          );
            },
          ),
        ],
      ),

      body: Column(children:[
        Row(children:[
          TextButton(child:Text(" < ", style:TextStyle(fontWeight:FontWeight.bold,color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null),),
            onPressed:()async{
              setState((){
                if (monthList==DateTime(2020,1)){

                } else {
                  if (monthList.month == 1){
                    monthList = DateTime(monthList.year -1,12);
                    fetchMonth = DateTime(fetchMonth.year -1,12);
                  } else {
                    monthList = DateTime(monthList.year,monthList.month -1);
                    fetchMonth = DateTime(fetchMonth.year,fetchMonth.month -1);
                  }
                } 
              });
            }),
          TextButton(
            child: 
            Text(intl.DateFormat(dateFormatYm).format(monthList), //y年M月
            style: TextStyle(fontSize:20,color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null),),
            onPressed:(){
              _pickMonth(context);
            },
          ),

          TextButton(child:Text(" > ", style:TextStyle(fontWeight:FontWeight.bold,color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null),),
            onPressed:()async{
              setState((){
                if (monthList == DateTime(2150,12)){
                } else {
                  if (monthList.month == 12){
                    monthList = DateTime(monthList.year +1,1);
                    fetchMonth = DateTime(fetchMonth.year +1,1);
                  } else {
                    monthList = DateTime(monthList.year,monthList.month +1);
                    fetchMonth = DateTime(fetchMonth.year,fetchMonth.month +1);
                  }
                }
              });
            }),


        ],),
        Expanded(child:
        FutureBuilder<List<Map<String, dynamic>>>(
            future: AttendanceLogic.fetchMonthlyRecords(intl.DateFormat('yyyy-MM').format(fetchMonth)),
            builder: (context,snapshot){
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No records found.'));
              }
              records = snapshot.data!;
             
              var functions = Functions();
              return FutureBuilder<Map<String, dynamic>>(
            future: functions.getSharedPref(),
            builder: (context,snap){
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              } else if (!snap.hasData || snap.data!.isEmpty) {
                return const Center(child: Text('No records found.'));
              }
              final prefsData = snap.data!;

              if (prefsData['onTimeIn'] != null){
                onTimeIn = stringToTimeOfDay(prefsData['onTimeIn']);
              }
              if (prefsData['onTimeOut'] != null){
                onTimeOut = stringToTimeOfDay(prefsData['onTimeOut']);
              }

              int timeIn = 0;
              int timeOut = 0;
              for (int i = 0; i< records.length; i++){                
                if (onTimeIn != null && records[i]['check_in']!=null){
                  if (records[i]['check_in'] == L10n.of(context)!.unregistered || records[i]['check_in'] == "N/A"){
                    
                  } else {
                    TimeOfDay checkInTOD =  stringToTimeOfDay(records[i]['check_in']);
                    int onTimeInMinute = onTimeIn!.hour * 60 + onTimeIn!.minute;
                    int checkInMinute = checkInTOD!.hour * 60 + checkInTOD!.minute;
                    if (onTimeInMinute > checkInMinute){
                      timeIn = timeIn + onTimeInMinute - checkInMinute;
                    }
                  }
                }
                if (onTimeOut != null && records[i]['check_out']!=null){
                  if (records[i]['check_out'] == L10n.of(context)!.unregistered || records[i]['check_out'] == "N/A"){
                    
                  } else {
                    TimeOfDay checkOutTOD =  stringToTimeOfDay(records[i]['check_out']);
                    int onTimeOutMinute = onTimeOut!.hour * 60 + onTimeOut!.minute;
                    int checkOutMinute = checkOutTOD!.hour * 60 + checkOutTOD!.minute;
                    if (onTimeOutMinute < checkOutMinute){
                      timeOut = timeOut - onTimeOutMinute + checkOutMinute;
                    }
                  }
                }
              }
              int totalOvertime = timeIn + timeOut;
              TimeOfDay totalOvertimeTOD = TimeOfDay(hour: totalOvertime ~/60,minute:totalOvertime % 60);
              String totalOvertimeTODhmString = "${totalOvertimeTOD.hour}h ${totalOvertimeTOD.minute}m"; 
              if (prefsData['onTimeIn'] == null && prefsData['onTimeOut'] == null){totalOvertimeTODhmString = L10n.of(context)!.notsetontime;}

              return ListView.builder(
                controller: _scrollController,
                itemCount:records.length+2,//１つ下の余白に使う,1つtotal overtime用に追加
                itemBuilder: (context,index){
                  
                  if (index == 0){
                    return Padding(padding: const EdgeInsets.only(right:20),
                      child: Align(
                      alignment:Alignment.centerRight,
                      child:Text('${L10n.of(context)!.totalovertime} : $totalOvertimeTODhmString'),
                    ),);
                  }

                  if (index == records.length+1){
                      return const SizedBox(height:100);
                  }

                  final record = records[index-1];
                  final formatDate = formatDateString(record['date']).replaceAll("-","/");

                  
                  if (record['check_in'] != null && (record['check_in'] != L10n.of(context)!.unregistered && record['check_in'] != "N/A") ){

                    checkIn = stringToTimeOfDay(record['check_in']);
                  }
                  if (record['check_out'] != null && (record['check_out'] != L10n.of(context)!.unregistered && record['check_out'] != "N/A")){
                    
                    checkOut = stringToTimeOfDay(record['check_out']);
                  }

                  int overtimePre = 0 ;
                  int overtimePost = 0 ;
                  if(onTimeIn != null && (record['check_in'] != null && (record['check_in'] != L10n.of(context)!.unregistered && record['check_in'] != "N/A") )){
                    int onTimeMin1 = onTimeIn!.hour * 60 + onTimeIn!.minute;
                    int checkInMin = checkIn!.hour * 60 + checkIn!.minute;
                    if (onTimeMin1 > checkInMin){
                      overtimePre = onTimeMin1 - checkInMin;
                    }                
                  }
                  if(onTimeOut != null && (record['check_out'] != null && (record['check_out'] != L10n.of(context)!.unregistered && record['check_out'] != "N/A")  )){
                    int onTimeMin2 = onTimeOut!.hour * 60 + onTimeOut!.minute;
                    int checkOutMin = checkOut!.hour * 60 + checkOut!.minute;
                    if (onTimeMin2 < checkOutMin){
                      overtimePost = checkOutMin - onTimeMin2;
                    }                
                  }
                  int overtime = overtimePre + overtimePost ;
                  TimeOfDay overtimeTimeOfDay = TimeOfDay(hour:overtime ~/ 60,minute:overtime % 60);

                  return GestureDetector(
                    onTap: (){
                      _currentScrollPosition = _scrollController.position.pixels;
                      setState((){
                        selectedIndex = index-1;
                      });
                      Future.delayed(const Duration(milliseconds:100),(){
                        _scrollController.jumpTo(_currentScrollPosition!);
                      });
                      
                      },
                    onLongPress:()async{
                      final String? result = await _showEditDialog(context,records[index-1]);
                      _stateValue = result ?? 'state';
                      setState((){});
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical:2,horizontal:15),
                      decoration: BoxDecoration(
                        color: selectedIndex == index-1
                          ? const Color(0x156E79CF)
                          : Colors.transparent,
                        border: Border.all(
                          color: selectedIndex == index-1
                            ? const Color(0x8F6E79CF)
                            : Colors.transparent,
                          width:2,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment:CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,
                            children:[
                            Text('${L10n.of(context)!.date}: $formatDate',
                              style:const TextStyle(fontWeight:FontWeight.bold,)),
                            Text(overtime != 0 ? '${L10n.of(context)!.overtime}: ${overtimeTimeOfDay.hour}h${overtimeTimeOfDay.minute}m' : "",
                              style:const TextStyle(fontSize:12)),
                            const SizedBox.shrink(),
                          ],),
                          Row(children:[
                            Text('${L10n.of(context)!.attendance_time} : ${record['check_in'] ?? L10n.of(context)!.unregistered}'),
                            const SizedBox(width:25),
                            Text('${L10n.of(context)!.leavework_time} : ${record['check_out'] ?? L10n.of(context)!.unregistered}'),
                          ]),
                          Text('${L10n.of(context)!.reason} : ${record['overtime_reasons'] ?? ''}'),
                          Text('${L10n.of(context)!.remarks} : ${record['free'] ?? ''}'),
                        ],
                      ),
                    ),
                  );
                },
              );},
              );        
            },
        ),),
        ],),
      floatingActionButton: Stack(
        children:[
          Positioned(
            bottom: 16,
            left : 30,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: ()async{
              if (selectedIndex == null){
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content:Text(L10n.of(context)!.tobedelete)), //削除対象を選択してください。
              );
            } else {
              showDialog(
                context:context,
                builder:(_) => AlertDialog(
                  title:Text(L10n.of(context)!.confirm_delete), //削除確認
                  content: Text(
                    L10n.of(context)!.reallydelete  //"本当に削除してもよろしいですか？"
                  ),
                  actions: [
                    TextButton(
                      child:Text("Cancel",style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child:Text("OK",style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
                      onPressed: () async{
                        Navigator.of(context).pop();
                          final selectRecord = records[selectedIndex!];
                          final selectId = selectRecord['id'];
                          await DatabaseHelper.deleteRecord("attendance_table",'id = ?',[selectId]);
                          setState((){selectedIndex = null;});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(L10n.of(context)!.deleted)),);  //削除しました。
                      }
                      
                    ),
                  ],
                )
              );
            }
            },

              child:const Icon(Icons.delete ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(onPressed: ()async{
              final String? result = await _showAddAttendanceModal(context,monthList);
              _stateValue = result ?? 'state';
                setState((){ });
              
            },
              child:const Icon(Icons.playlist_add ),
            ),
          ),
        ],
      ),

    );
    
  }
TimeOfDay stringToTimeOfDay(String time){
  final parts = time.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  return TimeOfDay(hour:hour,minute:minute);
}

//一覧画面の編集用モーダル
Future<String?> _showEditDialog(BuildContext context,Map<String,dynamic> item)async{
  TimeOfDay? checkInTime ;
  TimeOfDay? checkOutTime ;
  Set<int> selectedIndices = <int>{};
  String? free = item['free'];
  DateTime editDay = DateTime.parse(item['date']);

  final DateTime displayDate = DateTime.parse(item['date']);

  Future<void> initialIndices(Map<String,dynamic> item)async{
  List<Map<String,dynamic>> prerecords = await AttendanceLogic.overtimeReasonRecords();
  if (item['overtime_reasons'] != null && item['overtime_reasons'].isNotEmpty){
    for (String reason in item['overtime_reasons'].split(',')){
      for (var record in prerecords){
        if (record['overtime_reason'] == reason){
          selectedIndices.add(record['id']);  
        }
      }
    } 
  }}
  await initialIndices(item);
                    

  final result = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder:(BuildContext context,StateSetter setState){
      return AlertDialog(
        title: Text(L10n.of(context)!.edit),  //編集
        content: SingleChildScrollView(
          child: Column(children:[
          Align(  alignment: Alignment.centerLeft,
            child: Text(intl.DateFormat('y-M-dd(EEE)').format(displayDate),style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),),
          TextButton(
            style: TextButton.styleFrom(
              side: const BorderSide(color:Colors.grey,width:1),
              shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),),
            ),
            onPressed:()async{
              final time = await _showTimePicker(context);
              if (time != null){            
                setState((){ checkInTime = time; });          
              }
            },
            child: Text(checkInTime != null 
              ? "${L10n.of(context)!.attendance_time} : ${MaterialLocalizations.of(context).formatTimeOfDay(checkInTime!, alwaysUse24HourFormat: true)}" 
              : '${L10n.of(context)!.attendance_time} : ${item['check_in']}',style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              side: const BorderSide(color:Colors.grey,width:1),
              shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),),
            ),
            onPressed:()async{
              final time = await _showTimePicker(context);
              if (time != null){
                setState((){ checkOutTime = time; });
              }
            },
            child: Text(checkOutTime != null 
              ? "${L10n.of(context)!.leavework_time} : ${MaterialLocalizations.of(context).formatTimeOfDay(checkOutTime!, alwaysUse24HourFormat: true)}" 
              : '${L10n.of(context)!.leavework_time} : ${item['check_out']}',style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
          ),
          Align(
                  alignment:Alignment.centerLeft,
                  child:
                    TextButton(                     
                      onPressed: ()async {
                        free = await _showInputFreeDialog(context,free); 
                        setState((){});      
                      },
                      style: TextButton.styleFrom(
                            side: const BorderSide(color:Colors.grey,width:1),
                            padding: const EdgeInsets.symmetric(horizontal:20,vertical:8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),),
                            backgroundColor: (free?.isEmpty ?? true)
                              ? Colors.transparent
                              : Theme.of(context).brightness == Brightness.dark ? Colors.black :const Color.fromARGB(255,235,235,255),
                            
                      ),
                      child: Text(L10n.of(context)!.free,style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),  //自由記述
                    ),
          ),
          FutureBuilder<List<Map<String,dynamic>>>(
                  future: AttendanceLogic.overtimeReasonRecords(),
                  builder: (context, snapshot){
                    if (snapshot.connectionState == ConnectionState.waiting){
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError){
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty){
                      return const Center(child: Text('No records found.'));
                    }
                    final records = snapshot.data!;


                    return Container(
                      margin: const EdgeInsets.fromLTRB(0,10,0,15),
                      width: MediaQuery.of(context).size.width *0.9,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color:Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child:GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 2.8,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 0.5,
                          ),
                          itemCount: records.length,
                          itemBuilder: (context,index){
                            final record = records[index];
                            final recordId = record['id'] as int;
                            
                            final isSelected = selectedIndices.contains(recordId);
                            return GestureDetector(
                              onTap: (){
                                setState((){
                                  if (isSelected) {
                                    selectedIndices.remove(recordId);                                  
                                  } else {
                                    selectedIndices.add(recordId);                                 
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical:5,horizontal:5),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,50,50,50) :const Color(0x156E79CF) 
                                    : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected 
                                      ? Theme.of(context).brightness == Brightness.dark ? Colors.grey :const Color(0x8F6E79CF) 
                                      : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding:  const EdgeInsets.all(5),
                                child: Column(
                          
                                  children: [
                                    Text(
                                      record['overtime_reason'] ?? '',
                                      style:  const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis, // 長い文字列を省略
                                      maxLines: 1, // 最大2行
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                ),
          
        ],),),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('ok'),
            style: TextButton.styleFrom(
                        backgroundColor:const Color.fromARGB(255,200,200,200),
                        foregroundColor:const Color.fromARGB(255,0,0,0),
                      padding: const EdgeInsets.symmetric(horizontal:20,vertical:10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),),
                      ),
            child: Text(L10n.of(context)!.cancel,style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
          ),
          TextButton(
            onPressed:()async {
              checkInTime ??= (item['check_in'] != L10n.of(context)!.unregistered && item['check_in'] != "N/A")
                ? stringToTimeOfDay(item['check_in'])
                : null;            
              checkOutTime ??= (item['check_out'] != L10n.of(context)!.unregistered && item['check_in'] != "N/A")
                ? stringToTimeOfDay(item['check_out'])
                : null;      
              
              final overReason = selectedIndices.toList();
              final overtimeReason = overReason.join(',');
              await AttendanceUtils.addAttendance(
                context:context,
                date:editDay,
                checkInTime:checkInTime,
                checkOutTime:checkOutTime,
                free:free,
                overtimeReason:overtimeReason,
                flagInOut: "edit",
              ); 
            },
            style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,30,30,30) :const Color.fromARGB(255, 95, 130, 234),
                        foregroundColor:const Color.fromARGB(255,255,255,255),
                        padding: const EdgeInsets.symmetric(horizontal:30,vertical:10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),),
                      ),
            child: Text(L10n.of(context)!.edit,style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),  //編集
          ),
        ],
      );
        },);
    },
  );
  return Future.value();
}

Future<TimeOfDay?> _showTimePicker(BuildContext context) async {
    TimeOfDay? pickedDate = await showTimePicker(
      context:context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale:const Locale('en','US'),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );      
    if (pickedDate != null){
      return pickedDate;
    }
      return null;
    }

Future<String?> _showInputFreeDialog(BuildContext context,String? free) async {
    final TextEditingController _controller = TextEditingController(text:free);

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children:[
            Text(L10n.of(context)!.content_input,style:const TextStyle(fontSize:15,)), //内容を入力してください。
            const SizedBox(height:2),
            Text(L10n.of(context)!.twentychar,style:const TextStyle(fontSize:12,),),  //（20文字以内）
            ],),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: L10n.of(context)!.here),  //ここに入力
            maxLength:20,
            
          ),
          actions: [
            TextButton(
              onPressed: (){
                  Navigator.of(context).pop(free);                 
              },
              child: Text('Cancel',style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
            ),
            TextButton(
              onPressed: ()async {
                Navigator.of(context).pop((_controller.text).trim());
              },
              child: Text('OK',style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
            ),
          ],
        );
      },
      );
  }

//一覧画面の編集追加モーダル
  Future<String?> _showAddAttendanceModal(BuildContext context,DateTime monthList)async {
    //初期値
    TimeOfDay checkInTime = const TimeOfDay(hour:0,minute:0);
    TimeOfDay checkOutTime = const TimeOfDay(hour:0,minute:0);
    Set<int> selectedIndices = <int>{}; 
    DateTime _selectedDate = monthList;
    String? free;
    
    Future<TimeOfDay?> _showTimePicker(BuildContext context) async {
    TimeOfDay? pickedDate = await showTimePicker(
      context:context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale:const Locale('en','US'),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );      
    if (pickedDate != null){
      return pickedDate;
    }
      return null;
    }
    Future<void> _pickDate(BuildContext context,StateSetter setState)  async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate:DateTime(2100),
        locale: Localizations.localeOf(context),
      );
      if (pickedDate != null && pickedDate != _selectedDate) {
        setState((){
          _selectedDate = pickedDate;
        });
      }
    }
    void _showInputDialog(BuildContext context){
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children:[
            Text(L10n.of(context)!.itemname,style:const TextStyle(fontSize:15,)), //'項目名を入力してください。'
            const SizedBox(height:2),
            Text(L10n.of(context)!.omission,style:const TextStyle(fontSize:12,),), //'(15文字以内:長文は一覧では省略されます。)'
            ],),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: L10n.of(context)!.here),  //'ここに入力'
            maxLength:15,
            
          ),
          actions: [
            TextButton(
              onPressed: (){
                Navigator.of(context).pop();
              },
              child: Text(L10n.of(context)!.cancel,style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
            ),
            TextButton(
              onPressed: ()async {
                //登録処理 _controller.text
                var functions = Functions();
                if ((_controller.text).trim().isEmpty){
                  functions.informationModal(L10n.of(context)!.error,L10n.of(context)!.itemname,context,); //エラー、項目名を入力してください。
                  return;
                }
                Navigator.of(context).pop();
                
                bool reason = await AttendanceLogic.checkOvertimeReason(_controller.text);
                if(reason){
                  functions.informationModal(L10n.of(context)!.regist_complete,"${_controller.text}${L10n.of(context)!.isregistered}",context,);  //登録完了、を登録しました。
                  setState((){});
                }  else {
                  functions.informationModal(L10n.of(context)!.error,"${_controller.text}${L10n.of(context)!.yetregist}",context,);  //エラー、はすでに登録済みです。
                }
                
              },
              child: Text('OK',style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
            ),
          ],
        );
      },
      );
  }
    String dateFormatLong = L10n.of(context)!.date_formatlong;
    final result = await showDialog<String>(
      context:context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context,StateSetter setState){

        return AlertDialog(
          title: Text(L10n.of(context)!.newinput, //新規入力
            style:const TextStyle(fontSize:20),),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:[
                Align(
                  alignment:Alignment.centerLeft,
                  child:
                    TextButton(
                      onPressed:()async{
                        await _pickDate(context,setState);
                      },
                      style: TextButton.styleFrom(
                        side: const BorderSide(color:Colors.grey,width:1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text( intl.DateFormat(dateFormatLong).format(_selectedDate),style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null) ),  //y年M月d日(EEE)
                    ),
                ),

                TextButton(                
                  onPressed: ()async {
                    final time = await _showTimePicker(context);
                    if (time != null){                     
                      setState((){checkInTime = time;});          
                    }
                  },
                  style: TextButton.styleFrom(
                        side: const BorderSide(color:Colors.grey,width:1),
                        padding: const EdgeInsets.symmetric(horizontal:20,vertical:10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                  ),
                  child: Text("${L10n.of(context)!.attendance_time} : ${MaterialLocalizations.of(context).formatTimeOfDay(checkInTime, alwaysUse24HourFormat: true)}",style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),  //出勤時間
                ),
                TextButton(               
                  onPressed: ()async {
                    final time = await _showTimePicker(context);
                    if (time != null){                     
                      setState((){checkOutTime = time;});                   
                    }
                  },
                  style: TextButton.styleFrom(
                        side: const BorderSide(color:Colors.grey,width:1),
                        padding: const EdgeInsets.symmetric(horizontal:20,vertical:10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                  ),
                  child: Text("${L10n.of(context)!.leavework_time} : ${MaterialLocalizations.of(context).formatTimeOfDay(checkOutTime, alwaysUse24HourFormat: true)}",style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)), //退勤時間
                ),
                Align(
                  alignment:Alignment.centerLeft,
                  child:
                    TextButton(                   
                      onPressed: ()async {
                        free = await _showInputFreeDialog(context,free); 
                        setState((){});      
                      },
                      style: TextButton.styleFrom(
                            side: const BorderSide(color:Colors.grey,width:1),
                            padding: const EdgeInsets.symmetric(horizontal:20,vertical:8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),),
                            backgroundColor: (free?.isEmpty ?? true)
                              ? Colors.transparent
                              : Theme.of(context).brightness == Brightness.dark ? Colors.black :const Color.fromARGB(255,235,235,255),
                            
                      ),
                      child: Text(L10n.of(context)!.free,style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),  //自由記述
                    ),
                ),

                FutureBuilder<List<Map<String,dynamic>>>(
                  future: AttendanceLogic.overtimeReasonRecords(),
                  builder: (context, snapshot){
                    if (snapshot.connectionState == ConnectionState.waiting){
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError){
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty){
                      return const Center(child: Text('No records found.'));
                    }
                    final records = snapshot.data!;

                    return Container(
                      margin: const EdgeInsets.fromLTRB(0,10,0,15),
                      width: MediaQuery.of(context).size.width *0.9,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color:Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child:GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 2.8,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 0.5,
                          ),
                          itemCount: records.length,
                          itemBuilder: (context,index){
                            final record = records[index];
                            final recordId = record['id'] as int;
                            final isSelected = selectedIndices.contains(recordId);

                            return GestureDetector(
                              onTap: (){
                                setState((){
                                  if (isSelected) {
                                    selectedIndices.remove(recordId);
                                  } else {
                                    selectedIndices.add(recordId);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical:5,horizontal:5),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,50,50,50) :const Color(0x156E79CF) 
                                    : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected 
                                      ? Theme.of(context).brightness == Brightness.dark ? Colors.grey :const Color(0x8F6E79CF) 
                                      : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding:  const EdgeInsets.all(5),
                                child: Column(
                          
                                  children: [
                                    Text(
                                      record['overtime_reason'] ?? '',
                                      style:  const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis, // 長い文字列を省略
                                      maxLines: 1, // 最大2行
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children:[
                    TextButton(
                      onPressed:(){
                        Navigator.of(context).pop('ok');
                      },
                      style: TextButton.styleFrom(
                        backgroundColor:const Color.fromARGB(255,200,200,200),
                        foregroundColor:const Color.fromARGB(255,0,0,0),
                      padding: const EdgeInsets.symmetric(horizontal:20,vertical:10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),),
                      ),
                      child:Text(L10n.of(context)!.cancel),
                    ),
                    const SizedBox(width:10),
                    TextButton(
                      onPressed: ()async {
                        final overReason = selectedIndices.toList();
                        final overtimeReason = overReason.join(',');
                        await AttendanceUtils.addAttendance(
                          context:context,
                          date:_selectedDate,
                          checkInTime:checkInTime,
                          checkOutTime:checkOutTime,
                          free:free,
                          overtimeReason:overtimeReason,
                          flagInOut: "inOut",
                        );
                        Navigator.of(context).pop;
                      },
                      style: TextButton.styleFrom(
                        backgroundColor:const Color.fromARGB(255, 95, 130, 234),
                        foregroundColor:const Color.fromARGB(255,255,255,255),
                        padding: const EdgeInsets.symmetric(horizontal:30,vertical:10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),),
                      ),
                      child:Text(L10n.of(context)!.regist), //登録
                    ),

                  ]
                )

              ],

            ),
          ),
        );
        },);
      },
      
    );

  }

}
//一覧画面カレンダーver.
class AttendanceListScreenCalendar extends StatefulWidget {
  const AttendanceListScreenCalendar({super.key,required this.initialDate});

  final DateTime initialDate;

  @override
  State<AttendanceListScreenCalendar> createState() => _AttendanceListScreenCalendarState();
}

class _AttendanceListScreenCalendarState extends State<AttendanceListScreenCalendar> {
     
    Map<DateTime, List<String>> _events ={};
    late DateTime _focusedDay;
    DateTime? _selectedDay;
    String? free ;
    TimeOfDay? selectedTime;
    TimeOfDay? checkInTime ;
    TimeOfDay? checkOutTime ;
    Set<int> selectedIndices = <int>{};
    String? _selectedEvent;
    String _stateValue = 'state';
    DateTime? displayMonth; 
    DateTime focusedDay = DateTime.now();

    @override
    void initState(){
      super.initState();
      _focusedDay = widget.initialDate;
      _selectedDay = _focusedDay;
      displayMonth =  widget.initialDate;
            
    }

    Future<void> _loadEvents(BuildContext context) async{
      final events = await _initializedEvents(context);
      setState((){
        _events = events;
      });
    }
      //日付ごとのリストデータ
    Future<Map<DateTime,List<String>>> _initializedEvents(BuildContext context) async {
        
        final records = await AttendanceLogic.allRecords();
        final events = <DateTime, List<String>>{};
        var functions = Functions();
        final prefData = await functions.getSharedPref();
        TimeOfDay? onTimeIn;
        TimeOfDay? onTimeOut;
        int onTimeInMin = 0;
        int onTimeOutMin = 0;
        if (prefData['onTimeIn'] != null){
          onTimeIn = stringToTimeOfDay(prefData['onTimeIn']);
          onTimeInMin = onTimeIn.hour *60 + onTimeIn.minute;
        }
        if (prefData['onTimeOut'] != null){
          onTimeOut = stringToTimeOfDay(prefData['onTimeOut']);
          onTimeOutMin = onTimeOut.hour *60 + onTimeOut.minute;
        }

        for (var record in records){
          DateTime eventDate = DateTime.parse(record['date']);
          eventDate = DateTime(eventDate.year,eventDate.month,eventDate.day);

          int overtimeInMin =0 ;
          int overtimeOutMin = 0;
          if (record['check_in'] != null && (record['check_in'] != L10n.of(context)!.unregistered && record['check_in'] != "N/A") ){
            TimeOfDay? checkInTOD = stringToTimeOfDay(record['check_in']);
            int checkInMin = checkInTOD.hour *60 + checkInTOD.minute;
            if (onTimeInMin > checkInMin){overtimeInMin = onTimeInMin - checkInMin;}
          }
          if (prefData['onTimeIn'] == null){overtimeInMin = 0;}
          if (record['check_out'] != null && (record['check_out'] != L10n.of(context)!.unregistered && record['check_out'] != "N/A") ){
            TimeOfDay? checkOutTOD = stringToTimeOfDay(record['check_out']);
            int checkOutMin = checkOutTOD.hour *60 + checkOutTOD.minute;
            if (onTimeOutMin < checkOutMin){overtimeOutMin = checkOutMin - onTimeOutMin ;}
          }
          if (prefData['onTimeOut'] == null){overtimeOutMin = 0;}
          int overtime = overtimeInMin + overtimeOutMin;
          TimeOfDay overtimeTOD = TimeOfDay(hour:overtime ~/ 60,minute:overtime % 60);
          String overtimeTODString = "\n ${L10n.of(context)!.overtime} : ${overtimeTOD.hour}h ${overtimeTOD.minute}m";
          if (prefData['onTimeOut'] == null && prefData['onTimeIn'] == null){overtimeTODString = "";}
          String checkIn = record['check_in'] ?? L10n.of(context)!.unregistered;
          checkIn = '${L10n.of(context)!.inwork} : $checkIn';
          String checkOut = record['check_out'] ?? L10n.of(context)!.unregistered;
          checkOut = '${L10n.of(context)!.outwork} : $checkOut';
          String overtimeReason = record['overtime_reasons'] ?? '';
          String free = record['free'] ?? '';
          
          String dateFormatLong = L10n.of(context)!.date_formatlong ;
          
          String? monthDate = intl.DateFormat(dateFormatLong).format(eventDate);
          
          events[eventDate] ??= [];
          events[eventDate]!.add('$monthDate $overtimeTODString\n $checkIn   $checkOut \n ${L10n.of(context)!.item}$overtimeReason \n ${L10n.of(context)!.remarks} : $free');  //項目：、備考：
          }
        return events;
      }
    

    //選択した日付のイベントリスト取得
    List<String> _getEventsForDay(DateTime day){
      DateTime dateOnly = DateTime(day.year, day.month, day.day);
      return _events[dateOnly] ?? [];      
    }
   

    @override
    Widget build(BuildContext context){

      if (_events.isEmpty) {
          _loadEvents(context);
      }
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children:[
              Text(L10n.of(context)!.monthlist), //月別一覧
          ],),
          actions: [
            IconButton(icon: const Icon(Icons.list),
            onPressed: (){Navigator.of(context).pop(); },
            ),
          ],),
        body: Column(
          children: [
            TableCalendar(
             headerStyle: const HeaderStyle(
                formatButtonVisible:false,
              ),
              focusedDay: _focusedDay,
              firstDay: DateTime(2020),
              lastDay: DateTime(2150),
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) =>isSameDay(_selectedDay, day),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color:Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,200,200,200) :null),
                weekendStyle: TextStyle(color:Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,200,200,200) :null),
              ),
              onDaySelected: (selectedDay, focusedDay)async {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _events.clear();
                  await _loadEvents(context);
                setState((){
                  _selectedEvent = null;                 
                });
              },
              eventLoader: _getEventsForDay,
              calendarStyle:  CalendarStyle(
                defaultTextStyle:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,250,250,250) :null),
                weekendTextStyle: TextStyle(color:Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,200,200,200) :null),
                todayDecoration: const BoxDecoration(
                  color: Color.fromARGB(255,255,200,150),
                  shape: BoxShape.circle,
                  
                ),
                todayTextStyle: const TextStyle(color:Colors.black,),
                selectedDecoration: BoxDecoration(
                  color: const Color.fromARGB(100,200,200,255),
                  shape: BoxShape.circle,
                  border: Border.all(width:1.5,color: Colors.red),
                  
                ),
                selectedTextStyle: const TextStyle(color:Colors.black,),
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  
                ),
              ),
              onPageChanged:(focusedDay){
                setState((){ 
                  displayMonth = focusedDay;
                  _selectedDay = focusedDay;
                  this._focusedDay = focusedDay;
                  });
              },
              calendarBuilders: CalendarBuilders(
                headerTitleBuilder: (context,day){
                  return GestureDetector(
                    onTap:(){
                      _pickMonth(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '${displayMonth!.year}${L10n.of(context)!.year} ${displayMonth!.month}${L10n.of(context)!.month}',
                        style: const TextStyle(fontSize:20,),
                      ),
                    ),
                  );
                },
              ),

            ),
            const SizedBox(height: 20),
            //選択された日付のイベントをリスト表示
            Expanded(
              child: ListView.builder(
                itemCount: _getEventsForDay(_selectedDay!).length,
                itemBuilder: (context, index){
                  final event = _getEventsForDay(_selectedDay!)[index];
                  final isSelected = _selectedEvent == event;
                  return ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(event),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: isSelected 
                          ? Theme.of(context).brightness == Brightness.dark ? Colors.grey :const Color(0x8F6E79CF) 
                          : Colors.transparent, // 枠線を変更
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),),
                    onTap:(){
                      setState((){ _selectedEvent = event;});
                    },
                    onLongPress:()async{
                      final records = await AttendanceLogic.allRecords();
                      List<Map<String,dynamic>> filterRecord = records.where((record){
                        DateTime recordDate = DateTime.parse(record['date']);
                        return isSameDay(recordDate, _selectedDay);
                      }).toList();
                      final String? result = await _showEditDialog(context,filterRecord[0]);
                      setState((){ _stateValue = result ?? 'state'; });
                      _events.clear();
                      _initializedEvents(context);  
                    },
                  );
                },
              ),
            ),
    ],),

          
          floatingActionButton: Stack(children:[
          Positioned(
            bottom: 16,
            left : 30,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: ()async{
              if (_selectedDay == null){
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content:Text(L10n.of(context)!.tobedelete)), //'削除対象を選択してください。'
              );
            } else {
              showDialog(
                context:context,
                builder:(_) => AlertDialog(
                  title:Text(L10n.of(context)!.confirm_delete), //'削除確認'
                  content: Text(
                    L10n.of(context)!.reallydelete  //"本当に削除してもよろしいですか？"
                  ),
                  actions: [
                    TextButton(
                      child:Text("Cancel",style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child:Text("OK",style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
                      onPressed: () async{
                        Navigator.of(context).pop();
                          final records = await AttendanceLogic.allRecords();
                          String compareDay = intl.DateFormat('y-MM-dd').format(_selectedDay!);
                          List<int> matchDay = records
                            .where((record){
                              return record['date'] == compareDay;
                            })
                            .map<int>((record) => record['id'])
                            .toList();
                          
                          final selectId = matchDay;
                          await DatabaseHelper.deleteRecord("attendance_table",'id = ?',selectId);
                          setState((){ _selectedDay = DateTime(_selectedDay!.year,_selectedDay!.month,1);
                            _events.clear();
                            _initializedEvents(context);  
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(L10n.of(context)!.deleted)),);  //'削除しました。'
                      }
                      
                    ),
                  ],
                )
              );
            }
            },

              child:const Icon(Icons.delete ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: ()async{
                final result = await _showAddAttendanceModal(context,_selectedDay ?? DateTime.now());
                if (result != null){
                  setState((){_events.clear();
                  _initializedEvents(context);});
                } else {
                  setState((){_events.clear();
                  _initializedEvents(context);});
                }   
              },
              child:const Icon(Icons.playlist_add ),
            ),
          ),
        ],
          ),
      );
    }
  Future<void> _pickMonth(BuildContext context) async{
    DateTime? picked = await showMonthPicker(
      context:context,
      initialDate: displayMonth,
      firstDate:DateTime(2020),
      lastDate: DateTime(2150),
    );
    if (picked != null && picked != displayMonth){
      setState((){ 
        focusedDay = DateTime(picked.year,picked.month); 
        _focusedDay = DateTime(picked.year,picked.month);
        });
    }
  }
}

  //一覧カレンダーページの編集モーダル
  Future<String?> _showEditDialog(BuildContext context,Map<String,dynamic> item)async{
  TimeOfDay? checkInTime ;
  TimeOfDay? checkOutTime ;
  Set<int> selectedIndices = <int>{};
  String? free = item['free'];
  DateTime editDay = DateTime.parse(item['date']);
 
  final DateTime displayDate = DateTime.parse(item['date']);

  Future<void> initialIndices(Map<String,dynamic> item)async{
  List<Map<String,dynamic>> prerecords = await AttendanceLogic.overtimeReasonRecords();
  if (item['overtime_reasons'] != null && item['overtime_reasons'].isNotEmpty){
    for (String reason in item['overtime_reasons'].split(',')){
      for (var record in prerecords){
        if (record['overtime_reason'] == reason){
          selectedIndices.add(record['id']);  
        }
      }
    } 
  }}
  await initialIndices(item);
                    

  final result = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder:(BuildContext context,StateSetter setState){
      return AlertDialog(
        title: Text(L10n.of(context)!.edit),  //編集
        content: SingleChildScrollView(
          child: Column(children:[
          Align(  alignment: Alignment.centerLeft,
            child: Text(intl.DateFormat('y-M-dd(EEE)').format(displayDate)),),
          TextButton(          
            style: TextButton.styleFrom(
              side: const BorderSide(color:Colors.grey,width:1),
              shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),),
            ),
            onPressed:()async{
              final time = await _showTimePicker(context);
              if (time != null){            
                setState((){ checkInTime = time; });          
              }
            },
            child: Text(checkInTime != null ? "${L10n.of(context)!.attendance_time}：${MaterialLocalizations.of(context).formatTimeOfDay(checkInTime!, alwaysUse24HourFormat: true)}" : '${L10n.of(context)!.attendance_time}：${item['check_in']}',style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
          ),
          TextButton(        
            style: TextButton.styleFrom(
              side: const BorderSide(color:Colors.grey,width:1),
              shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),),
            ),
            onPressed:()async{
              final time = await _showTimePicker(context);
              if (time != null){
                setState((){ checkOutTime = time; });
              }
            },
            child: Text(checkOutTime != null ? "${L10n.of(context)!.leavework_time}：${MaterialLocalizations.of(context).formatTimeOfDay(checkOutTime!, alwaysUse24HourFormat: true)}" : '${L10n.of(context)!.leavework_time}：${item['check_out']}',style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
          ),
          Align(
                  alignment:Alignment.centerLeft,
                  child:
                    TextButton(                  
                      onPressed: ()async {
                        free = await _showInputFreeDialog(context,free); 
                        setState((){});      
                      },
                      style: TextButton.styleFrom(
                            side: const BorderSide(color:Colors.grey,width:1),
                            padding: const EdgeInsets.symmetric(horizontal:20,vertical:8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),),
                            backgroundColor: (free?.isEmpty ?? true)
                              ? Colors.transparent
                              : Theme.of(context).brightness == Brightness.dark ? Colors.black :const Color.fromARGB(255,235,235,255),
                            
                      ),
                      child: Text(L10n.of(context)!.free,style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),  //自由記述
                    ),
          ),
          FutureBuilder<List<Map<String,dynamic>>>(
                  future: AttendanceLogic.overtimeReasonRecords(),
                  builder: (context, snapshot){
                    if (snapshot.connectionState == ConnectionState.waiting){
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError){
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty){
                      return const Center(child: Text('No records found.'));
                    }
                    final records = snapshot.data!;


                    return Container(
                      margin: const EdgeInsets.fromLTRB(0,10,0,15),
                      width: MediaQuery.of(context).size.width *0.9,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color:Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child:GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 2.8,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 0.5,
                          ),
                          itemCount: records.length,
                          itemBuilder: (context,index){
                            final record = records[index];
                            final recordId = record['id'] as int;
                            
                            final isSelected = selectedIndices.contains(recordId);
                            return GestureDetector(
                              onTap: (){
                                setState((){
                                  if (isSelected) {
                                    selectedIndices.remove(recordId);                                  
                                  } else {
                                    selectedIndices.add(recordId);                                 
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical:5,horizontal:5),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,50,50,50) :const Color(0x156E79CF) 
                                    : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected 
                                      ? Theme.of(context).brightness == Brightness.dark ? Colors.grey :const Color(0x8F6E79CF) 
                                      : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding:  const EdgeInsets.all(5),
                                child: Column(
                          
                                  children: [
                                    Text(
                                      record['overtime_reason'] ?? '',
                                      style:  const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis, // 長い文字列を省略
                                      maxLines: 1, // 最大2行
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                ),
          
        ],),),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('ok'),
            style: TextButton.styleFrom(
                        backgroundColor:const Color.fromARGB(255,200,200,200),
                        foregroundColor:const Color.fromARGB(255,0,0,0),
                      padding: const EdgeInsets.symmetric(horizontal:20,vertical:10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),),
                      ),
            child: Text(L10n.of(context)!.cancel,style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
          ),
          TextButton(
            onPressed:()async {
              checkInTime ??= (item['check_in'] != L10n.of(context)!.unregistered && item['check_in'] != "N/A")
                ? stringToTimeOfDay(item['check_in'])
                : null;            
              checkOutTime ??= (item['check_out'] != L10n.of(context)!.unregistered && item['check_out'] != "N/A") 
                ? stringToTimeOfDay(item['check_out'])
                : null; 
              
              final overReason = selectedIndices.toList();
              final overtimeReason = overReason.join(',');
              await AttendanceUtils.addAttendance(
                context:context,
                date:editDay,
                checkInTime:checkInTime,
                checkOutTime:checkOutTime,
                free:free,
                overtimeReason:overtimeReason,
                flagInOut: "edit",
              );          
            },
            style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,30,30,30) :const Color.fromARGB(255, 95, 130, 234),
                    foregroundColor:const Color.fromARGB(255,255,255,255),
                    padding: const EdgeInsets.symmetric(horizontal:30,vertical:10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),),
                   ),
            child: Text(L10n.of(context)!.edit,style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),  //編集
          ),
        ],
      );
        },);
    },
  );
  return Future.value();
}
  Future<TimeOfDay?> _showTimePicker(BuildContext context) async {
    TimeOfDay? pickedDate = await showTimePicker(
      context:context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale:const Locale('en','US'),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );      
    if (pickedDate != null){
      return pickedDate;
    }
      return null;
  }

  TimeOfDay stringToTimeOfDay(String time){
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour:hour,minute:minute);
  }

  //一覧画面の編集（追加）モーダル　カレンダーページ
  Future<String?> _showAddAttendanceModal(BuildContext context,DateTime day)async {
    //初期値
    TimeOfDay checkInTime = const TimeOfDay(hour:0,minute:0);
    TimeOfDay checkOutTime = const TimeOfDay(hour:0,minute:0);
    Set<int> selectedIndices = <int>{}; 
    DateTime _selectedDate = day;
    String? free;
    
    Future<TimeOfDay?> _showTimePicker(BuildContext context) async {
    TimeOfDay? pickedDate = await showTimePicker(
      context:context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale:const Locale('en','US'),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );      
    if (pickedDate != null){
      return pickedDate;
    }
      return null;
    }
    Future<void> _pickDate(BuildContext context,StateSetter setState)  async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate:DateTime(2100),
        locale: Localizations.localeOf(context),
      );
      if (pickedDate != null && pickedDate != _selectedDate) {
        setState((){
          _selectedDate = pickedDate;
        });
      }
    }
    void _showInputDialog(BuildContext context){
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children:[
            Text(L10n.of(context)!.itemname,style:const TextStyle(fontSize:15,)), //'項目名を入力してください。'
            const SizedBox(height:2),
            Text(L10n.of(context)!.omission,style:const TextStyle(fontSize:12,),),  //'(15文字以内:長文は一覧では省略されます。)'
            ],),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText:L10n.of(context)!.here ),  //'ここに入力'
            maxLength:15,
            
          ),
          actions: [
            TextButton(
              onPressed: (){
                Navigator.of(context).pop();
              },
              child: Text('Cancel',style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
            ),
            TextButton(
              onPressed: ()async {
                //登録処理 _controller.text
                var functions = Functions();
                if ((_controller.text).trim().isEmpty){
                  functions.informationModal(L10n.of(context)!.error,L10n.of(context)!.itemname,context,); //"エラー","項目名を入力してください。"
                  return;
                }
                Navigator.of(context).pop();
                
                bool reason = await AttendanceLogic.checkOvertimeReason(_controller.text);
                if(reason){
                  functions.informationModal(L10n.of(context)!.regist_complete,"${_controller.text}${L10n.of(context)!.isregistered}",context,);  //登録完了、を登録しました。
                  
                }  else {
                  functions.informationModal(L10n.of(context)!.error,"${_controller.text}${L10n.of(context)!.yetregist}",context,);  //エラー、はすでに登録済です。
                }
                
              },
              child: Text('OK',style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
            ),
          ],
        );
      },
      );
  }
    String dateFormatLong = L10n.of(context)!.date_formatlong;
    final result = await showDialog<String>(
      context:context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context,StateSetter setState){

        return AlertDialog(
          title: Text(L10n.of(context)!.newinput, //新規入力
            style:const TextStyle(fontSize:20),),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:[
                Align(
                  alignment:Alignment.centerLeft,
                  child:
                    TextButton(
                      onPressed:()async{
                        await _pickDate(context,setState);
                      },
                      style: TextButton.styleFrom(
                        side: const BorderSide(color:Colors.grey,width:1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text( intl.DateFormat(dateFormatLong).format(_selectedDate),style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null) ),
                    ),
                ),

                TextButton(
                  onPressed: ()async {
                    final time = await _showTimePicker(context);
                    if (time != null){                     
                      setState((){checkInTime = time;});          
                    }
                  },
                  style: TextButton.styleFrom(
                        side: BorderSide(color:Colors.grey,width:1),
                        padding: EdgeInsets.symmetric(horizontal:20,vertical:10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                  ),
                  child: Text("${L10n.of(context)!.attendance_time} : ${MaterialLocalizations.of(context).formatTimeOfDay(checkInTime, alwaysUse24HourFormat: true)}",style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),  //出勤時間
                ),
                TextButton(             
                  onPressed: ()async {
                    final time = await _showTimePicker(context);
                    if (time != null){                     
                      setState((){checkOutTime = time;});                   
                    }
                  },
                  style: TextButton.styleFrom(
                        side: BorderSide(color:Colors.grey,width:1),
                        padding: EdgeInsets.symmetric(horizontal:20,vertical:10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                  ),
                  child: Text("${L10n.of(context)!.leavework_time} : ${MaterialLocalizations.of(context).formatTimeOfDay(checkOutTime, alwaysUse24HourFormat: true)}",style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),   //退勤時間
                ),
                Align(
                  alignment:Alignment.centerLeft,
                  child:
                    TextButton(                   
                      onPressed: ()async {
                        free = await _showInputFreeDialog(context,free); 
                        setState((){});      
                      },
                      style: TextButton.styleFrom(
                            side: const BorderSide(color:Colors.grey,width:1),
                            padding: const EdgeInsets.symmetric(horizontal:20,vertical:8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),),
                            backgroundColor: (free?.isEmpty ?? true)
                              ? Colors.transparent
                              : Theme.of(context).brightness == Brightness.dark ? Colors.black :const Color.fromARGB(255,235,235,255),                         
                      ),
                      child: Text(L10n.of(context)!.free, //自由記述
                        style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
                    ),
                ),

                FutureBuilder<List<Map<String,dynamic>>>(
                  future: AttendanceLogic.overtimeReasonRecords(),
                  builder: (context, snapshot){
                    if (snapshot.connectionState == ConnectionState.waiting){
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError){
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty){
                      return const Center(child: Text('No records found.'));
                    }
                    final records = snapshot.data!;

                    return Container(
                      margin: const EdgeInsets.fromLTRB(0,10,0,15),
                      width: MediaQuery.of(context).size.width *0.9,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color:Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child:GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 2.8,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 0.5,
                          ),
                          itemCount: records.length,
                          itemBuilder: (context,index){
                            final record = records[index];
                            final recordId = record['id'] as int;
                            final isSelected = selectedIndices.contains(recordId);

                            return GestureDetector(
                              onTap: (){
                                setState((){
                                  if (isSelected) {
                                    selectedIndices.remove(recordId);
                                  } else {
                                    selectedIndices.add(recordId);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical:5,horizontal:5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                    ? Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,50,50,50) :const Color(0x156E79CF) 
                                    : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected 
                                      ? Theme.of(context).brightness == Brightness.dark ? Colors.grey :const Color(0x8F6E79CF) 
                                      : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding:  const EdgeInsets.all(5),
                                child: Column(
                          
                                  children: [
                                    Text(
                                      record['overtime_reason'] ?? '',
                                      style:  const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis, // 長い文字列を省略
                                      maxLines: 1, // 最大2行
                                    ),
                                  ],
                                ),

                              ),

                            );
                          },
                        ),
                      ),
                    );

                  }
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children:[
                    TextButton(
                      onPressed:(){
                        Navigator.of(context).pop('ok');
                        
                      },
                      style: TextButton.styleFrom(
                        backgroundColor:const Color.fromARGB(255,200,200,200),
                        foregroundColor:const Color.fromARGB(255,0,0,0),
                      padding: const EdgeInsets.symmetric(horizontal:20,vertical:10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),),
                      ),
                      child:Text(L10n.of(context)!.cancel),
                    ),
                    const SizedBox(width:10),
                    TextButton(
                      onPressed: ()async {
                        final overReason = selectedIndices.toList();
                        final overtimeReason = overReason.join(',');
                        await AttendanceUtils.addAttendance(
                          context:context,
                          date:_selectedDate,
                          checkInTime:checkInTime,
                          checkOutTime:checkOutTime,
                          free:free,
                          overtimeReason:overtimeReason,
                          flagInOut: "inOut",
                        );       
                        Navigator.of(context).pop();           
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color.fromARGB(255,30,30,30) :const Color.fromARGB(255, 95, 130, 234),
                        foregroundColor:const Color.fromARGB(255,255,255,255),
                        padding: const EdgeInsets.symmetric(horizontal:30,vertical:10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),),
                      ),
                      child:Text(L10n.of(context)!.regist), //登録
                    ),

                  ]
                )

              ],

            ),
          ),
        );
        },);
      },
    );

  }
  Future<String?> _showInputFreeDialog(BuildContext context,String? free) async {
    final TextEditingController _controller = TextEditingController(text:free);

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title:  Column(crossAxisAlignment: CrossAxisAlignment.start,
            children:[
            Text(L10n.of(context)!.content_input,style:const TextStyle(fontSize:15,)), //'内容を入力してください。'
            const SizedBox(height:2),
            Text(L10n.of(context)!.twentychar,style:const TextStyle(fontSize:12,),),  //'(20文字以内)'
            ],),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: L10n.of(context)!.here),  //'ここに入力'
            maxLength:20,
            
          ),
          actions: [
            TextButton(
              onPressed: (){
                  Navigator.of(context).pop(free);                 
              },
              child: Text('Cancel',style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
            ),
            TextButton(
              onPressed: ()async {
                Navigator.of(context).pop((_controller.text).trim());
              },
              child: Text('OK',style:TextStyle(color:Theme.of(context).brightness == Brightness.dark ? Colors.white :null)),
            ),
          ],
        );
      },
      );
  }
