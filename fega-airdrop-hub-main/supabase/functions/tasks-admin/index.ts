// tasks-admin Edge Function
// Provides admin CRUD for tasks with header-based ADMIN_API_KEY auth.
// Uses service role key to bypass RLS for writes.

import { createClient } from "npm:@supabase/supabase-js";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-admin-api-key",
};

function getEnv(name: string, fallback?: string): string {
  const v = Deno.env.get(name)?.trim();
  if (v) return v;
  if (fallback) return fallback;
  throw new Error(`Missing required environment variable: ${name}`);
}

const SUPABASE_URL = getEnv("SUPABASE_URL", "https://idcfieikxrcopimxfxup.supabase.co");
const SERVICE_ROLE_KEY = getEnv("SUPABASE_SERVICE_ROLE_KEY");
const ADMIN_API_KEY = getEnv("ADMIN_API_KEY");

const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

function unauthorized(msg = "Unauthorized") {
  return new Response(JSON.stringify({ error: msg }), { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } });
}

function badRequest(msg = "Bad Request", details?: any) {
  return new Response(JSON.stringify({ error: msg, details }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
}

function ok(body: any) {
  return new Response(JSON.stringify(body), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
}

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method Not Allowed" }), { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    const adminKey = req.headers.get("x-admin-api-key")?.trim();
    if (!adminKey || adminKey !== ADMIN_API_KEY) {
      return unauthorized();
    }

    const { action, payload } = await req.json().catch(() => ({ action: undefined, payload: undefined }));
    if (!action) {
      return badRequest("Missing 'action' in request body");
    }

    // Actions: health, list, create, update, delete, toggle, getSettings, updateSettings
    switch (action) {
      case "health": {
        return ok({ ok: true });
      }

      case "list": {
        const { includeInactive } = payload || {};
        const query = adminClient.from("tasks").select("*").order("created_at", { ascending: false });
        if (!includeInactive) query.eq("is_active", true);
        const { data, error } = await query;
        if (error) return badRequest("Failed to list tasks", error.message);
        return ok({ data });
      }

      case "create": {
        const { title, description, task_url, task_type, reward_tokens, is_active = true } = payload || {};
        if (!title || !task_url || !task_type || typeof reward_tokens !== "number") {
          return badRequest("Missing required fields: title, task_url, task_type, reward_tokens");
        }
        const { data, error } = await adminClient
          .from("tasks")
          .insert([{ title, description, task_url, task_type, reward_tokens, is_active }])
          .select("*")
          .single();
        if (error) return badRequest("Failed to create task", error.message);
        return ok({ data });
      }

      case "update": {
        const { id, ...fields } = payload || {};
        if (!id) return badRequest("Missing 'id' for update");
        const allowed = ["title", "description", "task_url", "task_type", "reward_tokens", "is_active"] as const;
        const updatePayload: Record<string, any> = {};
        for (const key of allowed) {
          if (key in fields) updatePayload[key] = (fields as any)[key];
        }
        if (Object.keys(updatePayload).length === 0) return badRequest("No valid fields to update");
        const { data, error } = await adminClient.from("tasks").update(updatePayload).eq("id", id).select("*").single();
        if (error) return badRequest("Failed to update task", error.message);
        return ok({ data });
      }

      case "delete": {
        const { id } = payload || {};
        if (!id) return badRequest("Missing 'id' for delete");
        const { error } = await adminClient.from("tasks").delete().eq("id", id);
        if (error) return badRequest("Failed to delete task", error.message);
        return ok({ success: true });
      }

      case "toggle": {
        const { id, is_active } = payload || {};
        if (!id || typeof is_active !== "boolean") return badRequest("Missing 'id' or 'is_active' for toggle");
        const { data, error } = await adminClient.from("tasks").update({ is_active }).eq("id", id).select("*").single();
        if (error) return badRequest("Failed to toggle task", error.message);
        return ok({ data });
      }

      case "getSettings": {
        const { data, error } = await adminClient.from("platform_settings").select("*");
        if (error) return badRequest("Failed to get settings", error.message);
        return ok({ data });
      }

      case "updateSettings": {
        const { settings } = payload || {};
        if (!settings || typeof settings !== "object") return badRequest("Missing 'settings' object");
        
        const updates = [];
        for (const [key, value] of Object.entries(settings)) {
          if (typeof value === "string" || typeof value === "number") {
            updates.push(
              adminClient
                .from("platform_settings")
                .update({ setting_value: String(value) })
                .eq("setting_key", key)
            );
          }
        }
        
        const results = await Promise.all(updates);
        const errors = results.filter(result => result.error);
        if (errors.length > 0) {
          return badRequest("Failed to update some settings", errors.map(e => e.error?.message));
        }
        
        return ok({ success: true });
      }

      default:
        return badRequest(`Unknown action: ${action}`);
    }
  } catch (e: any) {
    console.error("tasks-admin error", e);
    return new Response(JSON.stringify({ error: "Internal Server Error", details: e?.message || String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
