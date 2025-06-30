# Ingetin

A simple app to Remind your daily task.

## Features
- You can add a new Reminder, set it's name and the time 
- Get Local Notification 10 minutes before the set time
- List of current active and completed reminders
- 

## Compilation
this project is compiled using Xcode 16.2 with iOS 16 as minimum target

### Built with
- **SwiftUI**
- **MVVM+Coordinator** View-View-ViewModel-Coordinator
- **Combine** for subscribing CoreData changes, search input debouncing 
- **Factory** for Dependencies Injection
- **CoreData** for managing local ReminderItem data
