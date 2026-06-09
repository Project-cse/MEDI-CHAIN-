class SlotModel {
  final String time;
  final String displayTime;
  final bool available;
  final int? slotId;
  final String? slotType;

  const SlotModel({
    required this.time,
    required this.displayTime,
    this.available = true,
    this.slotId,
    this.slotType,
  });
}

class DaySlotsModel {
  final String date;
  final String displayDate;
  final List<SlotModel> slots;

  const DaySlotsModel({
    required this.date,
    required this.displayDate,
    required this.slots,
  });
}
