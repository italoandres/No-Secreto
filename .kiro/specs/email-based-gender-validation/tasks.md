# Implementation Plan

- [x] 1. Fix core login synchronization logic


  - Replace the problematic `_syncUserSexo()` method with `_validateAndSyncUserSexo()`
  - Implement Firestore-first validation logic that reads sexo from Firestore and updates TokenUsuario
  - Add proper error handling for Firestore read failures
  - _Requirements: 1.1, 1.2, 3.1, 3.2_



- [ ] 2. Remove problematic correction logic from UsuarioRepository
  - Remove the inverse logic that updates Firestore based on TokenUsuario in `getUser()` method
  - Replace with proper validation that updates TokenUsuario based on Firestore value



  - Ensure admin status validation remains intact
  - _Requirements: 3.1, 3.2, 4.1, 4.2_

- [ ] 3. Enhance debug utilities for better troubleshooting
  - Update `printCurrentUserState()` to show before/after values during correction
  - Add automatic detection and fixing of inconsistencies
  - Improve logging to clearly show the source of truth (Firestore) vs local cache (TokenUsuario)
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 4. Test and validate the fix with existing problematic accounts
  - Test with the existing female account (itala3@gmail.com) that was showing male content
  - Verify that login now correctly reads sexo from Firestore and updates TokenUsuario
  - Confirm UI shows correct buttons (👰‍♀️ for female, 🤵 for male users)
  - _Requirements: 1.1, 1.2, 1.3, 4.3_

- [ ] 5. Verify new user registration flow still works correctly
  - Test that new user onboarding properly saves sexo to Firestore
  - Confirm that subsequent logins maintain the correct sexo from Firestore
  - Ensure no regression in the registration process
  - _Requirements: 2.1, 2.2, 2.3_