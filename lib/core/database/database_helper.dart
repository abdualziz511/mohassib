import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'mohassib_v3.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS suppliers (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          name            TEXT    NOT NULL,
          phone           TEXT,
          address         TEXT,
          current_balance REAL    NOT NULL DEFAULT 0.0,
          notes           TEXT,
          created_at      TEXT    NOT NULL,
          updated_at      TEXT    NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchases (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          supplier_id     INTEGER REFERENCES suppliers(id),
          invoice_number  TEXT    NOT NULL,
          total_amount    REAL    NOT NULL,
          paid_amount     REAL    NOT NULL DEFAULT 0.0,
          payment_method  TEXT    NOT NULL,
          notes           TEXT,
          created_at      TEXT    NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_items (
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          purchase_id   INTEGER NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
          product_id    INTEGER NOT NULL,
          product_name  TEXT    NOT NULL,
          buy_price     REAL    NOT NULL,
          quantity      REAL    NOT NULL,
          unit          TEXT    NOT NULL,
          total         REAL    NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS currencies (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          code            TEXT    NOT NULL UNIQUE,
          name            TEXT    NOT NULL,
          exchange_rate   REAL    NOT NULL DEFAULT 1.0,
          symbol          TEXT,
          is_default      INTEGER NOT NULL DEFAULT 0,
          updated_at      TEXT    NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_units (
          id                INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id        INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
          unit_name         TEXT    NOT NULL,
          conversion_factor REAL    NOT NULL DEFAULT 1.0,
          is_purchase_unit  INTEGER NOT NULL DEFAULT 0,
          is_sale_unit      INTEGER NOT NULL DEFAULT 0,
          price_markup      REAL    NOT NULL DEFAULT 0.0
        )
      ''');

      try { await db.execute('ALTER TABLE products ADD COLUMN currency_id INTEGER REFERENCES currencies(id)'); } catch(_) {}
      try { await db.execute('ALTER TABLE products ADD COLUMN wholesale_price REAL DEFAULT 0.0'); } catch(_) {}

      final now = DateTime.now().toIso8601String();
      await db.insert('currencies', {'code': 'YER', 'name': 'ريال يمني', 'exchange_rate': 1.0, 'symbol': 'ر.ي', 'is_default': 1, 'updated_at': now});
      await db.insert('currencies', {'code': 'SAR', 'name': 'ريال سعودي', 'exchange_rate': 148.0, 'symbol': 'ر.س', 'is_default': 0, 'updated_at': now});
      await db.insert('currencies', {'code': 'USD', 'name': 'دولار أمريكي', 'exchange_rate': 530.0, 'symbol': '\$', 'is_default': 0, 'updated_at': now});
    }

    if (oldVersion < 4) {
      // 1. إضافة جدول العملاء
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customers (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          name            TEXT    NOT NULL,
          phone           TEXT,
          address         TEXT,
          current_balance REAL    NOT NULL DEFAULT 0.0,
          notes           TEXT,
          created_at      TEXT    NOT NULL,
          updated_at      TEXT    NOT NULL
        )
      ''');

      // 2. إضافة جدول حركة الصندوق (الكاشير)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cash_transactions (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          type            TEXT    NOT NULL, -- 'in', 'out'
          amount          REAL    NOT NULL,
          reference_type  TEXT, -- 'sale', 'purchase', 'expense', 'debt_payment'
          reference_id    INTEGER,
          notes           TEXT,
          created_at      TEXT    NOT NULL
        )
      ''');

      // 3. إضافة أعمدة لربط الديون بالعملاء والموردين والعملات
      try { await db.execute('ALTER TABLE debts ADD COLUMN customer_id INTEGER REFERENCES customers(id)'); } catch(_) {}
      try { await db.execute('ALTER TABLE debts ADD COLUMN supplier_id INTEGER REFERENCES suppliers(id)'); } catch(_) {}
      try { await db.execute('ALTER TABLE debts ADD COLUMN currency_id INTEGER REFERENCES currencies(id)'); } catch(_) {}

      // 4. إضافة ربط المبيعات بالعملاء
      try { await db.execute('ALTER TABLE sales ADD COLUMN customer_id INTEGER REFERENCES customers(id)'); } catch(_) {}
      
      // 5. إضافة stock_qty لجدول تفاصيل المبيعات والمشتريات لمعرفة الخصم الحقيقي
      try { await db.execute('ALTER TABLE sale_items ADD COLUMN stock_qty REAL NOT NULL DEFAULT 1.0'); } catch(_) {}
      try { await db.execute('ALTER TABLE purchase_items ADD COLUMN stock_qty REAL NOT NULL DEFAULT 1.0'); } catch(_) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. العملات
    await db.execute('''
      CREATE TABLE currencies (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        code            TEXT    NOT NULL UNIQUE,
        name            TEXT    NOT NULL,
        exchange_rate   REAL    NOT NULL DEFAULT 1.0,
        symbol          TEXT,
        is_default      INTEGER NOT NULL DEFAULT 0,
        updated_at      TEXT    NOT NULL
      )
    ''');

    // 2. إعدادات المتجر
    await db.execute('''
      CREATE TABLE store_settings (
        id          INTEGER PRIMARY KEY,
        store_name  TEXT    NOT NULL DEFAULT 'متجري',
        owner_name  TEXT    NOT NULL DEFAULT 'صاحب المتجر',
        phone       TEXT,
        address     TEXT,
        currency    TEXT    NOT NULL DEFAULT 'ر.ي',
        tax_rate    REAL    NOT NULL DEFAULT 0.0,
        logo_path   TEXT,
        created_at  TEXT    NOT NULL,
        updated_at  TEXT    NOT NULL
      )
    ''');

    // 3. الموردين
    await db.execute('''
      CREATE TABLE suppliers (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        name            TEXT    NOT NULL,
        phone           TEXT,
        address         TEXT,
        current_balance REAL    NOT NULL DEFAULT 0.0,
        notes           TEXT,
        created_at      TEXT    NOT NULL,
        updated_at      TEXT    NOT NULL
      )
    ''');

    // 4. العملاء
    await db.execute('''
      CREATE TABLE customers (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        name            TEXT    NOT NULL,
        phone           TEXT,
        address         TEXT,
        current_balance REAL    NOT NULL DEFAULT 0.0,
        notes           TEXT,
        created_at      TEXT    NOT NULL,
        updated_at      TEXT    NOT NULL
      )
    ''');

    // 5. المنتجات
    await db.execute('''
      CREATE TABLE products (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        name            TEXT    NOT NULL,
        barcode         TEXT,
        buy_price       REAL    NOT NULL DEFAULT 0.0,
        sell_price      REAL    NOT NULL DEFAULT 0.0,
        wholesale_price REAL    DEFAULT 0.0,
        quantity        REAL    NOT NULL DEFAULT 0.0,
        unit            TEXT    NOT NULL DEFAULT 'قطعة',
        currency_id     INTEGER REFERENCES currencies(id),
        is_liquid       INTEGER NOT NULL DEFAULT 0,
        is_by_weight    INTEGER NOT NULL DEFAULT 0,
        low_stock_alert REAL    NOT NULL DEFAULT 5.0,
        image_path      TEXT,
        is_active       INTEGER NOT NULL DEFAULT 1,
        created_at      TEXT    NOT NULL,
        updated_at      TEXT    NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_products_active  ON products(is_active)');

    // 6. وحدات المنتجات
    await db.execute('''
      CREATE TABLE product_units (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id        INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        unit_name         TEXT    NOT NULL,
        conversion_factor REAL    NOT NULL DEFAULT 1.0,
        is_purchase_unit  INTEGER NOT NULL DEFAULT 0,
        is_sale_unit      INTEGER NOT NULL DEFAULT 0,
        price_markup      REAL    NOT NULL DEFAULT 0.0
      )
    ''');

    // 7. الفواتير
    await db.execute('''
      CREATE TABLE sales (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_number     INTEGER NOT NULL,
        total_amount    REAL    NOT NULL,
        discount        REAL    NOT NULL DEFAULT 0.0,
        tax_amount      REAL    NOT NULL DEFAULT 0.0,
        payment_method  TEXT    NOT NULL,
        customer_name   TEXT,
        customer_phone  TEXT,
        notes           TEXT,
        status          TEXT    NOT NULL DEFAULT 'completed',
        customer_id     INTEGER REFERENCES customers(id),
        created_at      TEXT    NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_sales_date   ON sales(created_at)');

    // 8. تفاصيل الفاتورة
    await db.execute('''
      CREATE TABLE sale_items (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id       INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
        product_id    INTEGER NOT NULL,
        product_name  TEXT    NOT NULL,
        buy_price     REAL    NOT NULL,
        sell_price    REAL    NOT NULL,
        quantity      REAL    NOT NULL,
        stock_qty     REAL    NOT NULL DEFAULT 1.0,
        total         REAL    NOT NULL
      )
    ''');

    // 9. المصروفات
    await db.execute('''
      CREATE TABLE expenses (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        amount      REAL    NOT NULL,
        category    TEXT    NOT NULL,
        notes       TEXT,
        created_at  TEXT    NOT NULL
      )
    ''');

    // 10. الديون
    await db.execute('''
      CREATE TABLE debts (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        type            TEXT    NOT NULL,
        person_name     TEXT    NOT NULL,
        phone           TEXT,
        amount          REAL    NOT NULL,
        paid_amount     REAL    NOT NULL DEFAULT 0.0,
        reminder_date   TEXT,
        notes           TEXT,
        status          TEXT    NOT NULL DEFAULT 'pending',
        whatsapp_alert  INTEGER NOT NULL DEFAULT 0,
        customer_id     INTEGER REFERENCES customers(id),
        supplier_id     INTEGER REFERENCES suppliers(id),
        currency_id     INTEGER REFERENCES currencies(id),
        created_at      TEXT    NOT NULL,
        updated_at      TEXT    NOT NULL
      )
    ''');

    // 11. سداد الديون
    await db.execute('''
      CREATE TABLE debt_payments (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        debt_id     INTEGER NOT NULL REFERENCES debts(id) ON DELETE CASCADE,
        amount      REAL    NOT NULL,
        notes       TEXT,
        created_at  TEXT    NOT NULL
      )
    ''');

    // 12. حركة الصندوق
    await db.execute('''
      CREATE TABLE cash_transactions (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        type            TEXT    NOT NULL,
        amount          REAL    NOT NULL,
        reference_type  TEXT,
        reference_id    INTEGER,
        notes           TEXT,
        created_at      TEXT    NOT NULL
      )
    ''');

    // 13. المشتريات
    await db.execute('''
      CREATE TABLE purchases (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id     INTEGER REFERENCES suppliers(id),
        invoice_number  TEXT    NOT NULL,
        total_amount    REAL    NOT NULL,
        paid_amount     REAL    NOT NULL DEFAULT 0.0,
        payment_method  TEXT    NOT NULL,
        notes           TEXT,
        created_at      TEXT    NOT NULL
      )
    ''');

    // 14. أصناف المشتريات
    await db.execute('''
      CREATE TABLE purchase_items (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id   INTEGER NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
        product_id    INTEGER NOT NULL,
        product_name  TEXT    NOT NULL,
        buy_price     REAL    NOT NULL,
        quantity      REAL    NOT NULL,
        stock_qty     REAL    NOT NULL DEFAULT 1.0,
        unit          TEXT    NOT NULL,
        total         REAL    NOT NULL
      )
    ''');

    // 15. سجل حركات المخزون
    await db.execute('''
      CREATE TABLE stock_movements (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id    INTEGER NOT NULL REFERENCES products(id),
        type          TEXT    NOT NULL,
        quantity      REAL    NOT NULL,
        reference_id  INTEGER,
        notes         TEXT,
        created_at    TEXT    NOT NULL
      )
    ''');

    // بيانات افتراضية
    final now = DateTime.now().toIso8601String();
    
    // إعدادات المتجر
    await db.insert('store_settings', {
      'store_name': 'متجري',
      'owner_name': 'صاحب المتجر',
      'currency': 'ر.ي',
      'tax_rate': 0.0,
      'created_at': now,
      'updated_at': now,
    });

    // العملات الافتراضية
    await db.insert('currencies', {'code': 'YER', 'name': 'ريال يمني', 'exchange_rate': 1.0, 'symbol': 'ر.ي', 'is_default': 1, 'updated_at': now});
    await db.insert('currencies', {'code': 'SAR', 'name': 'ريال سعودي', 'exchange_rate': 148.0, 'symbol': 'ر.س', 'is_default': 0, 'updated_at': now});
    await db.insert('currencies', {'code': 'USD', 'name': 'دولار أمريكي', 'exchange_rate': 530.0, 'symbol': '\$', 'is_default': 0, 'updated_at': now});
  }

  // ─────────────────────────────────────────────
  // STORE SETTINGS
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> getStoreSettings() async {
    final db = await database;
    final rows = await db.query('store_settings', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> updateStoreSettings({String? name, double? taxRate, String? currency}) async {
    final db = await database;
    final Map<String, dynamic> data = {};
    if (name != null) data['store_name'] = name;
    if (taxRate != null) data['tax_rate'] = taxRate;
    if (currency != null) data['currency'] = currency;
    data['updated_at'] = DateTime.now().toIso8601String();
    await db.update('store_settings', data, where: 'id = ?', whereArgs: [1]);
  }

  // ─────────────────────────────────────────────
  // PRODUCTS
  // ─────────────────────────────────────────────
  Future<int> insertProduct(Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;
    final id = await db.insert('products', data);
    await db.insert('stock_movements', {
      'product_id': id,
      'type': 'purchase',
      'quantity': data['quantity'] ?? 0.0,
      'notes': 'إضافة منتج جديد',
      'created_at': now,
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> getAllProducts({bool activeOnly = true}) async {
    final db = await database;
    return activeOnly
        ? await db.query('products', where: 'is_active = ?', whereArgs: [1], orderBy: 'created_at DESC')
        : await db.query('products', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    return await db.query(
      'products',
      where: 'is_active = 1 AND (name LIKE ? OR barcode = ?)',
      whereArgs: ['%$query%', query],
      orderBy: 'name ASC',
    );
  }

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await database;
    final rows = await db.query('products',
        where: 'barcode = ? AND is_active = 1', whereArgs: [barcode], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> updateProduct(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update('products', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> softDeleteProduct(int id) async {
    final db = await database;
    return await db.update('products', {
      'is_active': 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────
  // SALES (atomic transaction)
  // ─────────────────────────────────────────────
  Future<int> processSale({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required double totalAmount,
    required double discount,
    required double taxAmount,
    String? customerName,
    String? customerPhone,
    int? customerId, // الإضافة الجديدة
    String? notes,
  }) async {
    final db = await database;
    int saleId = 0;

    await db.transaction((txn) async {
      // رقم الفاتورة التسلسلي
      final countResult = await txn.rawQuery('SELECT COUNT(*) as cnt FROM sales');
      final int saleNumber = (countResult.first['cnt'] as int) + 1;
      final now = DateTime.now().toIso8601String();

      saleId = await txn.insert('sales', {
        'sale_number': saleNumber,
        'total_amount': totalAmount,
        'discount': discount,
        'tax_amount': taxAmount,
        'payment_method': paymentMethod,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_id': customerId,
        'notes': notes,
        'status': 'completed',
        'created_at': now,
      });

      for (final item in items) {
        final double stockQty = (item['stock_qty'] ?? item['quantity']).toDouble();

        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'buy_price': item['buy_price'],
          'sell_price': item['sell_price'],
          'quantity': item['quantity'],
          'stock_qty': stockQty,
          'total': item['total'],
        });

        // خصم المخزون باستخدام stockQty
        final updated = await txn.rawUpdate('''
          UPDATE products SET quantity = quantity - ?, updated_at = ?
          WHERE id = ? AND (quantity - ?) >= 0
        ''', [stockQty, now, item['product_id'], stockQty]);

        if (updated == 0) {
          throw Exception('الكمية غير كافية للمنتج: ${item['product_name']}');
        }

        await txn.insert('stock_movements', {
          'product_id': item['product_id'],
          'type': 'sale',
          'quantity': -stockQty,
          'reference_id': saleId,
          'notes': 'بيع - فاتورة #$saleNumber',
          'created_at': now,
        });
      }

      // إضافة حركة للصندوق إذا كان الدفع نقداً
      if (paymentMethod == 'cash') {
        await txn.insert('cash_transactions', {
          'type': 'in',
          'amount': totalAmount,
          'reference_type': 'sale',
          'reference_id': saleId,
          'notes': 'مبيعات نقدية - فاتورة #$saleNumber',
          'created_at': now,
        });
      }

      // إنشاء دين تلقائي وتحديث رصيد العميل إذا كان البيع آجل
      if (paymentMethod == 'debt' && (customerName != null || customerId != null)) {
        int? finalCustomerId = customerId;
        String finalName = customerName ?? 'عميل غير محدد';

        // إذا لم يكن هناك ID ولكن يوجد اسم، ابحث عن العميل أولاً لتجنب التكرار
        if (finalCustomerId == null && customerName != null) {
          final existing = await txn.query('customers', 
            where: 'name = ?', whereArgs: [customerName.trim()], limit: 1);
          
          if (existing.isNotEmpty) {
            finalCustomerId = existing.first['id'] as int;
          } else {
            // إنشاء عميل جديد
            finalCustomerId = await txn.insert('customers', {
              'name': customerName.trim(),
              'phone': customerPhone,
              'current_balance': 0.0, // سيتم تحديثه في الخطوة التالية
              'created_at': now,
              'updated_at': now,
            });
          }
        }

        if (finalCustomerId != null) {
          await txn.rawUpdate('''
            UPDATE customers 
            SET current_balance = current_balance + ?, 
                updated_at = ?
            WHERE id = ?
          ''', [totalAmount, now, finalCustomerId]);
        }

        await txn.insert('debts', {
          'type': 'receivable',
          'person_name': finalName,
          'phone': customerPhone,
          'customer_id': finalCustomerId,
          'amount': totalAmount,
          'paid_amount': 0.0,
          'status': 'pending',
          'notes': 'بيع آجل - فاتورة #$saleNumber',
          'whatsapp_alert': 0,
          'created_at': now,
          'updated_at': now,
        });
      }
    });

    return saleId;
  }

  Future<List<Map<String, dynamic>>> getSales({String? dateFilter}) async {
    final db = await database;
    if (dateFilter != null) {
      return await db.query('sales',
          where: "created_at LIKE ?",
          whereArgs: ['$dateFilter%'],
          orderBy: 'created_at DESC');
    }
    return await db.query('sales', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getSaleItems(int saleId) async {
    final db = await database;
    return await db.query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
  }

  Future<List<dynamic>> getSalesHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> salesMaps = await db.query('sales', orderBy: 'created_at DESC');
    
    // سنقوم بتحويل كل خريطة إلى SaleModel لاحقاً في الـ UI أو هنا
    // للتبسيط حالياً، سنعيد البيانات ونترك للـ SaleModel.fromMap المهمة
    // لكن SaleModel يحتاج لقائمة items، لذا سنجلبها لكل فاتورة
    
    // ملاحظة: من الأفضل استيراد SaleModel هنا إذا لزم الأمر، 
    // لكن لتجنب التعارضات الدائرية، سنعيد الخرائط مطورة
    List<Map<String, dynamic>> fullSales = [];
    for (var m in salesMaps) {
      var map = Map<String, dynamic>.from(m);
      final items = await getSaleItems(map['id']);
      map['items'] = items;
      fullSales.add(map);
    }
    return fullSales;
  }

  // ─────────────────────────────────────────────
  // EXPENSES
  // ─────────────────────────────────────────────
  Future<int> insertExpense(Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    data['created_at'] = now;
    
    int expenseId = 0;
    await db.transaction((txn) async {
      expenseId = await txn.insert('expenses', data);
      await txn.insert('cash_transactions', {
        'type': 'out',
        'amount': data['amount'],
        'reference_type': 'expense',
        'reference_id': expenseId,
        'notes': 'مصروف: ${data['category']}',
        'created_at': now,
      });
    });
    return expenseId;
  }

  Future<List<Map<String, dynamic>>> getExpenses({String? dateFilter, String? category}) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];
    if (dateFilter != null) { where.add("created_at LIKE ?"); args.add('$dateFilter%'); }
    if (category != null && category != 'الكل') { where.add("category = ?"); args.add(category); }
    return await db.query('expenses',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'created_at DESC');
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────
  // DEBTS
  // ─────────────────────────────────────────────
  Future<int> insertDebt(Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;
    return await db.insert('debts', data);
  }

  Future<List<Map<String, dynamic>>> getDebts({String? type}) async {
    final db = await database;
    return type != null
        ? await db.query('debts', where: 'type = ?', whereArgs: [type], orderBy: 'created_at DESC')
        : await db.query('debts', orderBy: 'created_at DESC');
  }

  Future<void> addDebtPayment(int debtId, double amount, String? notes) async {
    final db = await database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final paymentId = await txn.insert('debt_payments', {
        'debt_id': debtId,
        'amount': amount,
        'notes': notes,
        'created_at': now,
      });
      // تحديث paid_amount والحالة
      final rows = await txn.query('debts', where: 'id = ?', whereArgs: [debtId]);
      if (rows.isNotEmpty) {
        final debt = rows.first;
        final newPaid = (debt['paid_amount'] as double) + amount;
        final total = debt['amount'] as double;
        final status = newPaid >= total ? 'paid' : 'partial';
        await txn.update('debts', {
          'paid_amount': newPaid,
          'status': status,
          'updated_at': now,
        }, where: 'id = ?', whereArgs: [debtId]);

        // حركة الصندوق (إذا كان دين لنا فهو دخول، وإذا كان علينا فهو خروج)
        final debtType = debt['type'] as String;
        await txn.insert('cash_transactions', {
          'type': debtType == 'receivable' ? 'in' : 'out',
          'amount': amount,
          'reference_type': 'debt_payment',
          'reference_id': paymentId,
          'notes': 'دفعة دين لـ ${debt['person_name']}',
          'created_at': now,
        });

        // تحديث رصيد العميل أو المورد
        if (debtType == 'receivable' && debt['customer_id'] != null) {
          await txn.rawUpdate('''
            UPDATE customers 
            SET current_balance = current_balance - ?, 
                updated_at = ?
            WHERE id = ?
          ''', [amount, now, debt['customer_id']]);
        } else if (debtType == 'payable' && debt['supplier_id'] != null) {
          await txn.rawUpdate('''
            UPDATE suppliers 
            SET current_balance = current_balance - ?, 
                updated_at = ?
            WHERE id = ?
          ''', [amount, now, debt['supplier_id']]);
        }
      }
    });
  }

  Future<void> payCustomerDebtBulk(int customerId, double amount, String notes) async {
    final db = await database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final rows = await txn.query('debts', 
        where: 'customer_id = ? AND status != ? AND type = ?', 
        whereArgs: [customerId, 'paid', 'receivable'],
        orderBy: 'created_at ASC'
      );
      
      double remainingAmount = amount;
      
      for (final row in rows) {
        if (remainingAmount <= 0) break;
        
        final debtId = row['id'] as int;
        final debtAmount = row['amount'] as double;
        final paidAmount = row['paid_amount'] as double;
        final required = debtAmount - paidAmount;
        
        final paymentForThis = (remainingAmount >= required) ? required : remainingAmount;
        
        await txn.insert('debt_payments', {
          'debt_id': debtId,
          'amount': paymentForThis,
          'notes': notes,
          'created_at': now,
        });
        
        final newPaid = paidAmount + paymentForThis;
        final status = newPaid >= debtAmount ? 'paid' : 'partial';
        await txn.update('debts', {
          'paid_amount': newPaid,
          'status': status,
          'updated_at': now,
        }, where: 'id = ?', whereArgs: [debtId]);
        
        remainingAmount -= paymentForThis;
      }
      
      await txn.rawUpdate('''
        UPDATE customers 
        SET current_balance = current_balance - ?, 
            updated_at = ?
        WHERE id = ?
      ''', [amount, now, customerId]);
      
      await txn.insert('cash_transactions', {
        'type': 'in',
        'amount': amount,
        'reference_type': 'bulk_debt_payment',
        'reference_id': customerId,
        'notes': notes,
        'created_at': now,
      });
    });
  }

  Future<void> paySupplierDebtBulk(int supplierId, double amount, String notes) async {
    final db = await database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final rows = await txn.query('debts', 
        where: 'supplier_id = ? AND status != ? AND type = ?', 
        whereArgs: [supplierId, 'paid', 'payable'],
        orderBy: 'created_at ASC'
      );
      
      double remainingAmount = amount;
      
      for (final row in rows) {
        if (remainingAmount <= 0) break;
        
        final debtId = row['id'] as int;
        final debtAmount = row['amount'] as double;
        final paidAmount = row['paid_amount'] as double;
        final required = debtAmount - paidAmount;
        
        final paymentForThis = (remainingAmount >= required) ? required : remainingAmount;
        
        await txn.insert('debt_payments', {
          'debt_id': debtId,
          'amount': paymentForThis,
          'notes': notes,
          'created_at': now,
        });
        
        final newPaid = paidAmount + paymentForThis;
        final status = newPaid >= debtAmount ? 'paid' : 'partial';
        await txn.update('debts', {
          'paid_amount': newPaid,
          'status': status,
          'updated_at': now,
        }, where: 'id = ?', whereArgs: [debtId]);
        
        remainingAmount -= paymentForThis;
      }
      
      await txn.rawUpdate('''
        UPDATE suppliers 
        SET current_balance = current_balance - ?, 
            updated_at = ?
        WHERE id = ?
      ''', [amount, now, supplierId]);
      
      await txn.insert('cash_transactions', {
        'type': 'out',
        'amount': amount,
        'reference_type': 'bulk_debt_payment',
        'reference_id': supplierId,
        'notes': notes,
        'created_at': now,
      });
    });
  }

  Future<void> syncCustomerDebts(int customerId, String name) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query('debts', 
        where: 'type = ? AND person_name = ? AND customer_id IS NULL AND status != ?',
        whereArgs: ['receivable', name, 'paid']
      );

      if (rows.isEmpty) return;

      double totalRemaining = 0.0;
      for (final r in rows) {
        totalRemaining += (r['amount'] as double) - (r['paid_amount'] as double);
        await txn.update('debts', 
          {'customer_id': customerId}, 
          where: 'id = ?', 
          whereArgs: [r['id']]
        );
      }

      if (totalRemaining > 0) {
        await txn.rawUpdate('''
          UPDATE customers 
          SET current_balance = current_balance + ? 
          WHERE id = ?
        ''', [totalRemaining, customerId]);
      }
    });
  }

  Future<void> syncSupplierDebts(int supplierId, String name) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query('debts', 
        where: 'type = ? AND person_name = ? AND supplier_id IS NULL AND status != ?',
        whereArgs: ['payable', name, 'paid']
      );

      if (rows.isEmpty) return;

      double totalRemaining = 0.0;
      for (final r in rows) {
        totalRemaining += (r['amount'] as double) - (r['paid_amount'] as double);
        await txn.update('debts', 
          {'supplier_id': supplierId}, 
          where: 'id = ?', 
          whereArgs: [r['id']]
        );
      }

      if (totalRemaining > 0) {
        await txn.rawUpdate('''
          UPDATE suppliers 
          SET current_balance = current_balance + ? 
          WHERE id = ?
        ''', [totalRemaining, supplierId]);
      }
    });
  }

  Future<int> deleteDebt(int id) async {
    final db = await database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPersonStatement(String personName, String type) async {
    final db = await database;
    
    // type: 'receivable' (لي) or 'payable' (علي)
    final sql = '''
      SELECT 
        'debt' as record_type, 
        id, 
        amount, 
        notes, 
        created_at, 
        status
      FROM debts 
      WHERE person_name = ? AND type = ?

      UNION ALL

      SELECT 
        'payment' as record_type, 
        dp.id, 
        dp.amount, 
        dp.notes, 
        dp.created_at, 
        'paid' as status
      FROM debt_payments dp
      JOIN debts d ON dp.debt_id = d.id
      WHERE d.person_name = ? AND d.type = ?

      ORDER BY created_at ASC
    ''';
    
    return await db.rawQuery(sql, [personName, type, personName, type]);
  }

  // ─────────────────────────────────────────────
  // DASHBOARD STATS
  // ─────────────────────────────────────────────
  Future<Map<String, double>> getDailyStats(String date) async {
    final db = await database;
    final salesResult = await db.rawQuery('''
      SELECT COALESCE(SUM(total_amount),0) as total, COUNT(*) as count
      FROM sales WHERE created_at LIKE '$date%' AND status = 'completed'
    ''');
    final expResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount),0) as total FROM expenses WHERE created_at LIKE '$date%'
    ''');
    final profitResult = await db.rawQuery('''
      SELECT COALESCE(SUM((si.sell_price - si.buy_price) * si.quantity),0) as profit
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      WHERE s.created_at LIKE '$date%' AND s.status = 'completed'
    ''');

    final sales    = (salesResult.first['total']  as num?)?.toDouble() ?? 0;
    final expenses = (expResult.first['total']    as num?)?.toDouble() ?? 0;
    final profit   = (profitResult.first['profit'] as num?)?.toDouble() ?? 0;

    return {
      'sales':        sales,
      'expenses':     expenses,
      'gross_profit': profit,               // ربح المبيعات فقط
      'profit':       profit - expenses,    // صافي (legacy key)
      'net_profit':   profit - expenses,    // صافي الربح بعد المصروفات
      'count': (salesResult.first['count'] as int?)?.toDouble() ?? 0,
    };
  }

  Future<Map<String, double>> getDebtsSummary() async {
    final db = await database;
    final rec = await db.rawQuery('''
      SELECT COALESCE(SUM(amount - paid_amount),0) as total
      FROM debts WHERE type='receivable' AND status != 'paid'
    ''');
    final pay = await db.rawQuery('''
      SELECT COALESCE(SUM(amount - paid_amount),0) as total
      FROM debts WHERE type='payable' AND status != 'paid'
    ''');
    return {
      'receivable': (rec.first['total'] as num?)?.toDouble() ?? 0,
      'payable':    (pay.first['total'] as num?)?.toDouble() ?? 0,
    };
  }

  // ─────────────────────────────────────────────
  // SUPPLIERS
  // ─────────────────────────────────────────────
  Future<int> insertSupplier(Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;
    return await db.insert('suppliers', data);
  }

  Future<List<Map<String, dynamic>>> getAllSuppliers() async {
    final db = await database;
    return await db.query('suppliers', orderBy: 'name ASC');
  }

  Future<int> updateSupplier(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update('suppliers', data, where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────
  // PURCHASES (atomic transaction)
  // ─────────────────────────────────────────────
  Future<int> processPurchase({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required double totalAmount,
    required double paidAmount,
    int? supplierId,
    required String invoiceNumber,
    String? notes,
  }) async {
    final db = await database;
    int purchaseId = 0;

    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      // 1. إدراج رأس الفاتورة
      purchaseId = await txn.insert('purchases', {
        'supplier_id': supplierId,
        'invoice_number': invoiceNumber,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'payment_method': paymentMethod,
        'notes': notes,
        'created_at': now,
      });

      // 2. إدراج الأصناف وتحديث المخزون
      for (final item in items) {
        final double stockQty = (item['stock_qty'] ?? item['quantity']).toDouble();
        final double factor = (item['quantity'] > 0) ? (stockQty / item['quantity']) : 1.0;
        final double baseBuyPrice = item['buy_price'] / factor;

        await txn.insert('purchase_items', {
          'purchase_id': purchaseId,
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'buy_price': item['buy_price'],
          'quantity': item['quantity'],
          'stock_qty': stockQty,
          'unit': item['unit'] ?? 'قطعة',
          'total': item['total'],
        });

        // زيادة المخزون وتحديث سعر شراء الوحدة الصغرى
        await txn.rawUpdate('''
          UPDATE products 
          SET quantity = quantity + ?, 
              buy_price = ?, 
              updated_at = ?
          WHERE id = ?
        ''', [stockQty, baseBuyPrice, now, item['product_id']]);

        // سجل حركة المخزون
        await txn.insert('stock_movements', {
          'product_id': item['product_id'],
          'type': 'purchase',
          'quantity': stockQty,
          'reference_id': purchaseId,
          'notes': 'شراء - فاتورة #$invoiceNumber',
          'created_at': now,
        });
      }

      // تسجيل المدفوعات في الصندوق
      if (paidAmount > 0) {
        await txn.insert('cash_transactions', {
          'type': 'out',
          'amount': paidAmount,
          'reference_type': 'purchase',
          'reference_id': purchaseId,
          'notes': 'دفع مشتريات - فاتورة #$invoiceNumber',
          'created_at': now,
        });
      }

      // 3. تحديث مديونية المورد إذا كان الشراء آجل أو جزئي
      if (supplierId != null) {
        final remaining = totalAmount - paidAmount;
        if (remaining > 0) {
          await txn.rawUpdate('''
            UPDATE suppliers 
            SET current_balance = current_balance + ?, 
                updated_at = ?
            WHERE id = ?
          ''', [remaining, now, supplierId]);

          // إضافة سجل في جدول الديون لتوحيد المطالبات (اختياري، لكن مفيد للكشوفات)
          await txn.insert('debts', {
            'type': 'payable',
            'person_name': 'فاتورة مشتريات #$invoiceNumber',
            'phone': '', // يمكن جلبه من المورد لاحقاً
            'supplier_id': supplierId,
            'amount': remaining,
            'paid_amount': 0.0,
            'status': 'pending',
            'notes': 'فاتورة مشتريات رقم $invoiceNumber',
            'whatsapp_alert': 0,
            'created_at': now,
            'updated_at': now,
          });
        }
      }
    });

    return purchaseId;
  }

  Future<List<Map<String, dynamic>>> getPurchases() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, s.name as supplier_name 
      FROM purchases p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      ORDER BY p.created_at DESC
    ''');
  }

  // ─────────────────────────────────────────────
  // PRODUCT UNITS
  // ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getProductUnits(int productId) async {
    final db = await database;
    return await db.query('product_units', where: 'product_id = ?', whereArgs: [productId]);
  }

  Future<void> insertProductUnits(int productId, List<Map<String, dynamic>> units) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('product_units', where: 'product_id = ?', whereArgs: [productId]);
      for (var u in units) {
        u['product_id'] = productId;
        await txn.insert('product_units', u);
      }
    });
  }
}
