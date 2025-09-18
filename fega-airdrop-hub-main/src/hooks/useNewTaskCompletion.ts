import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAddress } from '@thirdweb-dev/react';
import { useToast } from '@/hooks/use-toast';
import { completeTask } from '@/services/fegaService';
import { handleApiError, showToast } from '@/utils/errorHandler';
import { syncUserState } from '@/services/stateSync';

export interface NewTask {
  id: string;
  name: string;
  description: string;
  link: string;
  reward_amount: number;
  type: string;
  completed: boolean;
  visited: boolean;
  icon: string;
}

export const useNewTaskCompletion = () => {
  const address = useAddress();
  const { toast } = useToast();
  const [tasks, setTasks] = useState<NewTask[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (address) {
      loadTasks();
    }
  }, [address]);

  const loadTasks = async () => {
    if (!address) return;

    try {
      setLoading(true);
      
      // Fetch all tasks
      const { data: allTasks, error: tasksError } = await supabase
        .from('tasks')
        .select('*')
        .order('created_at', { ascending: true });

      if (tasksError) {
        console.error('Error fetching tasks:', tasksError);
        return;
      }

      // Fetch completed task IDs for this wallet
      const { data: completions, error: completionsError } = await supabase
        .from('user_tasks')
        .select('task_id')
        .eq('user_wallet', address.toLowerCase());

      if (completionsError) {
        console.error('Error fetching completions:', completionsError);
        return;
      }

      const completedTaskIds = new Set(completions?.map(c => c.task_id) || []);

      // Map tasks with completion status
      const tasksWithStatus = allTasks?.map(task => ({
        id: task.id,
        name: task.name,
        description: task.name, // Use name as description since no separate description field
        reward_amount: task.reward_amount,
        link: task.link,
        type: task.type,
        completed: completedTaskIds.has(task.id),
        visited: false,
        icon: getTaskIcon(task.type)
      })) || [];

      setTasks(tasksWithStatus);
    } catch (error) {
      console.error('Error loading tasks:', error);
    } finally {
      setLoading(false);
    }
  };

  const getTaskIcon = (taskType: string): string => {
    const icons: { [key: string]: string } = {
      twitter: '𝕏',
      telegram: '📱',
      youtube: '📹',
      instagram: '📷',
      tiktok: '🎵',
      discord: '💬'
    };
    return icons[taskType.toLowerCase()] || '✨';
  };

  const markTaskVisited = (taskId: string) => {
    setTasks(prev => prev.map(task => 
      task.id === taskId ? { ...task, visited: true } : task
    ));
  };

  const markTaskCompleted = async (taskId: string) => {
    if (!address) return;

    try {
      const task = tasks.find(t => t.id === taskId);
      if (!task || task.completed) return;

      // Since we don't have claims table, check user_tasks instead
      const { data: existingTask } = await supabase
        .from('user_tasks')
        .select('id')
        .eq('task_id', taskId)
        .eq('user_wallet', address.toLowerCase())
        .maybeSingle();

      if (existingTask) {
        showToast("You have already completed this task.", 'error', toast);
        return;
      }

      // Complete the task using the service
      const result = await completeTask(address.toLowerCase(), taskId);

      if (result.success) {
        // Update local state immediately for instant UI feedback
        setTasks(prev => prev.map(t => 
          t.id === taskId ? { ...t, completed: true } : t
        ));

        showToast(`You earned ${result.reward_amount} FEGA tokens!`, 'success', toast);
        
        // Sync user state after successful completion
        await syncUserState(address.toLowerCase()).catch(console.error);
      } else {
        const errorMessage = handleApiError(result);
        showToast(errorMessage, 'error', toast);
      }

    } catch (error) {
      console.error('Error in markTaskCompleted:', error);
      const errorMessage = handleApiError(error);
      showToast(errorMessage, 'error', toast);
    }
  };

  const allTasksCompleted = tasks.length > 0 && tasks.every(task => task.completed);
  const completedTasksCount = tasks.filter(task => task.completed).length;

  return {
    tasks,
    loading,
    allTasksCompleted,
    completedTasksCount,
    markTaskVisited,
    markTaskCompleted,
    refetch: loadTasks
  };
};