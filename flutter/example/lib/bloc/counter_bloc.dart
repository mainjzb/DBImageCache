import 'package:bloc/bloc.dart';

import 'package:meta/meta.dart';

part 'counter_state.dart';

enum CounterEvent { increment, decrement }

class BlocCounter extends Bloc<CounterEvent, CounterState> {
  BlocCounter() : super(CounterState(counterValue: 0));

  @override
  Stream<CounterState> mapEventToState(CounterEvent event) async* {
    switch (event) {
      case CounterEvent.increment:
        yield CounterState(counterValue: state.counterValue + 1);
        break;
      case CounterEvent.decrement:
        yield CounterState(counterValue: state.counterValue - 1);
        break;
    }
  }
}
