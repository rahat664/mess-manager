# Mess Manager (Flutter + Firebase)

Modern mess/hostel manager built with Flutter (Material 3), Riverpod, GoRouter, and Firebase (Auth, Firestore, Storage). It covers members, meals, bazar/expenses, deposits, dashboards, and monthly reporting.

## Quick start
1. `flutter pub get`
2. Configure Firebase:
   - Install the CLI: `dart pub global activate flutterfire_cli`
   - Run `flutterfire configure` and replace `lib/firebase_options.dart` with the generated file (keeps the same class name `DefaultFirebaseOptions`).
3. Run: `flutter run`

## Project structure
```
lib/
  main.dart                // Firebase init + ProviderScope
  app/                     // MaterialApp + GoRouter
  core/                    // Theme, widgets, utils, constants
  features/
    auth/                  // Auth repo + login/register/splash UI
    mess/                  // Mess create/join/select
    members/               // Member model, role management
    meals/                 // Meal model, repo, list & add/edit
    expenses/              // Expense model, repo, list & add/edit
    deposits/              // Deposit model, repo, list & add/edit
    dashboard/             // Dashboard summary
    reports/               // Report service + monthly report UI
    settings/              // Sign out, switch mess
```

## Data model (Firestore)
- `messes/{messId}`: name, createdBy, createdAt, currentMonth, membersCount, joinCode
- `messMembers/{memberId}`: messId, userId, name, email, role (`admin|member`), isActive, joinedAt, monthlyFixedCostShare
- `meals/{mealId}`: messId, memberId, date (YYYY-MM-DD), breakfastCount, lunchCount, dinnerCount, createdAt
- `expenses/{expenseId}`: messId, date, amount, category, paidByMemberId, description, billImageUrl, createdAt
- `deposits/{depositId}`: messId, memberId, date, amount, description, createdAt
- `users/{userId}`: name, email, photoUrl, messIds[], createdAt

## Key flows
- Splash → Login/Register (email+password, Google) → Mess select/create/join → Dashboard.
- Dashboard shows current month totals, meal rate, and personal balance.
- Meals/Expenses/Deposits screens list + add/edit entries with member/date/category filters.
- Monthly report shows totals, rate, member-wise table, and exportable CSV-like text.

## Sample Firebase security rules (draft)
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() { return request.auth != null; }
    // Member docs use id format: "<messId>_<userId>"
    function membershipDoc(messId) {
      return get(/databases/$(database)/documents/messMembers/$(messId + '_' + request.auth.uid));
    }
    function isMember(messId) {
      return isSignedIn() && membershipDoc(messId).exists && membershipDoc(messId).data.isActive == true;
    }
    function isAdmin(messId) {
      return isMember(messId) && membershipDoc(messId).data.role == 'admin';
    }

    match /messes/{messId} {
      allow read: if isSignedIn() && isMember(messId);
      allow create: if isSignedIn();
      allow update, delete: if isAdmin(messId);
    }

    match /messMembers/{memberId} {
      allow read: if isSignedIn() && isMember(resource.data.messId);
      allow create: if isAdmin(request.resource.data.messId);
      allow update, delete: if isAdmin(resource.data.messId);
    }

    match /meals/{mealId} {
      allow read: if isSignedIn() && isMember(resource.data.messId);
      allow create, update: if isAdmin(resource.data.messId)
        || (isMember(resource.data.messId) && request.auth.uid == request.resource.data.memberId);
      allow delete: if isAdmin(resource.data.messId);
    }

    match /expenses/{expenseId} {
      allow read: if isSignedIn() && isMember(resource.data.messId);
      allow create, update, delete: if isAdmin(resource.data.messId);
    }

    match /deposits/{depositId} {
      allow read: if isSignedIn() && isMember(resource.data.messId);
      allow create, update: if isAdmin(resource.data.messId)
        || (isMember(resource.data.messId) && request.auth.uid == request.resource.data.memberId);
      allow delete: if isAdmin(resource.data.messId);
    }

    match /users/{userId} {
      allow read, update: if isSignedIn() && request.auth.uid == userId;
      allow create: if isSignedIn();
    }
  }
}
```

Adjust rules to your exact access policy (e.g., allowing members to add their own meals/deposits).

## What to change
- Replace Firebase options in `lib/firebase_options.dart`.
- Hook up image uploads (bill photos) via `ExpenseRepository.uploadBillImage`.
- Extend state (e.g., month switching, member summaries, admin-only toggles) as needed.
