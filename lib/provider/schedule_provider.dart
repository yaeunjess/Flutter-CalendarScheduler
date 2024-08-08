import 'package:flutter/cupertino.dart';
import 'package:flutter_calendar_scheduler/model/schedule_model.dart';
import 'package:flutter_calendar_scheduler/repository/schedule_repository.dart';
import 'package:uuid/uuid.dart';

class ScheduleProvider extends ChangeNotifier{
  final ScheduleRepository repository; // API 요청 로직을 담은 클래스

  DateTime selectedDate = DateTime.utc( // 선택한 날짜
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  Map<DateTime, List<ScheduleModel>> cache = {}; // 일정 정보를 저장해둘 변수

  ScheduleProvider({ // 생성자
    required this.repository,
  }) : super(){
    getSchedules(date: selectedDate);
  }

  void getSchedules({
    required DateTime date,
  }) async {
    final resp = await repository.getSchedules(date: date);

    cache.update(
      date,
      (value) => resp, // key(date)에 해당하는 값이 Map(cache)에 있을 때 실행되는 함수
      ifAbsent: () => resp // key(date)에 해당하는 값이 Map(cache)에 없을 때 실행되는 함수
    );

    notifyListeners();
    // 현재 클래스를 watch()하는 모든 위젯들의 build() 함수를 다시 실행한다. ChangeNotifier 클래스를 상속하는 이유이다.
    // 변경된 상태에 의존하는 위젯들만 build() 한다.
  }

  void createSchedule({
    required ScheduleModel schedule,
  }) async {
    final targetDate = schedule.date;

    final uuid = Uuid();

    final tempId = uuid.v4(); // 유일한 ID 값을 생성
    final newSchedule = schedule.copyWith(id: tempId,); // 임시 ID 지정

    // final savedSchedule = await repository.createSchedule(schedule: schedule);

    // 긍정적 응답, 서버에서 응답을 받기 전에 캐시를 먼저 업데이트 한다.
    cache.update(
      targetDate,
      (value) => [
        ...value,
        newSchedule // schedule.copyWith(id: savedSchedule,),
      ]..sort(
          (a, b) => a.startTime.compareTo(b.startTime),
      ),
      ifAbsent: () => [newSchedule],
    );

    // 캐시 업데이트 반영
    notifyListeners();

    try{
      final savedSchedule = await repository.createSchedule(schedule: schedule);

      // 1. 서버 응답 기반으로 캐시 업데이트
      cache.update(
        targetDate,
        (value) => value.map((e) => e.id == tempId ? e.copyWith(id: savedSchedule,) : e).toList(),
      );
    } catch(e) {
      // 2. 생성 실패 시 캐시 롤백하기
      cache.update(
        targetDate,
        (value) => value.where((e) => e.id != tempId).toList(),
      );
    }

  }

  void deleteSchedule({
    required DateTime date,
    required String id,
  }) async {
    /*final resp = await repository.deleteSchedule(id: id);

    cache.update(
      date,
      (value) => value.where((e) => e.id != id).toList(), // 'date' key 값이 Map인 cache에 key로 이미 존재할때 실행
      ifAbsent: () => [], // 'date' key 값이 Map인 cache에 key로 존재하지 않을때 실행
    );*/

    final targetSchedule = cache[date]!.firstWhere((e) => e.id == id);

    // 긍정적 응답, 응답 전에 캐시 먼저 업데이트 한다.
    cache.update(
      date,
      (value) => value.where((e) => e.id != id).toList(),
      ifAbsent: () => [],
    );

    try{
      // 1. 삭제 함수 실행
      await repository.deleteSchedule(id: id);
    } catch (e){
      // 2. 삭제 실패 시 캐시 롤백하기
      cache.update(
        date,
        (value) => [...value, targetSchedule]..sort((a,b) => a.startTime.compareTo(b.startTime)),
      );
    }

    notifyListeners();
  }

  void changeSelectedDate({
    required DateTime date,
  }) {
    selectedDate = date;
    notifyListeners();
  }

}