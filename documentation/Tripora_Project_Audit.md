# Tripora Project Audit

Project: Tripora: AI-Powered Personalized Travel Planner (`D:\tripora`)
Audit basis: read-only review of the project source, configuration, security rules, tests and Git history, carried out for the MCA Semester 3 Software Project I documentation.
Audit date: 19 October 2026 (the source was not changed by the audit).

This audit describes what the code does. Where a feature is demonstration data, a device-only store, or unverified, the entry says so.

## 1. Verified technology stack

| Item | Verified value | Evidence |
|---|---|---|
| UI framework | Flutter (Dart), Material theme | `pubspec.yaml`, `lib/theme/theme.dart` |
| Dart SDK constraint | `^3.12.0` | `pubspec.yaml` |
| Application version | `1.0.0+1` | `pubspec.yaml` |
| Authentication | Firebase Authentication, e-mail and password | `lib/services/login_page.dart`, `lib/services/signup_page.dart` |
| Database | Cloud Firestore | `lib/services/firestore_service.dart`, `firestore.rules` |
| Firebase core | `firebase_core ^4.15.0` | `pubspec.yaml` |
| Firebase packages | `firebase_auth ^6.7.0`, `cloud_firestore ^6.10.0` | `pubspec.yaml` |
| On-device storage | `shared_preferences ^2.5.6` | `pubspec.yaml`, `lib/services/*_store.dart` |
| HTTP client | `http ^1.6.0` | `pubspec.yaml`, `lib/services/ai_service.dart` |
| Sharing and links | `share_plus ^13.3.1`, `url_launcher ^6.3.3` | `pubspec.yaml`, `lib/services/trip_share.dart`, emergency and nearby screens |
| AI service | OpenRouter chat-completions API, model name `openrouter/free` | `lib/services/ai_service.dart` |
| Test packages | `flutter_test`, `integration_test`, `fake_cloud_firestore ^4.3.0`, `firebase_auth_mocks ^0.15.2`, `flutter_lints ^6.0.0` | `pubspec.yaml` |
| Platforms | Web (release build produced), Android (configured, not built in this audit) | `firebase.json`, `android/app/build.gradle.kts`, `web/` |

## 2. Application start-up and configuration

- `lib/main.dart` initialises Firebase with `DefaultFirebaseOptions.currentPlatform` (project `tripora-7ded0`), loads the saved appearance setting, and starts the app inside `LaunchIntroGate`.
- The root route is `AuthGate` (`lib/screens/auth_gate.dart`). An unauthenticated user sees `LoginPage`. A signed-in user is routed to `AdminDashboard` if the admin role check passes, otherwise to `WelcomeScreen`.
- The Firebase emulators are used only when the build define `USE_FIREBASE_EMULATORS` is true (off by default).
- The AI key is read at build time with `String.fromEnvironment('OPENROUTER_API_KEY')` (`lib/services/ai_service.dart`). No key value appears in the source.
- Firebase project files: `firebase.json` (points to `firestore.rules` and `firestore.indexes.json`), `.firebaserc` (default `tripora-7ded0`), `lib/firebase_options.dart`, `android/app/google-services.json`.

## 3. Feature inventory

Status key: **Implemented** (code path present and exercised by a test or by a verified flow), **Partial** (some of the feature is present), **Demo** (sample data or a demonstration record, no provider), **Device only** (stored on the device, not in Firestore), **Not implemented**.

| Feature | Status | Main files | Notes |
|---|---|---|---|
| Sign up | Implemented (no automated sign-up test) | `signup_page.dart` | Creates the Auth account and the `users` document. |
| Log in | Implemented | `login_page.dart`, `auth_gate.dart` | Records the sign-in in the background; checks the admin role. |
| Log out | Implemented | `welcome_screen.dart`, `admin_dashboard.dart` | Signs out of Firebase Auth. |
| Profile | Implemented | `profile_screen.dart`, `firestore_service.dart: updateProfile` | Name, phone, home city. |
| Destination discovery | Implemented | `explore_places_page.dart`, `lib/data/destinations.dart` | 35 destinations (30 Indian cities plus 5 abroad) held in code. |
| Destination details and reviews | Implemented | `destination_details_screen.dart`, `destination_reviews_section.dart` | Reviews only for destinations listed in `ReviewRules.reviewableDestinationIds`. |
| Favourites | Implemented | `favourites_store.dart`, `favourites_screen.dart` | Stored at `users/{uid}/favourites/{destinationId}`. |
| Trip planning with preferences | Implemented | `trip_details_screen.dart` | Budget, days, interest. |
| AI itinerary | Implemented (depends on build-time key) | `ai_service.dart` | OpenRouter call; errors mapped to messages. |
| Offline itinerary | Implemented | `offline_planner.dart` | Used when the AI call fails and the user accepts it. |
| Saved trips | Implemented | `my_trips_screen.dart`, `firestore_service.dart: saveTrip` | `trips` collection; owner can delete. |
| Travel checklist | Implemented | `checklist_service.dart`, `travel_checklist_section.dart` | Subcollection `trips/{tripId}/checklist`. |
| Tour packages | Implemented (built-in and admin-saved) | `packages_screen.dart`, `package_store.dart`, `lib/data/tour_packages.dart` | `packages` collection holds admin saves and overrides. |
| Demo package catalogue | Demo | `demo_catalogue_pages.dart`, `lib/data/demo_catalogue.dart` | 240 generated packages (30 cities times 8 templates); preview only. |
| Package booking | Demo record | `booking_form_screen.dart`, `firestore_service.dart: createBooking` | `bookings` document with `isDemo: true`. |
| Transport and hotel search | Demo | `travel_services_page.dart` | Seeded sample results for flights, trains, buses, cabs, hotels. |
| Bus seat map | Demo | `bus_seat_selection_page.dart` | Seats are illustrative; booked seats fixed per bus. |
| My bookings and cancel | Implemented | `my_bookings_screen.dart`, `firestore_service.dart: cancelBooking` | Owner can cancel pending or confirmed requests. |
| Reviews | Implemented | `review_service.dart` | Pending until an admin approves; one review per user per destination. |
| Support requests | Implemented with a known rules mismatch | `support_page.dart`, `support_service.dart` | See Section 7, issue 1. |
| Emergency help | Implemented | `emergency_help_page.dart`, `lib/data/emergency_contacts.dart` | Numbers listed with their sources and check date. |
| Nearby services | Demo | `nearby_services_page.dart`, `lib/data/nearby_services.dart` | 530 sample records, labelled as demonstration. |
| Food explorer | Implemented (151 dishes, 31 with photos) | `food_explorer_page.dart`, `lib/data/local_food.dart`, `lib/data/food_catalogue_more.dart` | Placeholders for dishes without verified photos. |
| Offers and coupons | Demo | `offers_service.dart`, `demo_catalogue_pages.dart` | Applied in the package preview only. |
| Gift cards | Demo, device only | `gift_card_service.dart`, `offers_gift_pages.dart` | No real value; stored locally. |
| Travel journal | Device only | `journal_store.dart`, `journal_pages.dart`, `journal_editor_page.dart` | Not synchronised. |
| Budget planner | Device only | `budget_store.dart`, `trip_budget_planner_page.dart`, `trip_budget_planner.dart` | Not synchronised. |
| Travel experiences | Device only | `experience_store.dart`, `experiences_page.dart` | Not synchronised. |
| Admin dashboard | Implemented | `admin_dashboard.dart` | Counts read from Firestore. |
| User and trip management | Implemented, read only | `admin_dashboard.dart` (`UserManagementPage`, `TripManagementPage`) | No write action. |
| Package management | Implemented | `admin_packages_page.dart` | Create, edit, hide, show, delete. |
| Booking management | Implemented | `admin_bookings_page.dart` | Status, note, delete. |
| Review moderation | Implemented | `admin_reviews_page.dart`, `review_service.dart` | Approve, reject, pending, delete. |
| Support management | Implemented | `admin_support_page.dart`, `support_service.dart: adminUpdate` | Status and reply, with audit entry in the same batch. |
| Audit log | Implemented (support actions only) | `audit_service.dart`, `admin_audit_page.dart` | Only support replies and status changes write entries. |
| Destination, food and nearby editing by admin | Not implemented | — | Catalogues are constants in code. |
| Offers and gift-card editing by admin | Not implemented | — | No admin screens. |
| Live transport, hotel, cab, flight inventory and payments | Not implemented | — | No provider or payment integration in the project. |

## 4. Architecture

- Layers: `lib/screens` (36 files, user and admin screens), `lib/services` (24 files, Firestore, AI, stores, validators, planners), `lib/models` (11 files), `lib/data` (9 files, catalogues), `lib/widgets` (shared visuals), `lib/theme`.
- Size: 95 Dart files and about 32,400 lines under `lib`; 23 test files under `test`.
- State: screens use `StatefulWidget`, streams from Firestore (`snapshots()`), and `ChangeNotifier` stores (`PackageStore`, `FavouritesStore`).
- Pure logic is separated from widgets for testing: `CouponValidator`, `PriceBreakdown`, `GiftCardRules`, `PackageQuery`, `PackageRecommender`, `CalculationEstimate`, `NearbyServices.search`.
- Demonstration data is generated by seeded random numbers (`DemoServiceProvider._rng`) so that the same search gives the same results.

## 5. Principal workflows (verified in source)

1. **Sign-in and routing.** `login_page.dart` signs in; `recordLogin` runs in the background; `isAdmin` reads `admins/{uid}` and requires `role == 'admin'`; `auth_gate.dart` routes the user.
2. **Trip generation.** `trip_details_screen.dart` calls `AiService.generateItinerary`; on failure it offers `OfflinePlanner.build`; `FirestoreService.saveTrip` writes the `trips` document.
3. **Demonstration booking.** `travel_services_page.dart` or `packages_screen.dart` opens `BookingFormScreen`; `createBooking` writes a `bookings` document with `status: pending` and `isDemo: true`.
4. **Review.** `ReviewService.save` writes or updates `reviews/{destinationId}_{uid}` with `status: pending`; an admin approves it through `setStatus`.
5. **Support.** `SupportService.submit` writes `support_tickets` with a 15-second timeout, or keeps the request in the device outbox; `adminUpdate` changes status and writes a reply and an `admin_audit` entry in one batch.

## 6. Database structures (Cloud Firestore)

| Path | Document ID | Key fields (type) | Written by |
|---|---|---|---|
| `admins/{uid}` | Firebase Auth UID (set by hand) | `role` (string) | Owner, in the Firebase Console only |
| `users/{uid}` | Firebase Auth UID | `uid`, `name`, `email` (string); `createdAt`, `lastLoginAt` (timestamp); `loginCount` (integer); `phone`, `homeCity` (string, optional) | `signup_page.dart`, `recordLogin`, `updateProfile` |
| `users/{uid}/favourites/{destinationId}` | destination identifier | `destinationId`, `name`, `location`, `imageUrl` (string); `addedAt` (timestamp) | `addFavourite` |
| `trips/{tripId}` | generated | `userId`, `destination`, `budget`, `interest`, `itinerary` (string); `days` (integer); `createdAt` (timestamp) | `saveTrip` |
| `trips/{tripId}/checklist/{itemId}` | item key | `label` (string); `done`, `custom` (boolean); `order` (integer); `createdAt`, `updatedAt` (timestamp) | `checklist_service.dart` |
| `packages/{packageId}` | package identifier | `title`, `region`, `category`, `hotelClass`, `description`, `imageUrl` (string); `durationDays`, `pricePerPerson` (integer); `cities`, `facilities`, `highlights` (array); `itinerary` (array of maps); `active` (boolean) | `savePackage` (admin) |
| `bookings/{bookingId}` | generated | `userId`, `userEmail`, `kind`, `itemId`, `title`, `subtitle`, `contactName`, `contactPhone`, `notes`, `status`, `reference` (string); `travellers`, `unitPrice`, `totalPrice` (integer); `details` (map); `travelDate`, `createdAt`, `updatedAt` (timestamp); `isDemo` (boolean); `adminNote` (string, optional) | `createBooking`, `cancelBooking`, `setBookingStatus` |
| `reviews/{destinationId}_{uid}` | composite | `destinationId`, `userId`, `displayName`, `text`, `status` (string); `rating` (integer); `createdAt`, `updatedAt`, `moderatedAt` (timestamp) | `ReviewService` |
| `support_tickets/{ticketId}` | generated | `userId`, `category`, `priority`, `subject`, `message`, `status` (string); `adminReply` (string, optional); `createdAt`, `updatedAt`, `repliedAt` (timestamp) | `SupportService` |
| `admin_audit/{entryId}` | generated | `actorUid`, `action`, `target`, `summary` (string); `createdAt` (timestamp) | `AuditService.addTo` |

Relationships are application-level references (string identifiers) except subcollections, which are enforced by their path. Firestore does not enforce the string references. The report's Figure 3.2 shows this model.

Indexes: `firestore.indexes.json` lists no composite indexes. The queries in the code use a single field (`where userId`, `where destinationId` with `where status`) or a single `orderBy createdAt`, which need no composite index.

## 7. Security rules (repository copy) and their limits

- The repository `firestore.rules` (362 lines) is byte-identical to `firestore.rules.proposed`. It contains a header that says "PROPOSED ... NOT deployed".
- Emulator evidence (`firestore_rules_test/firestore-debug.log`, 17 October 2026) shows evaluation errors for support tickets.
- The live rules were not verified in this audit (no Firebase Console access).

Confirmed issues (not fixed by this audit):

1. **Support tickets (high).** The app writes `priority` and the category values `bug`, `feature`, `improvement`, `ui`, `help` (`support_service.dart: _newTicketData`, `lib/models/support_ticket.dart`). The repository rules accept only `booking`, `trip`, `account`, `other` for `category` and do not accept `priority`. A ticket written by the current code is refused by these rules. The app then keeps it in the device outbox, so administrators do not see it. A proposed rules file (`firestore.rules.feedback.proposed`) accepts both, but it has not been deployed.
2. **Rules file header (high).** The header of `firestore.rules` describes a proposal, while the Git history and the deployment log record a release on 17 October 2026. The live text must be compared with the file.
3. **Rules tests target a different file (medium).** `firestore_rules_test/rules.test.js` reads `firestore.rules.proposed` and `feedback_rules.test.js` reads `firestore.rules.feedback.proposed`. Neither was run in this audit.
4. **Review destinations (medium).** The rule lists 16 destination identifiers. The catalogue has 35, and the review section is hidden for the others.
5. **Tests use fakes (medium).** The application tests use `fake_cloud_firestore`, which does not enforce rules, so payload mismatches are not caught by them.

## 8. AI integration

- Request: POST to the OpenRouter chat-completions endpoint with a bearer key, a referer header naming the application, the model name, and the prompt (destination, budget, days, interest).
- Response: the first choice's text is returned. An empty answer is retried, up to three attempts in total.
- Errors: HTTP 401 means an invalid or expired key; HTTP 429 means a busy free model; other failures report the status code and a short message. The trip screen then offers the offline plan.
- No automated test covers a live call, an invalid key, a rate limit or a malformed answer. Only the missing-key message has a test (`widget_test.dart`).

## 9. Tests and checks

- Last full run: `flutter test` passed 297 of 297, exit code 0. `flutter analyze` reported no issues. `flutter build web --release` completed, exit code 0.
- The test files and their counts are listed in Table 5.4 of the report.
- Not run in this audit: the Firestore rules emulator tests, the Android build, browser visual checks, and any check against the live Firebase project.

## 10. Known limitations

- Transport, cab, hotel, flight and train results are generated sample data. No provider is contacted.
- The AI itinerary needs a key supplied at build time, and it depends on a free model that is sometimes busy.
- Journal, budget, experiences, gift cards and the feedback outbox are device-only and are not synchronised.
- Admin users and trips pages are read-only. Destinations, food, nearby services, offers and gift cards cannot be edited by an admin.
- Only support actions write audit entries.
- 120 of 151 dishes have no verified photograph; placeholders are shown.
- Photos are licensed (CC0, public domain, CC BY, CC BY-SA) and credited; see `assets/vehicles/credits.json` and the source files.

## 11. Source files referenced

- Entry and routing: `lib/main.dart`, `lib/screens/auth_gate.dart`
- Authentication: `lib/services/login_page.dart`, `lib/services/signup_page.dart`, `lib/services/firestore_service.dart`
- Data access: `lib/services/firestore_service.dart`, `lib/services/package_store.dart`, `lib/services/favourites_store.dart`, `lib/services/checklist_service.dart`, `lib/services/review_service.dart`, `lib/services/support_service.dart`, `lib/services/audit_service.dart`
- AI and planners: `lib/services/ai_service.dart`, `lib/services/offline_planner.dart`
- Booking and transport: `lib/screens/travel_services_page.dart`, `lib/screens/bus_seat_selection_page.dart`, `lib/screens/booking_form_screen.dart`, `lib/screens/my_bookings_screen.dart`
- Admin: `lib/screens/admin_dashboard.dart`, `lib/screens/admin_packages_page.dart`, `lib/screens/admin_bookings_page.dart`, `lib/screens/admin_reviews_page.dart`, `lib/screens/admin_support_page.dart`, `lib/screens/admin_audit_page.dart`
- Catalogues: `lib/data/destinations.dart`, `lib/data/demo_catalogue.dart`, `lib/data/tour_packages.dart`, `lib/data/local_food.dart`, `lib/data/food_catalogue_more.dart`, `lib/data/nearby_services.dart`, `lib/data/emergency_contacts.dart`, `lib/data/vehicle_photos.dart`
- Rules and configuration: `firestore.rules`, `firebase.json`, `.firebaserc`, `firestore.indexes.json`, `lib/firebase_options.dart`

## 12. Unresolved questions for the owner

1. Which Firestore rules are live now? Compare the Firebase Console text and publish time with `firestore.rules`.
2. Should the support rules be changed to accept `priority` and the five new categories (approval needed)?
3. Should the review destination list be extended to the 19 missing destinations (approval needed)?
4. Is an admin account present, and does its `admins/{uid}` document have `role: admin`? (Existence only; no credentials to be shared.)
5. Should the AI key stay in the build, or move behind a server?
