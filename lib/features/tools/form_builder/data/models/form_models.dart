class FormFieldModel {
  final String label;
  final String fieldType;
  final bool isRequired;
  final List<String>? options;
  final int orderIndex;

  FormFieldModel({
    required this.label,
    required this.fieldType,
    this.isRequired = false,
    this.options,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'field_type': fieldType,
      'is_required': isRequired,
      'options': options,
      'order_index': orderIndex,
    };
  }

  factory FormFieldModel.fromJson(Map<String, dynamic> json) {
    return FormFieldModel(
      label: json['label'] ?? '',
      fieldType: json['field_type'] ?? 'text',
      isRequired: json['is_required'] ?? false,
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      orderIndex: json['order_index'] ?? 0,
    );
  }
}

class FormCreateModel {
  final String title;
  final String? description;
  final String? headerImageUrl;
  final String formType;
  final bool isPublished;
  final bool allowMultipleResponses;
  final List<FormFieldModel> fields;

  FormCreateModel({
    required this.title,
    this.description,
    this.headerImageUrl,
    this.formType = 'Survey',
    this.isPublished = true,
    this.allowMultipleResponses = true,
    required this.fields,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'header_image_url': headerImageUrl,
      'form_type': formType,
      'is_published': isPublished,
      'allow_multiple_responses': allowMultipleResponses,
      'fields': fields.map((f) => f.toJson()).toList(),
    };
  }
}

class FormResponseModel {
  final String id;
  final String title;
  final String formType;
  final int fieldsCount;

  FormResponseModel({
    required this.id,
    required this.title,
    required this.formType,
    required this.fieldsCount,
  });

  factory FormResponseModel.fromJson(Map<String, dynamic> json) {
    return FormResponseModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      formType: json['form_type'] ?? '',
      fieldsCount: json['fields_count'] ?? 0,
    );
  }
}

class FormDetailModel {
  final String id;
  final String title;
  final String? description;
  final String? headerImageUrl;
  final bool isPublished;
  final bool allowMultipleResponses;
  final List<FormFieldModel> fields;

  FormDetailModel({
    required this.id,
    required this.title,
    this.description,
    this.headerImageUrl,
    this.isPublished = true,
    this.allowMultipleResponses = true,
    required this.fields,
  });

  factory FormDetailModel.fromJson(Map<String, dynamic> json) {
    return FormDetailModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      headerImageUrl: json['header_image_url'],
      isPublished: json['is_published'] ?? true,
      allowMultipleResponses: json['allow_multiple_responses'] ?? true,
      fields: (json['fields'] as List?)?.map((f) => FormFieldModel.fromJson(f)).toList() ?? [],
    );
  }
}
