import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:seeds/constants/app_colors.dart';
import 'package:seeds/models/models.dart';
import 'package:seeds/providers/services/eos_service.dart';
import 'package:seeds/providers/services/navigation_service.dart';
import 'package:seeds/utils/extensions/SafeHive.dart';
import 'package:seeds/widgets/main_button.dart';
import 'package:seeds/widgets/main_text_field.dart';
import 'package:seeds/i18n/wallet.i18n.dart';
import 'package:seeds/utils/double_extension.dart';
import 'package:path/path.dart';

class Receive extends StatefulWidget {
  Receive({Key key}) : super(key: key);

  @override
  _ReceiveState createState() => _ReceiveState();
}

class _ReceiveState extends State<Receive> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          EosService.of(context).accountName ?? '',
          style: TextStyle(color: Colors.black87),
        ),
      ),
      backgroundColor: Colors.white,
      body: Container(
        margin: EdgeInsets.only(left: 15, right: 15),
        child: ReceiveForm(),
      ),
    );
  }
}

class ProductsCatalog extends StatefulWidget {
  final Function onTap;
  ProductsCatalog(this.onTap);

  @override
  _ProductsCatalogState createState() => _ProductsCatalogState();
}

class _ProductsCatalogState extends State<ProductsCatalog> {
  Box<ProductModel> box;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  PersistentBottomSheetController bottomSheetController;

  List<ProductModel> products = List();

  String localImagePath = '';

  @override
  void initState() {
    loadProducts();

    super.initState();
  }

  void loadProducts() async {
    box = await SafeHive.safeOpenBox<ProductModel>("products");

    setState(() {
      products.addAll(box.values);
    });

    box.watch().listen((event) {
      setState(() {
        products.clear();
        products.addAll(box.values);
      });
    });
  }

  void chooseProductPicture() async {
    final PickedFile image =
        await ImagePicker().getImage(source: ImageSource.gallery);

    if (image == null) return;

    File localImage = File(image.path);

    final String path = (await getApplicationDocumentsDirectory()).path;
    final fileName = basename(image.path);
    final fileExtension = extension(image.path);

    localImage = await localImage.copy("$path/$fileName$fileExtension");

    setState(() {
      localImagePath = localImage.path;
    });

    bottomSheetController.setState(() {});
  }

  void createNewProduct() {
    if (products.indexWhere((element) => element.name == nameController.text) !=
        -1) return;

    final product = ProductModel(
      name: nameController.text,
      price: NumberParser.parseInput(priceController.text),
      picture: localImagePath,
    );

    box.add(product);
  }

  void editProduct(int index) {
    final product = ProductModel(
      name: nameController.text,
      price: NumberParser.parseInput(priceController.text),
      picture: localImagePath,
    );

    box.putAt(index, product);
  }

  void deleteProduct(int index) {
    box.deleteAt(index);
  }

  Future<void> showDeleteProduct(BuildContext context, int index) {
    final product = products[index];

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete ${product.name} ?"),
          actions: [
            FlatButton(
              child: Text("Approve"),
              onPressed: () {
                deleteProduct(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildPictureWidget() {
    return Container(
        height: 40,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: localImagePath.isNotEmpty
                ? [
                    CircleAvatar(
                      backgroundImage: FileImage(File(localImagePath)),
                      radius: 20,
                    ),
                    SizedBox(width: 10),
                    Text("Change Picture"),
                  ]
                : [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.add,
                        color: Colors.black,
                        size: 15,
                      ),
                      radius: 15,
                    ),
                    Text("Add Picture"),
                  ]));
  }

  void showEditProduct(BuildContext context, int index) {
    nameController.text = products[index].name;
    priceController.text = products[index].price.toString();

    bottomSheetController = Scaffold.of(context).showBottomSheet(
      (context) => Container(
        padding: EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 15,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              blurRadius: 8,
              color: AppColors.blue,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Wrap(
          runSpacing: 10.0,
          children: <Widget>[
            DottedBorder(
              color: AppColors.grey,
              strokeWidth: 1,
              child: GestureDetector(
                onTap: chooseProductPicture,
                child: buildPictureWidget(),
              ),
            ),
            MainTextField(
              labelText: 'Name',
              controller: nameController,
            ),
            MainTextField(
              labelText: 'Price',
              controller: priceController,
              endText: 'SEEDS',
              keyboardType:
                  TextInputType.numberWithOptions(signed: false, decimal: true),
            ),
            MainButton(
              title: 'Edit Product',
              onPressed: () {
                editProduct(index);
                bottomSheetController.close();
                bottomSheetController = null;
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );

    setState(() {});
  }

  void showNewProduct(BuildContext context) {
    nameController.clear();
    priceController.clear();
    localImagePath = "";

    bottomSheetController = Scaffold.of(context).showBottomSheet(
      (context) => Container(
        padding: EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 15,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              blurRadius: 8,
              color: AppColors.blue,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Wrap(
          runSpacing: 10.0,
          children: <Widget>[
            DottedBorder(
              color: AppColors.grey,
              strokeWidth: 1,
              child: GestureDetector(
                onTap: chooseProductPicture,
                child: buildPictureWidget(),
              ),
            ),
            MainTextField(
              labelText: 'Name',
              controller: nameController,
            ),
            MainTextField(
              labelText: 'Price',
              controller: priceController,
              endText: 'SEEDS',
              keyboardType:
                  TextInputType.numberWithOptions(signed: false, decimal: true),
            ),
            MainButton(
              title: 'Add Product',
              onPressed: () {
                createNewProduct();
                bottomSheetController.close();
                bottomSheetController = null;
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Your Products'.i18n,
          style: TextStyle(color: Colors.black87),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) => bottomSheetController == null
            ? FloatingActionButton(
                backgroundColor: AppColors.blue,
                onPressed: () => showNewProduct(context),
                child: Icon(Icons.add),
              )
            : FloatingActionButton(
                backgroundColor: AppColors.blue,
                onPressed: () {
                  bottomSheetController.close();
                  bottomSheetController = null;
                  setState(() {});
                },
                child: Icon(Icons.close),
              ),
      ),
      body: ListView.builder(
        shrinkWrap: true,
        itemCount: products.length,
        itemBuilder: (ctx, index) => ListTile(
          leading: CircleAvatar(
            backgroundImage: products[index].picture.isNotEmpty
                ? FileImage(File(products[index].picture))
                : null,
            child: products[index].picture.isEmpty
                ? Container(
                    color: AppColors.getColorByString(products[index].name),
                    child: Center(
                      child: Text(
                        products[index].name.characters.first,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : null,
            radius: 20,
          ),
          title: Material(
            child: Text(
              products[index].name,
              style: TextStyle(
                  fontFamily: "worksans", fontWeight: FontWeight.w500),
            ),
          ),
          subtitle: Material(
            child: Text(
              products[index].price.seedsFormatted + " SEEDS",
              style: TextStyle(
                  fontFamily: "worksans", fontWeight: FontWeight.w400),
            ),
          ),
          trailing: Builder(
            builder: (context) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    showEditProduct(context, index);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    showDeleteProduct(context, index);
                  },
                ),
              ],
            ),
          ),
          onTap: () {
            widget.onTap(products[index]);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

class ReceiveForm extends StatefulWidget {
  @override
  _ReceiveFormState createState() => _ReceiveFormState();
}

class _ReceiveFormState extends State<ReceiveForm> {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController(text: '');
  String invoiceAmount = '0.00 SEEDS';
  double invoiceAmountDouble = 0;

  List<ProductModel> cart = List();
  Map<String, int> cartQuantity = Map();

  void changeTotalPrice(double amount) {
    invoiceAmountDouble += amount;
    invoiceAmount = invoiceAmountDouble.toString();
    controller.text = invoiceAmount;
  }

  void removeProductFromCart(ProductModel product) {
    setState(() {
      cartQuantity[product.name]--;

      if (cartQuantity[product.name] == 0) {
        cart.removeWhere((element) => element.name == product.name);
        cartQuantity[product.name] = null;
      }

      changeTotalPrice(-product.price);
    });
  }

  void removePriceDifference() {
    final difference = donationOrDiscountAmount();

    setState(() {
      changeTotalPrice(difference);
    });
  }

  void addProductToCart(ProductModel product) {
    setState(() {
      if (cartQuantity[product.name] == null) {
        cart.add(product);
        cartQuantity[product.name] = 1;
      } else {
        cartQuantity[product.name]++;
      }

      changeTotalPrice(product.price);
    });
  }

  void showMerchantCatalog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductsCatalog(addProductToCart),
        maintainState: true,
        fullscreenDialog: true,
      ),
    );
  }

  void generateInvoice(String amount) async {
    double receiveAmount = NumberParser.parseInput(amount) ?? 0;

    setState(() {
      invoiceAmountDouble = receiveAmount;
      invoiceAmount = receiveAmount.toStringAsFixed(4);
    });
  }

  double donationOrDiscountAmount() {
    final cartTotalPrice = cart
        .map((product) => product.price * cartQuantity[product.name])
        .reduce((value, element) => value + element);

    final difference = cartTotalPrice - invoiceAmountDouble;

    return difference;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          children: <Widget>[
            MainTextField(
              suffixIcon: IconButton(
                icon: Icon(Icons.add_shopping_cart, color: AppColors.blue),
                onPressed: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  showMerchantCatalog(context);
                },
              ),
              keyboardType:
                  TextInputType.numberWithOptions(signed: false, decimal: true),
              controller: controller,
              labelText: 'Receive (SEEDS)'.i18n,
              autofocus: true,
              validator: (String amount) {
                String error;

                double receiveAmount = NumberParser.parseInput(amount);

                if (amount == null || amount.isEmpty) {
                  error = null;
                } else if (receiveAmount == 0.0) {
                  error = "Amount cannot be 0.".i18n;
                } else if (receiveAmount < 0.0001) {
                  error = "Amount must be > 0.0001".i18n;
                } else if (receiveAmount == null) {
                  error = "Receive amount is not valid".i18n;
                }

                return error;
              },
              onChanged: (String amount) {
                if (formKey.currentState.validate()) {
                  generateInvoice(amount);
                } else {
                  setState(() {
                    invoiceAmountDouble = 0;
                  });
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 33, 0, 0),
              child: MainButton(
                  title: "Next".i18n,
                  active: invoiceAmountDouble != 0,
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    NavigationService.of(context)
                        .navigateTo(Routes.receiveQR, invoiceAmountDouble);
                  }),
            ),
            cart.length > 0 ? buildCart() : Container(),
          ],
        ),
      ),
    );
  }

  Widget buildCart() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: GridView(
        physics: ScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200.0,
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
        ),
        shrinkWrap: true,
        children: [
          ...cart
              .map(
                (product) => GridTile(
                  header: Container(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        product.picture.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage:
                                    FileImage(File(product.picture)),
                                radius: 20,
                              )
                            : Container(),
                        Row(
                          children: [
                            Text(
                              product.price.toString(),
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Image.asset(
                              'assets/images/seeds.png',
                              height: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.getColorByString(product.name),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          blurRadius: 15,
                          color: AppColors.getColorByString(product.name),
                          offset: Offset(6, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        product.name.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  footer: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: FlatButton(
                          padding: EdgeInsets.zero,
                          color: AppColors.red,
                          child: Icon(
                            Icons.remove,
                            size: 21,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            removeProductFromCart(product);
                          },
                        ),
                      ),
                      Text(
                        cartQuantity[product.name].toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: FlatButton(
                          padding: EdgeInsets.zero,
                          color: AppColors.green,
                          child: Icon(
                            Icons.add,
                            size: 21,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            addProductToCart(product);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          buildDonationOrDiscountItem(),
        ],
      ),
    );
  }

  Widget buildDonationOrDiscountItem() {
    double difference = donationOrDiscountAmount();

    if (difference == 0) {
      return Container();
    } else {
      final name = difference > 0 ? "Discount" : "Donation";
      final price = difference.abs();

      return GridTile(
        header: Container(
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.blue,
                child: Icon(difference > 0 ? Icons.remove : Icons.add,
                    color: Colors.white),
                radius: 20,
              ),
              Row(
                children: [
                  Text(
                    price.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Image.asset(
                    'assets/images/seeds.png',
                    height: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.getColorByString(name),
            boxShadow: <BoxShadow>[
              BoxShadow(
                blurRadius: 15,
                color: AppColors.getColorByString(name),
                offset: Offset(6, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: FlatButton(
                padding: EdgeInsets.zero,
                color: AppColors.blue,
                child: Icon(
                  Icons.cancel_outlined,
                  size: 21,
                  color: Colors.white,
                ),
                onPressed: removePriceDifference,
              ),
            ),
          ],
        ),
      );
    }
  }
}
