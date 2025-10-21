# Implementation Plan

- [x] 1. Remove camera icon from chat AppBar



  - Locate and remove the camera IconButton from chat_view.dart AppBar actions
  - Test that the three-dots menu functionality remains intact
  - Verify that chat interface looks cleaner without the camera icon


  - _Requirements: 2.1, 2.2, 2.3_

- [ ] 2. Analyze current profile edit dialog structure
  - Examine existing _showEditProfileDialog method in chat_view.dart

  - Document current fields (username, name) and their implementation
  - Identify where to add new profile photo and wallpaper sections
  - _Requirements: 1.1, 3.1_

- [ ] 3. Add profile photo section to edit dialog
  - Create profile photo preview widget with current user photo


  - Add "Alterar Foto de Perfil" button below the preview

  - Implement _selectProfilePhoto method using existing photo selection logic
  - Add proper error handling for photo selection and upload
  - _Requirements: 1.2, 3.2, 4.4_




- [ ] 4. Add wallpaper section to edit dialog
  - Create wallpaper preview widget showing current chat wallpaper
  - Add "Alterar Papel de Parede" button below the preview
  - Implement _selectWallpaper method for wallpaper selection
  - Add proper error handling for wallpaper selection and upload
  - _Requirements: 1.3, 3.2, 4.4_


- [ ] 5. Implement immediate wallpaper application
  - Modify wallpaper selection to apply changes immediately to chat background
  - Ensure wallpaper changes are visible when user returns to chat
  - Add logic to maintain message readability with new wallpaper
  - Test wallpaper persistence across app restarts


  - _Requirements: 1.4, 4.1, 4.2, 4.3_

- [ ] 6. Reorganize dialog layout and styling
  - Arrange fields in specified order: Username, Nome, Foto de Perfil, Papel de Parede
  - Ensure proper spacing and visual hierarchy in the dialog
  - Add section dividers or grouping for better organization
  - Test dialog responsiveness on different screen sizes
  - _Requirements: 3.1, 3.2_

- [ ] 7. Implement auto-save functionality
  - Add automatic saving when user changes any profile setting
  - Provide visual feedback when changes are being saved
  - Handle save errors gracefully with user feedback
  - Test that changes persist correctly in both local storage and Firestore
  - _Requirements: 3.3, 4.4_

- [ ] 8. Add image preview functionality
  - Display current profile photo in the edit dialog
  - Display current wallpaper preview in the edit dialog
  - Ensure previews update immediately when user selects new images
  - Handle cases where user has no profile photo or wallpaper set
  - _Requirements: 3.2_

- [ ] 9. Implement cancel functionality for image changes
  - Add ability to cancel image selection without applying changes
  - Ensure original images are maintained when user cancels
  - Test cancel functionality for both profile photo and wallpaper
  - Provide clear UI indicators for cancel vs save actions
  - _Requirements: 3.4_

- [x] 10. Add comprehensive error handling



  - Handle network errors during image upload
  - Handle file selection cancellation gracefully
  - Handle invalid file formats with user-friendly messages
  - Handle storage quota exceeded scenarios
  - Test error recovery and user experience during failures
  - _Requirements: 4.4_

- [ ] 11. Test complete user flow
  - Test accessing profile edit through three-dots menu
  - Verify all profile options are accessible in one location
  - Test profile photo change and immediate application
  - Test wallpaper change and immediate application in chat
  - Verify that camera icon is completely removed from chat interface
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2_

- [ ] 12. Performance optimization and cleanup
  - Optimize image loading and caching for previews
  - Ensure proper disposal of image controllers and resources
  - Test memory usage with large wallpaper images
  - Add image compression if needed for better performance
  - Clean up any unused code related to the removed camera icon
  - _Requirements: 4.1, 4.2, 4.3_