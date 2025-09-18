import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Clock, CheckCircle, XCircle, RefreshCw } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

interface WithdrawalWithUser {
  id: string;
  amount: number;
  status: 'pending' | 'approved' | 'rejected';
  created_at: string;
  wallet_address?: string;
  tx_hash?: string;
}

export const AdminWithdrawals: React.FC = () => {
  const [withdrawals, setWithdrawals] = useState<WithdrawalWithUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [processingIds, setProcessingIds] = useState<Set<string>>(new Set());
  const { toast } = useToast();

  const fetchWithdrawals = async () => {
    try {
      setLoading(true);
      
      // Use the new get_all_withdrawals function
      const { data, error } = await supabase.rpc('get_all_withdrawals');
      
      if (error) {
        throw error;
      }

      setWithdrawals((data as any)?.withdrawals || []);
    } catch (error: any) {
      console.error('Error fetching withdrawals:', error);
      setWithdrawals([]);
      toast({
        title: "Error",
        description: "Failed to load withdrawals",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWithdrawals();
  }, []);

  const processWithdrawal = async (withdrawalId: string, action: 'approve' | 'reject') => {
    setProcessingIds(prev => new Set([...prev, withdrawalId]));
    
    try {
      const { data, error } = await supabase.rpc('process_withdrawal' as any, {
        p_withdrawal_id: withdrawalId,
        p_action: action
      });

      if (error) {
        throw error;
      }

      const result = data as any;
      if (result && result.success) {
        toast({
          title: "Success",
          description: `Withdrawal ${action}d successfully`,
        });
        await fetchWithdrawals(); // Refresh the list
      } else {
        throw new Error(result?.error || `Failed to ${action} withdrawal`);
      }
    } catch (error: any) {
      console.error(`Error ${action}ing withdrawal:`, error);
      toast({
        title: "Error",
        description: error.message || `Failed to ${action} withdrawal`,
        variant: "destructive"
      });
    } finally {
      setProcessingIds(prev => {
        const newSet = new Set(prev);
        newSet.delete(withdrawalId);
        return newSet;
      });
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pending':
        return <Clock className="h-4 w-4" />;
      case 'approved':
        return <CheckCircle className="h-4 w-4" />;
      case 'rejected':
        return <XCircle className="h-4 w-4" />;
      default:
        return <Clock className="h-4 w-4" />;
    }
  };

  const getStatusVariant = (status: string) => {
    switch (status) {
      case 'pending':
        return 'secondary';
      case 'approved':
        return 'default';
      case 'rejected':
        return 'destructive';
      default:
        return 'secondary';
    }
  };

  if (loading) {
    return (
      <Card className="card-glow">
        <CardContent className="p-6">
          <div className="text-center">Loading withdrawals...</div>
        </CardContent>
      </Card>
    );
  }

  const safeWithdrawals = Array.isArray(withdrawals) ? withdrawals : [];
  const pendingWithdrawals = safeWithdrawals.filter(w => w.status === 'pending');
  const processedWithdrawals = safeWithdrawals.filter(w => w.status !== 'pending');

  return (
    <div className="space-y-6">
      {/* Pending Withdrawals */}
      <Card className="card-glow">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center space-x-2">
              <CheckCircle className="h-5 w-5" />
              <span>Automated Withdrawals (All approved instantly)</span>
            </CardTitle>
            <Button onClick={fetchWithdrawals} variant="outline" size="sm">
              <RefreshCw className="h-4 w-4 mr-2" />
              Refresh
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-muted-foreground">
            All withdrawals are now processed automatically via smart contract.
            <br />
            <span className="text-sm text-primary">No manual approval required!</span>
          </div>
        </CardContent>
      </Card>

      {/* All Withdrawals History */}
      <Card className="card-glow">
        <CardHeader>
          <CardTitle>All Withdrawals History</CardTitle>
        </CardHeader>
        <CardContent>
          {safeWithdrawals.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              No withdrawals found
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Wallet</TableHead>
                  <TableHead>Amount</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>TX Hash</TableHead>
                  <TableHead>Date</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {safeWithdrawals.map((withdrawal) => (
                  <TableRow key={withdrawal.id}>
                    <TableCell className="font-mono text-sm">
                      {withdrawal.wallet_address?.slice(0, 6)}...{withdrawal.wallet_address?.slice(-4)}
                    </TableCell>
                    <TableCell className="font-medium">
                      {withdrawal.amount.toLocaleString()} FEGA
                    </TableCell>
                    <TableCell>
                      <Badge variant={getStatusVariant(withdrawal.status)} className="flex items-center w-fit space-x-1">
                        {getStatusIcon(withdrawal.status)}
                        <span className="capitalize">{withdrawal.status}</span>
                      </Badge>
                    </TableCell>
                    <TableCell className="font-mono text-xs">
                      {withdrawal.tx_hash ? (
                        <span title={withdrawal.tx_hash}>
                          {withdrawal.tx_hash.slice(0, 8)}...{withdrawal.tx_hash.slice(-6)}
                        </span>
                      ) : (
                        <span className="text-muted-foreground">N/A</span>
                      )}
                    </TableCell>
                    <TableCell>
                      {new Date(withdrawal.created_at).toLocaleDateString()}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
};