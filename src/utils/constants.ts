// FEGA Token Airdrop Constants - Production Ready
export const FEGA_CONFIG = {
  // Token Economics
  BASE_REWARD: 1000,           // Base tokens for completing all tasks
  REFERRAL_BONUS: 200,         // Bonus tokens per successful referral (HARDCODED FOR LAUNCH)
  TASK_REWARDS: {
    twitter: 100,
    telegram: 150,
    youtube: 200,
    instagram: 100,
    tiktok: 100,
  },

  // Claim Settings
  CLAIM_PERIOD: {
    start: { day: 6, hour: 12 }, // Saturday 12:00 PM UTC
    end: { day: 1, hour: 0 },    // Monday 12:00 AM UTC
  },

  // URLs
  DOMAIN: 'airdrop.fegatoken.com',
  SOCIAL_LINKS: {
    twitter: 'https://twitter.com/FegatToken',
    telegram: 'https://t.me/FegatToken',
    youtube: 'https://youtube.com/@FegatToken',
    instagram: 'https://instagram.com/FegatToken',
  },

  // Network Configuration
  CHAIN_ID: 56, // Binance Smart Chain
  CHAIN_NAME: 'Binance Smart Chain',
  
  // Contract Addresses (Production)
  CONTRACTS: {
    FEGA_TOKEN: '0x...', // To be set with actual token contract
    AIRDROP: '0x...',    // To be set with actual airdrop contract
  },

  // Admin Configuration
  ADMIN_ROUTE: '/admin',
  SUPER_ADMIN_WALLETS: [
    '0x19d9Edb0D6B6635bB24062537d6478CedF6a0874' // Add admin wallet addresses
  ],

  // Feature Flags
  FEATURES: {
    REFERRALS_ENABLED: true,
    CLAIMS_ENABLED: true,
    ADMIN_PANEL_ENABLED: true,
    PRODUCTION_BANNER: true,
  }
};

// HARDCODED SETTINGS FOR LAUNCH - BYPASSING DATABASE
export const LAUNCH_SETTINGS = {
  REFERRAL_BONUS: 200,          // Hardcoded referral bonus percentage
  CLAIM_COOLDOWN_HOURS: 24,     // Hardcoded claim cooldown in hours
  MIN_WITHDRAWAL: 1000,         // Minimum withdrawal amount in tokens
  CLAIM_GAS_FEE: 0.0013,       // Gas fee required for claims in BNB
  GAS_FEE_WALLET: '0x19d9Edb0D6B6635bB24062537d6478CedF6a0874' // Admin wallet for gas fees
};

// Helper Functions
export const isClaimPeriod = (): boolean => {
  const now = new Date();
  const dayOfWeek = now.getUTCDay(); // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
  const hour = now.getUTCHours();
  
  // Saturday from 12 PM onwards
  if (dayOfWeek === 6 && hour >= 12) return true;
  
  // All of Sunday
  if (dayOfWeek === 0) return true;
  
  // Monday before 12 AM (effectively Sunday night)
  if (dayOfWeek === 1 && hour < 12) return true;
  
  return false;
};

export const getNextClaimDate = (): Date => {
  const now = new Date();
  const nextSaturday = new Date(now);
  
  // Calculate days until next Saturday
  const daysUntilSaturday = (6 - now.getUTCDay() + 7) % 7;
  if (daysUntilSaturday === 0 && now.getUTCHours() < 12) {
    // It's Saturday but before 12 PM, so today is the claim day
    nextSaturday.setUTCHours(12, 0, 0, 0);
  } else {
    // Go to next Saturday
    nextSaturday.setUTCDate(now.getUTCDate() + (daysUntilSaturday || 7));
    nextSaturday.setUTCHours(12, 0, 0, 0);
  }
  
  return nextSaturday;
};

export const getReferralLink = (walletAddress: string): string => {
  const baseUrl = window.location.hostname === 'localhost' 
    ? window.location.origin 
    : `https://${FEGA_CONFIG.DOMAIN}`;
  
  return `${baseUrl}/?ref=${walletAddress.toLowerCase()}`;
};

export const formatTokenAmount = (amount: number): string => {
  if (amount >= 1000000) {
    return `${(amount / 1000000).toFixed(1)}M`;
  } else if (amount >= 1000) {
    return `${(amount / 1000).toFixed(1)}K`;
  }
  return amount.toString();
};