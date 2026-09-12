import { SESClient, SendEmailCommand } from "@aws-sdk/client-ses";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { randomUUID } from "crypto";

const ses = new SESClient({});
const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "OPTIONS,POST"
};

export const handler = async (event) => {
  try {
    const body = JSON.parse(event.body || "{}");
    const { name, email, message } = body;

    if (!name || !email || !message) {
      return respond(400, { error: "name, email and message are required" });
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return respond(400, { error: "invalid email address" });
    }

    const submissionId = randomUUID();

    await ddb.send(new PutCommand({
      TableName: process.env.TABLE_NAME,
      Item: { submissionId, name, email, message, createdAt: new Date().toISOString() }
    }));

    await ses.send(new SendEmailCommand({
      Source: process.env.SENDER_EMAIL,
      Destination: { ToAddresses: [process.env.RECIPIENT_EMAIL] },
      Message: {
        Subject: { Data: `New contact form submission from ${name}` },
        Body: { Text: { Data: `Name: ${name}\nEmail: ${email}\n\nMessage:\n${message}` } }
      }
    }));

    return respond(200, { message: "Submission received", submissionId });
  } catch (err) {
    console.error(err);
    return respond(500, { error: "Internal server error" });
  }
};

function respond(statusCode, body) {
  return { statusCode, headers: CORS_HEADERS, body: JSON.stringify(body) };
}