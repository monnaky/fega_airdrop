import { useToast } from '@/hooks/use-toast';

export interface ApiError {
  message?: string;
  error?: string;
  code?: string;
  details?: string;
}

/**
 * Centralized error handling utility for the FEGA app
 */
export const handleApiError = (error: any): string => {
  // Handle Supabase/PostgreSQL errors
  if (error?.message) {
    const message = error.message.toLowerCase();
    
    // Map common database errors to user-friendly messages
    if (message.includes('insufficient balance') || message.includes('balance')) {
      return 'Insufficient balance. Please check your current balance and try again.';
    }
    
    if (message.includes('task already completed') || message.includes('already completed')) {
      return 'This task has already been completed.';
    }
    
    if (message.includes('user not found')) {
      return 'Please connect your wallet to continue.';
    }
    
    if (message.includes('minimum withdrawal')) {
      return error.message; // Return the specific minimum withdrawal message
    }
    
    if (message.includes('weekly claim not available') || message.includes('cooldown')) {
      return 'Daily claim is not available yet. Please wait for the cooldown to expire.';
    }
    
    if (message.includes('invalid referrer') || message.includes('referral')) {
      return 'Invalid referral link. Please check the link and try again.';
    }
    
    if (message.includes('network') || message.includes('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    
    // Return the original message if no specific mapping found
    return error.message;
  }
  
  // Handle RPC function response errors
  if (error?.error) {
    return handleApiError({ message: error.error });
  }
  
  // Handle string errors
  if (typeof error === 'string') {
    return handleApiError({ message: error });
  }
  
  // Fallback for unknown errors
  return 'An unexpected error occurred. Please try again.';
};

/**
 * Show a toast notification with consistent styling
 */
export const showToast = (
  message: string, 
  type: 'success' | 'error' | 'info' = 'info',
  toast: ReturnType<typeof useToast>['toast']
) => {
  const titles = {
    success: '✅ Success!',
    error: '❌ Error',
    info: 'ℹ️ Info'
  };
  
  toast({
    title: titles[type],
    description: message,
    variant: type === 'error' ? 'destructive' : 'default',
  });
};

/**
 * Wrapper for async operations with standardized error handling
 */
export const withErrorHandling = async <T>(
  operation: () => Promise<T>,
  toast: ReturnType<typeof useToast>['toast'],
  successMessage?: string
): Promise<T | null> => {
  try {
    const result = await operation();
    if (successMessage) {
      showToast(successMessage, 'success', toast);
    }
    return result;
  } catch (error) {
    const errorMessage = handleApiError(error);
    showToast(errorMessage, 'error', toast);
    return null;
  }
};