const { Consumer } = require("sqs-consumer");
const { SQSClient } = require("@aws-sdk/client-sqs");
const driverService = require("./driver.service");

const queueUrl = process.env.SQS_QUEUE_URL;

if (!queueUrl) {
  console.warn("SQS_QUEUE_URL is not set. SQS Consumer will not start.");
}

const app = Consumer.create({
  queueUrl: queueUrl,
  handleMessage: async (message) => {
    try {
      const body = JSON.parse(message.Body);
      console.log("Received booking request:", body);

      await driverService.handleBookingRequest(body);
    } catch (error) {
      console.error("Error processing message:", error);
      throw error;
    }
  },
  sqs: new SQSClient({
    region: process.env.AWS_REGION || "ap-southeast-1",
  }),
});

app.on("error", (err) => {
  console.error(err.message);
});

app.on("processing_error", (err) => {
  console.error(err.message);
});

module.exports = app;
