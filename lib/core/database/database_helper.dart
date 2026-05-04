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
    return await (String path,
        {int? version,
        OnDatabaseConfigureFn? onConfigure,
        OnDatabaseCreateFn? onCreate,
        OnDatabaseVersionChangeFn? onUpgrade,
        OnDatabaseVersionChangeFn? onDowngrade,
        OnDatabaseOpenFn? onOpen,
        bool? readOnly = false,
        bool? singleInstance = true}) {
      final options = OpenDatabaseOptions(
          version: version,
          onConfigure: onConfigure,
          onCreate: onCreate,
          onUpgrade: onUpgrade,
          onDowngrade: onDowngrade,
          onOpen: onOpen,
          readOnly: readOnly,
          singleInstance: singleInstance);
      return databaseFactory.openDatabase(path, options: options);
    }(
      path,
      version: 11,
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

    if (oldVersion < 5) {
      // 1. إضافة حقل تصنيف المنتجات
      try { await db.execute("ALTER TABLE products ADD COLUMN category TEXT DEFAULT 'عام'"); } catch(_) {}
    }

    if (oldVersion < 7) {
      // إضافة جداول المرتجعات
      await db.execute('''
        CREATE TABLE returns (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id         INTEGER,
          sale_number     TEXT,
          total_amount    REAL    NOT NULL,
          payment_method  TEXT    NOT NULL,
          notes           TEXT,
          created_at      TEXT    NOT NULL,
          FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE SET NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE return_items (
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          return_id     INTEGER NOT NULL,
          product_id    INTEGER NOT NULL,
          product_name  TEXT    NOT NULL,
          quantity      REAL    NOT NULL,
          price         REAL    NOT NULL,
          total         REAL    NOT NULL,
          FOREIGN KEY (return_id) REFERENCES returns (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 8) {
      // إضافة جدول جلسات الصندوق
      await db.execute('''
        CREATE TABLE cash_sessions (
          id                INTEGER PRIMARY KEY AUTOINCREMENT,
          opening_balance   REAL    NOT NULL DEFAULT 0.0,
          closing_balance   REAL,
          actual_cash       REAL,
          difference        REAL,
          status            TEXT    NOT NULL DEFAULT 'open', -- 'open' or 'closed'
          notes             TEXT,
          opened_at         TEXT    NOT NULL,
          closed_at         TEXT
        )
      ''');
    }

    if (oldVersion < 9) {
      // إضافة الفهارس المفقودة لتحسين الأداء
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_suppliers_name ON suppliers(name)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_product_units_pid ON product_units(product_id)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_customer_id ON sales(customer_id)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_sid ON sale_items(sale_id)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(created_at)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_debts_person_name ON debts(person_name)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_debts_customer_id ON debts(customer_id)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_debts_supplier_id ON debts(supplier_id)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_debts_status ON debts(status)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_debt_payments_did ON debt_payments(debt_id)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_cash_transactions_date ON cash_transactions(created_at)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_purchases_supplier_id ON purchases(supplier_id)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_purchase_items_pid ON purchase_items(purchase_id)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_movements_pid ON stock_movements(product_id)'); } catch(_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_movements_date ON stock_movements(created_at)'); } catch(_) {}
    }

    if (oldVersion < 10) {
      // إضافة جدول تصنيفات المصروفات
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expense_categories (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          name       TEXT    NOT NULL UNIQUE,
          icon       TEXT,
          color      TEXT,
          is_default INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL DEFAULT 0
        )
      ''');
      // إدراج التصنيفات الافتراضية
      final defCats = [
        {'name': 'إيجار',                    'icon': 'home',          'is_default': 1, 'sort_order': 1},
        {'name': 'كهرباء',                   'icon': 'flash_on',      'is_default': 1, 'sort_order': 2},
        {'name': 'نقل',                      'icon': 'local_shipping', 'is_default': 1, 'sort_order': 3},
        {'name': 'الإلتزامات',               'icon': 'handshake',     'is_default': 1, 'sort_order': 4},
        {'name': 'منتجات منتهية الصلاحية',   'icon': 'no_food',       'is_default': 1, 'sort_order': 5},
        {'name': 'رواتب',                    'icon': 'people',        'is_default': 1, 'sort_order': 6},
        {'name': 'صيانة',                    'icon': 'build',         'is_default': 1, 'sort_order': 7},
        {'name': 'أخرى',                     'icon': 'more_horiz',    'is_default': 1, 'sort_order': 8},
      ];
      for (final c in defCats) {
        try { await db.insert('expense_categories', c); } catch (_) {}
      }
    }

    if (oldVersion < 11) {
      try { await db.execute('ALTER TABLE product_units ADD COLUMN barcode TEXT'); } catch(_) {}
      try { await db.execute('ALTER TABLE product_units ADD COLUMN sell_price REAL DEFAULT 0.0'); } catch(_) {}
      try { await db.execute('CREATE INDEX idx_product_units_barcode ON product_units(barcode)'); } catch(_) {}
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
    await db.execute('CREATE INDEX idx_suppliers_name ON suppliers(name)');

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
    await db.execute('CREATE INDEX idx_customers_name ON customers(name)');

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
        category        TEXT    DEFAULT 'عام',
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
    await db.execute('CREATE INDEX idx_products_name    ON products(name)');

    // 6. وحدات المنتجات
    await db.execute('''
      CREATE TABLE product_units (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id        INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        unit_name         TEXT    NOT NULL,
        conversion_factor REAL    NOT NULL DEFAULT 1.0,
        is_purchase_unit  INTEGER NOT NULL DEFAULT 0,
        is_sale_unit      INTEGER NOT NULL DEFAULT 0,
        price_markup      REAL    NOT NULL DEFAULT 0.0,
        barcode           TEXT,
        sell_price        REAL    DEFAULT 0.0
      )
    ''');
    await db.execute('CREATE INDEX idx_product_units_pid ON product_units(product_id)');
    await db.execute('CREATE INDEX idx_product_units_barcode ON product_units(barcode)');


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
    await db.execute('CREATE INDEX idx_sales_date       ON sales(created_at)');
    await db.execute('CREATE INDEX idx_sales_customer_id ON sales(customer_id)');

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
    await db.execute('CREATE INDEX idx_sale_items_sid ON sale_items(sale_id)');

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
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(created_at)');

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
    await db.execute('CREATE INDEX idx_debts_person_name ON debts(person_name)');
    await db.execute('CREATE INDEX idx_debts_customer_id ON debts(customer_id)');
    await db.execute('CREATE INDEX idx_debts_supplier_id ON debts(supplier_id)');
    await db.execute('CREATE INDEX idx_debts_status      ON debts(status)');

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
    await db.execute('CREATE INDEX idx_debt_payments_did ON debt_payments(debt_id)');

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
    await db.execute('CREATE INDEX idx_cash_transactions_date ON cash_transactions(created_at)');

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
    await db.execute('CREATE INDEX idx_purchases_date ON purchases(created_at)');
    await db.execute('CREATE INDEX idx_purchases_supplier_id ON purchases(supplier_id)');

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
    await db.execute('CREATE INDEX idx_purchase_items_pid ON purchase_items(purchase_id)');

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
    await db.execute('CREATE INDEX idx_stock_movements_pid ON stock_movements(product_id)');
    await db.execute('CREATE INDEX idx_stock_movements_date ON stock_movements(created_at)');

    // 16. المرتجعات
    await db.execute('''
      CREATE TABLE returns (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id         INTEGER,
        sale_number     TEXT,
        total_amount    REAL    NOT NULL,
        payment_method  TEXT    NOT NULL,
        notes           TEXT,
        created_at      TEXT    NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_returns_date ON returns(created_at)');

    // 17. أصناف المرتجعات
    await db.execute('''
      CREATE TABLE return_items (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        return_id     INTEGER NOT NULL,
        product_id    INTEGER NOT NULL,
        product_name  TEXT    NOT NULL,
        quantity      REAL    NOT NULL,
        price         REAL    NOT NULL,
        total         REAL    NOT NULL,
        FOREIGN KEY (return_id) REFERENCES returns (id) ON DELETE CASCADE
      )
    ''');

    // 18. جلسات الصندوق
    await db.execute('''
      CREATE TABLE cash_sessions (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        opening_balance   REAL    NOT NULL DEFAULT 0.0,
        closing_balance   REAL,
        actual_cash       REAL,
        difference        REAL,
        status            TEXT    NOT NULL DEFAULT 'open',
        notes             TEXT,
        opened_at         TEXT    NOT NULL,
        closed_at         TEXT
      )
    ''');

    // 19. تصنيفات المصروفات
    await db.execute('''
      CREATE TABLE expense_categories (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL UNIQUE,
        icon       TEXT,
        color      TEXT,
        is_default INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
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

    // تصنيفات المصروفات الافتراضية
    final defCats = [
      {'name': 'إيجار',                    'icon': 'home',          'is_default': 1, 'sort_order': 1},
      {'name': 'كهرباء',                   'icon': 'flash_on',      'is_default': 1, 'sort_order': 2},
      {'name': 'نقل',                      'icon': 'local_shipping', 'is_default': 1, 'sort_order': 3},
      {'name': 'الإلتزامات',               'icon': 'handshake',     'is_default': 1, 'sort_order': 4},
      {'name': 'منتجات منتهية الصلاحية',   'icon': 'no_food',       'is_default': 1, 'sort_order': 5},
      {'name': 'رواتب',                    'icon': 'people',        'is_default': 1, 'sort_order': 6},
      {'name': 'صيانة',                    'icon': 'build',         'is_default': 1, 'sort_order': 7},
      {'name': 'أخرى',                     'icon': 'more_horiz',    'is_default': 1, 'sort_order': 8},
    ];
    for (final c in defCats) {
      await db.insert('expense_categories', c);
    }
  }

  // ─────────────────────────────────────────────
  // STORE SETTINGS
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> getStoreSettings() async {
    final db = await database;
    final rows = await db.query('store_settings', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> updateStoreSettings({String? name, double? taxRate, String? currency, String? phone, String? address, String? logoPath}) async {
    final db = await database;
    final Map<String, dynamic> data = {};
    if (name != null) data['store_name'] = name;
    if (taxRate != null) data['tax_rate'] = taxRate;
    if (currency != null) data['currency'] = currency;
    if (phone != null) data['phone'] = phone;
    if (address != null) data['address'] = address;
    if (logoPath != null) data['logo_path'] = logoPath;
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
    
    // 1. نبحث في المنتج الأساسي
    var rows = await db.query('products',
        where: 'barcode = ? AND is_active = 1', whereArgs: [barcode], limit: 1);
        
    if (rows.isNotEmpty) {
      final pMap = Map<String, dynamic>.from(rows.first);
      pMap['selected_unit'] = null; // لم يستخدم وحدة فرعية
      return pMap;
    }

    // 2. إذا لم نجد، نبحث في وحدات المنتجات
    final unitRows = await db.query('product_units',
        where: 'barcode = ?', whereArgs: [barcode], limit: 1);
        
    if (unitRows.isNotEmpty) {
      final u = unitRows.first;
      final productId = u['product_id'];
      
      // جلب المنتج الأساسي للوحدة
      final pRows = await db.query('products',
          where: 'id = ? AND is_active = 1', whereArgs: [productId], limit: 1);
          
      if (pRows.isNotEmpty) {
        final pMap = Map<String, dynamic>.from(pRows.first);
        // نعيد المنتج، مع دمج بيانات الوحدة لاستخدامها في المبيعات
        pMap['selected_unit'] = u;
        return pMap;
      }
    }
    
    return null;
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

  Future<List<dynamic>> getSalesHistory({bool fetchItems = false}) async {
    final db = await database;
    final List<Map<String, dynamic>> salesMaps = await db.query('sales', orderBy: 'created_at DESC');
    
    if (!fetchItems) return salesMaps;

    List<Map<String, dynamic>> fullSales = [];
    for (var m in salesMaps) {
      var map = Map<String, dynamic>.from(m);
      final items = await getSaleItems(map['id']);
      map['items'] = items;
      fullSales.add(map);
    }
    return fullSales;
  }

  /// فلترة المبيعات حسب نطاق تاريخ، طريقة دفع، أو اسم عميل
  Future<List<Map<String, dynamic>>> getSalesFiltered({
    DateTime? from,
    DateTime? to,
    String? paymentMethod,
    String? customerName,
    bool fetchItems = false,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (from != null) {
      where.add("created_at >= ?");
      args.add(from.toIso8601String().substring(0, 10));
    }
    if (to != null) {
      where.add("created_at < ?");
      args.add(to.add(const Duration(days: 1)).toIso8601String().substring(0, 10));
    }
    if (paymentMethod != null && paymentMethod != 'الكل') {
      where.add("payment_method = ?");
      args.add(paymentMethod);
    }
    if (customerName != null && customerName.isNotEmpty) {
      where.add("customer_name LIKE ?");
      args.add('%$customerName%');
    }

    final salesMaps = await db.query(
      'sales',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
    );

    if (!fetchItems) return salesMaps;

    List<Map<String, dynamic>> fullSales = [];
    for (var m in salesMaps) {
      var map = Map<String, dynamic>.from(m);
      final items = await getSaleItems(map['id']);
      map['items'] = items;
      fullSales.add(map);
    }
    return fullSales;
  }

  /// بيانات المبيعات اليومية لآخر N يوم (للرسم البياني)
  Future<List<Map<String, dynamic>>> getDailySalesChart({int days = 7}) async {
    final db = await database;
    final result = <Map<String, dynamic>>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final rows = await db.rawQuery('''
        SELECT COALESCE(SUM(total_amount),0) as total, COUNT(*) as cnt
        FROM sales WHERE created_at LIKE '$dateStr%' AND status='completed'
      ''');
      result.add({
        'date': dateStr,
        'label': '${date.day}/${date.month}',
        'total': (rows.first['total'] as num?)?.toDouble() ?? 0.0,
        'count': (rows.first['cnt'] as int?) ?? 0,
      });
    }
    return result;
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

    int debtId = 0;
    await db.transaction((txn) async {
      debtId = await txn.insert('debts', data);

      final type = data['type'] as String;
      final amount = (data['amount'] as num).toDouble();
      final paid = (data['paid_amount'] as num?)?.toDouble() ?? 0.0;
      final remaining = amount - paid;

      if (remaining != 0) {
        if (type == 'receivable' && data['customer_id'] != null) {
          await txn.rawUpdate(
            'UPDATE customers SET current_balance = current_balance + ?, updated_at = ? WHERE id = ?',
            [remaining, now, data['customer_id']]
          );
        } else if (type == 'payable' && data['supplier_id'] != null) {
          await txn.rawUpdate(
            'UPDATE suppliers SET current_balance = current_balance + ?, updated_at = ? WHERE id = ?',
            [remaining, now, data['supplier_id']]
          );
        }
      }
    });
    return debtId;
  }

  Future<void> updateDebt(int id, Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    data['updated_at'] = now;

    await db.transaction((txn) async {
      final oldRows = await txn.query('debts', where: 'id = ?', whereArgs: [id]);
      if (oldRows.isEmpty) return;
      final old = oldRows.first;

      // 1. عكس الرصيد القديم
      final oldRemaining = (old['amount'] as double) - (old['paid_amount'] as double);
      if (old['type'] == 'receivable' && old['customer_id'] != null) {
        await txn.rawUpdate('UPDATE customers SET current_balance = current_balance - ? WHERE id = ?', [oldRemaining, old['customer_id']]);
      } else if (old['type'] == 'payable' && old['supplier_id'] != null) {
        await txn.rawUpdate('UPDATE suppliers SET current_balance = current_balance - ? WHERE id = ?', [oldRemaining, old['supplier_id']]);
      }

      // 2. تحديث الدين
      await txn.update('debts', data, where: 'id = ?', whereArgs: [id]);

      // 3. تطبيق الرصيد الجديد
      final updatedRows = await txn.query('debts', where: 'id = ?', whereArgs: [id]);
      final updated = updatedRows.first;
      final newRemaining = (updated['amount'] as double) - (updated['paid_amount'] as double);

      if (updated['type'] == 'receivable' && updated['customer_id'] != null) {
        await txn.rawUpdate('UPDATE customers SET current_balance = current_balance + ? WHERE id = ?', [newRemaining, updated['customer_id']]);
      } else if (updated['type'] == 'payable' && updated['supplier_id'] != null) {
        await txn.rawUpdate('UPDATE suppliers SET current_balance = current_balance + ? WHERE id = ?', [newRemaining, updated['supplier_id']]);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getDebts({String? type}) async {
    final db = await database;
    return type != null
        ? await db.query('debts', where: 'type = ?', whereArgs: [type], orderBy: 'created_at DESC')
        : await db.query('debts', orderBy: 'created_at DESC');
  }

  Future<double> addDebtPayment(int debtId, double amount, String? notes) async {
    final db = await database;
    double excess = 0;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      
      // جلب الدين للتأكد من المتبقي
      final rows = await txn.query('debts', where: 'id = ?', whereArgs: [debtId]);
      if (rows.isNotEmpty) {
        final debt = rows.first;
        final total = debt['amount'] as double;
        final alreadyPaid = debt['paid_amount'] as double;
        final remaining = total - alreadyPaid;
        
        final double appliedAmount = (amount >= remaining) ? remaining : amount;
        excess = amount - appliedAmount;

        final paymentId = await txn.insert('debt_payments', {
          'debt_id': debtId,
          'amount': appliedAmount,
          'notes': notes,
          'created_at': now,
        });

        final newPaid = alreadyPaid + appliedAmount;
        final status = newPaid >= total ? 'paid' : 'partial';
        
        await txn.update('debts', {
          'paid_amount': newPaid,
          'status': status,
          'updated_at': now,
        }, where: 'id = ?', whereArgs: [debtId]);

        // حركة الصندوق (بالقيمة الفعلية المطبقة فقط)
        final debtType = debt['type'] as String;
        await txn.insert('cash_transactions', {
          'type': debtType == 'receivable' ? 'in' : 'out',
          'amount': appliedAmount,
          'reference_type': 'debt_payment',
          'reference_id': paymentId,
          'notes': 'سداد دين - ${debt['person_name']}',
          'created_at': now,
        });

        // تحديث رصيد العميل أو المورد (بالقيمة المطبقة فقط)
        if (debtType == 'receivable' && debt['customer_id'] != null) {
          await txn.rawUpdate('''
            UPDATE customers SET current_balance = current_balance - ?, updated_at = ?
            WHERE id = ?
          ''', [appliedAmount, now, debt['customer_id']]);
        } else if (debtType == 'payable' && debt['supplier_id'] != null) {
          await txn.rawUpdate('''
            UPDATE suppliers SET current_balance = current_balance - ?, updated_at = ?
            WHERE id = ?
          ''', [appliedAmount, now, debt['supplier_id']]);
        }
      }
    });
    return excess;
  }

  Future<double> payCustomerDebtBulk(int customerId, double amount, String notes) async {
    final db = await database;
    double appliedTotal = 0;
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
        appliedTotal += paymentForThis;
      }
      
      if (appliedTotal > 0) {
        await txn.rawUpdate('''
          UPDATE customers SET current_balance = current_balance - ?, updated_at = ?
          WHERE id = ?
        ''', [appliedTotal, now, customerId]);
        
        await txn.insert('cash_transactions', {
          'type': 'in',
          'amount': appliedTotal,
          'reference_type': 'bulk_debt_payment',
          'reference_id': customerId,
          'notes': '$notes (إجمالي مسدد من الحساب)',
          'created_at': now,
        });
      }
    });
    return amount - appliedTotal; // Excess
  }

  Future<double> paySupplierDebtBulk(int supplierId, double amount, String notes) async {
    final db = await database;
    double appliedTotal = 0;
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
        appliedTotal += paymentForThis;
      }
      
      if (appliedTotal > 0) {
        await txn.rawUpdate('''
          UPDATE suppliers SET current_balance = current_balance - ?, updated_at = ?
          WHERE id = ?
        ''', [appliedTotal, now, supplierId]);
        
        await txn.insert('cash_transactions', {
          'type': 'out',
          'amount': appliedTotal,
          'reference_type': 'bulk_debt_payment',
          'reference_id': supplierId,
          'notes': '$notes (إجمالي مسدد من الحساب)',
          'created_at': now,
        });
      }
    });
    return amount - appliedTotal; // Excess
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

  /// مزامنة كافة الديون غير المرتبطة مع العملاء والموردين دفعة واحدة (محسن)
  Future<void> syncAllAnonymousDebts() async {
    final db = await database;
    await db.transaction((txn) async {
      // جلب الأسماء الفريدة التي لديها ديون غير مرتبطة
      final anonDebts = await txn.rawQuery('''
        SELECT DISTINCT person_name, type 
        FROM debts 
        WHERE (customer_id IS NULL AND supplier_id IS NULL) 
        AND status != 'paid'
      ''');

      for (final row in anonDebts) {
        final name = row['person_name'] as String;
        final type = row['type'] as String;

        if (type == 'receivable') {
          final customer = await txn.query('customers', where: 'name = ?', whereArgs: [name], limit: 1);
          if (customer.isNotEmpty) {
            final customerId = customer.first['id'] as int;
            final debts = await txn.query('debts', 
              where: 'type = ? AND person_name = ? AND customer_id IS NULL AND status != ?',
              whereArgs: ['receivable', name, 'paid']
            );

            double totalRemaining = 0.0;
            for (final d in debts) {
              totalRemaining += (d['amount'] as double) - (d['paid_amount'] as double);
              await txn.update('debts', {'customer_id': customerId}, where: 'id = ?', whereArgs: [d['id']]);
            }
            if (totalRemaining > 0) {
              await txn.rawUpdate('UPDATE customers SET current_balance = current_balance + ? WHERE id = ?', [totalRemaining, customerId]);
            }
          }
        } else if (type == 'payable') {
          final supplier = await txn.query('suppliers', where: 'name = ?', whereArgs: [name], limit: 1);
          if (supplier.isNotEmpty) {
            final supplierId = supplier.first['id'] as int;
            final debts = await txn.query('debts', 
              where: 'type = ? AND person_name = ? AND supplier_id IS NULL AND status != ?',
              whereArgs: ['payable', name, 'paid']
            );

            double totalRemaining = 0.0;
            for (final d in debts) {
              totalRemaining += (d['amount'] as double) - (d['paid_amount'] as double);
              await txn.update('debts', {'supplier_id': supplierId}, where: 'id = ?', whereArgs: [d['id']]);
            }
            if (totalRemaining > 0) {
              await txn.rawUpdate('UPDATE suppliers SET current_balance = current_balance + ? WHERE id = ?', [totalRemaining, supplierId]);
            }
          }
        }
      }
    });
  }

  Future<int> deleteDebt(int id) async {
    final db = await database;
    int result = 0;
    await db.transaction((txn) async {
      final rows = await txn.query('debts', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final debt = rows.first;
        final remaining = (debt['amount'] as double) - (debt['paid_amount'] as double);

        // عكس الرصيد قبل الحذف
        if (remaining != 0) {
          if (debt['type'] == 'receivable' && debt['customer_id'] != null) {
            await txn.rawUpdate('UPDATE customers SET current_balance = current_balance - ? WHERE id = ?', [remaining, debt['customer_id']]);
          } else if (debt['type'] == 'payable' && debt['supplier_id'] != null) {
            await txn.rawUpdate('UPDATE suppliers SET current_balance = current_balance - ? WHERE id = ?', [remaining, debt['supplier_id']]);
          }
        }
        
        // حذف المدفوعات المرتبطة أيضاً يدوياً لضمان الدقة (رغم وجود ON DELETE CASCADE)
        await txn.delete('debt_payments', where: 'debt_id = ?', whereArgs: [id]);
        result = await txn.delete('debts', where: 'id = ?', whereArgs: [id]);
      }
    });
    return result;
  }

  Future<void> deleteDebtPayment(int paymentId) async {
    final db = await database;
    await db.transaction((txn) async {
      final pRows = await txn.query('debt_payments', where: 'id = ?', whereArgs: [paymentId]);
      if (pRows.isEmpty) return;
      final payment = pRows.first;
      final amount = payment['amount'] as double;
      final debtId = payment['debt_id'] as int;

      final dRows = await txn.query('debts', where: 'id = ?', whereArgs: [debtId]);
      if (dRows.isEmpty) return;
      final debt = dRows.first;

      // 1. تحديث مبلغ الدين المدفوع
      final newPaid = (debt['paid_amount'] as double) - amount;
      final status = newPaid <= 0 ? 'pending' : 'partial';
      await txn.update('debts', {
        'paid_amount': newPaid,
        'status': status,
        'updated_at': DateTime.now().toIso8601String()
      }, where: 'id = ?', whereArgs: [debtId]);

      // 2. تحديث رصيد الشخص (إعادة المبلغ المستقطع للرصيد)
      if (debt['type'] == 'receivable' && debt['customer_id'] != null) {
        await txn.rawUpdate('UPDATE customers SET current_balance = current_balance + ? WHERE id = ?', [amount, debt['customer_id']]);
      } else if (debt['type'] == 'payable' && debt['supplier_id'] != null) {
        await txn.rawUpdate('UPDATE suppliers SET current_balance = current_balance + ? WHERE id = ?', [amount, debt['supplier_id']]);
      }

      // 3. حذف حركة الصندوق المرتبطة
      await txn.delete('cash_transactions', where: 'reference_type = ? AND reference_id = ?', whereArgs: ['debt_payment', paymentId]);

      // 4. حذف السجل
      await txn.delete('debt_payments', where: 'id = ?', whereArgs: [paymentId]);
    });
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
    
    // 1. المبيعات
    final salesResult = await db.rawQuery('''
      SELECT COALESCE(SUM(total_amount),0) as total, COUNT(*) as count
      FROM sales WHERE created_at LIKE '$date%' AND status = 'completed'
    ''');
    
    // 2. المصروفات
    final expResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount),0) as total FROM expenses WHERE created_at LIKE '$date%'
    ''');
    
    // 3. المرتجعات
    final returnResult = await db.rawQuery('''
      SELECT COALESCE(SUM(total_amount),0) as total FROM returns WHERE created_at LIKE '$date%'
    ''');

    // 4. ربح المبيعات (المباع - تكلفته)
    final profitResult = await db.rawQuery('''
      SELECT COALESCE(SUM((si.sell_price - si.buy_price) * si.quantity),0) as profit
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      WHERE s.created_at LIKE '$date%' AND s.status = 'completed'
    ''');

    // 5. ربح المرتجعات (الربح الذي تم استرجاعه/خسارته)
    final returnProfitResult = await db.rawQuery('''
      SELECT COALESCE(SUM((ri.price - p.buy_price) * ri.quantity),0) as profit
      FROM return_items ri
      JOIN products p ON p.id = ri.product_id
      JOIN returns r ON r.id = ri.return_id
      WHERE r.created_at LIKE '$date%'
    ''');

    final sales        = (salesResult.first['total']        as num?)?.toDouble() ?? 0;
    final expenses     = (expResult.first['total']          as num?)?.toDouble() ?? 0;
    final returns      = (returnResult.first['total']       as num?)?.toDouble() ?? 0;
    final grossProfit  = (profitResult.first['profit']      as num?)?.toDouble() ?? 0;
    final returnProfit = (returnProfitResult.first['profit'] as num?)?.toDouble() ?? 0;

    final netSales = sales - returns;
    final actualGrossProfit = grossProfit - returnProfit;

    return {
      'sales':        netSales,
      'expenses':     expenses,
      'returns':      returns,
      'gross_profit': actualGrossProfit,
      'net_profit':   actualGrossProfit - expenses,
      'count': (salesResult.first['count'] as num?)?.toDouble() ?? 0,
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
  // RETURNS
  // ─────────────────────────────────────────────
  Future<int> processReturn({
    required int saleId,
    required String saleNumber,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String paymentMethod,
    String? notes,
  }) async {
    final db = await database;
    int returnId = 0;

    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      // 1. إدراج رأس المرتجع
      returnId = await txn.insert('returns', {
        'sale_id': saleId,
        'sale_number': saleNumber,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'notes': notes,
        'created_at': now,
      });

      // 2. إدراج الأصناف المرتجعة وتحديث المخزون
      for (final item in items) {
        await txn.insert('return_items', {
          'return_id': returnId,
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'quantity': item['quantity'],
          'price': item['price'],
          'total': item['total'],
        });

        // زيادة المخزون مجدداً
        await txn.rawUpdate('''
          UPDATE products SET quantity = quantity + ?, updated_at = ?
          WHERE id = ?
        ''', [item['quantity'], now, item['product_id']]);

        // سجل حركة المخزون
        await txn.insert('stock_movements', {
          'product_id': item['product_id'],
          'type': 'return',
          'quantity': item['quantity'],
          'reference_id': returnId,
          'notes': 'مرتجع مبيعات - فاتورة #$saleNumber',
          'created_at': now,
        });
      }

      // 3. سجل الحركة المالية بناءً على طريقة الدفع الأصلية
      if (paymentMethod == 'cash') {
        // فاتورة نقدية → نُرجع النقود من الصندوق
        await txn.insert('cash_transactions', {
          'type': 'out',
          'amount': totalAmount,
          'reference_type': 'return',
          'reference_id': returnId,
          'notes': 'إرجاع مبلغ فاتورة #$saleNumber',
          'created_at': now,
        });
      } else if (paymentMethod == 'debt') {
        // فاتورة آجل → نُخفِّض رصيد العميل المدين
        // جلب معرف العميل من الفاتورة الأصلية
        final saleRows = await txn.query('sales',
            where: 'id = ?', whereArgs: [saleId], limit: 1);
        if (saleRows.isNotEmpty) {
          final customerId = saleRows.first['customer_id'];
          if (customerId != null) {
            // تخفيض رصيد العميل بقدر المرتجع
            await txn.rawUpdate('''
              UPDATE customers
              SET current_balance = MAX(0, current_balance - ?),
                  updated_at = ?
              WHERE id = ?
            ''', [totalAmount, now, customerId]);

            // تخفيض مبلغ الدين المرتبط بنفس القدر
            // نطبّق على أحدث دين معلّق لهذا العميل
            final debtRows = await txn.query('debts',
                where: 'customer_id = ? AND type = ? AND status != ?',
                whereArgs: [customerId, 'receivable', 'paid'],
                orderBy: 'created_at DESC',
                limit: 1);
            if (debtRows.isNotEmpty) {
              final debt = debtRows.first;
              final debtId  = debt['id'] as int;
              final oldAmt  = (debt['amount']  as num).toDouble();
              final oldPaid = (debt['paid_amount'] as num).toDouble();
              final newAmt  = (oldAmt - totalAmount).clamp(0.0, double.infinity);
              final newStatus = newAmt <= oldPaid ? 'paid' : (oldPaid > 0 ? 'partial' : 'pending');
              await txn.update('debts', {
                'amount': newAmt,
                'status': newStatus,
                'updated_at': now,
              }, where: 'id = ?', whereArgs: [debtId]);
            }

            // تسجيل الحركة في الصندوق كتخفيض من الذمم المدينة
            await txn.insert('cash_transactions', {
              'type': 'in',
              'amount': totalAmount,
              'reference_type': 'return_debt',
              'reference_id': returnId,
              'notes': 'إرجاع بيع آجل - فاتورة #$saleNumber',
              'created_at': now,
            });
          }
        }
      }
    });

    return returnId;
  }

  Future<List<Map<String, dynamic>>> getReturns() async {
    final db = await database;
    return await db.query('returns', orderBy: 'created_at DESC');
  }

  // ─────────────────────────────────────────────
  // LOW STOCK PRODUCTS
  // ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM products
      WHERE is_active = 1
        AND quantity <= low_stock_alert
      ORDER BY quantity ASC
    ''');
  }

  Future<int> getLowStockCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as cnt FROM products
      WHERE is_active = 1 AND quantity <= low_stock_alert
    ''');
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ─────────────────────────────────────────────
  // EXPENSE CATEGORIES MANAGEMENT
  // ─────────────────────────────────────────────
  /// جلب التصنيفات من جدول expense_categories مرتبةً حسب sort_order
  Future<List<Map<String, dynamic>>> getExpenseCategoriesFull() async {
    final db = await database;
    return await db.query('expense_categories', orderBy: 'sort_order ASC, name ASC');
  }

  Future<List<String>> getExpenseCategories() async {
    final rows = await getExpenseCategoriesFull();
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<int> addExpenseCategory(String name) async {
    final db = await database;
    return await db.insert('expense_categories', {
      'name': name.trim(),
      'is_default': 0,
      'sort_order': 99,
    });
  }

  Future<void> renameExpenseCategory(String oldName, String newName) async {
    final db = await database;
    // تحديث الاسم في جدول التصنيفات
    await db.update('expense_categories', {'name': newName.trim()},
        where: 'name = ?', whereArgs: [oldName]);
    // تحديث كل المصروفات القديمة
    await db.update('expenses', {'category': newName.trim()},
        where: 'category = ?', whereArgs: [oldName]);
  }

  Future<int> deleteExpenseCategory(String name) async {
    final db = await database;
    return await db.delete('expense_categories',
        where: 'name = ? AND is_default = 0', whereArgs: [name]);
  }

  Future<Map<String, double>> getExpenseSummaryByCategory({String? dateFilter}) async {
    final db = await database;
    String where = '';
    if (dateFilter != null) where = "WHERE created_at LIKE '$dateFilter%'";
    final rows = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses
      $where
      GROUP BY category
      ORDER BY total DESC
    ''');
    return {for (var r in rows) r['category'] as String: (r['total'] as num).toDouble()};
  }


  // ─────────────────────────────────────────────
  // CASH SESSIONS (DAILY BOX)
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> getActiveCashSession() async {
    final db = await database;
    final rows = await db.query('cash_sessions', where: 'status = ?', whereArgs: ['open'], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> openCashSession(double openingBalance, String? notes) async {
    final db = await database;
    return await db.insert('cash_sessions', {
      'opening_balance': openingBalance,
      'status': 'open',
      'notes': notes,
      'opened_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> closeCashSession({
    required int sessionId,
    required double actualCash,
    String? notes,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    // 1. حساب الرصيد المتوقع بناءً على الحركات المالية منذ فتح الجلسة
    final session = await db.query('cash_sessions', where: 'id = ?', whereArgs: [sessionId]);
    if (session.isEmpty) return;
    
    final openTime = session.first['opened_at'] as String;
    final openBalance = session.first['opening_balance'] as double;

    // جلب صافي الحركات المالية (in - out)
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 'in' THEN amount ELSE 0 END) as total_in,
        SUM(CASE WHEN type = 'out' THEN amount ELSE 0 END) as total_out
      FROM cash_transactions 
      WHERE created_at >= ?
    ''', [openTime]);

    final totalIn  = (result.first['total_in'] as num?)?.toDouble() ?? 0.0;
    final totalOut = (result.first['total_out'] as num?)?.toDouble() ?? 0.0;
    
    final expectedBalance = openBalance + totalIn - totalOut;
    final difference = actualCash - expectedBalance;

    await db.update('cash_sessions', {
      'closing_balance': expectedBalance,
      'actual_cash': actualCash,
      'difference': difference,
      'status': 'closed',
      'notes': notes,
      'closed_at': now,
    }, where: 'id = ?', whereArgs: [sessionId]);
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

  Future<int> deleteProductUnits(int productId) async {
    final db = await database;
    return await db.delete('product_units', where: 'product_id = ?', whereArgs: [productId]);
  }
}
