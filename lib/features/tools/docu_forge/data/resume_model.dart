class ResumeData {
  String fullName;
  String email;
  String phone;
  String linkedIn;
  String github;
  String summary;
  List<Map<String, String>> experience; // {title, company, dates, description}
  List<Map<String, String>> projects;   // {title, link, description}
  List<Map<String, String>> education;  // {degree, school, year}
  List<String> skills;

  ResumeData({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.linkedIn = '',
    this.github = '',
    this.summary = '',
    this.experience = const [],
    this.projects = const [],
    this.education = const [],
    this.skills = const [],
  });
}
