import 'package:mohassib/core/database/database_helper.dart';
import 'package:mohassib/features/products/models/product_model.dart';
import 'package:mohassib/features/products/models/product_unit_model.dart';

class ProductRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<ProductModel>> getAll() async {
    final rows = await _db.getAllProducts();
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<List<ProductModel>> search(String query) async {
    final rows = await _db.searchProducts(query);
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<ProductModel?> getByBarcode(String barcode) async {
    final row = await _db.getProductByBarcode(barcode);
    return row != null ? ProductModel.fromMap(row) : null;
  }

  Future<int> insert(ProductModel p) => _db.insertProduct(p.toMap());

  Future<void> update(ProductModel p) => _db.updateProduct(p.id!, p.toMap());

  Future<int> insertWithUnits(ProductModel p, List<ProductUnitModel> units) async {
    final id = await _db.insertProduct(p.toMap());
    if (units.isNotEmpty) {
      await _db.insertProductUnits(id, units.map((u) => u.toMap()).toList());
    }
    return id;
  }

  Future<void> updateWithUnits(ProductModel p, List<ProductUnitModel> units) async {
    await _db.updateProduct(p.id!, p.toMap());
    await _db.deleteProductUnits(p.id!);
    if (units.isNotEmpty) {
      await _db.insertProductUnits(p.id!, units.map((u) => u.toMap()).toList());
    }
  }

  Future<void> delete(int id) => _db.softDeleteProduct(id);
}
