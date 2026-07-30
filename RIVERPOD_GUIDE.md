# Riverpod State Management — Easy Guide (crm_app)

This ONE file explains how state management works in this project.
Two examples: **(A) Button click** and **(B) API call**.
For each we show the **folder → file → step-by-step flow**, then the code.

---

## 0. The whole idea in 10 seconds

```
UI (view)  --calls-->  Provider (notifier)  --changes-->  state
   ^                                                        |
   |________________ auto rebuild (ref.watch) ______________|
```

- **Provider** = a global box that holds your data (the "state").
- `ref.watch(provider)` in the UI = show data + rebuild automatically when it changes.
- `ref.read(provider.notifier).doSomething()` in a button = change the data.
- Change `state = newValue` inside the notifier → every `watch`ing widget rebuilds.
- **No `setState`.** Ever.

This project keeps files in this folder shape (feature-first):

```
lib/features/<feature>/
   ├── data/        <- repository: talks to the API (dio)
   ├── model/       <- data classes (Customer, Lead, ...)
   ├── provider/    <- STATE lives here (Notifier + Provider)
   └── view/        <- screens/widgets (UI, reads the provider)
```

============================================================
# A) BUTTON CLICK STATE MANAGEMENT
============================================================
Example: a Counter. Press a button → number goes up → UI updates.

### FLOW (what happens, in order)

```
1. USER taps the (+) button
        |  onPressed
        v
2. VIEW file:     lib/features/counter/view/counter_screen.dart
   calls:         ref.read(counterProvider.notifier).increment()
        |
        v
3. PROVIDER file: lib/features/counter/provider/counter_provider.dart
   runs:          state = state + 1     // state changed!
        |
        v
4. Riverpod notices state changed, and tells everyone who watched it
        |
        v
5. VIEW rebuilds: ref.watch(counterProvider) now returns the new number
   -> Text shows the new value. DONE.
```

### STEP 1 — the provider (state lives here)
`lib/features/counter/provider/counter_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// A) A Notifier holds the state (here: an int) and the methods to change it.
class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;                          // <-- starting value

  void increment() => state = state + 1;     // <-- change state -> UI updates
  void decrement() => state = state - 1;
  void reset()     => state = 0;
}

// B) Expose it globally so any screen can use it.
final counterProvider =
    NotifierProvider<CounterNotifier, int>(CounterNotifier.new);
```

### STEP 2 — the view (UI reads + triggers)
`lib/features/counter/view/counter_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/counter_provider.dart';

// ConsumerWidget gives us `ref` (the remote control for providers).
class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WATCH -> read value AND rebuild this widget whenever it changes.
    final count = ref.watch(counterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: Text('Count: $count', style: const TextStyle(fontSize: 40)),
      ),
      floatingActionButton: FloatingActionButton(
        // READ .notifier -> call a method (an action, no rebuild needed here).
        onPressed: () => ref.read(counterProvider.notifier).increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

That is the ENTIRE button-click pattern. Everything else is a bigger version of this.

> Real example already in this project:
> `lib/features/customers/provider/customers_provider.dart`
> `CustomersNotifier` holds a `List<CustomerModel>` and has `add()` / `delete()`.
> Same 3 steps — just a List instead of an int.

============================================================
# B) API CALL STATE MANAGEMENT
============================================================
Example: load customers from the server, show loading spinner, then the list.

There are 4 states an API screen needs: **loading, data, error, empty**.
Riverpod handles this cleanly.

### FLOW (what happens, in order)

```
1. SCREEN opens -> ref.watch(customersApiProvider)
        |
        v
2. PROVIDER build() runs -> shows isLoading = true (spinner shows)
   and starts _load(1)
        |  ref.read(customersRepositoryProvider).getCustomers()
        v
3. DATA/REPOSITORY file: lib/features/customers/data/customers_repository.dart
   makes the real HTTP call with dio (GET /customers)
        |  returns Success(data) or Failure(error)
        v
4. Back in PROVIDER: state = state.copyWith(items: data, isLoading: false)
        |
        v
5. SCREEN rebuilds (it was watching) -> spinner gone, list shows. DONE.
   (on error -> state.error set -> screen shows an error message)
```

### Two ways to do API calls in this project

## Way 1 — `FutureProvider` (SIMPLEST, use for a single value / detail)

This is the shortest way. Riverpod gives you loading/error/data for free.

`lib/features/customers/provider/customers_provider.dart` (already in project):

```dart
// Loads ONE customer by id.  .family = it takes an argument (the id).
final customerDetailProvider =
    FutureProvider.autoDispose.family<CustomerModel, String>((ref, id) async {
  final result = await ref.read(customersRepositoryProvider).getCustomer(id);
  return switch (result) {
    Success(:final data)  => data,       // -> becomes AsyncData
    Failure(:final error) => throw error, // -> becomes AsyncError
  };
});
```

In the view — `.when(...)` handles all 3 states automatically:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final async = ref.watch(customerDetailProvider('123')); // pass the id

  return async.when(
    loading: ()      => const Center(child: CircularProgressIndicator()),
    error:   (e, _)  => Center(child: Text('Error: $e')),
    data:    (customer) => Text(customer.name),   // success!
  );
}
```

- `.autoDispose` = throw away the data when the screen closes (refetch next time).
- `.family<Result, Arg>` = the provider needs an input (here the `id`).

## Way 2 — `Notifier` + a state class (use for LISTS: loading + items + paging)

When you need MANY fields together (isLoading + list + page number + error),
make a small state class and update it with `copyWith`.
This project's real example: `lib/features/customers/provider/customers_api_provider.dart`.

### STEP 1 — the state class (all the fields the screen needs)

```dart
class CustomersApiState {
  final List<CustomerListItem> items;
  final bool isLoading;
  final Object? error;

  const CustomersApiState({
    this.items = const [],
    this.isLoading = true,
    this.error,
  });

  // copyWith = make a new copy changing only some fields (state is immutable).
  CustomersApiState copyWith({
    List<CustomerListItem>? items,
    bool? isLoading,
    Object? error,
  }) => CustomersApiState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
```

### STEP 2 — the notifier (calls the repository, updates state)

```dart
class CustomersApi extends Notifier<CustomersApiState> {
  @override
  CustomersApiState build() {
    _load();                                   // start loading immediately
    return const CustomersApiState(isLoading: true);  // initial = spinner
  }

  Future<void> _load() async {
    // 1) show spinner
    state = state.copyWith(isLoading: true, error: null);

    // 2) call the API (repository does the real dio request)
    final result = await ref.read(customersRepositoryProvider).getCustomers();

    // 3) put the result into state -> UI rebuilds
    result.when(
      success: (data) => state = state.copyWith(
        items: data.items,
        isLoading: false,
      ),
      failure: (e) => state = state.copyWith(
        isLoading: false,
        error: e,
      ),
    );
  }

  // Pull-to-refresh / retry button calls this.
  Future<void> refresh() => _load();
}

final customersApiProvider =
    NotifierProvider<CustomersApi, CustomersApiState>(CustomersApi.new);
```

### STEP 3 — the repository (the actual API call — data/ folder)

`lib/features/customers/data/customers_repository.dart` (already in project).
The provider NEVER calls dio directly — it asks the repository. This keeps
network code in one place.

```dart
class CustomersRepository {
  final ApiClient _client;
  CustomersRepository(this._client);

  Future<ApiResult<CustomersPage>> getCustomers() async {
    // dio GET request, parse JSON into models, return Success or Failure.
    ...
  }
}

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository(ref.read(apiClientProvider));
});
```

### STEP 4 — the view (watch the state, show the right thing)

```dart
class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(customersApiProvider);   // WATCH the whole state

    if (s.isLoading) {
      return const Center(child: CircularProgressIndicator());   // loading
    }
    if (s.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: ${s.error}'),
            ElevatedButton(
              // button click -> call refresh() -> reloads -> UI updates
              onPressed: () => ref.read(customersApiProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (s.items.isEmpty) {
      return const Center(child: Text('No customers'));          // empty
    }

    return ListView.builder(                                     // data!
      itemCount: s.items.length,
      itemBuilder: (_, i) => ListTile(title: Text(s.items[i].name)),
    );
  }
}
```

============================================================
# C) BUTTON THAT DOES AN API CALL (create + update UI)
============================================================
Example: press "Create Customer" -> POST to server -> list refreshes.
This project already does this in `CustomersApi.createCustomer(...)`.

### FLOW

```
1. USER fills form, taps "Save"
        |  onPressed
        v
2. VIEW: ref.read(customersApiProvider.notifier)
             .createCustomer(name: ..., email: ...)
        |
        v
3. PROVIDER method calls repository.createCustomer()  (POST /customers)
        |
        v
4. DATA/REPOSITORY: dio POST, returns Success/Failure
        |
        v
5. PROVIDER: on success -> refresh() reloads the list
        |            on failure -> return the error text
        v
6. VIEW: if error text != null -> show a SnackBar
         else -> Navigator/GoRouter pop back; list already updated. DONE.
```

### Provider method (in the notifier)

```dart
// returns null on success, or an error message on failure.
Future<String?> createCustomer({required String name, String? email}) async {
  final result = await ref.read(customersRepositoryProvider)
      .createCustomer(name: name, email: email);

  final error = result.errorOrNull;
  if (error != null) return error.message;   // failure -> give message back

  await refresh();                           // success -> reload list (UI updates)
  return null;
}
```

### View (the button)

```dart
ElevatedButton(
  onPressed: () async {
    final error = await ref
        .read(customersApiProvider.notifier)
        .createCustomer(name: _nameController.text);

    if (error != null) {
      // show error, stay on screen
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      // success -> go back; the list was already refreshed by the provider
      context.pop();
    }
  },
  child: const Text('Save'),
)
```

============================================================
# D) NAVIGATION (go_router) — moving between screens
============================================================
Routes are defined in `lib/routes/app_routes.dart`.

```dart
// Open a screen (keeps a back button)
context.push(AppRoutes.createCustomer);

// Open a screen AND pass data to it
context.push(AppRoutes.customerDetail, extra: customer);

// Go back to the previous screen
context.pop();

// Replace the whole stack (e.g. after login)
context.go(AppRoutes.dashboard);
```

The route reads that passed data via `state.extra`:

```dart
GoRoute(
  path: AppRoutes.customerDetail,
  builder: (context, state) =>
      CustomerDetailScreen(customer: state.extra as CustomerModel),
),
```

============================================================
# CHEAT SHEET
============================================================

```dart
// READING state
ref.watch(p)          // read value + REBUILD UI  -> use inside build()
ref.read(p)           // read value ONCE, no rebuild -> use inside onPressed
ref.read(p.notifier)  // get the notifier so you can CALL its methods

// CHANGING state (inside a Notifier)
state = newValue                 // simple state (int, bool, List)
state = state.copyWith(x: ...)   // state class with many fields

// PROVIDER TYPES used in this project
NotifierProvider   // state you change with methods (list, bool, counter, api state)
Provider           // computed/derived value (e.g. filtered list) OR a repository
FutureProvider     // async data -> gives AsyncValue -> use .when(loading/error/data)
.family            // provider that takes an argument (e.g. an id)
.autoDispose       // auto cleanup when the screen closes

// ASYNC UI
async.when(
  loading: () => spinner,
  error:   (e, _) => errorWidget,
  data:    (value) => successWidget,
);

// NAVIGATION (go_router)
context.push(path, extra: obj)   // open screen + pass data
context.pop()                    // go back
context.go(path)                 // replace stack
```

## Remember the flow every time:

```
BUTTON (view)  ->  ref.read(provider.notifier).method()
                        |
                        v
PROVIDER       ->  state = newValue   (for API: call data/repository first)
                        |
                        v
UI (view)      ->  ref.watch(provider) rebuilds automatically
```
