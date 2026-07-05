import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/entities/search_result.dart';
import '../../domain/usecases/search_all_usecase.dart';

sealed class SearchEvent {
  const SearchEvent();
}

final class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);

  final String query;
}

sealed class SearchState {
  const SearchState();
}

final class SearchInitial extends SearchState {
  const SearchInitial();
}

final class SearchLoading extends SearchState {
  const SearchLoading();
}

final class SearchLoaded extends SearchState {
  const SearchLoaded(this.results);

  final List<SearchResult> results;

  @override
  bool operator ==(Object other) =>
      other is SearchLoaded &&
      other.results.length == results.length &&
      other.results.every((r) => results.any((mine) => mine.id == r.id && mine.type == r.type));

  @override
  int get hashCode => Object.hashAll(results.map((r) => (r.id, r.type)));
}

final class SearchError extends SearchState {
  const SearchError(this.message);

  final String message;

  @override
  bool operator ==(Object other) => other is SearchError && other.message == message;

  @override
  int get hashCode => message.hashCode;
}

/// The one place PLAN.md calls for a full `Bloc` over a `Cubit` — search
/// input needs a debounce event transformer, which only the event layer
/// gives you.
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._searchAll) : super(const SearchInitial()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: (events, mapper) => events.debounceTime(const Duration(milliseconds: 400)).switchMap(mapper),
    );
  }

  final SearchAllUseCase _searchAll;

  Future<void> _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) async {
    if (event.query.trim().isEmpty) {
      emit(const SearchInitial());
      return;
    }

    emit(const SearchLoading());
    final result = await _searchAll(event.query).run();
    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (results) => emit(SearchLoaded(results)),
    );
  }
}
