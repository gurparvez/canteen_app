import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js";
import { JWT } from "npm:google-auth-library@9";

console.log("Hello from Functions!");

const supabase = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
);

const getAccessToken = async ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string;
  privateKey: string;
}): Promise<string> => {
  const jwtClient = new JWT({
    email: clientEmail,
    key: privateKey,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });

  const tokens = await jwtClient.authorize();
  return tokens.access_token!;
};

Deno.serve(async (req) => {
  try {
    const { record, old_record } = await req.json();

    // Check if this is a new order
    if (!old_record && record) {

      // Get all staff FCM tokens
      const { data: staffData, error: staffError } = await supabase
        .from("users")
        .select("fcm_token")
        .eq("role", "staff");

      if (staffError) {
        throw new Error(`Failed to fetch staff FCM tokens: ${staffError.message}`);
      }

      if (!staffData || staffData.length === 0) {
        throw new Error("No staff members found with valid FCM tokens");
      }

      const { default: serviceAccount } = await import("../service-account.json", {
        with: { type: "json" },
      });

      const accessToken = await getAccessToken({
        clientEmail: serviceAccount.client_email,
        privateKey: serviceAccount.private_key,
      });

      // Send notification to each staff member
      const notifications = staffData.map((staff) =>
        fetch(
          `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${accessToken}`,
            },
            body: JSON.stringify({
              message: {
                token: staff.fcm_token,
                notification: {
                  title: "New Order Received! 📦",
                  body: `Order from: ${record.user_name}, Amount: Rs.${record.total_price}`,
                },
                data: {
                  order_id: record.id,
                  click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
              },
            }),
          }
        )
      );

      const responses = await Promise.all(notifications);

      // Check if any notification failed
      const failedNotifications = responses.filter((response) => !response.ok);
      if (failedNotifications.length > 0) {
        throw new Error(`Failed to send some notifications: ${failedNotifications.length}`);
      }

      return new Response(
        JSON.stringify({
          message: "Notifications sent successfully to all staff members",
        }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ message: "No new order detected" }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: error.message || "Unknown error occurred",
        stack: error.stack,
      }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
