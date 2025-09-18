import { useEffect, useState } from 'react';

export const useReferralTracking = () => {
  const [isProcessingReferral, setIsProcessingReferral] = useState(false);

  useEffect(() => {
    // Check for referral code in URL
    const urlParams = new URLSearchParams(window.location.search);
    const referrerWallet = urlParams.get('ref');
    
    if (referrerWallet) {
      // Store referrer wallet in localStorage
      localStorage.setItem('referrer_wallet', referrerWallet);
      
      // Clean URL without page refresh
      const newUrl = window.location.protocol + "//" + window.location.host + window.location.pathname;
      window.history.replaceState({ path: newUrl }, '', newUrl);
    }
  }, []);

  const getReferralLink = (walletAddress: string) => {
    return `${window.location.origin}/?ref=${walletAddress}`;
  };

  return {
    isProcessingReferral,
    getReferralLink
  };
};