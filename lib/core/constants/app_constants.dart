enum UserRole { admin, member }

extension UserRoleLabel on UserRole {
  String get label => this == UserRole.admin ? 'Admin' : 'Member';
}

const mealCategories = ['breakfast', 'lunch', 'dinner'];
const expenseCategories = ['bazar', 'gas', 'electricity', 'internet', 'misc'];
