import 'package:mohassib/core/database/database_helper.dart';
import 'package:mohassib/features/products/models/product_model.dart';

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

  Future<void> delete(int id) => _db.softDeleteProduct(id);
}
