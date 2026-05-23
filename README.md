# 💰 Personal Expense Tracker

A fully-featured personal finance app built with **Flutter** that helps users track their daily income and expenses — completely offline, no internet required.

---

## 📱 App Preview

> Built with Flutter • Works on Android • Local Storage with Hive • No internet required

---

## ✅ Core Features

### ➤ Add Transactions
- Add **Income** or **Expense** separately
- Income screen has **green theme**, Expense screen has **red theme**
- Fields: Amount (PKR), Title, Category, Date, Note
- Form validation on all required fields

### ➤ Categories
- **Expense Categories:** Food, Travel, Bills, Shopping, Health, Entertainment, Education, Groceries, Fuel, Other
- **Income Categories:** Salary, Freelance, Business, Gift, Investment, Rental, Bonus, Pension, Other
- **Custom Categories:** Users can create their own categories for both income and expense
- Long press a custom category to delete it

### ➤ Edit / Delete
- Tap any transaction to open the Edit screen
- All fields are pre-filled and editable
- **Delete Button** available on the Edit screen with confirmation dialog
- **Swipe Left** on any transaction in the home screen to delete (with confirmation)

### ➤ Monthly Summary
- Total Income for selected month
- Total Expenses for selected month
- Net Balance (profit or overspending indicator)
- Savings Rate percentage
- Daily Average Expense
- Category-wise spending breakdown with progress bars
- Income sources breakdown

### ➤ Basic Charts
- **Pie Chart** — Visual breakdown of expenses by category (interactive, tap to see %)
- **Line Chart (Monthly Trend)** — Income vs Expense over last 6 months
- Monthly breakdown table with current month highlighted

### ➤ Local Storage
- All data stored using **Hive** (NoSQL local database)
- Data persists across app restarts and phone reboots
- Completely offline — no internet required
- Custom categories also stored locally

### ➤ Other Features
- Month navigation — browse any past month
- Filter transactions: All / Income / Expense
- Balance card changes color: green when profit, red when overspending
- Swipe to delete with undo snackbar
- Two FABs: separate Income (green) and Expense (red) quick-add buttons

## 📱 Screenshots
<img width="773" height="450" alt="image" src="https://github.com/user-attachments/assets/3249ae86-f460-48d8-aaad-98e9066f1e17" />
<img width="774" height="455" alt="image" src="https://github.com/user-attachments/assets/db5fec7b-ed48-4cd1-bd5b-4a0a3aa4a150" />

---

## 📦 Packages & Libraries Used

| Package | Version | Purpose |
|---------|---------|---------|
| `provider` | ^6.1.1 | State management — shares data across all screens |
| `hive` | ^2.2.3 | Local NoSQL database for storing transactions |
| `hive_flutter` | ^1.1.0 | Flutter integration for Hive (file path handling) |
| `hive_generator` | ^2.0.1 | Auto-generates TypeAdapter code for Hive models |
| `build_runner` | ^2.4.8 | Code generation tool (runs hive_generator) |
| `fl_chart` | ^0.68.0 | Pie chart and line chart for visual analytics |
| `intl` | ^0.19.0 | Date formatting and number formatting (PKR currency) |
| `uuid` | ^4.3.3 | Generates unique IDs for each transaction |
| `cupertino_icons` | ^1.0.6 | iOS-style icons |

---

## 🏗️ Architecture & State Management

### Architecture: Feature-based Clean Structure
```
lib/
├── main.dart                            # Entry point, Hive init, Provider setup
├── models/
│   ├── transaction_model.dart           # Transaction data class + Hive annotations
│   ├── transaction_model.g.dart         # Auto-generated Hive TypeAdapter
│   └── category_model.dart              # Category definitions (income + expense)
├── providers/
│   └── transaction_provider.dart        # All business logic + state (ChangeNotifier)
├── screens/
│   ├── home_screen.dart                 # Main screen — transaction list, summary cards
│   ├── add_edit_transaction_screen.dart # Add new / Edit existing transaction
│   ├── monthly_summary_screen.dart      # Monthly income/expense summary
│   └── charts_screen.dart              # Pie chart + monthly trend line chart
└── utils/
    └── app_theme.dart                   # Colors, ThemeData, typography
```

### State Management: Provider Pattern
This app uses the **Provider** package with the `ChangeNotifier` pattern:

- **`TransactionProvider`** is the single source of truth for all transaction data
- It extends `ChangeNotifier` — when data changes, it calls `notifyListeners()`
- All screens subscribe using `context.watch<TransactionProvider>()` inside `build()`
- Button callbacks use `context.read<TransactionProvider>()` for one-time access
- `ChangeNotifierProvider` in `main.dart` injects the provider at the root level, making it available to every screen

**Why Provider?**
- Simple and official Flutter recommendation
- No boilerplate compared to BLoC
- Perfect for apps of this scale

---

## 💾 Local Storage: Hive

**Hive** is a lightweight, fast NoSQL key-value database for Flutter/Dart.

### How it's used in this app:

**Box 1: `transactions`** — stores all `TransactionModel` objects
```dart
// Save
await _transactionBox.put(transaction.id, transaction);

// Load all
_transactions = _transactionBox.values.toList();

// Delete
await _transactionBox.delete(id);
```

**Box 2: `custom_categories`** — stores user-created custom category names as strings

### Why Hive over SQLite?
- No native code — pure Dart
- Much faster for simple object storage
- Zero configuration
- Works perfectly offline
- flutter-friendly API

---

## 🚀 How to Run

### Prerequisites
- Flutter SDK 3.0+
- Android Studio or VS Code
- Android Emulator or physical Android device

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/expense_tracker.git
cd expense_tracker

# 2. Install dependencies
flutter pub get

# 3. Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run
```

### Build APK
```bash
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📊 Data Flow

```
User Action (Add Transaction)
        ↓
AddEditTransactionScreen (UI)
        ↓
context.read<TransactionProvider>().addTransaction(...)
        ↓
TransactionProvider saves to Hive Box
        ↓
_loadTransactions() called → notifyListeners()
        ↓
All screens with context.watch<TransactionProvider>() rebuild
        ↓
HomeScreen shows updated transaction list
```

---

## 🎨 Design Decisions

- **Dark theme** throughout for modern look and battery efficiency on AMOLED screens
- **Green = Income**, **Red = Expense** — consistent color coding everywhere
- **Income and Expense have separate category sets** — Income categories (Salary, Freelance etc.) make more sense than showing Food/Travel as income sources
- **Dismissible widget** for swipe-to-delete — standard mobile UX pattern
- **AnimatedContainer** for smooth category selection animation

---

## 👨‍💻 Developer

**Alizeh Ibad**

- GitHub: [@alizehibad7-droid](https://github.com/alizehibad7-droid)

---

## 📄 License

This project is for educational purposes — submitted as coursework assignment.
