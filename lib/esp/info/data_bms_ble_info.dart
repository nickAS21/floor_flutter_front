class DataBmsBleInfo {
  String mac;
  String name;

  DataBmsBleInfo({
    this.mac = '',
    this.name = '',
  });

  factory DataBmsBleInfo.fromJson(Map<String, dynamic> json) {
    return DataBmsBleInfo(
      mac: json['mac'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'mac': mac,
    'name': name,
  };
}