import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Clock, CheckCircle, XCircle } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { syncUserState } from '@/services/stateSync';

interface Withdrawal {
  id: string;
  amount: number;
  status: 'pending' | 'approved' | 'rejected';
  created_at: string;
}

interface WithdrawalHistoryProps {
  walletAddress: string;
  refreshTrigger?: number;
}

export const WithdrawalHistory: React.FC<WithdrawalHistoryProps> = ({
  walletAddress,
  refreshTrigger
}) => {
  const [withdrawals, setWithdrawals] = useState<Withdrawal[]>([]);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();

  const fetchWithdrawals = async () => {
    try {
      setLoading(true);
      
      // First get the user ID from wallet address
      const { data: userData, error: userError } = await supabase
        .from('users')
        .select('id')
        .eq('wallet_address', walletAddress)
        .maybeSingle();

      if (userError || !userData) {
        console.error('User not found:', userError);
        setWithdrawals([]);
        return;
      }

      // Use a simple RPC call to get withdrawals
      const { data, error } = await supabase.rpc('exec_sql', {
        sql: `SELECT id, amount, status, created_at FROM withdrawals WHERE user_id = '${userData.id}' ORDER BY created_at DESC`
      });

      if (error) {
        throw error;
      }

      const safeData = Array.isArray(data) ? data as unknown as Withdrawal[] : [];
      setWithdrawals(safeData);
    } catch (error: any) {
      console.error('Error fetching withdrawals:', error);
      setWithdrawals([]);
      toast({
        title: "Error",
        description: "Failed to load withdrawal history",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (walletAddress) {
      fetchWithdrawals();
    }
  }, [walletAddress, refreshTrigger]);

  // Sync state on initial load
  useEffect(() => {
    const initSync = async () => {
      if (walletAddress) {
        try {
          await syncUserState(walletAddress);
        } catch (error) {
          console.error('Failed to sync user state:', error);
        }
      }
    };
    initSync();
  }, [walletAddress]);

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
          <div className="text-center">Loading withdrawal history...</div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="card-glow">
      <CardHeader>
        <CardTitle>Withdrawal History</CardTitle>
      </CardHeader>
      <CardContent>
        {withdrawals.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">
            No withdrawals yet
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Amount</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Date</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {withdrawals.map((withdrawal) => (
                <TableRow key={withdrawal.id}>
                  <TableCell className="font-medium">
                    {withdrawal.amount.toLocaleString()} FEGA
                  </TableCell>
                  <TableCell>
                    <Badge variant={getStatusVariant(withdrawal.status)} className="flex items-center w-fit space-x-1">
                      {getStatusIcon(withdrawal.status)}
                      <span className="capitalize">{withdrawal.status}</span>
                    </Badge>
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
  );
};