import { NextResponse } from "next/server";
import { createServiceRoleClient } from "@/lib/supabase/server";

/**
 * Companion to the reject endpoint (Phase 4, section 3) — the review queue
 * needs both actions to exist symmetrically, even though this one doesn't
 * generate feedback-loop data itself. Sets stage = 'scheduled', the next
 * stage per the content_items.stage enum (Phase 5, scheduling/publishing,
 * hasn't been built in this codebase yet, so there is no more specific
 * scheduling logic to defer to here — this is exactly what the brief's
 * "(or whatever the next stage is per your scheduling logic from Phase 5)"
 * falls back to in that case).
 */
export async function POST(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  const supabase = createServiceRoleClient();

  const { data: existing, error: fetchError } = await supabase
    .from("content_items")
    .select("id, stage")
    .eq("id", id)
    .single();

  if (fetchError || !existing) {
    return NextResponse.json({ error: "content_item not found." }, { status: 404 });
  }

  // Same rationale as the reject endpoint's guard: approving only makes
  // sense once an item has passed automated QA, whether or not assets have
  // been generated yet.
  const approvableStages = ["qa_passed", "assets_generated"];
  if (!approvableStages.includes(existing.stage)) {
    return NextResponse.json(
      {
        error: `content_item is at stage '${existing.stage}' — only items at ${approvableStages.map((s) => `'${s}'`).join(" or ")} (i.e. already passed automated QA) can be approved.`,
      },
      { status: 409 }
    );
  }

  const { data, error: updateError } = await supabase
    .from("content_items")
    .update({ stage: "scheduled" })
    .eq("id", id)
    .select()
    .single();

  if (updateError) {
    return NextResponse.json({ error: updateError.message }, { status: 500 });
  }

  return NextResponse.json(data);
}
