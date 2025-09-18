export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "12.2.12 (cd3cf9e)"
  }
  public: {
    Tables: {
      debug_log: {
        Row: {
          created_at: string | null
          id: number
          message: string | null
        }
        Insert: {
          created_at?: string | null
          id?: number
          message?: string | null
        }
        Update: {
          created_at?: string | null
          id?: number
          message?: string | null
        }
        Relationships: []
      }
      settings: {
        Row: {
          admin_password: string | null
          claim_cooldown_hours: number | null
          claim_gas_fee: number | null
          gas_fee_wallet_address: string | null
          id: number
          min_withdrawal: number | null
          referral_bonus: number | null
        }
        Insert: {
          admin_password?: string | null
          claim_cooldown_hours?: number | null
          claim_gas_fee?: number | null
          gas_fee_wallet_address?: string | null
          id?: number
          min_withdrawal?: number | null
          referral_bonus?: number | null
        }
        Update: {
          admin_password?: string | null
          claim_cooldown_hours?: number | null
          claim_gas_fee?: number | null
          gas_fee_wallet_address?: string | null
          id?: number
          min_withdrawal?: number | null
          referral_bonus?: number | null
        }
        Relationships: []
      }
      tasks: {
        Row: {
          created_at: string | null
          id: string
          link: string
          name: string
          reward_amount: number | null
          type: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          link: string
          name: string
          reward_amount?: number | null
          type?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          link?: string
          name?: string
          reward_amount?: number | null
          type?: string | null
        }
        Relationships: []
      }
      user_tasks: {
        Row: {
          completed_at: string | null
          id: string
          task_id: string | null
          user_wallet: string | null
        }
        Insert: {
          completed_at?: string | null
          id?: string
          task_id?: string | null
          user_wallet?: string | null
        }
        Update: {
          completed_at?: string | null
          id?: string
          task_id?: string | null
          user_wallet?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_tasks_task_id_fkey"
            columns: ["task_id"]
            isOneToOne: false
            referencedRelation: "tasks"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          balance: number | null
          created_at: string | null
          id: string
          referral_earnings: number | null
          referrals_count: number | null
          referrer_id: string | null
          wallet_address: string
          weekly_claim_last: string | null
        }
        Insert: {
          balance?: number | null
          created_at?: string | null
          id?: string
          referral_earnings?: number | null
          referrals_count?: number | null
          referrer_id?: string | null
          wallet_address: string
          weekly_claim_last?: string | null
        }
        Update: {
          balance?: number | null
          created_at?: string | null
          id?: string
          referral_earnings?: number | null
          referrals_count?: number | null
          referrer_id?: string | null
          wallet_address?: string
          weekly_claim_last?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "users_referrer_id_fkey"
            columns: ["referrer_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      withdrawals: {
        Row: {
          amount: number
          created_at: string | null
          id: string
          status: string | null
          tx_hash: string | null
          user_id: string | null
        }
        Insert: {
          amount: number
          created_at?: string | null
          id?: string
          status?: string | null
          tx_hash?: string | null
          user_id?: string | null
        }
        Update: {
          amount?: number
          created_at?: string | null
          id?: string
          status?: string | null
          tx_hash?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "withdrawals_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_process_withdrawal: {
        Args: { new_status: string; withdrawal_id: string }
        Returns: Json
      }
      admin_update_settings: {
        Args: {
          p_admin_key: string
          p_claim_cooldown_hours: number
          p_claim_gas_fee: number
          p_gas_fee_wallet_address: string
          p_min_withdrawal: number
          p_referral_bonus: number
        }
        Returns: Json
      }
      calculate_referral_earnings: {
        Args: { referrer_profile_id: string }
        Returns: number
      }
      claim_daily_bonus: {
        Args: { p_wallet_address: string }
        Returns: Json
      }
      claim_weekly_bonus: {
        Args: { p_wallet_address: string }
        Returns: Json
      }
      cleanup_test_data: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      complete_task: {
        Args: { p_task_id: string; p_user_wallet: string }
        Returns: Json
      }
      complete_task_enhanced: {
        Args: { p_task_id: string; p_wallet_address: string }
        Returns: Json
      }
      complete_task_with_claim: {
        Args: { p_task_id: string; p_user_wallet: string }
        Returns: Json
      }
      exec_sql: {
        Args: { sql: string }
        Returns: Json
      }
      get_admin_data: {
        Args: Record<PropertyKey, never>
        Returns: Json
      }
      get_admin_stats: {
        Args: Record<PropertyKey, never>
        Returns: Json
      }
      get_all_withdrawals: {
        Args: Record<PropertyKey, never>
        Returns: Json
      }
      get_referral_stats: {
        Args: { p_wallet_address: string }
        Returns: Json
      }
      get_settings: {
        Args: Record<PropertyKey, never>
        Returns: Json
      }
      get_withdrawal_status: {
        Args: { p_wallet_address: string }
        Returns: Json
      }
      increment_profile_tokens: {
        Args: {
          p_task_increment?: number
          p_token_increment: number
          p_wallet_address: string
        }
        Returns: undefined
      }
      increment_referral: {
        Args: { p_referrer_wallet: string }
        Returns: undefined
      }
      increment_referral_count: {
        Args: { p_token_increment: number; p_wallet_address: string }
        Returns: undefined
      }
      is_admin: {
        Args: Record<PropertyKey, never>
        Returns: boolean
      }
      log_error: {
        Args: { error_message: string }
        Returns: undefined
      }
      process_referral_enhanced: {
        Args: { p_new_user_wallet: string; p_referrer_code: string }
        Returns: Json
      }
      process_withdrawal: {
        Args: { p_action: string; p_withdrawal_id: string }
        Returns: Json
      }
      request_withdrawal: {
        Args: { p_amount: number; p_wallet_address: string }
        Returns: Json
      }
      request_withdrawal_enhanced: {
        Args: { p_amount: number; p_wallet_address: string }
        Returns: Json
      }
      reset_production_data: {
        Args: Record<PropertyKey, never>
        Returns: Json
      }
      validate_referral_creation: {
        Args: { p_referred_id: string; p_referrer_id: string }
        Returns: boolean
      }
      validate_referral_creation_wallet: {
        Args: { p_referred_wallet: string; p_referrer_wallet: string }
        Returns: boolean
      }
      validate_reset: {
        Args: Record<PropertyKey, never>
        Returns: Json
      }
      validate_task_completion_access: {
        Args: { p_wallet_address: string }
        Returns: boolean
      }
      withdraw_to_wallet: {
        Args: { p_amount: number; p_wallet_address: string }
        Returns: Json
      }
      withdraw_tokens: {
        Args: { p_amount: number; p_user_wallet: string }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
