import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DuaOverlayState {
  hidden,
  sehriActive,
  iftarActive,
}

class DuaOverlayNotifier extends StateNotifier<DuaOverlayState> {
  DateTime? _lastDismissalTime;
  
  DuaOverlayNotifier() : super(DuaOverlayState.hidden);
  
  void setActive(DuaOverlayState newState) {
    state = newState;
  }
  
  void dismiss() {
    _lastDismissalTime = DateTime.now();
    state = DuaOverlayState.hidden;
  }
  
  bool canShowOverlay(DuaOverlayState overlayType) {
    // Don't show if dismissal was less than 5 minutes ago
    if (_lastDismissalTime != null) {
      final timeSinceDismissal = DateTime.now().difference(_lastDismissalTime!);
      if (timeSinceDismissal.inMinutes < 5) {
        return false;
      }
    }
    return true;
  }
  
  void reset() {
    _lastDismissalTime = null;
  }
}

final duaOverlayProvider = 
    StateNotifierProvider<DuaOverlayNotifier, DuaOverlayState>((ref) {
  return DuaOverlayNotifier();
});
