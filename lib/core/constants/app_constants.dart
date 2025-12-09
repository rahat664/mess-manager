enum UserRole { admin, member }

extension UserRoleLabel on UserRole {
  String get label => this == UserRole.admin ? 'Admin' : 'Member';
}

const mealCategories = ['breakfast', 'lunch', 'dinner'];
const expenseCategories = ['bazar', 'gas', 'electricity', 'internet', 'misc'];

// Notification constants
const notificationChannelId = 'mess_notifications';
const notificationChannelName = 'Mess Notifications';
const notificationChannelDescription = 'Notifications for mess activities';
