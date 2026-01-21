// logic/dashboard_search_cubit.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chitchat/models/search_model.dart';

// This is the parent file - it holds the imports and the class
class DashboardSearchCubit extends Cubit<DashboardSearchState> {
  final SearchService _searchService;
  Timer? _debounceTimer;
  
  DashboardSearchCubit(this._searchService) : super(DashboardSearchInitial());
  
  Future<void> search(String query) async {
    if (query.isEmpty) {
      emit(DashboardSearchInitial());
      return;
    }
    
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }
    
    emit(DashboardSearchLoading());
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await _searchService.search(query);
        emit(DashboardSearchSuccess(
          query: query,
          results: results,
        ));
        
        await _searchService.saveToHistory(query);
      } catch (e) {
        emit(DashboardSearchError(e.toString()));
      }
    });
  }
  
  Future<void> clearSearch() {
    emit(DashboardSearchInitial());
    return loadSearchHistory();
  }
  
  Future<void> loadSearchHistory() async {
    try {
      final history = await _searchService.getSearchHistory();
      emit(DashboardSearchHistoryLoaded(history: history));
    } catch (e) { /* ignore */ }
  }
  
  Future<void> clearHistory() async {
    await _searchService.clearSearchHistory();
    emit(DashboardSearchInitial());
  }
  
  Future<void> removeFromHistory(String historyId) async {
    await _searchService.removeFromHistory(historyId);
    loadSearchHistory();
  }
  
  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

// These states were in the same file; I've moved them here clearly
abstract class DashboardSearchState {
  const DashboardSearchState();
}

class DashboardSearchInitial extends DashboardSearchState {
  const DashboardSearchInitial();
}

class DashboardSearchLoading extends DashboardSearchState {
  const DashboardSearchLoading();
}

class DashboardSearchError extends DashboardSearchState {
  final String message;
  const DashboardSearchError(this.message);
}

class DashboardSearchSuccess extends DashboardSearchState {
  final String query;
  final List<SearchResult> results;
  const DashboardSearchSuccess({required this.query, required this.results});
}

class DashboardSearchHistoryLoaded extends DashboardSearchState {
  final List<SearchHistory> history;
  const DashboardSearchHistoryLoaded({required this.history});
}
