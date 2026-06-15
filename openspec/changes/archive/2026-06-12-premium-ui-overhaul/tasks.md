# Tasks: Premium UI Overhaul

- `[ ]` **Phase 1: Foundation & Theming**
  - `[ ]` Add dependencies to `pubspec.yaml` (`google_fonts`, `fl_chart`, `easy_date_timeline`, `flutter_svg`)
  - `[ ]` Redefine `AppTheme.lightTheme` with `#0052FF` (Primary Blue) and `#F8F9FF` (Background)
  - `[ ]` Configure global `Inter` font theme using `GoogleFonts`
- `[ ]` **Phase 2: Core Premium Widgets**
  - `[ ]` Create `CustomAvatar` widget (Photo -> Initial fallback logic)
  - `[ ]` Create `DailyProgressIndicator` (Linear animated progress bar)
  - `[ ]` Create high-fidelity `TaskCard` (24px radius, soft shadows, custom icons)
- `[ ]` **Phase 3: Screen Reconstruction**
  - `[ ]` Refactor `HomeScreen` header to remove `AppBar` and add custom greeting
  - `[ ]` Integrate `EasyDateTimeLine` for horizontal filtering
  - `[ ]` Implement the "Focus Card" (Dark Surface highlighting the priority task)
  - `[ ]` Ensure all Firestore streams remain active and correctly filtered by day
