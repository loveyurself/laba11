import 'package:flutter/material.dart';

void main() {
  runApp(const StoreAsyncApp());
}

class StoreAsyncApp extends StatelessWidget {
  const StoreAsyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Async Store Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const StoreHomePage(),
    );
  }
}

class UserProfile {
  final String name;
  final String email;
  final String city;

  const UserProfile({
    required this.name,
    required this.email,
    required this.city,
  });
}

class ProductItem {
  final String title;
  final double price;

  const ProductItem({
    required this.title,
    required this.price,
  });
}

class OrderRecord {
  final String id;
  final String summary;
  final String status;

  const OrderRecord({
    required this.id,
    required this.summary,
    required this.status,
  });
}

class StoreRepository {
  Future<UserProfile> getUser({bool simulateError = false}) async {
    await Future.delayed(const Duration(seconds: 2));
    if (simulateError) {
      throw Exception('Не вдалося завантажити профіль користувача');
    }
    return const UserProfile(
      name: 'Аліна',
      email: 'alina@example.com',
      city: 'Луцьк',
    );
  }

  Future<List<ProductItem>> getProducts({bool simulateError = false}) async {
    await Future.delayed(const Duration(seconds: 3));
    if (simulateError) {
      throw Exception('Сервіс каталогу товарів тимчасово недоступний');
    }
    return const [
      ProductItem(title: 'Механічна клавіатура', price: 2890.0),
      ProductItem(title: 'Бездротова миша', price: 1350.0),
      ProductItem(title: 'USB-C хаб', price: 980.0),
    ];
  }

  Future<List<OrderRecord>> getOrders({bool simulateError = false}) async {
    await Future.delayed(const Duration(seconds: 2));
    if (simulateError) {
      throw Exception('Помилка отримання історії замовлень');
    }
    return const [
      OrderRecord(
        id: '#ORD-1042',
        summary: 'Механічна клавіатура × 1',
        status: 'Доставлено',
      ),
      OrderRecord(
        id: '#ORD-1089',
        summary: 'Бездротова миша × 1, USB-C хаб × 1',
        status: 'В обробці',
      ),
    ];
  }
}

class StoreHomePage extends StatefulWidget {
  const StoreHomePage({super.key});

  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> {
  final StoreRepository _repository = StoreRepository();

  bool _isLoading = false;
  bool _simulateError = false;
  String? _errorMessage;
  String? _elapsedInfo;

  UserProfile? _user;
  List<ProductItem> _products = [];
  List<OrderRecord> _orders = [];

  Future<void> _loadStoreDataConcurrently() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _elapsedInfo = null;
    });

    final stopwatch = Stopwatch()..start();

    try {
      final results = await Future.wait<dynamic>([
        _repository.getUser(simulateError: _simulateError),
        _repository.getProducts(simulateError: _simulateError),
        _repository.getOrders(simulateError: _simulateError),
      ]);

      stopwatch.stop();

      setState(() {
        _user = results[0] as UserProfile;
        _products = results[1] as List<ProductItem>;
        _orders = results[2] as List<OrderRecord>;
        _elapsedInfo =
        'Завантажено конкурентно за ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)} с';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Інтернет-магазин (Async/Await)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('Імітувати помилку запиту'),
              subtitle: const Text('Перевірка обробки винятків try / catch'),
              value: _simulateError,
              onChanged: _isLoading
                  ? null
                  : (val) => setState(() => _simulateError = val),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadStoreDataConcurrently,
              icon: const Icon(Icons.sync),
              label: const Text('Отримати дані магазину'),
            ),
            const SizedBox(height: 12),
            if (_elapsedInfo != null)
              Text(
                _elapsedInfo!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Виконуються запити getUser(), getProducts(), getOrders()...',
                  textAlign: TextAlign.center,
                ),
              ),
            ] else if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Помилка: $_errorMessage',
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ListView(
                  children: [
                    if (_user != null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Користувач',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(_user!.name),
                          subtitle: Text('${_user!.email} • ${_user!.city}'),
                        ),
                      ),
                    ],
                    if (_products.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Товари',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ..._products.map(
                            (item) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.shopping_bag),
                            title: Text(item.title),
                            trailing: Text('${item.price.toStringAsFixed(0)} грн'),
                          ),
                        ),
                      ),
                    ],
                    if (_orders.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Історія замовлень',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ..._orders.map(
                            (order) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.receipt_long),
                            title: Text('${order.id} — ${order.status}'),
                            subtitle: Text(order.summary),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}