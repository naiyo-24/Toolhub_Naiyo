class OrganizationModel {
  final int id;
  final String name;
  final String? type;

  OrganizationModel({
    required this.id,
    required this.name,
    this.type,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }
}

class BankerProfileModel {
  final int id;
  final String userId;
  final int? organizationId;
  final String? employeeId;
  final String? designation;
  final OrganizationModel? organization;

  BankerProfileModel({
    required this.id,
    required this.userId,
    this.organizationId,
    this.employeeId,
    this.designation,
    this.organization,
  });

  factory BankerProfileModel.fromJson(Map<String, dynamic> json) {
    return BankerProfileModel(
      id: json['id'],
      userId: json['user_id'],
      organizationId: json['organization_id'],
      employeeId: json['employee_id'],
      designation: json['designation'],
      organization: json['organization'] != null 
          ? OrganizationModel.fromJson(json['organization']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'organization_id': organizationId,
      'employee_id': employeeId,
      'designation': designation,
      if (organization != null) 'organization': organization!.toJson(),
    };
  }
}
