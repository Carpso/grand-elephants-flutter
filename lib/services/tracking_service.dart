class TrackingStep {
  final String id;
  final String label;
  final String description;
  final String timestamp;
  final bool completed;
  final String status;
  final String? location;

  const TrackingStep({
    required this.id,
    required this.label,
    required this.description,
    required this.timestamp,
    required this.completed,
    required this.status,
    this.location,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'description': description,
        'timestamp': timestamp,
        'completed': completed,
        'status': status,
        'location': location,
      };

  factory TrackingStep.fromJson(Map<String, dynamic> json) => TrackingStep(
        id: json['id'] as String,
        label: json['label'] as String,
        description: json['description'] as String,
        timestamp: json['timestamp'] as String,
        completed: json['completed'] as bool,
        status: json['status'] as String,
        location: json['location'] as String?,
      );
}

class TrackingService {
  static Future<List<TrackingStep>> getTrackingHistory(
      String orderId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      const TrackingStep(
        id: '1',
        label: 'Order Confirmed',
        description: 'Your order has been received and confirmed',
        timestamp: 'Today, 9:00 AM',
        completed: true,
        status: 'Confirmed',
      ),
      const TrackingStep(
        id: '2',
        label: 'Processing',
        description: 'Your order is being prepared',
        timestamp: 'Today, 10:30 AM',
        completed: true,
        status: 'Processing',
      ),
      TrackingStep(
        id: '3',
        label: 'Out for Delivery',
        description: 'Your order is on the way',
        timestamp: 'Today, 12:00 PM',
        completed: true,
        status: 'Out for Delivery',
        location: 'Main Street Warehouse',
      ),
      const TrackingStep(
        id: '4',
        label: 'Delivered',
        description: 'Your order has been delivered',
        timestamp: 'Pending',
        completed: false,
        status: 'Pending',
      ),
    ];
  }
}
