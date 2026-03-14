enum SolarmanExcelColumns {
  timeStamp("Updated Time"),
  gridPower("Total Grid Power(W)"),
  // gridDailyTotalPower("Total Energy Buy(kWh)"),
  gridDailyTotalPower("Total Energy Buy(kWh)"),
  solarPower("Total Solar Power(W)"),
  solarDailyPower("Daily Production (Active)(kWh)"),
  homePower("Total Inverter Output Power(W)"),
  homeDailyPower("Total Inverter Output Power(W)"),
  bmsSoc("SoC(%)"),
  bmsDailyDischarge("Total Discharging Energy(kWh)"),
  bmsDailyCharge("Total Charging Energy(kWh)");

  //   static const String time = "Updated Time";
  // static const String gridPower = "Total Grid Power(W)";
  // // static const String gridDailyDayPower;
  // // static const String gridDailyNightPower;
  // static const String gridDailyTotalPower = "Daily Energy Buy(kWh)"; // Daily Energy
  // static const String solarPower = "Total Solar Power(W)";
  // static const String solarDailyPower = "Daily Production (Active)(kWh)"; // Solar
  // static const String homePower = "Total Inverter Output Power(W)";
  // static const String homeDailyPower = "Total Inverter Output Power(W)";
  // static const String bmsSoc = "SoC(%)"; // int
  // static const String bmsDailyDischarge = "Total Discharging Energy(kWh)";
  // static const String bmsDailyCharge = "Total Charging Energy(kWh)";

  final String label;
  const SolarmanExcelColumns(this.label);
}