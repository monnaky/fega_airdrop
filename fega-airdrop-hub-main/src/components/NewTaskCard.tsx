import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { ExternalLink, Check } from 'lucide-react';

interface NewTask {
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

interface NewTaskCardProps {
  task: NewTask;
  onVisit: (taskId: string) => void;
  onComplete: (taskId: string) => void;
  isConnected: boolean;
}

export const NewTaskCard: React.FC<NewTaskCardProps> = ({
  task,
  onVisit,
  onComplete,
  isConnected
}) => {
  const handleVisit = () => {
    window.open(task.link, '_blank', 'noopener,noreferrer');
    onVisit(task.id);
  };

  const handleComplete = async () => {
    await onComplete(task.id);
  };

  return (
    <Card className={`transition-all duration-300 ${
      task.completed 
        ? 'bg-success/10 border-success/50 dark:bg-success/5 dark:border-success/30' 
        : 'hover:shadow-lg card-glow'
    }`}>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <span className="text-2xl">{task.icon}</span>
            <div>
              <CardTitle className="text-lg">{task.name}</CardTitle>
              <Badge variant="secondary" className="mt-1">
                {task.type}
              </Badge>
            </div>
          </div>
          <div className="text-right">
            <div className="text-lg font-bold text-primary">
              +{task.reward_amount} FEGA
            </div>
          </div>
        </div>
      </CardHeader>
      
      <CardContent className="pt-0">
        <CardDescription className="mb-4">
          {task.description}
        </CardDescription>
        
        <div className="flex space-x-2">
          {!task.completed ? (
            <>
              <Button
                onClick={handleVisit}
                variant="outline"
                size="sm"
                className="flex-1"
                disabled={!isConnected}
              >
                <ExternalLink className="w-4 h-4 mr-2" />
                Visit
              </Button>
              
              <Button
                onClick={handleComplete}
                size="sm"
                className="flex-1"
                disabled={!task.visited || !isConnected}
              >
                Complete Task
              </Button>
            </>
          ) : (
            <Button
              disabled
              size="sm"
              className="flex-1 !bg-green-500 !text-white hover:!bg-green-500 !border-green-500"
            >
              <Check className="w-4 h-4 mr-2" />
              ✅ Completed
            </Button>
          )}
        </div>
        
        {!isConnected && (
          <p className="text-sm text-muted-foreground mt-2">
            Connect your wallet to complete tasks
          </p>
        )}
      </CardContent>
    </Card>
  );
};