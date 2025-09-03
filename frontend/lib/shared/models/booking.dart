// Booking domain models used across the app and BookingService

class Schedule {
	final String date; // yyyy-MM-dd
	final String startTime; // HH:mm
	final String endTime; // HH:mm
	final int? duration; // minutes (optional)
	final String? timezone;

	Schedule({
		required this.date,
		required this.startTime,
		required this.endTime,
		this.duration,
		this.timezone,
	});

	factory Schedule.fromJson(Map<String, dynamic> json) {
		return Schedule(
			date: (json['date'] ?? '').toString(),
			startTime: (json['startTime'] ?? json['start'] ?? '').toString(),
			endTime: (json['endTime'] ?? json['end'] ?? '').toString(),
			duration: json['duration'] is int
					? json['duration'] as int
					: (json['duration'] is String
							? int.tryParse(json['duration'] as String)
							: null),
			timezone: (json['timezone'] ?? json['tz'])?.toString(),
		);
	}

	Map<String, dynamic> toJson() => {
				'date': date,
				'startTime': startTime,
				'endTime': endTime,
				if (duration != null) 'duration': duration,
				if (timezone != null) 'timezone': timezone,
			};
}

class Coordinates {
	final double latitude;
	final double longitude;

	Coordinates({required this.latitude, required this.longitude});

	factory Coordinates.fromJson(Map<String, dynamic> json) {
		// Support various shapes: {latitude, longitude} or {lat, lng}
		final lat = (json['latitude'] ?? json['lat']);
		final lng = (json['longitude'] ?? json['lng']);
		return Coordinates(
			latitude: lat is num ? lat.toDouble() : double.tryParse(lat?.toString() ?? '0') ?? 0,
			longitude: lng is num ? lng.toDouble() : double.tryParse(lng?.toString() ?? '0') ?? 0,
		);
	}

	Map<String, dynamic> toJson() => {
				'latitude': latitude,
				'longitude': longitude,
			};
}

class Location {
	final String address;
	final Coordinates? coordinates;
	final String? instructions;

	Location({
		required this.address,
		this.coordinates,
		this.instructions,
	});

	factory Location.fromJson(Map<String, dynamic> json) {
		return Location(
			address: (json['address'] ?? '').toString(),
			coordinates: json['coordinates'] is Map<String, dynamic>
					? Coordinates.fromJson(json['coordinates'] as Map<String, dynamic>)
					: null,
			instructions: (json['instructions'])?.toString(),
		);
	}

	Map<String, dynamic> toJson() => {
				'address': address,
				if (coordinates != null) 'coordinates': coordinates!.toJson(),
				if (instructions != null) 'instructions': instructions,
			};
}

class Pricing {
	final double totalAmount;
	final String currency;
	final String? type; // hourly | fixed | daily

	Pricing({
		required this.totalAmount,
		required this.currency,
		this.type,
	});

	factory Pricing.fromJson(Map<String, dynamic> json) {
		final amountRaw = json['totalAmount'] ?? json['total'] ?? json['amount'] ?? 0;
		final amount = amountRaw is num ? amountRaw.toDouble() : double.tryParse(amountRaw.toString()) ?? 0.0;
		return Pricing(
			totalAmount: amount,
			currency: (json['currency'] ?? 'ILS').toString(),
			type: (json['type'])?.toString(),
		);
	}

	Map<String, dynamic> toJson() => {
				'totalAmount': totalAmount,
				'currency': currency,
				if (type != null) 'type': type,
			};
}

class PaymentInfo {
	final String status; // pending | paid | failed
	final String? method; // cash | credit_card | bank_transfer

	PaymentInfo({required this.status, this.method});

	factory PaymentInfo.fromJson(Map<String, dynamic> json) {
		return PaymentInfo(
			status: (json['status'] ?? 'pending').toString(),
			method: (json['method'])?.toString(),
		);
	}

	Map<String, dynamic> toJson() => {
				'status': status,
				if (method != null) 'method': method,
			};
}

class ServiceDetails {
	final String title;
	final String? category;
	final String? serviceId;

	ServiceDetails({required this.title, this.category, this.serviceId});

	factory ServiceDetails.fromJson(Map<String, dynamic> json) {
		return ServiceDetails(
			title: (json['title'] ?? json['name'] ?? 'Service').toString(),
			category: (json['category'])?.toString(),
			serviceId: (json['id'] ?? json['_id'] ?? json['serviceId'])?.toString(),
		);
	}

	Map<String, dynamic> toJson() => {
				'title': title,
				if (category != null) 'category': category,
				if (serviceId != null) 'id': serviceId,
			};
}

class BookingModel {
	final String id;
	final String? bookingId;
	final DateTime? createdAt;
	final ServiceDetails serviceDetails;
	final Schedule schedule;
	final Location location;
	final Pricing pricing;
	final String status;
	final PaymentInfo? payment;
	final String? notes;
	// Optional provider info (populated by backend list endpoint)
	final String? providerId;
	final String? providerName;
	// Optional client info (for admin/provider listings)
	final String? clientId;
	final String? clientName;
	final bool emergency;
	final List<CancellationRequest> cancellationRequests;

	BookingModel({
		required this.id,
		this.bookingId,
		this.createdAt,
		required this.serviceDetails,
		required this.schedule,
		required this.location,
		required this.pricing,
		required this.status,
		this.payment,
		this.notes,
		this.providerId,
		this.providerName,
		this.clientId,
			this.clientName,
			this.emergency = false,
		this.cancellationRequests = const [],
	});

	factory BookingModel.fromJson(Map<String, dynamic> json) {
		// Some APIs wrap details under 'service' or 'serviceDetails'
		final serviceJson = (json['serviceDetails'] ?? json['service'] ?? {}) as Map<String, dynamic>;
		final scheduleJson = (json['schedule'] ?? {}) as Map<String, dynamic>;
		final locationJson = (json['location'] ?? {}) as Map<String, dynamic>;
		final pricingJson = (json['pricing'] ?? json['price'] ?? {}) as Map<String, dynamic>;
		final paymentJson = (json['payment'] ?? {}) as Map<String, dynamic>;

		final idVal = json['_id'] ?? json['id'] ?? json['bookingId'] ?? '';

		return BookingModel(
			id: idVal.toString(),
			bookingId: (json['bookingId'])?.toString(),
		createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
			serviceDetails: ServiceDetails.fromJson(serviceJson),
			schedule: Schedule.fromJson(scheduleJson),
			location: Location.fromJson(locationJson),
			pricing: Pricing.fromJson(pricingJson),
			status: (json['status'] ?? 'pending').toString(),
			payment: paymentJson.isNotEmpty ? PaymentInfo.fromJson(paymentJson) : null,
			notes: (() {
				final n = json['notes'];
				if (n is Map<String, dynamic>) {
					return (n['clientNotes'] ?? n['note'] ?? n['notes'])?.toString();
				}
				return n?.toString();
			})(),
			providerId: (() {
				final p = json['provider'];
				if (p is Map<String, dynamic>) {
					return (p['_id'] ?? p['id'])?.toString();
				}
				if (p != null) return p.toString();
				return null;
			})(),
			providerName: (() {
				final p = json['provider'];
				if (p is Map<String, dynamic>) {
					final first = (p['firstName'] ?? '').toString();
					final last = (p['lastName'] ?? '').toString();
					final name = [first, last].where((e) => e.isNotEmpty).join(' ').trim();
					return name.isNotEmpty ? name : null;
				}
				return null;
			})(),
				clientId: (() {
					final c = json['client'];
					if (c is Map<String, dynamic>) {
						return (c['_id'] ?? c['id'])?.toString();
					}
					if (c != null) return c.toString();
					return null;
				})(),
				clientName: (() {
					final c = json['client'];
					if (c is Map<String, dynamic>) {
						final first = (c['firstName'] ?? '').toString();
						final last = (c['lastName'] ?? '').toString();
						final name = [first, last].where((e) => e.isNotEmpty).join(' ').trim();
						return name.isNotEmpty ? name : null;
					}
					return null;
				})(),
				emergency: (() {
					final e = json['emergency'] ?? json['isEmergency'] ?? false;
					if (e is bool) return e;
					if (e is String) return e.toLowerCase() == 'true';
					if (e is num) return e != 0;
					return false;
				})(),
				cancellationRequests: (() {
					final list = json['cancellationRequests'];
					if (list is List) {
						return list
							.map((e) => e is Map<String, dynamic> ? CancellationRequest.fromJson(e) : null)
							.whereType<CancellationRequest>()
							.toList();
					}
					return <CancellationRequest>[];
				})(),
		);
	}

	Map<String, dynamic> toJson() => {
				'_id': id,
				if (bookingId != null) 'bookingId': bookingId,
		if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
				'serviceDetails': serviceDetails.toJson(),
				'schedule': schedule.toJson(),
				'location': location.toJson(),
				'pricing': pricing.toJson(),
				'status': status,
				if (payment != null) 'payment': payment!.toJson(),
			if (notes != null) 'notes': notes,
	if (providerId != null) 'provider': providerId,
	if (clientId != null) 'client': clientId,
			};
}

class CancellationRequest {
	final String id;
	final String status; // pending | accepted | declined | expired
	final String? requestedByRole; // client | provider
	final String? requestedTo; // id
	final String? reason;
	final DateTime? requestedAt;

	CancellationRequest({
		required this.id,
		required this.status,
		this.requestedByRole,
		this.requestedTo,
		this.reason,
		this.requestedAt,
	});

	factory CancellationRequest.fromJson(Map<String, dynamic> json) {
		return CancellationRequest(
			id: (json['_id'] ?? json['id'] ?? '').toString(),
			status: (json['status'] ?? 'pending').toString(),
			requestedByRole: json['requestedByRole']?.toString(),
			requestedTo: (json['requestedTo'])?.toString(),
			reason: json['reason']?.toString(),
			requestedAt: json['requestedAt'] != null ? DateTime.tryParse(json['requestedAt'].toString()) : null,
		);
	}
}

class CreateBookingRequest {
	final String serviceId;
	final Schedule schedule;
	final Location location;
	final String? notes;
	final bool? emergency;

	CreateBookingRequest({
		required this.serviceId,
		required this.schedule,
		required this.location,
		this.notes,
		this.emergency,
	});

	Map<String, dynamic> toJson() => {
				'serviceId': serviceId,
				'schedule': schedule.toJson(),
				'location': location.toJson(),
				if (notes != null) 'notes': notes,
		if (emergency != null) 'emergency': emergency,
			};
}

class UpdateBookingStatusRequest {
	final String status;

	UpdateBookingStatusRequest({required this.status});

	Map<String, dynamic> toJson() => {
				'status': status,
			};
}

