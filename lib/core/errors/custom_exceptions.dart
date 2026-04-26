class OutOfStockException implements Exception {
  final String productName;
  
  OutOfStockException(this.productName);

  @override
  String toString() {
    return "الكمية غير متوفرة: $productName";
  }
}
