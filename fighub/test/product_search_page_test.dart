import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fighub/product_model.dart';
import 'package:fighub/product_search_page.dart';

Product _product(String name, String description) => Product(
      sellerId: 'seller-1',
      name: name,
      price: '250',
      category: 'Other',
      condition: 'New',
      description: description,
      paymentMethod: 'Cash on Delivery',
    );

void main() {
  testWidgets('search filters products without showing an error screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductSearchPage(
          products: [
            _product('Space Ranger Figure', 'Original sci-fi collectible'),
            _product('Wooden Desk Model', 'Handmade display piece'),
          ],
          onOpenProduct: (_) {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'space ranger');
    await tester.pumpAndSettle();

    expect(find.text('Space Ranger Figure'), findsOneWidget);
    expect(find.text('Wooden Desk Model'), findsNothing);
    expect(find.textContaining('مفيش منتجات مطابقة'), findsNothing);
  });

  testWidgets('unmatched search shows a safe empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductSearchPage(
          products: [_product('Space Ranger Figure', 'Original sci-fi collectible')],
          onOpenProduct: (_) {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'nothing matches');
    await tester.pumpAndSettle();

    expect(find.text('مفيش منتجات مطابقة. جرّب كلمة تانية.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
