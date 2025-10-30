// CORS fix for Firebase Storage images
(function() {
    // Override fetch to add CORS headers for Firebase Storage
    const originalFetch = window.fetch;
    
    window.fetch = function(url, options = {}) {
        // Check if it's a Firebase Storage URL
        if (typeof url === 'string' && url.includes('firebasestorage.googleapis.com')) {
            console.log('🔥 CORS FIX: Intercepting Firebase Storage request:', url);
            
            // Add CORS headers
            options.mode = 'cors';
            options.headers = {
                ...options.headers,
                'Access-Control-Allow-Origin': '*',
            };
        }
        
        return originalFetch.call(this, url, options);
    };
    
    console.log('🔥 CORS FIX: Firebase Storage CORS fix loaded');
})();