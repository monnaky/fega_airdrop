import React from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { LAUNCH_SETTINGS } from '@/utils/constants';
import { InfoIcon } from 'lucide-react';

const AdminSettings = () => {
  const currentSettings = [
    { label: 'Referral Reward (%)', value: LAUNCH_SETTINGS.REFERRAL_BONUS },
    { label: 'Claim Cooldown (Hours)', value: LAUNCH_SETTINGS.CLAIM_COOLDOWN_HOURS },
    { label: 'Minimum Withdrawal Amount', value: LAUNCH_SETTINGS.MIN_WITHDRAWAL },
    { label: 'Claim Gas Fee (BNB)', value: LAUNCH_SETTINGS.CLAIM_GAS_FEE },
    { label: 'Gas Fee Wallet Address', value: LAUNCH_SETTINGS.GAS_FEE_WALLET }
  ];

  return (
    <div className="container mx-auto p-6 max-w-2xl">
      <Card>
        <CardHeader>
          <CardTitle>Admin Settings (Hardcoded for Launch)</CardTitle>
          <div className="mt-4 p-4 bg-red-50 dark:bg-red-900/20 rounded-lg border border-red-200 dark:border-red-800">
            <h3 className="font-semibold text-red-800 dark:text-red-200 mb-2">⚠️ CRITICAL REQUIREMENTS</h3>
            <ul className="text-sm text-red-700 dark:text-red-300 space-y-1">
              <li>• Admin wallet MUST be funded with BNB for gas fees</li>
              <li>• Admin wallet MUST hold sufficient FEGA tokens for withdrawals</li>
              <li>• Monitor admin wallet balance regularly to prevent withdrawal failures</li>
            </ul>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          <Alert>
            <InfoIcon className="h-4 w-4" />
            <AlertDescription>
              Settings are currently hardcoded in the application code for launch stability. 
              To modify these values, a developer must update the constants in src/utils/constants.ts
            </AlertDescription>
          </Alert>
          
          {currentSettings.map(setting => (
            <div key={setting.label} className="space-y-2">
              <label className="text-sm font-medium">{setting.label}</label>
              <div className="p-3 bg-muted rounded-md font-mono text-sm">
                {setting.value}
              </div>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
};

export default AdminSettings;