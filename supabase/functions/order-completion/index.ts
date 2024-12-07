// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'npm:@supabase/supabase-js'
import { JWT } from "npm:google-auth-library@9"

console.log("Hello from Functions!")

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
)

const getAccessToken = async ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string,
  privateKey: string,
}): Promise<string> => {
  const jwtClient = new JWT({
    email: clientEmail,
    key: privateKey,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });

  const tokens = await jwtClient.authorize();
  return tokens.access_token!;
}

Deno.serve(async (req) => {
  try {
    const { record, old_record } = await req.json()

    // Check if status was changed to completed
    if (old_record.status !== 'completed' && record.status === 'completed') {
      // Get user's FCM token
      const { data: userData, error: userError } = await supabase
        .from('users')
        .select('fcm_token')
        .eq('id', record.user_id)
        .single()

      if (userError || !userData?.fcm_token) {
        throw new Error('Could not find user FCM token')
      }

      const { default: serviceAccount } = await import("../service-account.json", {
        with: { type: "json" }
      })

      const accessToken = await getAccessToken({
        clientEmail: serviceAccount.client_email,
        privateKey: serviceAccount.private_key
      })

      // Send notification using FCM
      const response = await fetch(`https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: userData.fcm_token,
            notification: {
              title: 'Order Completed! 🎉',
              body: `Your order of Rs.${record.total_price} is ready for pickup!`,
            },
            data: {
              order_id: record.id,
              click_action: 'FLUTTER_NOTIFICATION_CLICK'
            }
          }
        })
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(`Failed to send notification: ${JSON.stringify(errorData)}`)
      }

      const responseData = await response.json()
      return new Response(
        JSON.stringify({
          message: 'Notification sent successfully',
          response: responseData
        }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ message: 'No notification needed' }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({
        error: error.message || 'Unknown error occurred',
        stack: error.stack
      }),
      {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
})
