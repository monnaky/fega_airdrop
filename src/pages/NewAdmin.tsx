import { useState, useEffect } from 'react';
import { supabaseUser, adminAPI, getClientType, validateAdminAccess } from '@/lib/supabaseClients';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useToast } from '@/hooks/use-toast';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Trash2, Settings, Users, BarChart3, Plus, Edit, Download, LogOut, Wallet } from 'lucide-react';
import { AdminWithdrawals } from '@/components/AdminWithdrawals';

interface Task {
  id: string;
  name: string;
  description: string;
  link: string;
  reward_amount: number;
  type: string;
  created_at: string;
}

interface User {
  id: string;
  wallet_address: string;
  balance: number;
  referrer_id: string | null;
  referrals_count: number;
  referral_earnings: number;
  created_at: string;
}

interface AdminStats {
  total_users: number;
  total_tokens_distributed: number;
  total_referrals: number;
}

interface TaskFormData {
  name: string;
  link: string;
  reward_amount: string;
  type: string;
}

// Settings are now hardcoded - no longer using this interface
// interface AdminSettings {
//   referral_bonus: string;
//   claim_cooldown_hours: string;
// }

const NewAdmin = () => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [adminPassword, setAdminPassword] = useState('');
  const [tasks, setTasks] = useState<Task[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [stats, setStats] = useState<AdminStats>({
    total_users: 0,
    total_tokens_distributed: 0,
    total_referrals: 0
  });
  const [newTask, setNewTask] = useState<TaskFormData>({
    name: '',
    link: '',
    reward_amount: '',
    type: ''
  });
  const [editingTask, setEditingTask] = useState<Task | null>(null);
  // Settings are now hardcoded - removed settings state
  const [showTaskDialog, setShowTaskDialog] = useState(false);
  const [filterWallet, setFilterWallet] = useState('');
  const [filterStartDate, setFilterStartDate] = useState('');
  const [filterEndDate, setFilterEndDate] = useState('');
  const [filterMinReferrals, setFilterMinReferrals] = useState('');
  const [filterMaxReferrals, setFilterMaxReferrals] = useState('');
  const { toast } = useToast();

  // Check localStorage on mount
  useEffect(() => {
    const isAdmin = localStorage.getItem('isAdmin');
    if (isAdmin === 'true') {
      setIsAuthenticated(true);
    }
  }, []);

  useEffect(() => {
    if (isAuthenticated) {
      fetchTasks();
      fetchUsers();
      fetchStats();
      // Settings are now hardcoded - no need to fetch from database
    }
  }, [isAuthenticated]);

  const handleLogin = () => {
    // Get admin key from env (VITE_ADMIN_KEY in .env file)
    const correctPassword = 'fegaadmin@11111'; // This matches VITE_ADMIN_KEY from .env
    
    if (adminPassword === correctPassword) {
      localStorage.setItem('isAdmin', 'true');
      localStorage.setItem('adminKey', adminPassword); // Store the admin key for later use
      setIsAuthenticated(true);
      
      
      console.log('✅ Admin authenticated - will use service_role via backend API');
      
      toast({
        title: "Login successful",
        description: "Welcome to the admin panel",
      });
    } else {
      toast({
        title: "Login failed",
        description: "❌ Invalid admin key",
        variant: "destructive"
      });
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('isAdmin');
    localStorage.removeItem('adminKey'); // Clear the stored admin key
    setIsAuthenticated(false);
    
    console.log('👋 User client used - Logged out');
    
    toast({
      title: "Logged out",
      description: "You have been logged out successfully",
    });
  };

  const fetchTasks = async () => {
    try {
      console.log('🔍 Admin API used - Fetching tasks via backend...');
      const result = await adminAPI.getTasks();

      if (!result.success) {
        throw new Error(result.error);
      }
      
      console.log('✅ Tasks fetched successfully:', result.data?.length || 0);
      const safeTasks = Array.isArray(result.data) ? result.data : [];
      setTasks(safeTasks);
    } catch (error) {
      console.error('❌ Error fetching tasks:', error);
      toast({
        title: "Error",
        description: "Failed to fetch tasks",
        variant: "destructive"
      });
    }
  };

  const fetchUsers = async () => {
    try {
      console.log('🔍 Admin API used - Fetching users via backend...');
      const result = await adminAPI.getUsers();

      if (!result.success) {
        throw new Error(result.error);
      }
      
      console.log('✅ Users fetched successfully:', result.data?.length || 0);
      const safeUsers = Array.isArray(result.data) ? result.data : [];
      setUsers(safeUsers);
    } catch (error) {
      console.error('❌ Error fetching users:', error);
      toast({
        title: "Error",
        description: "Failed to fetch users",
        variant: "destructive"
      });
    }
  };

  const fetchStats = async () => {
    try {
      console.log('🔍 Admin API used - Fetching stats via backend...');
      const result = await adminAPI.getStats();
      
      if (!result.success) {
        throw new Error(result.error);
      }
      
      console.log('✅ Stats fetched successfully:', result.data);
      setStats(result.data);
    } catch (error) {
      console.error('❌ Error fetching stats:', error);
      toast({
        title: "Error", 
        description: `Failed to fetch statistics: ${error.message}`,
        variant: "destructive"
      });
    }
  };

  // Settings are now hardcoded - removed fetchSettings function completely

  const handleTaskSubmit = async () => {
    if (!newTask.name || !newTask.link || !newTask.reward_amount || !newTask.type) {
      toast({
        title: "Error",
        description: "Please fill in all required fields",
        variant: "destructive"
      });
      return;
    }

    try {
      console.log('Submitting task:', newTask);
      
      if (editingTask) {
        // Update existing task
        console.log('✏️ Admin API used - Updating task with ID:', editingTask.id);
        const result = await adminAPI.updateTask({
          id: editingTask.id,
          name: newTask.name,
          link: newTask.link,
          reward_amount: newTask.reward_amount,
          type: newTask.type
        });

        if (!result.success) {
          throw new Error(result.error);
        }
        
        console.log('✅ Task updated successfully via backend');
        toast({
          title: "Success",
          description: "Task updated successfully",
        });
      } else {
        // Add new task
        console.log('➕ Admin API used - Adding new task via backend...');
        const result = await adminAPI.createTask({
          name: newTask.name,
          link: newTask.link,
          reward_amount: newTask.reward_amount,
          type: newTask.type
        });

        if (!result.success) {
          throw new Error(result.error);
        }

        console.log('✅ Task added successfully via backend');
        toast({
          title: "Success",
          description: "Task added successfully",
        });
      }

      setNewTask({ name: '', link: '', reward_amount: '', type: '' });
      setEditingTask(null);
      setShowTaskDialog(false);
      
      fetchTasks();
    } catch (error) {
      console.error('Error in handleTaskSubmit:', error);
      toast({
        title: "Error",
        description: `Failed to ${editingTask ? 'update' : 'add'} task: ${error.message}`,
        variant: "destructive"
      });
    }
  };

  const editTask = (task: Task) => {
    setEditingTask(task);
    setNewTask({
      name: task.name,
      link: task.link,
      reward_amount: task.reward_amount.toString(),
      type: task.type
    });
    setShowTaskDialog(true);
  };

  const deleteTask = async (taskId: string) => {
    if (!confirm('Are you sure you want to delete this task? This action cannot be undone.')) {
      return;
    }
    
    try {
      console.log('🗑️ Admin API used - Deleting task with ID:', taskId);
      const result = await adminAPI.deleteTask(taskId);

      if (!result.success) {
        throw new Error(result.error);
      }

      console.log('✅ Task deleted successfully via backend');
      
      toast({
        title: "Success",
        description: "Task deleted successfully",
      });
      fetchTasks();
    } catch (error) {
      console.error('Error in deleteTask:', error);
      toast({
        title: "Error",
        description: `Failed to delete task: ${error.message}`,
        variant: "destructive"
      });
    }
  };

  const updateSetting = async (key: string, value: string) => {
    try {
  // Settings update function is removed - settings are now hardcoded
      
      toast({
        title: "Success",
        description: "Setting updated successfully",
      });
    } catch (error) {
      console.error('❌ Error in updateSetting:', error);
      toast({
        title: "Error",
        description: `Failed to update setting: ${error.message}`,
        variant: "destructive"
      });
    }
  };

  const exportUsers = async (filtered = false) => {
    try {
      console.log('🔍 Export functionality temporarily disabled for demo');
      
      toast({
        title: "Info",
        description: "Export functionality is in demo mode",
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to export users",
        variant: "destructive"
      });
    }
  };

  const resetProductionData = async () => {
    if (!confirm('Are you sure you want to reset all production data? This action cannot be undone.')) {
      return;
    }

    try {
      console.log('🔍 Admin API used - Resetting production data via backend...');
      const result = await adminAPI.resetData();
      
      if (!result.success) {
        throw new Error(result.error);
      }

      toast({
        title: "Success",
        description: "Production data reset successfully",
      });
      fetchStats();
      fetchUsers();
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to reset production data",
        variant: "destructive"
      });
    }
  };

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4" style={{background: 'var(--gradient-background)'}}>
        <Card className="w-full max-w-md card-glow">
          <CardHeader>
            <CardTitle className="text-center text-2xl font-bold gradient-text">
              🔐 FEGA Admin Login
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <Input
              type="password"
              placeholder="Enter Admin Key"
              value={adminPassword}
              onChange={(e) => setAdminPassword(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleLogin()}
              className="bg-background/50 border-primary/30 focus:border-primary/60 focus:ring-primary/20"
            />
            <Button 
              onClick={handleLogin} 
              className="w-full btn-pink"
            >
              🚀 Access Admin Panel
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen p-4 space-y-6" style={{background: 'var(--gradient-background)'}}>
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold gradient-text">
          ⚡ FEGA Admin Dashboard
        </h1>
        <div className="flex items-center gap-4">
          <p className="text-sm text-muted-foreground">✅ Logged in as Admin</p>
          <Button onClick={handleLogout} variant="outline" size="sm">
            <LogOut className="h-4 w-4 mr-2" />
            Logout
          </Button>
        </div>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="card-glow animate-pulse-glow">
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="p-3 rounded-full bg-primary/20">
                <Users className="h-6 w-6 text-primary" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground font-medium">Total Users</p>
                <p className="text-3xl font-bold gradient-text">{stats.total_users.toLocaleString()}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="card-glow animate-pulse-glow">
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="p-3 rounded-full bg-primary/20">
                <BarChart3 className="h-6 w-6 text-primary" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground font-medium">Tokens Distributed</p>
                <p className="text-3xl font-bold gradient-text">{stats.total_tokens_distributed.toLocaleString()}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="card-glow animate-pulse-glow">
          <CardContent className="p-6">
            <div className="flex items-center space-x-4">
              <div className="p-3 rounded-full bg-primary/20">
                <Users className="h-6 w-6 text-primary" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground font-medium">Total Referrals</p>
                <p className="text-3xl font-bold gradient-text">{stats.total_referrals.toLocaleString()}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="tasks" className="w-full">
        <TabsList className="grid w-full grid-cols-6">
          <TabsTrigger value="tasks">Tasks</TabsTrigger>
          <TabsTrigger value="users">Users</TabsTrigger>
          <TabsTrigger value="withdrawals">Withdrawals</TabsTrigger>
          <TabsTrigger value="settings">Settings</TabsTrigger>
          <TabsTrigger value="export">Export</TabsTrigger>
          <TabsTrigger value="system">System</TabsTrigger>
        </TabsList>

        <TabsContent value="tasks" className="space-y-4">
          <div className="flex justify-between items-center">
            <h2 className="text-xl font-semibold">Task Management</h2>
            <Dialog open={showTaskDialog} onOpenChange={setShowTaskDialog}>
              <DialogTrigger asChild>
                <Button onClick={() => {
                  setEditingTask(null);
                  setNewTask({ name: '', link: '', reward_amount: '', type: '' });
                }}>
                  <Plus className="h-4 w-4 mr-2" />
                  Add Task
                </Button>
              </DialogTrigger>
              <DialogContent className="bg-card/95 backdrop-blur-sm border-primary/20">
                <DialogHeader>
                  <DialogTitle>{editingTask ? 'Edit Task' : 'Add New Task'}</DialogTitle>
                </DialogHeader>
                <div className="space-y-4">
                  <Input
                    placeholder="Task Name"
                    value={newTask.name}
                    onChange={(e) => setNewTask({ ...newTask, name: e.target.value })}
                    className="bg-background/50 border-primary/30"
                  />
                  <Input
                    placeholder="Task Link"
                    value={newTask.link}
                    onChange={(e) => setNewTask({ ...newTask, link: e.target.value })}
                    className="bg-background/50 border-primary/30"
                  />
                  <Input
                    type="number"
                    placeholder="Reward Amount"
                    value={newTask.reward_amount}
                    onChange={(e) => setNewTask({ ...newTask, reward_amount: e.target.value })}
                    className="bg-background/50 border-primary/30"
                  />
                  <Select value={newTask.type} onValueChange={(value) => setNewTask({ ...newTask, type: value })}>
                    <SelectTrigger className="bg-background/50 border-primary/30">
                      <SelectValue placeholder="Select task type" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Twitter">Twitter</SelectItem>
                      <SelectItem value="Telegram">Telegram</SelectItem>
                      <SelectItem value="YouTube">YouTube</SelectItem>
                      <SelectItem value="Custom">Custom</SelectItem>
                    </SelectContent>
                  </Select>
                  <Button onClick={handleTaskSubmit} className="w-full">
                    {editingTask ? 'Update Task' : 'Add Task'}
                  </Button>
                </div>
              </DialogContent>
            </Dialog>
          </div>

          <Card className="card-glow">
            <CardHeader>
              <CardTitle className="gradient-text">📋 Existing Tasks</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Reward</TableHead>
                    <TableHead>Link</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {Array.isArray(tasks) ? tasks.map((task) => (
                    <TableRow key={task.id}>
                      <TableCell className="font-medium">{task.name}</TableCell>
                      <TableCell>{task.type}</TableCell>
                      <TableCell>{task.reward_amount} FEGA</TableCell>
                      <TableCell>
                        <a href={task.link} target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">
                          View
                        </a>
                      </TableCell>
                      <TableCell>
                        <div className="flex gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => editTask(task)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="destructive"
                            size="sm"
                            onClick={() => deleteTask(task.id)}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  )) : []}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="users" className="space-y-4">
          <Card className="bg-card/80 backdrop-blur-sm border-primary/20">
            <CardHeader>
              <CardTitle>User Management</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Wallet Address</TableHead>
                    <TableHead>Balance</TableHead>
                    <TableHead>Referrer</TableHead>
                    <TableHead>Created At</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {Array.isArray(users) ? users.map((user) => (
                    <TableRow key={user.id}>
                      <TableCell className="font-mono text-xs">{user.wallet_address}</TableCell>
                      <TableCell>{user.balance} FEGA</TableCell>
                      <TableCell className="font-mono text-xs">
                        {user.referrer_id ? user.referrer_id.substring(0, 10) + '...' : 'None'}
                      </TableCell>
                      <TableCell>{new Date(user.created_at).toLocaleDateString()}</TableCell>
                    </TableRow>
                  )) : []}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="settings" className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Card className="bg-card/80 backdrop-blur-sm border-primary/20">
              <CardHeader>
                <CardTitle>System Settings (Hardcoded for Launch)</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="p-4 bg-muted rounded-lg">
                  <p className="text-sm text-muted-foreground mb-4">
                    Settings are currently hardcoded for launch stability. To modify, update constants in src/utils/constants.ts
                  </p>
                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <span className="font-medium">Referral Bonus:</span>
                      <span className="font-mono">200 FEGA</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="font-medium">Claim Cooldown:</span>
                      <span className="font-mono">24 hours</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="font-medium">Min Withdrawal:</span>
                      <span className="font-mono">1000 FEGA</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="font-medium">Gas Fee:</span>
                      <span className="font-mono">0.0013 BNB</span>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="export" className="space-y-4">
          <Card className="bg-card/80 backdrop-blur-sm border-primary/20">
            <CardHeader>
              <CardTitle>Export Users</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <Input
                  placeholder="Search by wallet address"
                  value={filterWallet}
                  onChange={(e) => setFilterWallet(e.target.value)}
                  className="bg-background/50 border-primary/30"
                />
                <Input
                  type="date"
                  placeholder="Start date"
                  value={filterStartDate}
                  onChange={(e) => setFilterStartDate(e.target.value)}
                  className="bg-background/50 border-primary/30"
                />
                <Input
                  type="date"
                  placeholder="End date"
                  value={filterEndDate}
                  onChange={(e) => setFilterEndDate(e.target.value)}
                  className="bg-background/50 border-primary/30"
                />
                <Input
                  type="number"
                  placeholder="Min referrals"
                  value={filterMinReferrals}
                  onChange={(e) => setFilterMinReferrals(e.target.value)}
                  className="bg-background/50 border-primary/30"
                />
                <Input
                  type="number"
                  placeholder="Max referrals"
                  value={filterMaxReferrals}
                  onChange={(e) => setFilterMaxReferrals(e.target.value)}
                  className="bg-background/50 border-primary/30"
                />
              </div>
              <div className="flex gap-4">
                <Button onClick={() => exportUsers(false)} className="flex items-center gap-2">
                  <Download className="h-4 w-4" />
                  Export All
                </Button>
                <Button onClick={() => exportUsers(true)} variant="outline" className="flex items-center gap-2">
                  <Download className="h-4 w-4" />
                  Export Filtered
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="system" className="space-y-4">
          <Card className="bg-card/80 backdrop-blur-sm border-primary/20">
            <CardHeader>
              <CardTitle>System Controls</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="p-4 border-2 border-destructive/20 rounded-lg bg-destructive/5">
                <h3 className="font-semibold text-destructive mb-2">⚠️ Danger Zone</h3>
                <p className="text-sm text-muted-foreground mb-4">
                  This will reset all user data including balances and referrals. Tasks will be preserved.
                </p>
                <Button onClick={resetProductionData} variant="destructive">
                  Reset Production Data
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default NewAdmin;