import 'package:flutter/material.dart';
import 'package:flutter_calendar_scheduler/database/drift_database.dart';
import 'package:flutter_calendar_scheduler/provider/schedule_provider.dart';
import 'package:flutter_calendar_scheduler/repository/schedule_repository.dart';
import 'package:flutter_calendar_scheduler/screen/home_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 플러터 프레임워크가 준비될 때까지 대기

  await initializeDateFormatting(); // init 패키지 초기화 (다국어)

  final database = LocalDatabase(); // 데이터베이스 생성

  GetIt.I.registerSingleton<LocalDatabase>(database); // GetIt 데이터베이스 변수 주입하기

  final repository = ScheduleRepository(); // 인스턴스화
  final scheduleProvider = ScheduleProvider(repository: repository); // 인스턴스화

  runApp(
    ChangeNotifierProvider( // 이 위젯은 프로바이더를 현재 위치에 주입시키고, 주입한 위치의 서브에 있는 모든 위젯에서 프로바이더를 사용하도록 해준다.
      create: (_) => scheduleProvider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeScreen(),
      ),
    ),
  );
}
