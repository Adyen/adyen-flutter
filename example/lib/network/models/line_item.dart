class LineItem {
  int? quantity;
  int? amountExcludingTax;
  int? taxPercentage;
  String? description;
  String? id;
  int? taxAmount;
  int? amountIncludingTax;
  String? productUrl;
  String? imageUrl;

  LineItem({
    this.quantity,
    this.amountExcludingTax,
    this.taxPercentage,
    this.description,
    this.id,
    this.taxAmount,
    this.amountIncludingTax,
    this.productUrl,
    this.imageUrl,
  });

  LineItem.fromJson(Map<String, dynamic> json) {
    quantity = json['quantity'];
    amountExcludingTax = json['amountExcludingTax'];
    taxPercentage = json['taxPercentage'];
    description = json['description'];
    id = json['id'];
    taxAmount = json['taxAmount'];
    amountIncludingTax = json['amountIncludingTax'];
    productUrl = json['productUrl'];
    imageUrl = json['imageUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['quantity'] = quantity;
    data['amountExcludingTax'] = amountExcludingTax;
    data['taxPercentage'] = taxPercentage;
    data['description'] = description;
    data['id'] = id;
    data['taxAmount'] = taxAmount;
    data['amountIncludingTax'] = amountIncludingTax;
    data['productUrl'] = productUrl;
    data['imageUrl'] = imageUrl;
    return data;
  }
}
