# Implementation Plan - Stories System Fixes

- [x] 1. Configure Firebase indexes for stories system



  - Update firestore.indexes.json with required composite indexes
  - Add indexes for story_likes collection with storyId and dataCadastro fields
  - Add indexes for story_comments collection with isBlocked, parentCommentId, storyId, and dataCadastro fields




  - _Requirements: 1.1, 1.2, 1.3_

- [ ] 2. Implement stories history migration system
  - Create StoriesHistoryService class with methods for moving expired stories
  - Implement moveExpiredStoriesToHistory method to check and migrate 24h+ old stories


  - Implement moveStoryToHistory method for individual story migration
  - Add getHistoryStories method to retrieve user's historical stories
  - _Requirements: 2.1, 2.2, 2.3_



- [x] 3. Enhance image loading with retry logic and caching


  - Create EnhancedImageLoader utility class for robust image handling


  - Implement buildCachedImage method with placeholder and error widgets
  - Add preloadImage method for next stories optimization
  - Implement clearImageCache method for memory management
  - _Requirements: 3.1, 3.2, 3.3_


- [ ] 4. Implement auto-close functionality for stories
  - Create StoryAutoCloseController class to manage automatic story progression
  - Implement startAutoClose method with different timers for images vs videos
  - Add pauseAutoClose and resumeAutoClose methods for user interaction handling
  - Implement cancelAutoClose method for cleanup
  - _Requirements: 4.1, 4.2, 4.3_





- [ ] 5. Update stories repository with history integration
  - Modify stories repository to use enhanced image loading



  - Integrate history migration calls in story lifecycle
  - Update error handling to use new retry mechanisms


  - Add logging for migration and loading operations
  - _Requirements: 2.1, 3.1_

- [x] 6. Update enhanced stories viewer with auto-close



  - Integrate StoryAutoCloseController into EnhancedStoriesViewerView
  - Implement timer management based on story type (image/video)
  - Add gesture handling to pause/resume auto-close
  - Update story progression logic to work with auto-close
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 7. Update stories views to use enhanced image loading
  - Replace standard image widgets with EnhancedImageLoader in all story views
  - Update stories_view.dart to use new image loading system
  - Update story_favorites_view.dart with enhanced loading
  - Add error handling and retry logic to all image displays
  - _Requirements: 3.1, 3.2, 3.3_

- [ ] 8. Test and validate all fixes
  - Test Firebase index queries work without errors
  - Verify stories automatically move to history after 24 hours
  - Test image loading with network interruptions and retries
  - Validate auto-close functionality with different story types
  - Test integration between all components
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 4.1, 4.2, 4.3_