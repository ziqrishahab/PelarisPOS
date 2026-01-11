class PrinterSettings {
  final String id;
  final String? cabangId;
  final bool autoPrintEnabled;
  final String? printerName;
  final int paperWidth;
  final String storeName;
  final String? branchName;
  final String? address;
  final String? phone;
  final String? footerText1;
  final String? footerText2;

  PrinterSettings({
    required this.id,
    this.cabangId,
    this.autoPrintEnabled = true,
    this.printerName,
    this.paperWidth = 80,
    this.storeName = 'Pelaris.id',
    this.branchName,
    this.address,
    this.phone,
    this.footerText1,
    this.footerText2,
  });

  factory PrinterSettings.fromJson(Map<String, dynamic> json) {
    return PrinterSettings(
      id: json['id'] ?? '',
      cabangId: json['cabangId'],
      autoPrintEnabled: json['autoPrintEnabled'] ?? true,
      printerName: json['printerName'],
      paperWidth: json['paperWidth'] ?? 80,
      storeName: json['storeName'] ?? 'Pelaris.id',
      branchName: json['branchName'],
      address: json['address'],
      phone: json['phone'],
      footerText1: json['footerText1'],
      footerText2: json['footerText2'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cabangId': cabangId,
      'autoPrintEnabled': autoPrintEnabled,
      'printerName': printerName,
      'paperWidth': paperWidth,
      'storeName': storeName,
      'branchName': branchName,
      'address': address,
      'phone': phone,
      'footerText1': footerText1,
      'footerText2': footerText2,
    };
  }

  // Default settings
  static PrinterSettings defaultSettings() {
    return PrinterSettings(
      id: '',
      storeName: 'Pelaris.id',
      paperWidth: 80,
      autoPrintEnabled: true,
    );
  }
}
