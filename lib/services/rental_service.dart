import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/rental_model.dart';

class RentalService {
  final Dio _dio = DioClient.instance;

  Future<void> createRental(RentalModel rental) async {
    try {
      await _dio.post(
        ApiEndpoints.rental,
        data: {
          'equipmentId': rental.equipmentId,
          'startDate': rental.startDate,
          'endDate': rental.expectedReturnDate.isNotEmpty
              ? rental.expectedReturnDate
              : rental.endDate,
        },
      );
    } catch (_) {}
  }

  Future<RentalModel?> getRental(String id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.rental}/$id');
      if (response.data != null && response.data['success'] == true) {
        return RentalModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<void> updateRentalStatus(String rentalId, RentalStatus status) async {
    try {
      await _dio.patch(
        '${ApiEndpoints.rental}/$rentalId/status',
        data: {'status': status.name.toUpperCase()},
      );
    } catch (_) {}
  }

  Future<void> submitInspection({
    required String rentalId,
    required String equipmentId,
    required bool hasDamage,
    required String afterCondition,
    required String notes,
  }) async {
    try {
      final newStatus = hasDamage ? RentalStatus.DISPUTED : RentalStatus.COMPLETED;
      await updateRentalStatus(rentalId, newStatus);
    } catch (_) {}
  }

  Stream<List<RentalModel>> streamRentalsByNgo(String ngoId) async* {
    try {
      final response = await _dio.get(ApiEndpoints.rental);
      if (response.data != null && response.data['success'] == true) {
        final List rawList = response.data['data'] ?? [];
        yield rawList
            .map((json) => RentalModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        yield [];
      }
    } catch (_) {
      yield [];
    }
  }

  Future<List<RentalModel>> getRentalsByNgo(String ngoId) async {
    try {
      final response = await _dio.get(ApiEndpoints.rental);
      if (response.data != null && response.data['success'] == true) {
        final List rawList = response.data['data'] ?? [];
        return rawList
            .map((json) => RentalModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
