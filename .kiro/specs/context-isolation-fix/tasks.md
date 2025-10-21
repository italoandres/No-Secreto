# Implementation Plan

- [x] 1. Create context validation utilities



  - Create ContextValidator class with validation methods
  - Create StoryContextFilter class for filtering stories by context
  - Add debug flags and logging utilities for context operations



  - _Requirements: 3.1, 3.2, 3.3_



- [ ] 2. Fix StoriesRepository context isolation
  - [ ] 2.1 Add explicit context filters to getAllSinaisRebeca method
    - Add WHERE contexto = 'sinais_rebeca' filter to Firestore query


    - Add validation to ensure only sinais_rebeca stories are returned
    - Add debug logging to track stories loaded by context
    - _Requirements: 1.1, 3.1_



  - [ ] 2.2 Add explicit context filters to getAllSinaisIsaque method
    - Add WHERE contexto = 'sinais_isaque' filter to Firestore query





    - Add validation to ensure only sinais_isaque stories are returned



    - Add debug logging to track stories loaded by context
    - _Requirements: 1.1, 3.1_



  - [ ] 2.3 Fix getAll method to filter principal context only
    - Add WHERE contexto = 'principal' filter to stories_files collection query



    - Add validation to ensure only principal stories are returned
    - Add debug logging to track principal stories loaded
    - _Requirements: 1.1, 3.1_




- [ ] 3. Fix StoryInteractionsRepository favorites isolation
  - [x] 3.1 Strengthen context filtering in getUserFavoritesStream





    - Add strict validation that contexto parameter matches returned favorites
    - Add debug logging to track favorites loaded by context
    - Add fallback handling for invalid contexts
    - _Requirements: 2.1, 2.2, 3.2_


  - [ ] 3.2 Add context validation to toggleFavorite method
    - Validate that contexto parameter is valid before saving



    - Add debug logging to track favorite operations by context
    - Ensure favorites are saved with correct context
    - _Requirements: 2.1, 3.2_




- [ ] 4. Add context validation to Enhanced Stories Viewer
  - Add context validation before loading stories in EnhancedStoriesViewerView
  - Filter stories to ensure only correct context stories are displayed
  - Add debug logging to track stories displayed by context
  - _Requirements: 1.1, 4.1, 4.2_

- [ ] 5. Add context validation to Story Favorites View
  - Add validation that loaded stories match expected context
  - Filter out stories that don't belong to the specified context
  - Add debug logging to track favorites displayed by context
  - _Requirements: 2.2, 2.3_

- [ ] 6. Fix circle notification calculations by context
  - [ ] 6.1 Fix hasUnviewedStories method context isolation
    - Ensure method only checks stories from specified context
    - Add context validation to prevent cross-context contamination
    - Add debug logging to track unviewed stories by context
    - _Requirements: 4.1, 4.2, 4.3_

  - [ ] 6.2 Fix allStoriesViewedInContext method filtering
    - Add strict context filtering to ensure only correct context stories are checked
    - Add validation that viewed stories match the context being checked
    - Add debug logging to track viewed status by context
    - _Requirements: 4.1, 4.2, 4.3_

- [ ] 7. Add comprehensive debug logging system
  - Add context operation logging to all repository methods
  - Add story loading and filtering logs with context information
  - Add favorite operation logs with context tracking
  - _Requirements: 3.1, 3.2, 3.3_

- [ ] 8. Test context isolation fixes
  - Test that Sinais Rebeca view shows only sinais_rebeca stories
  - Test that Chat Principal view shows only principal stories
  - Test that favorites are properly isolated by context
  - Test that circle notifications work correctly per context
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 4.1, 4.2, 4.3_